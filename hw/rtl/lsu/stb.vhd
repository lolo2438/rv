library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library rtl;
use rtl.common_pkg.all;

entity stb is
  generic (
    RST_LEVEL : std_logic := '0';
    STB_LEN   : natural;
    GRP_LEN   : natural;
    TAG_LEN   : natural;
    XLEN      : natural
  );
  port (
    -- Control I/F
    i_clk   : in  std_logic;
    i_arst  : in  std_logic;
    i_srst  : in  std_logic;
    o_full  : out std_logic;

    -- Dispatch I/F
    i_disp_valid  : in  std_logic;                                --! Dispatch data is valid
    i_disp_store  : in  std_logic;                                --! Store instruction
    i_disp_f3     : in  std_logic_vector(2 downto 0);             --! L/S F3

    i_disp_va     : in  std_logic_vector(XLEN-1 downto 0);        --! Address field value for Load/Store
    i_disp_ta     : in  std_logic_vector(TAG_LEN-1 downto 0);     --! Address tag to look for if it's not ready
    i_disp_ra     : in  std_logic;                                --! Address ready flag

    i_disp_vd     : in  std_logic_vector(XLEN-1 downto 0);        --! Data field value for Store
    i_disp_td     : in  std_logic_vector(TAG_LEN-1 downto 0);     --! Data tag to look for if it's not ready
    i_disp_rd     : in  std_logic;                                --! Data ready flag

    -- GRP I/F
    i_wr_grp        : in  std_logic_vector(GRP_LEN-1 downto 0);     --! Group to attribute to the stores
    i_rd_grp        : in  std_logic_vector(GRP_LEN-1 downto 0);     --! Group to attribute to the stores
    o_rd_grp_match  : out std_logic;                                --! The input group specified is active in the LDB

    -- CDB I/F
    i_cdb_vq      : in  std_logic_vector(XLEN-1 downto 0);        --! Data from the CDB bus
    i_cdb_tq      : in  std_logic_vector(TAG_LEN-1 downto 0);     --! Tag from the CDB bus
    i_cdb_rq      : in  std_logic;                                --! CDB Ready flag

    -- LDB I/F
    o_stb_dep     : out std_logic_vector(2**STB_LEN-1 downto 0);  --! Dependency flags for Loads
    o_stb_addr    : out std_logic_vector(STB_LEN-1 downto 0);     --! Address of the dispatched store to clear the dependency flag

    -- Issue I/F
    i_issue_rdy   : in  std_logic;                                --! Memory unit is ready for a store
    o_issue_valid : out std_logic;                                --! The store is valid
    o_issue_f3    : out std_logic_vector(2 downto 0);             --! F3 of the store
    o_issue_addr  : out std_logic_vector(XLEN-1 downto 0);        --! Address of the store op
    o_issue_data  : out std_logic_vector(XLEN-1 downto 0)         --! Data of the store op
  );
end entity;

architecture rtl of stb is

  constant STB_SIZE : natural := 2**STB_LEN;

  type stb_buf_field_t is record
    addr        : std_logic_vector(XLEN-1 downto 0);
    addr_src    : std_logic_vector(TAG_LEN-1 downto 0);
    addr_rdy    : std_logic;

    data        : std_logic_vector(XLEN-1 downto 0);
    data_src    : std_logic_vector(TAG_LEN-1 downto 0);
    data_rdy    : std_logic;

    grp         : std_logic_vector(GRP_LEN-1 downto 0);

    f3          : std_logic_vector(2 downto 0);
    busy        : std_logic;
    commited    : std_logic;
  end record;

  type stb_buf_t is array (0 to STB_SIZE-1) of stb_buf_field_t;

  signal grp_match : std_logic;
  signal current_grp : std_logic_vector(GRP_LEN-1 downto 0);

  signal store    : std_logic;
  signal stb      : stb_buf_t;
  signal wr_ptr   : natural range 0 to STB_SIZE-1;
  signal rd_ptr   : natural range 0 to STB_SIZE-1;
  signal full     : std_logic;
  signal commit   : std_logic;

  signal busy_flags : std_logic_vector(0 to STB_SIZE-1);
  signal stb_deps   : std_logic_vector(0 to STB_SIZE-1);
  signal store_rdy  : std_logic;

  signal stb_entry : stb_buf_field_t;

begin

  ---
  -- INPUT
  ---
  store <= i_disp_valid and i_disp_store;

  stb_entry <= (
    addr_rdy    => i_disp_ra,
    addr        => i_disp_va,
    addr_src    => i_disp_ta,
    data        => i_disp_vd,
    data_rdy    => i_disp_rd,
    data_src    => i_disp_td,
    f3          => i_disp_f3,
    grp         => i_wr_grp,
    busy        => '1',
    commited    => '0'
  );

  commit <= store_rdy and i_issue_rdy;

  ---
  -- LOGIC
  ---
  p_stb:
  process(i_clk, i_arst)
  begin
    if i_arst = RST_LEVEL then
      for i in 0 to STB_SIZE-1 loop
        stb(i).busy     <= '0';
        stb(i).commited <= '0';
      end loop;
      wr_ptr <= 0;
      rd_ptr <= 0;

    elsif rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        for i in 0 to STB_SIZE-1 loop
          stb(i).busy     <= '0';
          stb(i).commited <= '0';
        end loop;
        wr_ptr <= 0;
        rd_ptr <= 0;

      else
      -- NEW ENTRY
        if store = '1' and full = '0' then
          stb(wr_ptr) <= stb_entry;
          wr_ptr <= wr_ptr + 1;
        end if;

      -- CDB WRITEBACK
        if i_cdb_rq = '1' then
          for i in 0 to STB_SIZE-1 loop
            if stb(i).busy = '1' and stb(i).commited = '0' then
              if stb(i).addr_rdy = '0' and stb(i).addr_src = i_cdb_tq then
                stb(i).addr <= i_cdb_vq;
                stb(i).addr_rdy <= '1';
              end if;

              if stb(i).data_rdy = '0' and stb(i).data_src = i_cdb_tq then
                stb(i).data <= i_cdb_vq;
                stb(i).data_rdy <= '1';
              end if;
            end if;
          end loop;
        end if;

      -- COMMIT STORE
        if commit = '1' then
          stb(rd_ptr).commited <= '1';
          stb(rd_ptr).busy <= '0';
          rd_ptr <= rd_ptr + 1;
        end if;
      end if;
    end if;
  end process;


  p_flags_map:
  for i in 0 to STB_SIZE-1 generate
    busy_flags(i) <= stb(i).busy;
    stb_deps(i) <= stb(i).busy and not stb(i).commited;
  end generate;

  full <= and busy_flags;

  current_grp <= stb(rd_ptr).grp;
  grp_match <= '1' when i_rd_grp = current_grp else '0';
  store_rdy <= stb(rd_ptr).data_rdy and stb(rd_ptr).addr_rdy and stb(rd_ptr).busy and grp_match;


  ---
  -- OUTPUT
  ---
  o_full <= full;
  o_rd_grp_match <= grp_match;
  o_stb_dep <= bit_reverse(stb_deps);
  o_stb_addr <= std_logic_vector(to_unsigned(rd_ptr, o_stb_addr'length));

  o_issue_valid <= commit;
  o_issue_f3    <= stb(rd_ptr).f3;
  o_issue_addr  <= stb(rd_ptr).addr;
  o_issue_data  <= stb(rd_ptr).data;

end architecture;
