library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library riscv;
use riscv.RV32I.all;

library hw;

library sim;
use sim.tb_pkg.clk_gen;

library common;
use common.types.std_logic_matrix;

entity rob_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of rob_tb is

 constant RST_LEVEL : std_logic := '0';   --! Reset level, default = '0'
 constant REG_LEN   : natural   := 5;     --! REG_SIZE = 2**REG_LEN
 constant ROB_LEN   : natural   := 2;     --! ROB_SIZE = 2**ROB_LEN
 constant XLEN      : natural   := 32;    --! RV XLEN


 ---
 -- DUT SIGNALS
 ---
 signal  i_clk           : std_logic := '0';
 signal  i_arst          : std_logic := not RST_LEVEL;
 signal  i_srst          : std_logic := not RST_LEVEL;
 signal  i_flush         : std_logic := '0';
 signal  o_full          : std_logic;
 signal  o_empty         : std_logic;

 signal  i_disp_rob      : std_logic := '0';
 signal  i_disp_rd       : std_logic_vector(REG_LEN-1 downto 0) := (others => '0');
 signal  o_disp_qr       : std_logic_vector(ROB_LEN-1 downto 0);

 signal  i_disp_rs1      : std_logic_vector(REG_LEN-1 downto 0) := (others => '0');
 signal  o_disp_vj       : std_logic_vector(XLEN-1 downto 0);
 signal  o_disp_qj       : std_logic_vector(ROB_LEN-1 downto 0);
 signal  o_disp_rj       : std_logic;

 signal  i_disp_rs2      : std_logic_vector(REG_LEN-1 downto 0) := (others => '0');
 signal  o_disp_vk       : std_logic_vector(XLEN-1 downto 0);
 signal  o_disp_qk       : std_logic_vector(ROB_LEN-1 downto 0);
 signal  o_disp_rk       : std_logic;

 signal  o_reg_commit    : std_logic;
 signal  o_reg_rd        : std_logic_vector(REG_LEN-1 downto 0);
 signal  o_reg_qr        : std_logic_vector(ROB_LEN-1 downto 0);
 signal  o_reg_result    : std_logic_vector(XLEN-1 downto 0);

 signal  i_wb_addr       : std_logic_vector(ROB_LEN-1 downto 0) := (others => '0');
 signal  i_wb_result     : std_logic_vector(XLEN-1 downto 0) := (others => '0');
 signal  i_wb_valid      : std_logic := '0';

 ---
 -- TB CONSTANTS
 ---
 constant CLK_FREQ  : real := 100.0e6;
 constant ROB_SIZE : natural := 2**ROB_LEN;

 ---
 -- TB SIGNALS
 ---

 signal qr : std_logic_matrix(0 to ROB_SIZE-1)(ROB_LEN-1 downto 0) := (others => (others => '0'));

begin

  clk_gen(i_clk, CLK_FREQ);

  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      qr <= (others => (others => '0'));
      i_srst <= RST_LEVEL;
      wait until rising_edge(i_clk);
      i_srst <= not RST_LEVEL;

      if run("VQ0_single_op") then

        i_disp_rob <= '1';
        i_disp_rd <= REG_X10;
        wait until rising_edge(i_clk);
        qr(0) <= o_disp_qr;

        i_disp_rob <= '0';
        i_disp_rd <= (others => '0');

        i_wb_addr   <= qr(0);
        i_wb_result <= x"DEADBEEF";
        i_wb_valid  <= '1';
        wait until rising_edge(i_clk);

        i_wb_valid  <= '0';
        i_wb_result <= (others => '0');
        i_wb_addr   <= (others => '0');
        wait until rising_edge(i_clk);

        check_equal(o_reg_commit, '1');
        check_equal(o_reg_rd, REG_X10);
        check_equal(o_reg_qr, qr(0));
        check_equal(o_reg_result, std_logic_vector'(x"DEADBEEF"));

      elsif run("VQ0_multi_write_read_in_order") then
        i_disp_rob <= '1';
        i_disp_rd <= REG_X10;
        wait until rising_edge(i_clk);

        i_disp_rd <= REG_X15;
        qr(0) <= o_disp_qr;
        wait until rising_edge(i_clk);

        i_disp_rd <= REG_X20;
        qr(1) <= o_disp_qr;
        wait until rising_edge(i_clk);

        qr(2) <= o_disp_qr;
        i_disp_rob    <= '0';
        i_disp_rd     <= (others => '0');

        i_wb_addr   <= qr(0);
        i_wb_result <= x"1A2B3C4D";
        i_wb_valid  <= '1';
        wait until rising_edge(i_clk);

        i_wb_addr   <= qr(1);
        i_wb_result <= x"4D3C2B1A";
        wait until rising_edge(i_clk);

        i_wb_addr   <= qr(2);
        i_wb_result <= x"AABBCCDD";

        check_equal(o_reg_commit, '1');
        check_equal(o_reg_rd, REG_X10);
        check_equal(o_reg_qr, qr(0));
        check_equal(o_reg_result, std_logic_vector'(x"1A2B3C4D"));
        wait until rising_edge(i_clk);

        i_wb_valid  <= '0';
        i_wb_result <= (others => '0');
        i_wb_addr   <= (others => '0');

        check_equal(o_reg_commit, '1');
        check_equal(o_reg_rd, REG_X15);
        check_equal(o_reg_qr, qr(1));
        check_equal(o_reg_result, std_logic_vector'(x"4D3C2B1A"));
        wait until rising_edge(i_clk);

        check_equal(o_reg_commit, '1');
        check_equal(o_reg_rd, REG_X20);
        check_equal(o_reg_qr, qr(2));
        check_equal(o_reg_result, std_logic_vector'(x"AABBCCDD"));

      elsif run("VQ0_multi_write_read_ooo") then
        i_disp_rob <= '1';
        i_disp_rd <= REG_X04;
        wait until rising_edge(i_clk);

        i_disp_rd <= REG_X08;
        qr(0) <= o_disp_qr;
        wait until rising_edge(i_clk);

        i_disp_rd <= REG_X12;
        qr(1) <= o_disp_qr;
        wait until rising_edge(i_clk);

        qr(2) <= o_disp_qr;
        i_disp_rob    <= '0';
        i_disp_rd     <= (others => '0');

        i_wb_addr   <= qr(1);
        i_wb_result <= x"CAFEDECA";
        i_wb_valid  <= '1';
        wait until rising_edge(i_clk);

        i_wb_addr   <= qr(2);
        i_wb_result <= x"D4C3B2A1";
        wait until rising_edge(i_clk);

        i_wb_addr   <= qr(0);
        i_wb_result <= x"DDCCBBAA";

        wait until rising_edge(i_clk);

        i_wb_valid  <= '0';
        i_wb_result <= (others => '0');
        i_wb_addr   <= (others => '0');
        wait until rising_edge(i_clk);

        check_equal(o_reg_commit, '1');
        check_equal(o_reg_rd, REG_X04);
        check_equal(o_reg_qr, qr(0));
        check_equal(o_reg_result, std_logic_vector'(x"DDCCBBAA"));
        wait until rising_edge(i_clk);

        check_equal(o_reg_commit, '1');
        check_equal(o_reg_rd, REG_X08);
        check_equal(o_reg_qr, qr(1));
        check_equal(o_reg_result, std_logic_vector'(x"CAFEDECA"));
        wait until rising_edge(i_clk);

        check_equal(o_reg_commit, '1');
        check_equal(o_reg_rd, REG_X12);
        check_equal(o_reg_qr, qr(2));
        check_equal(o_reg_result, std_logic_vector'(x"D4C3B2A1"));

      elsif run("VQ0_foward") then
        i_disp_rob <= '1';
        i_disp_rd <= REG_X04;
        wait until rising_edge(i_clk);
        qr(0) <= o_disp_qr;
        i_disp_rd <= REG_X08;
        wait until rising_edge(i_clk);
        qr(1) <= o_disp_qr;
        i_disp_rd <= REG_X12;
        wait until rising_edge(i_clk);
        qr(2) <= o_disp_qr;
        i_disp_rd <= REG_X16;
        wait until rising_edge(i_clk);
        qr(3) <= o_disp_qr;
        i_disp_rob <= '0';

        i_wb_addr <= qr(1);
        i_wb_result <= x"AABBCCDD";
        i_wb_valid <= '1';
        wait until rising_edge(i_clk);

        i_wb_addr <= qr(2);
        i_wb_result <= x"1A2B3C4D";
        wait until rising_edge(i_clk);

        i_wb_addr <= qr(3);
        i_wb_result <= x"DEADBEEF";
        wait until rising_edge(i_clk);

        i_wb_valid <= '0';
        i_disp_rs1 <= REG_X08;
        i_disp_rs2 <= REG_X12;
        wait until rising_edge(i_clk);

        check(o_disp_rj = '1', "REGX08 should be ready");
        check_equal(o_disp_vj, std_logic_vector'(x"AABBCCDD"));
        check_equal(o_disp_qj, qr(1));

        check(o_disp_rk = '1', "REGX12 should be ready");
        check_equal(o_disp_vk, std_logic_vector'(x"1A2B3C4D"));
        check_equal(o_disp_qk, qr(2));

        i_disp_rs1 <= REG_X04;
        i_disp_rs2 <= REG_X16;
        wait until rising_edge(i_clk);

        check(o_disp_rj = '0', "REGX04 should not be ready");
        check_equal(o_disp_vj, std_logic_vector'(x"UUUUUUUU"));
        check_equal(o_disp_qj, qr(0));

        check(o_disp_rk = '1', "REGX16 should be ready");
        check_equal(o_disp_vk, std_logic_vector'(x"DEADBEEF"));
        check_equal(o_disp_qk, qr(3));

      elsif run("VQ1_empty_full") then
        i_disp_rob <= '1';
        i_disp_rd <= REG_X04;
        wait until rising_edge(i_clk);
        qr(0) <= o_disp_qr;
        check(o_empty = '1', "Should be empty at begining");
        check(o_full = '0', "should not be full because empty");

        wait until rising_edge(i_clk);
        qr(1) <= o_disp_qr;
        check(o_empty = '0', "Should not be since we wrote 1 data");
        check(o_full = '0', "should not be full because only wrote 1 data");

        wait until rising_edge(i_clk);
        qr(2) <= o_disp_qr;
        check(o_empty = '0', "Should not be since we wrote 2 data");
        check(o_full = '0', "should not be full because only wrote 2 data");

        i_wb_valid <= '1';
        i_wb_addr <= qr(0);
        wait until rising_edge(i_clk);
        check(o_empty = '0', "Should not be empty we wrote 3 data");
        check(o_full = '0', "should be full because writing the 3rd data");
        qr(3) <= o_disp_qr;

        i_disp_rob <= '0';
        i_wb_addr <= qr(1);
        wait until rising_edge(i_clk);

        i_wb_addr <= qr(2);
        check(o_empty = '0', "Should not be empty because we wrote 4 data");
        check(o_full = '1', "should be full because we wrote 4 data");
        wait until rising_edge(i_clk);

        i_wb_addr <= qr(3);
        check(o_empty = '0', "Should not be empty because containts 3 data ");
        check(o_full = '0', "should not be full because contains 3 data ");
        wait until rising_edge(i_clk);

        check(o_empty = '0', "Should not be empty because contains 2 data");
        check(o_full = '0', "should not be full because contains 2 data ");

        wait until rising_edge(i_clk);
        check(o_empty = '0', "Should not be empty because contains 1 data");
        check(o_full = '0', "should not be full because contains 1 data ");

        wait until rising_edge(i_clk);
        check(o_empty = '1', "Should be empty at end");
        check(o_full = '0', "should be full because empty at end");

      elsif run("VQ1_foward_latest") then
        i_disp_rob <= '1';
        i_disp_rd <= REG_X04;
        wait until rising_edge(i_clk);
        qr(0) <= o_disp_qr;
        i_disp_rd <= REG_X04;
        wait until rising_edge(i_clk);
        qr(1) <= o_disp_qr;
        i_disp_rd <= REG_X04;
        wait until rising_edge(i_clk);
        qr(2) <= o_disp_qr;
        i_disp_rd <= REG_X04;
        wait until rising_edge(i_clk);
        qr(3) <= o_disp_qr;
        i_disp_rob <= '0';

        i_wb_addr <= qr(1);
        i_wb_result <= x"AABBCCDD";
        i_wb_valid <= '1';
        wait until rising_edge(i_clk);

        i_wb_addr <= qr(3);
        i_wb_result <= x"DDCCBBAA";
        i_wb_valid <= '1';
        wait until rising_edge(i_clk);

        i_wb_valid <= '0';
        i_disp_rs1 <= REG_X04;
        wait until rising_edge(i_clk);

        check(o_disp_rj = '1', "REGX04 should be ready");
        check_equal(o_disp_vj, std_logic_vector'(x"DDCCBBAA"));
        check_equal(o_disp_qj, qr(3));

      --elsif run("VQ1_simultaneous") then
      --elsif run("VQ1_typical") then
      --elsif run("VQ2_foward_latest_not_rdy") then
      --elsif run("VQ2_buffer_overrun") then
      --elsif run("VQ2_buffer_underrun") then
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

  u_DUT:
  entity hw.rob
  generic map(
    RST_LEVEL     => RST_LEVEL,
    REG_LEN       => REG_LEN,
    ROB_LEN       => ROB_LEN,
    XLEN          => XLEN
  )
  port map(
    i_clk           => i_clk,
    i_arst          => i_arst,
    i_srst          => i_srst,
    i_flush         => i_flush,
    o_full          => o_full,
    o_empty         => o_empty,
    i_disp_rob      => i_disp_rob,
    i_disp_rd       => i_disp_rd,
    o_disp_qr       => o_disp_qr,
    i_disp_rs1      => i_disp_rs1,
    o_disp_vj       => o_disp_vj,
    o_disp_qj       => o_disp_qj,
    o_disp_rj       => o_disp_rj,
    i_disp_rs2      => i_disp_rs2,
    o_disp_vk       => o_disp_vk,
    o_disp_qk       => o_disp_qk,
    o_disp_rk       => o_disp_rk,
    o_reg_commit    => o_reg_commit,
    o_reg_rd        => o_reg_rd,
    o_reg_qr        => o_reg_qr,
    o_reg_result    => o_reg_result,
    i_wb_addr       => i_wb_addr,
    i_wb_result     => i_wb_result,
    i_wb_valid      => i_wb_valid
  );

end architecture;
