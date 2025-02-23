library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library rtl;
use rtl.common_pkg.all;

library riscv;
use riscv.RV32I.all;

entity ldb is
  generic(
    RST_LEVEL : std_logic := '0';   --! Reset level
    LDB_LEN   : natural;            --! LDB_SIZE = 2**LDB_LEN
    GRP_LEN   : natural;
    STB_LEN   : natural;            --! Store buffer len
    TAG_LEN   : natural;            --! Tag length
    XLEN      : natural             --! Operand size
  );
  port(
    -- CONTROL I/F
    i_clk         : in  std_logic;                                --! LDB Clock
    i_arst        : in  std_logic;                                --! Async Reset
    i_srst        : in  std_logic;                                --! Sync Reset
    o_full        : out std_logic;

    -- DISPATCH I/F
    i_disp_valid  : in  std_logic;                                --! Dispatch data is valid
    i_disp_load   : in  std_logic;                                --! Load instruction
    i_disp_f3     : in  std_logic_vector(2 downto 0);             --! L/S F3
    i_disp_tq     : in  std_logic_vector(TAG_LEN-1 downto 0);     --! Address to store the load result
    i_disp_va     : in  std_logic_vector(XLEN-1 downto 0);        --! Address field value for Load/Store
    i_disp_ta     : in  std_logic_vector(TAG_LEN-1 downto 0);     --! Address tag to look for if it's not ready
    i_disp_ra     : in  std_logic;                                --! Address ready flag

    -- CDB I/F
    i_cdb_vq      : in  std_logic_vector(XLEN-1 downto 0);        --! Data from the CDB bus
    i_cdb_tq      : in  std_logic_vector(TAG_LEN-1 downto 0);     --! Tag from the CDB bus
    i_cdb_rq      : in  std_logic;                                --! CDB Ready flag

    -- GROUP I/F
    i_wr_grp        : in  std_logic_vector(GRP_LEN-1 downto 0);     --! Group to attribute to the stores
    i_rd_grp        : in  std_logic_vector(GRP_LEN-1 downto 0);     --! Group to attribute to the stores
    o_rd_grp_match  : out std_logic;                                --! The input group specified is active in the LDB

    -- STB I/F
    i_stb_issue   : in std_logic;                                 --! '1' when store operation is issued
    i_stb_addr    : in std_logic_vector(STB_LEN-1 downto 0);      --! Store buffer address that is issued
    i_stb_data    : in std_logic_vector(XLEN-1 downto 0);         --! stb data fowarding
    i_stb_dep     : in std_logic_vector(2**STB_LEN-1 downto 0);   --! STB current dependencies

    -- ISSUE I/F
    i_issue_rdy   : in  std_logic;                                --! Memory unit is ready for a store
    o_issue_valid : out std_logic;                                --! The store is valid
    o_issue_addr  : out std_logic_vector(XLEN-1 downto 0);        --! Address of the store op
    o_issue_ldb_ptr : out std_logic_vector(LDB_LEN-1 downto 0);

    -- WB I/F
    i_wb_valid      : out std_logic;                                  --! Write back valid
    i_wb_ldb_ptr    : out std_logic_vector(LDB_LEN-1 downto 0);       --! Write back address
    i_wb_data       : out std_logic_vector(XLEN-1 downto 0);          --! Write back data

    -- CDB WR I/F
    o_cdb_vq      : out std_logic_vector(XLEN-1 downto 0);     --! Data to write on the bus
    o_cdb_tq      : out std_logic_vector(TAG_LEN-1 downto 0);  --! Tag to write on the CDB bus
    o_cdb_req     : out std_logic;                             --! Request to the CDB bus
    o_cdb_lh      : out std_logic;                             --! Look Ahead flag indicates that there are at least 2 values that are ready
    i_cdb_ack     : in  std_logic                              --! Acknowledge from the CDB bus
  );
end entity;

architecture rtl of ldb is

  constant LDB_SIZE : natural := 2**LDB_LEN;
  constant STB_SIZE : natural := 2**STB_LEN;

  ---
  -- LOAD BUFFER
  ---
  type ldb_buf_field_t is record
    addr        : std_logic_vector(XLEN-1 downto 0);        -- Mem addr to load from
    addr_src    : std_logic_vector(TAG_LEN-1 downto 0);     -- TAG to snoop for addr if not ready
    addr_rdy    : std_logic;                                -- ADDR field is ready

    data        : std_logic_vector(XLEN-1 downto 0);        -- Data loaded from memory
    data_dst    : std_logic_vector(TAG_LEN-1 downto 0);     -- Destination of the loaded data in the ROB

    grp         : std_logic_vector(GRP_LEN-1 downto 0);
    f3          : std_logic_vector(2 downto 0);             -- Funct3
    busy        : std_logic;                                -- The ldb field is active
    commited    : std_logic;                                -- The ldb field operation has been commited to the memory
    done        : std_logic;                                -- The ldb field has been populated with the memory value

    st_spec     : std_logic;                                -- SPECULATIVE: A store address was not ready but the load operation is still executed
    st_dep      : std_logic_vector(STB_SIZE-1 downto 0);    -- The stb entries of which the load depends on (store addr not ready) are stored here. When updated, the load will verify
  end record;

  type ldb_buf_t is array (0 to LDB_SIZE-1) of ldb_buf_field_t;

  signal ldb_entry  : ldb_buf_field_t;
  signal ldb        : ldb_buf_t;
  signal disp_ptr     : natural range 0 to LDB_SIZE-1;
  signal issue_ptr     : natural range 0 to LDB_SIZE-1;
  signal load_rdy   : std_logic_vector(0 to LDB_LEN-1);
  signal full       : std_logic;
  signal commit     : std_logic;

  signal dispatch : std_logic;

  signal busy_flags : std_logic_vector(0 to LDB_SIZE-1);
  signal done_flags : std_logic_vector(0 to LDB_SIZE-1);

  signal grp_cmp_flags : std_logic_vector(0 to LDB_SIZE-1);
  signal rd_grp_match : std_logic;

  signal sched_wr_addr : std_logic_vector(LDB_LEN-1 downto 0);
  signal sched_rd_addr : std_logic_vector(LDB_LEN-1 downto 0);

  signal load : std_logic;

  signal retire      : std_logic;
  signal retire_ptr : natural range 0 to LDB_SIZE-1;

  signal ldb_done_pairs : std_logic_vector(0 to STB_SIZE-2);
  signal ldb_lh : std_logic;

  signal wb_data_f3 : std_logic_vector(2 downto 0);
  signal wb_data : std_logic_vector(XLEN-1 downto 0);

begin

  ---
  -- INPUT
  ---
  load <= i_disp_load and i_disp_valid;

  commit <= i_issue_rdy and rd_grp_match;

  retire <= i_cdb_ack;

  wb_data_f3 <= ldb(to_integer(unsigned(i_wb_ldb_ptr))).f3;

  -- TODO: Rethink about memory alignments
  with wb_data_f3 select
    wb_data <= std_logic_vector(resize(signed(i_wb_data(7 downto 0)), wb_data'length))    when FUNCT3_LB,
               std_logic_vector(resize(signed(i_wb_data(15 downto 0)), wb_data'length))   when FUNCT3_LH,
               std_logic_vector(resize(unsigned(i_wb_data(7 downto 0)), wb_data'length))  when FUNCT3_LBU,
               std_logic_vector(resize(unsigned(i_wb_data(15 downto 0)), wb_data'length)) when FUNCT3_LHU,
               i_wb_data                                                                  when FUNCT3_LW,
               (others => 'X') when others;

  ---
  -- LOGIC
  ---
  ldb_entry <= (
    addr        => i_disp_va,
    addr_src    => i_disp_ta,
    addr_rdy    => i_disp_ra,
    data        => (others => 'X'),
    data_dst    => i_disp_tq,
    grp         => i_wr_grp,
    f3          => i_disp_f3,
    busy        => '1',
    commited    => '0',
    done        => '0',
    st_spec     => '0',
    st_dep      => i_stb_dep
  );

  dispatch <= load and not full;

  --TODO
  --retire_ptr <=

  p_ldb:
  process(i_clk, i_arst)
  begin
    if i_arst = RST_LEVEL then
    elsif rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        for i in 0 to LDB_SIZE-1 loop
          ldb(i).busy     <= '0';
          ldb(i).commited <= '0';
          ldb(i).done     <= '0';
        end loop;

        disp_ptr <= 0;
      else
        -- NEW ENTRY
        if dispatch = '1' then
          ldb(disp_ptr) <= ldb_entry;
        end if;

        -- CDB WRITE BACK
        if i_cdb_rq = '1' then
          for i in 0 to STB_SIZE-1 loop
            if (ldb(i).busy      = '1' and
                ldb(i).commited  = '0' and
                ldb(i).addr_rdy  = '0' and
                ldb(i).addr_src  = i_cdb_tq) then

                ldb(i).addr     <= i_cdb_vq;
                ldb(i).addr_rdy <= '1';
            end if;
          end loop;
        end if;

        -- DATA WRITE BACK
        if i_wb_valid = '1' then
          ldb(to_integer(unsigned(i_wb_ldb_ptr))).data <= wb_data;
          ldb(to_integer(unsigned(i_wb_ldb_ptr))).done <= '1';
        end if;

        -- ST DEPENDENCIES
        if i_stb_issue = '1' then
          for i in 0 to LDB_SIZE-1 loop
            if ldb(i).st_dep(to_integer(unsigned(i_stb_addr))) = '1' and ldb(i).busy = '1' then
              -- check address
              if ldb(i).addr_rdy = '1' and ldb(i).addr = i_stb_addr then
                ldb(i).data <= i_stb_data;
                ldb(i).done <= '1';
              end if;

              ldb(i).st_dep(to_integer(unsigned(i_stb_addr))) <= '0';
            end if;
          end loop;
        end if;

        -- LOAD SHEDULE
        if commit = '1' then
          ldb(issue_ptr).commited <= '1';
        end if;

        -- LOAD RETIRE
        if retire = '1' then
          ldb(retire_ptr).busy <= '0';
        end if;
      end if;
    end if;
  end process;


  g_flags:
  for i in 0 to LDB_SIZE-1 generate
    busy_flags(i) <= ldb(i).busy;
    done_flags(i) <= ldb(i).done;
    grp_cmp_flags(i) <= '1' when ldb(i).grp = std_logic_vector(i_rd_grp) else '0';
    load_rdy(i) <= ldb(i).busy and (not ldb(i).commited) and (not ldb(i).done) and grp_cmp_flags(i);
  end generate;

  g_done_pairs:
  for i in 0 to LDB_SIZE-2 generate
    ldb_done_pairs(i) <= ldb(i).done and ldb(i+1).done;
  end generate;
  ldb_lh <= or ldb_done_pairs;

  full <= and busy_flags;

  rd_grp_match <= or grp_cmp_flags;

  sched_wr_addr <= std_logic_vector(to_unsigned(disp_ptr, sched_wr_addr'length));

  u_ldb_shed: entity work.rv_otm(rtl)
  generic map (
    RST_LEVEL => RST_LEVEL,
    ADDR_LEN  => LDB_LEN
  )
  port map(
    i_clk       => i_clk,
    i_arst      => i_arst,
    i_srst      => i_srst,
    o_empty     => open,
    o_full      => open,
    i_we        => dispatch,
    i_re        => commit,
    i_wr_addr   => sched_wr_addr,
    i_rd_mask   => load_rdy,
    o_rd_addr   => sched_rd_addr,
    o_rd_valid  => open
  );

  issue_ptr <= to_integer(unsigned(sched_rd_addr));

  ---
  -- OUTPUT
  ---
  o_issue_valid   <= commit;
  o_issue_addr    <= ldb(issue_ptr).addr;
  o_rd_grp_match  <= rd_grp_match;
  o_issue_ldb_ptr <= std_logic_vector(to_unsigned(issue_ptr, o_issue_ldb_ptr'length));

  o_full      <= full;

  o_cdb_req   <= or done_flags;
  o_cdb_lh    <= ldb_lh;
  o_cdb_vq    <= ldb(retire_ptr).data;
  o_cdb_tq    <= ldb(retire_ptr).data_dst;

end architecture;

