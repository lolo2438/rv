
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library riscv;
use riscv.RV32I.all;

library hw;
library sim; use sim.tb_pkg.clk_gen; entity stu_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of stu_tb is

  ---
  -- DUT CONSTANTS
  ---

  constant RST_LEVEL : std_logic  := '0';
  constant STU_LEN   : natural    := 2;
  constant GRP_LEN   : natural    := 1;
  constant TAG_LEN   : natural    := 2;
  constant XLEN      : natural    := 32;

  ---
  -- DUT SIGNALS
  ---
  signal i_clk           : std_logic := '0';
  signal i_arst          : std_logic := not RST_LEVEL;
  signal i_srst          : std_logic := not RST_LEVEL;
  signal o_empty         : std_logic;
  signal o_full          : std_logic;
  signal i_disp_store    : std_logic := '0';
  signal i_disp_f3       : std_logic_vector(2 downto 0) := (others => '0');
  signal i_disp_va       : std_logic_vector(XLEN-1 downto 0) := (others => '0');
  signal i_disp_ta       : std_logic_vector(TAG_LEN-1 downto 0) := (others => '0');
  signal i_disp_ra       : std_logic := '0';
  signal i_disp_vd       : std_logic_vector(XLEN-1 downto 0) := (others => '0');
  signal i_disp_td       : std_logic_vector(TAG_LEN-1 downto 0) := (others => '0');
  signal i_disp_rd       : std_logic := '0';
  signal i_wr_grp        : std_logic_vector(GRP_LEN-1 downto 0) := (others => '0');
  signal i_rd_grp        : std_logic_vector(GRP_LEN-1 downto 0) := (others => '0');
  signal o_rd_grp_match  : std_logic;
  signal i_cdbr_vq       : std_logic_vector(XLEN-1 downto 0) := (others => '0');
  signal i_cdbr_tq       : std_logic_vector(TAG_LEN-1 downto 0) := (others => '0');
  signal i_cdbr_rq       : std_logic := '0';
  signal o_stu_dep       : std_logic_vector(2**STU_LEN-1 downto 0);
  signal o_stu_addr      : std_logic_vector(STU_LEN-1 downto 0);
  signal i_issue_rdy     : std_logic := '0';
  signal o_issue_valid   : std_logic;
  signal o_issue_f3      : std_logic_vector(2 downto 0);
  signal o_issue_addr    : std_logic_vector(XLEN-1 downto 0);
  signal o_issue_data    : std_logic_vector(XLEN-1 downto 0);

  ---
  -- TB CONSTANTS
  ---
  constant CLK_FREQ : real := 100.0e6;

  ---
  -- TB SIGNALS
  ---

begin

  clk_gen(i_clk, CLK_FREQ);

  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      i_srst <= RST_LEVEL;
      wait until rising_edge(i_clk);
      i_srst <= not RST_LEVEL;

      if run("VQ0_single_store") then
        i_disp_store <= '1';
        i_disp_f3    <= "101";
        i_disp_va    <= x"AABBCCDD";
        i_disp_ta    <= (others => 'X');
        i_disp_ra    <= '1';
        i_disp_vd    <= x"1A2B3C4D";
        i_disp_td    <= (others => 'X');
        i_disp_rd    <= '1';

        wait until rising_edge(i_clk);
        i_disp_store <= '0';

        wait until rising_edge(i_clk);
        i_issue_rdy <= '1';

        check(o_issue_valid = '1', "Issue should be ready");
        check_equal(o_issue_f3, std_logic_vector'("101"));
        check_equal(o_issue_addr, std_logic_vector'(x"AABBCCDD"));
        check_equal(o_issue_data, std_logic_vector'(x"1A2B3C4D"));
        check(o_stu_dep = "0001", "Should have 1 used value at location 0");
        check(o_stu_addr = "00", "STU Should be pointing at address 0");

        wait until rising_edge(i_clk);
        check(o_issue_valid = '1', "Issue should still be valid");

        wait until rising_edge(i_clk);
        check(o_issue_valid = '0', "Issue should not be ready after");

      elsif run("VQ0_wait_cdb_data_store") then
        i_disp_store <= '1';
        i_disp_f3    <= "110";
        i_disp_va    <= (others => 'X');
        i_disp_ta    <= "01";
        i_disp_ra    <= '0';
        i_disp_vd    <= (others => 'X');
        i_disp_td    <= "10";
        i_disp_rd    <= '0';

        wait until rising_edge(i_clk);
        i_disp_store <= '0';

        i_cdbr_tq    <= "10";
        i_cdbr_vq    <= x"DDBBCCAA";
        i_cdbr_rq    <= '1';

        wait until rising_edge(i_clk);
        i_cdbr_tq    <= "01";
        i_cdbr_vq    <= x"1D2C3B4A";
        i_cdbr_rq    <= '1';

        wait until rising_edge(i_clk);
        i_cdbr_rq    <= '0';

        wait until rising_edge(i_clk);
        check(o_issue_valid = '1', "Issue should be ready");
        check_equal(o_issue_f3, std_logic_vector'("110"));
        check_equal(o_issue_addr, std_logic_vector'(x"1D2C3B4A"));
        check_equal(o_issue_data, std_logic_vector'(x"DDBBCCAA"));

      elsif run("VQ0_fence_store") then
        i_wr_grp      <= "0";
        i_rd_grp      <= "0";
        i_disp_store  <= '1';
        i_disp_ra     <= '1';
        i_disp_rd     <= '1';

        wait until rising_edge(i_clk);
        check(o_issue_valid = '0', "START: Should not be valid");
        check(o_rd_grp_match = '0', "START: Group should not match");

        i_wr_grp <= "1";
        wait until rising_edge(i_clk);
        check(o_issue_valid = '1', "C0: Should have a valid value");
        check(o_rd_grp_match = '1', "C0: Rd group should match");

        i_issue_rdy <= '1';
        i_disp_store <= '0';
        wait until rising_edge(i_clk);
        check(o_issue_valid = '1', "C1: Should have a valid value");
        check(o_rd_grp_match = '1', "C1: Rd group should match");

        wait until rising_edge(i_clk);
        check(o_issue_valid = '0', "C2: Should not have a valid value because of group");
        check(o_rd_grp_match = '0', "C2: Rd group should match");

        i_rd_grp <= "1";
        wait until rising_edge(i_clk);
        check(o_issue_valid = '1', "C3: Should have a valid value");
        check(o_rd_grp_match = '1', "C3: Rd group should match");

        wait until rising_edge(i_clk);
        check(o_issue_valid = '0', "END: Should not have valid value");
        check(o_rd_grp_match = '0', "END: Rd group should not match");


      elsif run("VQ1_ooo_cdb_store") then
        i_issue_rdy <= '1';
        i_disp_store <= '1';
        i_disp_f3    <= "010";
        i_disp_ra    <= '0';
        i_disp_ta    <= "00";

        i_disp_rd    <= '0';
        i_disp_td    <= "01";

        wait until rising_edge(i_clk);
        i_disp_f3    <= "011";
        i_disp_ta    <= "10";

        i_disp_vd    <= x"CAFEDECA";
        i_disp_rd    <= '1';

        wait until rising_edge(i_clk);
        i_disp_f3    <= "101";
        i_disp_td    <= "11";
        i_disp_rd    <= '0';

        i_disp_ra    <= '1';
        i_disp_va    <= x"AAAABBBB";

        -- D1 VA
        i_cdbr_tq    <= "10";
        i_cdbr_vq    <= x"DEADBEEF";
        i_cdbr_rq    <= '1';

        wait until rising_edge(i_clk);
        i_disp_f3    <= "110";
        i_disp_va    <= x"01234567";
        i_disp_ra    <= '1';
        i_disp_vd    <= x"89ABCDEF";
        i_disp_rd    <= '1';

        -- D0 VA
        i_cdbr_tq    <= "00";
        i_cdbr_vq    <= x"ADEF3592";

        wait until rising_edge(i_clk);

        i_disp_store <= '0';

        -- D2 VD
        i_cdbr_tq    <= "11";
        i_cdbr_vq    <= x"CCCCDDDD";

        wait until rising_edge(i_clk);

        -- D0 VD
        i_cdbr_tq    <= "01";
        i_cdbr_vq    <= x"1234ABCD";

        wait until rising_edge(i_clk);

        i_cdbr_rq    <= '0';
        wait until rising_edge(i_clk);

        check(o_issue_valid = '1', "Issue should be ready");
        check_equal(o_issue_f3, std_logic_vector'("010"));
        check_equal(o_issue_addr, std_logic_vector'(x"ADEF3592"));
        check_equal(o_issue_data, std_logic_vector'(x"1234ABCD"));

        wait until rising_edge(i_clk);
        check(o_issue_valid = '1', "Issue should be ready");
        check_equal(o_issue_f3, std_logic_vector'("011"));
        check_equal(o_issue_addr, std_logic_vector'(x"DEADBEEF"));
        check_equal(o_issue_data, std_logic_vector'(x"CAFEDECA"));

        wait until rising_edge(i_clk);
        check(o_issue_valid = '1', "Issue should be ready");
        check_equal(o_issue_f3, std_logic_vector'("101"));
        check_equal(o_issue_addr, std_logic_vector'(x"AAAABBBB"));
        check_equal(o_issue_data, std_logic_vector'(x"CCCCDDDD"));

        wait until rising_edge(i_clk);
        check(o_issue_valid = '1', "Issue should be ready");
        check_equal(o_issue_f3, std_logic_vector'("110"));
        check_equal(o_issue_addr, std_logic_vector'(x"01234567"));
        check_equal(o_issue_data, std_logic_vector'(x"89ABCDEF"));

      elsif run("VQ1_empty_full") then
        i_disp_store  <= '1';
        i_disp_ra     <= '1';
        i_disp_rd     <= '1';

        wait until rising_edge(i_clk); -- D0
        check(o_empty = '1', "START: should be empty");
        check(o_full = '0', "START: should not be full");

        wait until rising_edge(i_clk); -- D1
        check(o_empty = '0', "D0: should not be empty");
        check(o_full = '0', "D0: should not be full");

        wait until rising_edge(i_clk); -- D2
        check(o_empty = '0', "D1: should not be empty");
        check(o_full = '0', "D1: should not be full");

        wait until rising_edge(i_clk); -- D3
        check(o_empty = '0', "D2: should not be empty");
        check(o_full = '0', "D2: should not be full");

        i_issue_rdy <= '1';
        wait until rising_edge(i_clk);
        check(o_empty = '0', "D3: should not be empty");
        check(o_full = '1', "D3: should be full");

        i_disp_store  <= '0';
        wait until rising_edge(i_clk); -- D2
        check(o_empty = '0', "D2: should not be empty");
        check(o_full = '0', "D2: should not be full");

        wait until rising_edge(i_clk); -- D1
        check(o_empty = '0', "D1: should not be empty");
        check(o_full = '0', "D1: should not be full");

        wait until rising_edge(i_clk); -- D0
        check(o_empty = '0', "D0: should not be empty");
        check(o_full = '0', "D0: should not be full");

        wait until rising_edge(i_clk);
        check(o_empty = '1', "END: should not be empty");
        check(o_full = '0', "END: should not be full");

      --elsif run("VQ2_underflow_overflow") then
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

  u_DUT:
  entity hw.stu
  generic map (
    RST_LEVEL => RST_LEVEL,
    STU_LEN   => STU_LEN,
    GRP_LEN   => GRP_LEN,
    TAG_LEN   => TAG_LEN,
    XLEN      => XLEN
  )
  port map (
    i_clk           => i_clk,
    i_arst          => i_arst,
    i_srst          => i_srst,
    o_empty         => o_empty,
    o_full          => o_full,
    i_disp_store    => i_disp_store,
    i_disp_f3       => i_disp_f3,
    i_disp_va       => i_disp_va,
    i_disp_ta       => i_disp_ta,
    i_disp_ra       => i_disp_ra,
    i_disp_vd       => i_disp_vd,
    i_disp_td       => i_disp_td,
    i_disp_rd       => i_disp_rd,
    i_wr_grp        => i_wr_grp,
    i_rd_grp        => i_rd_grp,
    o_rd_grp_match  => o_rd_grp_match,
    i_cdbr_vq       => i_cdbr_vq,
    i_cdbr_tq       => i_cdbr_tq,
    i_cdbr_rq       => i_cdbr_rq,
    o_stu_dep       => o_stu_dep,
    o_stu_addr      => o_stu_addr,
    i_issue_rdy     => i_issue_rdy,
    o_issue_valid   => o_issue_valid,
    o_issue_f3      => o_issue_f3,
    o_issue_addr    => o_issue_addr,
    o_issue_data    => o_issue_data
  );


end architecture;
