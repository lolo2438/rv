library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library common;

library hw;

library sim;
use sim.tb_pkg.clk_gen;

library riscv;
use riscv.RV32I.all;

entity exb_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of exb_tb is

  ---
  -- DUT Constants
  ---
  constant RST_LEVEL : std_logic := '0';
  constant EXB_LEN   : natural := 2;
  constant XLEN      : natural := 32;
  constant TAG_LEN   : natural := 4;

  ---
  -- DUT Signals
  ---
  signal i_clk       : std_logic := '0';
  signal i_arst      : std_logic := not RST_LEVEL;
  signal i_srst      : std_logic := not RST_LEVEL;
  signal o_full      : std_logic;
  signal o_empty     : std_logic;

  signal i_disp_we   : std_logic := '0';
  signal i_disp_op   : std_logic_vector(4 downto 0) := (others => '0');
  signal i_disp_f3   : std_logic_vector(2 downto 0) := (others => '0');
  signal i_disp_f7   : std_logic_vector(6 downto 0) := (others => '0');

  signal i_disp_vj   : std_logic_vector(XLEN-1 downto 0) := (others => '0');
  signal i_disp_tj   : std_logic_vector(TAG_LEN-1 downto 0) := (others => '0');
  signal i_disp_rj   : std_logic := '0';

  signal i_disp_vk   : std_logic_vector(XLEN-1 downto 0) := (others => '0');
  signal i_disp_tk   : std_logic_vector(TAG_LEN-1 downto 0) := (others => '0');
  signal i_disp_rk   : std_logic := '0';

  signal i_disp_tq   : std_logic_vector(TAG_LEN-1 downto 0) := (others => '0');

  signal i_issue_rdy : std_logic := '0';
  signal o_issue_vj  : std_logic_vector(XLEN-1 downto 0);
  signal o_issue_vk  : std_logic_vector(XLEN-1 downto 0);
  signal o_issue_f3  : std_logic_vector(2 downto 0);
  signal o_issue_f7  : std_logic_vector(6 downto 0);
  signal o_issue_tq  : std_logic_vector(TAG_LEN-1 downto 0);
  signal o_issue_we  : std_logic;

  signal i_cdbr_rq   : std_logic := '0';
  signal i_cdbr_tq   : std_logic_vector(TAG_LEN-1 downto 0) := (others => '0');
  signal i_cdbr_vq   : std_logic_vector(XLEN-1 downto 0) := (others => '0');

  ---
  -- TB CONSTANTS
  ---
  constant CLK_FREQ : real := 100.0e6;

begin

  clk_gen(i_clk, CLK_FREQ);

  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      i_srst <= RST_LEVEL;
      wait until rising_edge(i_clk);
      i_srst <= not RST_LEVEL;

      if run("VQ0_write_read") then
        i_disp_we <= '1';
        i_disp_op <= OP_OP;
        i_disp_f3 <= FUNCT3_ADDSUB;
        i_disp_f7 <= FUNCT7_SUB;
        i_disp_vj <= x"AABBCCDD";
        i_disp_tj <= (others => 'X');
        i_disp_rj <= '1';
        i_disp_vk <= x"1A2B3C4D";
        i_disp_tk <= (others => 'X');
        i_disp_rk <= '1';
        i_disp_tq <= x"A";

        wait until rising_edge(i_clk);
        i_disp_we <= '0';
        i_issue_rdy <= '1';
        check(o_issue_we = '0', "Should not try to issue");
        wait until rising_edge(i_clk);
        check(o_issue_we = '1', "Should try to issue");
        check_equal(o_issue_f3, FUNCT3_ADDSUB);
        check_equal(o_issue_f7, FUNCT7_SUB);
        check_equal(o_issue_vj, std_logic_vector'(x"AABBCCDD"));
        check_equal(o_issue_vk, std_logic_vector'(x"1A2B3C4D"));
        check_equal(o_issue_tq, std_logic_vector'(x"A"));
        wait until rising_edge(i_clk);
        check(o_issue_we = '0', "Should no longer try to issue");

      elsif run("VQ0_cdb_writeback") then
        i_disp_we <= '1';
        i_disp_op <= OP_IMM;
        i_disp_f3 <= FUNCT3_AND;
        i_disp_f7 <= (others => 'X');
        i_disp_vj <= (others => 'X');
        i_disp_tj <= x"A";
        i_disp_rj <= '0';
        i_disp_tq <= x"B";

        i_disp_vk <= x"ABCDEF01";
        i_disp_tk <= (others => 'X');
        i_disp_rk <= '1';

        wait until rising_edge(i_clk);
        i_disp_we <= '0';
        check(o_issue_we = '0', "should not try to issue when dispatching");
        wait until rising_edge(i_clk);
        check(o_issue_we = '0', "should not try to issue after dispatch");

        i_cdbr_rq <= '1';
        i_cdbr_tq <= x"A";
        i_cdbr_vq <= x"12345678";
        wait until rising_edge(i_clk);
        i_cdbr_rq <= '0';
        check(o_issue_we = '0', "should not try to issue right after cdb");
        wait until rising_edge(i_clk);
        check(o_issue_we = '1', "should try to issue after cdb request");
        check_equal(o_issue_f3, FUNCT3_AND);
        check_equal(o_issue_f7, std_logic_vector'(b"0000000"));
        check_equal(o_issue_vj, std_logic_vector'(x"12345678"));
        check_equal(o_issue_vk, std_logic_vector'(x"ABCDEF01"));
        check_equal(o_issue_tq, std_logic_vector'(x"B"));
        wait until rising_edge(i_clk);
        check(o_issue_we = '1', "should still try to issue after cdb request");
        i_issue_rdy <= '1';
        wait until rising_edge(i_clk);
        i_issue_rdy <= '0';
        wait until rising_edge(i_clk);
        check(o_issue_we = '0', "should not still try to issue after cdb request");

      elsif run("VQ0_load") then
        i_disp_we <= '1';
        i_disp_op <= OP_LOAD;
        i_disp_f3 <= FUNCT3_LBU;
        i_disp_rj <= '1';
        i_disp_rk <= '1';
        wait until rising_edge(i_clk);
        i_disp_we <= '0';
        wait until rising_edge(i_clk);
        check_equal(o_issue_f3, FUNCT3_ADDSUB);
        check_equal(o_issue_f7, FUNCT7_ADD);

      elsif run("VQ0_branch") then
        i_disp_we <= '1';
        i_disp_op <= OP_BRANCH;
        i_disp_f3 <= FUNCT3_BGE;
        i_disp_rj <= '1';
        i_disp_rk <= '1';
        wait until rising_edge(i_clk);
        i_disp_we <= '0';
        wait until rising_edge(i_clk);
        check_equal(o_issue_f3, FUNCT3_SLT);
        check_equal(o_issue_f7, std_logic_vector'("0000000"));

      elsif run("VQ1_normal_operation") then
        i_issue_rdy <= '1';
        i_disp_we <= '1';

        i_disp_op <= OP_OP;
        i_disp_f3 <= FUNCT3_ADDSUB;
        i_disp_f7 <= FUNCT7_ADD;

        i_disp_rj <= '1';
        i_disp_tj <= (others => 'X');
        i_disp_vj <= x"AABBCCDD";

        i_disp_rk <= '1';
        i_disp_tk <= (others => 'X');
        i_disp_vk <= x"BBCCDDEE";

        i_disp_tq <= x"0";

        wait until rising_edge(i_clk);
        i_disp_op <= OP_OP;
        i_disp_f3 <= FUNCT3_SL;
        i_disp_f7 <= FUNCT7_SLL;

        i_disp_rj <= '0';
        i_disp_tj <= x"0";
        i_disp_vj <= (others => 'X');

        i_disp_rk <= '1';
        i_disp_tk <= (others => 'X');
        i_disp_vk <= x"00000004";

        i_disp_tq <= x"1";

        wait until rising_edge(i_clk);
        check(o_issue_we = '1', "Should issue first operation");
        check_equal(o_issue_f3, FUNCT3_ADDSUB);
        check_equal(o_issue_f7, FUNCT7_ADD);
        check_equal(o_issue_vj, std_logic_vector'(x"AABBCCDD"));
        check_equal(o_issue_vk, std_logic_vector'(x"BBCCDDEE"));
        check_equal(o_issue_tq, std_logic_vector'(x"0"));

        i_disp_op <= OP_OP;
        i_disp_f3 <= FUNCT3_AND;
        i_disp_f7 <= (others => '0');

        i_disp_rj <= '0';
        i_disp_tj <= x"0";
        i_disp_vj <= (others => 'X');

        i_disp_rk <= '0';
        i_disp_tk <= x"1";
        i_disp_vk <= (others => 'X');

        i_disp_tq <= x"2";

        wait until rising_edge(i_clk);
        check(o_issue_we = '0', "Should no longer issue first operation");

        i_disp_op <= OP_BRANCH;
        i_disp_f3 <= FUNCT3_BEQ;
        i_disp_f7 <= (others => 'X');

        i_disp_rj <= '1';
        i_disp_tj <= (others => 'X');
        i_disp_vj <= x"ABCDEF01";

        i_disp_rk <= '0';
        i_disp_tk <= x"1";
        i_disp_vk <= (others => 'X');

        i_disp_tq <= x"3";

        -- AABBCCDD + BBCCDDEE
        i_cdbr_rq <= '1';
        i_cdbr_tq <= x"0";
        i_cdbr_vq <= x"6688AACB";

        wait until rising_edge(i_clk);
        check(o_issue_we = '0', "Should not issue since propagating operation");

        i_disp_we <= '0';
        i_cdbr_rq <= '0';

        wait until rising_edge(i_clk);
        check(o_issue_we = '1', "Should issue the second operation");
        check_equal(o_issue_f3, FUNCT3_SL);
        check_equal(o_issue_f7, FUNCT7_SLL);
        check_equal(o_issue_vj, std_logic_vector'(x"6688AACB"));
        check_equal(o_issue_vk, std_logic_vector'(x"00000004"));
        check_equal(o_issue_tq, std_logic_vector'(x"1"));

        i_cdbr_rq <= '1';
        i_cdbr_tq <= x"1";
        i_cdbr_vq <= x"688AACB0";

        wait until rising_edge(i_clk);
        check(o_issue_we = '0', "Should no longer issue the second operation");

        i_cdbr_rq <= '0';

        wait until rising_edge(i_clk);
        check(o_issue_we = '1', "Should issue the third operation");
        check_equal(o_issue_f3, FUNCT3_AND);
        check_equal(o_issue_f7, std_logic_vector'(b"0000000"));
        check_equal(o_issue_vj, std_logic_vector'(x"6688AACB"));
        check_equal(o_issue_vk, std_logic_vector'(x"688AACB0"));
        check_equal(o_issue_tq, std_logic_vector'(x"2"));

        wait until rising_edge(i_clk);
        check(o_issue_we = '1', "Should issue the fourth operation");
        check_equal(o_issue_f3, FUNCT3_ADDSUB);
        check_equal(o_issue_f7, FUNCT7_SUB);
        check_equal(o_issue_vj, std_logic_vector'(x"ABCDEF01"));
        check_equal(o_issue_vk, std_logic_vector'(x"688AACB0"));
        check_equal(o_issue_tq, std_logic_vector'(x"3"));

      end if;

    end loop;

    wait until rising_edge(i_clk);

    test_runner_cleanup(runner);
  end process;

  u_DUT:
  entity hw.exb
  generic map (
    RST_LEVEL => RST_LEVEL,
    EXB_LEN   => EXB_LEN,
    TAG_LEN   => TAG_LEN,
    XLEN      => XLEN
  )
  port map (
    i_clk       => i_clk,
    i_arst      => i_arst,
    i_srst      => i_srst,
    o_full      => o_full,
    o_empty     => o_empty,
    i_disp_we   => i_disp_we,
    i_disp_op   => i_disp_op,
    i_disp_f3   => i_disp_f3,
    i_disp_f7   => i_disp_f7,
    i_disp_vj   => i_disp_vj,
    i_disp_tj   => i_disp_tj,
    i_disp_rj   => i_disp_rj,
    i_disp_vk   => i_disp_vk,
    i_disp_tk   => i_disp_tk,
    i_disp_rk   => i_disp_rk,
    i_disp_tq   => i_disp_tq,
    i_issue_rdy => i_issue_rdy,
    o_issue_vj  => o_issue_vj,
    o_issue_vk  => o_issue_vk,
    o_issue_f3  => o_issue_f3,
    o_issue_f7  => o_issue_f7,
    o_issue_tq  => o_issue_tq,
    o_issue_we  => o_issue_we,
    i_cdbr_rq   => i_cdbr_rq,
    i_cdbr_tq   => i_cdbr_tq,
    i_cdbr_vq   => i_cdbr_vq
  );

end architecture;

