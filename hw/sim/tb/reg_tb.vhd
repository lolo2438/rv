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

entity reg_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of reg_tb is

    ---
    -- DUT SIGNALS
    ---

    constant RST_LEVEL : std_logic := '0';
    constant REG_LEN   : natural := 5;
    constant ROB_LEN   : natural := 2;
    constant XLEN      : natural := 32;

    signal i_clk         : std_logic := '0';
    signal i_arst        : std_logic := '0';
    signal i_srst        : std_logic := '0';
    signal i_disp_rs1    : std_logic_vector(REG_LEN-1 downto 0) := (others => '0');
    signal o_reg_vj      : std_logic_vector(XLEN-1 downto 0);
    signal o_reg_qj      : std_logic_vector(ROB_LEN-1 downto 0);
    signal o_reg_rj      : std_logic;
    signal i_disp_rs2    : std_logic_vector(REG_LEN-1 downto 0) := (others => '0');
    signal o_reg_vk      : std_logic_vector(XLEN-1 downto 0);
    signal o_reg_qk      : std_logic_vector(ROB_LEN-1 downto 0);
    signal o_reg_rk      : std_logic;
    signal i_disp_valid  : std_logic := '0';
    signal i_disp_wb     : std_logic := '0';
    signal i_disp_rd     : std_logic_vector(REG_LEN-1 downto 0) := (others => '0');
    signal i_disp_qr     : std_logic_vector(ROB_LEN-1 downto 0) := (others => '0');
    signal i_wb_we       : std_logic := '0';
    signal i_wb_rd       : std_logic_vector(REG_LEN-1 downto 0) := (others => '0');
    signal i_wb_data     : std_logic_vector(XLEN-1 downto 0) := (others => '0');

    ---
    -- TB SIGNALS
    ---
    constant CLK_FREQ : real := 100.0e6;

begin

  clk_gen(i_clk, CLK_FREQ);

  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("VQ0_Read_Empty") then
      elsif run("VQ0_Write_Read") then
      elsif run("VQ1_Dispatch_Read") then
      elsif run("VQ1_Dispatch_Write_Read") then
      elsif run("VQ2_write_read_X0") then
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;


  u_dut:
  entity hw.reg
  generic map (
    RST_LEVEL => RST_LEVEL,
    REG_LEN   => REG_LEN,
    ROB_LEN   => ROB_LEN,
    XLEN      => XLEN
  )
  port map (
    i_clk         => i_clk,
    i_arst        => i_arst,
    i_srst        => i_srst,
    i_disp_rs1    => i_disp_rs1,
    o_reg_vj      => o_reg_vj,
    o_reg_qj      => o_reg_qj,
    o_reg_rj      => o_reg_rj,
    i_disp_rs2    => i_disp_rs2,
    o_reg_vk      => o_reg_vk,
    o_reg_qk      => o_reg_qk,
    o_reg_rk      => o_reg_rk,
    i_disp_valid  => i_disp_valid,
    i_disp_wb     => i_disp_wb,
    i_disp_rd     => i_disp_rd,
    i_disp_qr     => i_disp_qr,
    i_wb_we       => i_wb_we,
    i_wb_rd       => i_wb_rd,
    i_wb_data     => i_wb_data
  );

end architecture;

