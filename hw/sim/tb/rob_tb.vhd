library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library hw;

library sim;
use sim.tb_pkg.clk_gen;

entity rob_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of rob_tb is

 constant RST_LEVEL : std_logic := '0';   --! Reset level, default = '0'
 constant REG_LEN   : natural   := 5;            --! REG_SIZE = 2**REG_LEN
 constant ROB_LEN   : natural   := 2;            --! ROB_SIZE = 2**ROB_LEN
 constant XLEN      : natural   := 32;            --! RV XLEN

 constant CLK_FREQ  : real := 100.0e6;

 -- DUT
 signal  i_clk           : std_logic;                            --! Clock domain
 signal  i_arst          : std_logic;                            --! asynchronous reset
 signal  i_srst          : std_logic;                            --! Synchronous reset
 signal  i_flush         : std_logic;                            --! Flush the content of the ROB
 signal  o_full          : std_logic;                            --! Rob is full

 signal  i_disp_valid    : std_logic;
 signal  i_disp_rob      : std_logic;                             --! Create an entry in the ROB
 signal  i_disp_rd       : std_logic_vector(REG_LEN-1 downto 0);  --! Destination register of the result
 signal  o_disp_qr       : std_logic_vector(ROB_LEN-1 downto 0); --! Rob address to write back the result

 signal  i_disp_rs1      : std_logic_vector(REG_LEN-1 downto 0);  --! Source register for operand 1
 signal  o_disp_vj       : std_logic_vector(XLEN-1 downto 0);    --! Data fowarded from ROB for operand 1
 signal  o_disp_qj       : std_logic_vector(ROB_LEN-1 downto 0); --! Rob address of the fowarded opreand 1
 signal  o_disp_rj       : std_logic;                            --! Value found in the ROB for operand 1

 signal  i_disp_rs2      : std_logic_vector(REG_LEN-1 downto 0);  --! Source register for operant 2
 signal  o_disp_vk       : std_logic_vector(XLEN-1 downto 0);    --! Data fowarded from ROB for operand 2
 signal  o_disp_qk       : std_logic_vector(ROB_LEN-1 downto 0); --! Rob address of the fowarded opreand 2
 signal  o_disp_rk       : std_logic;                            --! Value found in the ROB for operand 2

 signal  o_reg_commit    : std_logic;                            --! Rob is commiting a value that is ready and clearing it's entry
 signal  o_reg_rd        : std_logic_vector(REG_LEN-1 downto 0); --! Register Destination address
 signal  o_reg_result    : std_logic_vector(XLEN-1 downto 0);    --! Result to write to register

 signal  i_wb_addr       : std_logic_vector(ROB_LEN-1 downto 0);  --! Write back rob address
 signal  i_wb_result     : std_logic_vector(XLEN-1 downto 0);     --! Write back result
 signal  i_wb_valid      : std_logic;                             --! Write back result is valid


begin

  clk_gen(i_clk, CLK_FREQ);

  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("test0") then
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
    i_disp_valid    => i_disp_valid,
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
    o_reg_result    => o_reg_result,
    i_wb_addr       => i_wb_addr,
    i_wb_result     => i_wb_result,
    i_wb_valid      => i_wb_valid
  );

end architecture;
