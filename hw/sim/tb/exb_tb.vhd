library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library hw;
use hw.tag_pkg.TAG_LEN;

library common;

library sim;
use sim.tb_pkg.clk_gen;

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

  ---
  -- DUT Signals
  ---
  signal i_clk       : std_logic := '0';
  signal i_arst      : std_logic := '0';
  signal i_srst      : std_logic := '0';
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
      if run("test0") then
      end if;
    end loop;

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

