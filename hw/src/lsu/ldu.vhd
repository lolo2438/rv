library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library hw;
use hw.tag_pkg.all;

library common;
use common.fnct.priority_encoder;
use common.fnct.bit_reverse;

library riscv;
use riscv.RV32I.all;

entity ldu is
  generic(
    RST_LEVEL : std_logic := '0';   --! Reset level
    LDU_LEN   : natural;            --! LDU_SIZE = 2**LDU_LEN
    GRP_LEN   : natural;
    STU_LEN   : natural;            --! Store buffer len
    TAG_LEN   : natural;            --! Tag length
    XLEN      : natural             --! Operand size
  );
  port(
    -- CTRL I/F
    i_clk             : in  std_logic;                                --! ldu clock
    i_arst            : in  std_logic;                                --! async reset
    i_srst            : in  std_logic;                                --! sync reset
    o_empty           : out std_logic;                                --! ldu is empty
    o_full            : out std_logic;                                --! ldu is full

    -- DISPATCH I/F
    i_disp_load       : in  std_logic;                                --! load instruction
    i_disp_f3         : in  std_logic_vector(2 downto 0);             --! l/s f3
    i_disp_va         : in  std_logic_vector(XLEN-1 downto 0);        --! address field value for load/store
    i_disp_ta         : in  std_logic_vector(TAG_LEN-1 downto 0);     --! Tag for the address
    i_disp_ra         : in  std_logic;                                --! address ready flag

    i_disp_tq         : in  std_logic_vector(TAG_LEN-1 downto 0);     --! destination tag of the loaded data

    -- GRP I/F
    i_wr_grp          : in  std_logic_vector(GRP_LEN-1 downto 0);     --! group to attribute to the stores
    i_rd_grp          : in  std_logic_vector(GRP_LEN-1 downto 0);     --! group to attribute to the stores
    o_rd_grp_match    : out std_logic;                                --! the input group specified is active in the ldu

    -- STU I/F
    i_stu_issue       : in  std_logic;                                --! '1' when store operation is issued
    i_stu_addr        : in  std_logic_vector(STU_LEN-1 downto 0);     --! store buffer address that is issued
    i_stu_data        : in  std_logic_vector(XLEN-1 downto 0);        --! stu data fowarding
    i_stu_dep         : in  std_logic_vector(2**STU_LEN-1 downto 0);  --! stu current dependencies

    -- MEM WR I/F
    i_mem_wr_rdy      : in  std_logic;                                --! memory unit is ready for a store
    o_mem_wr_valid    : out std_logic;                                --! the store is valid
    o_mem_wr_addr     : out std_logic_vector(XLEN-1 downto 0);        --! address of the store op
    o_mem_wr_qr       : out std_logic_vector(LDU_LEN-1 downto 0);     --! Write back address of the LDU

    -- MEM RD I/F
    i_mem_rd_valid    : out std_logic;                                --! write back valid
    i_mem_rd_qr       : out std_logic_vector(LDU_LEN-1 downto 0);     --! write back address
    i_mem_rd_data     : out std_logic_vector(XLEN-1 downto 0);        --! write back data

    -- CDB READ I/F
    i_cdbr_vq         : in  std_logic_vector(XLEN-1 downto 0);        --! data from the cdb bus
    i_cdbr_tq         : in  std_logic_vector(TAG_LEN-1 downto 0);     --! Tag from the cdb bus
    i_cdbr_rq         : in  std_logic;                                --! CDB ready flag

    -- CDB WR I/F
    o_cdbw_vq         : out std_logic_vector(XLEN-1 downto 0);        --! Data to write on the bus
    o_cdbw_tq         : out std_logic_vector(TAG_LEN-1 downto 0);     --! Tag to write on the cdb bus
    o_cdbw_req        : out std_logic;                                --! Request to the cdb bus
    o_cdbw_lh         : out std_logic;                                --! Look ahead flag indicates that there are at least 2 values that are ready
    i_cdbw_ack        : in  std_logic                                 --! Acknowledge from the cdb bus
  );
end entity;

architecture rtl of ldu is

  constant LDU_SIZE : natural := 2**LDU_LEN;
  constant STU_SIZE : natural := 2**STU_LEN;

  ---
  -- LOAD BUFFER
  ---
  type ldu_buf_field_t is record
    addr        : std_logic_vector(XLEN-1 downto 0);        -- Mem addr to load from
    addr_tag    : std_logic_vector(TAG_LEN-1 downto 0);     -- Address to snoop for addr if not ready
    addr_rdy    : std_logic;                                -- ADDR field is ready

    data        : std_logic_vector(XLEN-1 downto 0);        -- Data loaded from memory
    data_tag    : std_logic_vector(TAG_LEN-1 downto 0);     -- Destination tag for the data

    grp         : std_logic_vector(GRP_LEN-1 downto 0);
    f3          : std_logic_vector(2 downto 0);             -- Funct3
    busy        : std_logic;                                -- The ldu field is active
    commited    : std_logic;                                -- The ldu field operation has been commited to the memory
    done        : std_logic;                                -- The ldu field has been populated with the memory value

    st_spec     : std_logic;                                -- SPECULATIVE: A store address was not ready but the load operation is still executed
    st_dep      : std_logic_vector(STU_SIZE-1 downto 0);    -- The stu entries of which the load depends on (store addr not ready) are stored here. When updated, the load will verify
  end record;

  type ldu_buf_t is array (0 to LDU_SIZE-1) of ldu_buf_field_t;

  signal ldu_entry  : ldu_buf_field_t;
  signal ldu        : ldu_buf_t;
  signal disp_ptr   : unsigned(LDU_LEN-1 downto 0);
  signal issue_ptr  : unsigned(LDU_LEN-1 downto 0);
  signal load_rdy   : std_logic_vector(0 to LDU_SIZE-1);
  signal full       : std_logic;
  signal empty      : std_logic;
  signal commit     : std_logic;

  signal dispatch : std_logic;

  signal busy_flags : std_logic_vector(0 to LDU_SIZE-1);
  signal dispatch_flags : std_logic_vector(0 to LDU_SIZE-1);
  signal done_flags : std_logic_vector(0 to LDU_SIZE-1);
  signal retire_flags : std_logic_vector(0 to LDU_SIZE-1);
  signal commit_flags : std_logic_vector(0 to LDU_SIZE-1);

  signal grp_cmp_flags : std_logic_vector(0 to LDU_SIZE-1);
  signal rd_grp_match : std_logic;

  signal sched_wr_addr : std_logic_vector(LDU_LEN-1 downto 0);
  signal sched_rd_addr : std_logic_vector(LDU_LEN-1 downto 0);

  signal load : std_logic;

  signal retire     : std_logic;
  signal retire_ptr : unsigned(LDU_LEN-1 downto 0);

  signal ldu_done_pairs : std_logic_vector(0 to STU_SIZE-2);
  signal ldu_lh : std_logic;

  signal wb_data_f3 : std_logic_vector(2 downto 0);
  signal wb_data : std_logic_vector(XLEN-1 downto 0);

  signal shed_rdy : std_logic;

  signal commit_rdy : std_logic;

begin

  ---
  -- INPUT
  ---
  load <= i_disp_load;

  commit <= i_mem_wr_rdy and rd_grp_match and shed_rdy and commit_rdy;

  retire <= i_cdbw_ack and (or retire_flags);

  wb_data_f3 <= ldu(to_integer(unsigned(i_mem_rd_qr))).f3;

  -- TODO: Rethink about memory alignments
  with wb_data_f3 select
    wb_data <= std_logic_vector(resize(signed(i_mem_rd_data(7 downto 0)), wb_data'length))    when FUNCT3_LB,
               std_logic_vector(resize(signed(i_mem_rd_data(15 downto 0)), wb_data'length))   when FUNCT3_LH,
               std_logic_vector(resize(unsigned(i_mem_rd_data(7 downto 0)), wb_data'length))  when FUNCT3_LBU,
               std_logic_vector(resize(unsigned(i_mem_rd_data(15 downto 0)), wb_data'length)) when FUNCT3_LHU,
               i_mem_rd_data                                                                  when FUNCT3_LW,
               (others => 'X') when others;

  ---
  -- LOGIC
  ---
  ldu_entry <= (
    addr        => i_disp_va,
    addr_tag    => i_disp_ta,
    addr_rdy    => i_disp_ra,
    data        => (others => 'X'),
    data_tag    => i_disp_tq,
    grp         => i_wr_grp,
    f3          => i_disp_f3,
    busy        => '1',
    commited    => '0',
    done        => '0',
    st_spec     => '0',
    st_dep      => i_stu_dep
  );

  dispatch <= load and not full;

  p_ldu:
  process(i_clk, i_arst)
  begin
    if i_arst = RST_LEVEL then
      for i in 0 to LDU_SIZE-1 loop
        ldu(i).busy     <= '0';
        ldu(i).commited <= '0';
        ldu(i).done     <= '0';
      end loop;
    elsif rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        for i in 0 to LDU_SIZE-1 loop
          ldu(i).busy     <= '0';
          ldu(i).commited <= '0';
          ldu(i).done     <= '0';
        end loop;

      else
        -- NEW ENTRY
        if dispatch = '1' then
          ldu(to_integer(disp_ptr)) <= ldu_entry;
        end if;

        -- CDB WRITE BACK
        if i_cdbr_rq = '1' then
          for i in 0 to STU_SIZE-1 loop
            if (ldu(i).busy      = '1' and
                ldu(i).commited  = '0' and
                ldu(i).addr_rdy  = '0' and
                ldu(i).addr_tag  = i_cdbr_tq) then

                ldu(i).addr     <= i_cdbr_vq;
                ldu(i).addr_rdy <= '1';
            end if;
          end loop;
        end if;

        -- DATA WRITE BACK
        if i_mem_rd_valid = '1' then
          ldu(to_integer(unsigned(i_mem_rd_qr))).data <= wb_data;
          ldu(to_integer(unsigned(i_mem_rd_qr))).done <= '1';
        end if;

        -- ST DEPENDENCIES
        if i_stu_issue = '1' then
          for i in 0 to LDU_SIZE-1 loop
            if ldu(i).st_dep(to_integer(unsigned(i_stu_addr))) = '1' and ldu(i).busy = '1' then
              -- check address
              if ldu(i).addr_rdy = '1' and ldu(i).addr = i_stu_addr then
                ldu(i).data <= i_stu_data;
                ldu(i).done <= '1';
              end if;

              ldu(i).st_dep(to_integer(unsigned(i_stu_addr))) <= '0';
            end if;
          end loop;
        end if;

        -- LOAD SHEDULE
        if commit = '1' then
          ldu(to_integer(issue_ptr)).commited <= '1';
        end if;

        -- LOAD RETIRE
        if retire = '1' then
          ldu(to_integer(retire_ptr)).busy <= '0';
        end if;
      end if;
    end if;
  end process;


  g_flags:
  for i in 0 to LDU_SIZE-1 generate
    busy_flags(i) <= ldu(i).busy;
    dispatch_flags(i) <= not ldu(i).busy;
    done_flags(i) <= ldu(i).done;
    commit_flags(i) <= ldu(i).busy and not (ldu(i).commited or ldu(i).done);
    retire_flags(i) <= ldu(i).busy and ldu(i).done;
    grp_cmp_flags(i) <= '1' when ldu(i).grp = std_logic_vector(i_rd_grp) else '0';
    load_rdy(i) <= ldu(i).busy and (not ldu(i).commited) and (not ldu(i).done) and grp_cmp_flags(i);
  end generate;


  g_done_pairs:
  for i in 0 to LDU_SIZE-2 generate
    ldu_done_pairs(i) <= ldu(i).done and ldu(i+1).done;
  end generate;
  ldu_lh <= or ldu_done_pairs;

  full  <= and busy_flags;
  empty <= nor busy_flags;

  disp_ptr <= unsigned(priority_encoder(dispatch_flags));

  retire_ptr <= unsigned(priority_encoder(retire_flags));

  rd_grp_match <= or grp_cmp_flags;

  sched_wr_addr <= std_logic_vector(disp_ptr);

  commit_rdy <= or commit_flags;

  u_ldu_shed: entity hw.otm
  generic map (
    RST_LEVEL => RST_LEVEL,
    ADDR_LEN  => LDU_LEN
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
    o_rd_rdy    => shed_rdy
  );

  issue_ptr <= unsigned(sched_rd_addr);

  ---
  -- OUTPUT
  ---

  o_mem_wr_valid   <= commit;
  o_mem_wr_addr    <= ldu(to_integer(issue_ptr)).addr;
  o_rd_grp_match   <= rd_grp_match;
  o_mem_wr_qr      <= std_logic_vector(issue_ptr);

  o_empty         <= empty;
  o_full          <= full;

  o_cdbw_req      <= or done_flags;
  o_cdbw_lh       <= ldu_lh;
  o_cdbw_vq       <= ldu(to_integer(retire_ptr)).data;
  o_cdbw_tq       <= ldu(to_integer(retire_ptr)).data_tag;

end architecture;

