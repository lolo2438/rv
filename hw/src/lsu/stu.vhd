library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stu is
  generic (
    RST_LEVEL : std_logic := '0';
    STU_LEN   : natural;
    GRP_LEN   : natural;
    TAG_LEN   : natural;
    XLEN      : natural
  );
  port (
    -- Control I/F
    i_clk           : in  std_logic;                                --! System clock
    i_arst          : in  std_logic;                                --! Asynchronous reset
    i_srst          : in  std_logic;                                --! Synchronous reset
    o_empty         : out std_logic;                                --! STU is empty
    o_full          : out std_logic;                                --! STU is full

    -- Dispatch I/F
    i_disp_store    : in  std_logic;                                --! Store instruction
    i_disp_f3       : in  std_logic_vector(2 downto 0);             --! L/S F3

    i_disp_va       : in  std_logic_vector(XLEN-1 downto 0);        --! Address field value for Load/Store
    i_disp_ta       : in  std_logic_vector(TAG_LEN-1 downto 0);     --! Address tag to look for if it's not ready
    i_disp_ra       : in  std_logic;                                --! Address ready flag

    i_disp_vd       : in  std_logic_vector(XLEN-1 downto 0);        --! Data field value for Store
    i_disp_td       : in  std_logic_vector(TAG_LEN-1 downto 0);     --! Data tag to look for if it's not ready
    i_disp_rd       : in  std_logic;                                --! Data ready flag

    o_disp_qr       : out std_logic_vector(STU_LEN-1 downto 0);     --! STU address to write back to

    -- GRP I/F
    i_wr_grp        : in  std_logic_vector(GRP_LEN-1 downto 0);     --! Group to set for the store operation
    i_rd_grp        : in  std_logic_vector(GRP_LEN-1 downto 0);     --! Current group to read
    o_rd_grp_match  : out std_logic;                                --! Indicates that there is at least one entry of rd_grp still waiting to be executed

    -- CDB RD I/F
    i_cdbr_vq       : in  std_logic_vector(XLEN-1 downto 0);        --! Data from the CDB bus
    i_cdbr_tq       : in  std_logic_vector(TAG_LEN-1 downto 0);     --! Tag from the CDB bus
    i_cdbr_rq       : in  std_logic;                                --! CDB Ready flag

    -- LDU I/F
    o_stu_dep       : out std_logic_vector(2**STU_LEN-1 downto 0);  --! Dependency flags for Loads
    o_stu_addr      : out std_logic_vector(STU_LEN-1 downto 0);     --! Address of the dispatched store to clear the dependency flag

    -- Issue I/F
    i_issue_rdy     : in  std_logic;                                --! Memory unit is ready for a store
    o_issue_valid   : out std_logic;                                --! The store is valid
    o_issue_f3      : out std_logic_vector(2 downto 0);             --! F3 of the store
    o_issue_addr    : out std_logic_vector(XLEN-1 downto 0);        --! Address of the store op
    o_issue_data    : out std_logic_vector(XLEN-1 downto 0)         --! Data of the store op
  );
end entity;

architecture rtl of stu is

  constant STU_SIZE : natural := 2**STU_LEN;

  type stu_buf_field_t is record
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

  type stb_t is array (0 to STU_SIZE-1) of stu_buf_field_t;

  signal grp_match : std_logic;
  signal current_grp : std_logic_vector(GRP_LEN-1 downto 0);

  signal store    : std_logic;
  signal stb      : stb_t;
  signal wr_ptr   : unsigned(STU_LEN-1 downto 0);
  signal rd_ptr   : unsigned(STU_LEN-1 downto 0);
  signal full     : std_logic;
  signal empty    : std_logic;
  signal commit   : std_logic;

  signal busy_flags : std_logic_vector(STU_SIZE-1 downto 0);
  signal stu_deps   : std_logic_vector(STU_SIZE-1 downto 0);
  signal store_rdy  : std_logic;

  signal stu_entry : stu_buf_field_t;

begin

  ---
  -- INPUT
  ---
  store <= i_disp_store;

  stu_entry <= (
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
  p_stu:
  process(i_clk, i_arst)
  begin
    if i_arst = RST_LEVEL then
      for i in 0 to STU_SIZE-1 loop
        stb(i).busy     <= '0';
        stb(i).commited <= '0';
      end loop;
      wr_ptr <= (others => '0');
      rd_ptr <= (others => '0');

    elsif rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        for i in 0 to STU_SIZE-1 loop
          stb(i).busy     <= '0';
          stb(i).commited <= '0';
        end loop;
        wr_ptr <= (others => '0');
        rd_ptr <= (others => '0');

      else
      -- NEW ENTRY
        if store = '1' and full = '0' then
          stb(to_integer(wr_ptr)) <= stu_entry;
          wr_ptr <= wr_ptr + 1;
        end if;

      -- CDB WRITEBACK
        if i_cdbr_rq = '1' then
          for i in 0 to STU_SIZE-1 loop
            if stb(i).busy = '1' and stb(i).commited = '0' then
              if stb(i).addr_rdy = '0' and stb(i).addr_src = i_cdbr_tq then
                stb(i).addr <= i_cdbr_vq;
                stb(i).addr_rdy <= '1';
              end if;

              if stb(i).data_rdy = '0' and stb(i).data_src = i_cdbr_tq then
                stb(i).data <= i_cdbr_vq;
                stb(i).data_rdy <= '1';
              end if;
            end if;
          end loop;
        end if;

      -- COMMIT STORE
        if commit = '1' then
          stb(to_integer(rd_ptr)).commited <= '1';
          stb(to_integer(rd_ptr)).busy <= '0';
          rd_ptr <= rd_ptr + 1;
        end if;
      end if;
    end if;
  end process;


  p_flags_map:
  for i in 0 to STU_SIZE-1 generate
    busy_flags(i) <= stb(i).busy;
    stu_deps(i) <= stb(i).busy and not stb(i).commited;
  end generate;

  full <= and busy_flags;
  empty <= nor busy_flags;

  current_grp <= stb(to_integer(rd_ptr)).grp;
  grp_match <= '1' when i_rd_grp = current_grp else '0';

  store_rdy <= stb(to_integer(rd_ptr)).data_rdy and stb(to_integer(rd_ptr)).addr_rdy and stb(to_integer(rd_ptr)).busy and grp_match;

  ---
  -- OUTPUT
  ---
  o_empty         <= empty;
  o_full          <= full;
  o_rd_grp_match  <= grp_match;
  o_disp_qr      <= std_logic_vector(wr_ptr);

  o_stu_dep       <= stu_deps;

  o_stu_addr      <= std_logic_vector(rd_ptr);

  o_issue_valid <= store_rdy;
  o_issue_f3    <= stb(to_integer(rd_ptr)).f3;
  o_issue_addr  <= stb(to_integer(rd_ptr)).addr;
  o_issue_data  <= stb(to_integer(rd_ptr)).data;

end architecture;
