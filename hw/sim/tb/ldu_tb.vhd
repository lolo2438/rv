library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library common;
use common.types.std_logic_matrix;

library hw;

library riscv;
use riscv.RV32I.all;

library sim;
use sim.tb_pkg.clk_gen;

entity ldu_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of ldu_tb is

  ---
  -- DUT CONSTANTS
  ---
  constant RST_LEVEL : std_logic := '0';
  constant LDU_LEN   : natural := 2;
  constant GRP_LEN   : natural := 1;
  constant STU_LEN   : natural := 2;
  constant TAG_LEN   : natural := 2;
  constant XLEN      : natural := 32;

  ---
  -- DUT SIGNALS
  ---
  signal i_clk            : std_logic := '0';
  signal i_arst           : std_logic := not RST_LEVEL;
  signal i_srst           : std_logic := not RST_LEVEL;
  signal o_empty          : std_logic;
  signal o_full           : std_logic;
  signal i_disp_load      : std_logic := '0';
  signal i_disp_f3        : std_logic_vector(2 downto 0) := (others => '0');
  signal i_disp_va        : std_logic_vector(XLEN-1 downto 0) := (others => '0');
  signal i_disp_ta        : std_logic_vector(TAG_LEN-1 downto 0) := (others => '0');
  signal i_disp_ra        : std_logic := '0';
  signal i_disp_tq        : std_logic_vector(TAG_LEN-1 downto 0) := (others => '0');
  signal i_cdbr_vq        : std_logic_vector(XLEN-1 downto 0) := (others => '0');
  signal i_cdbr_tq        : std_logic_vector(TAG_LEN-1 downto 0) := (others => '0');
  signal i_cdbr_rq        : std_logic := '0';
  signal i_wr_grp         : std_logic_vector(GRP_LEN-1 downto 0) := (others => '0');
  signal i_rd_grp         : std_logic_vector(GRP_LEN-1 downto 0) := (others => '0');
  signal o_rd_grp_match   : std_logic;
  signal i_stu_issue      : std_logic := '0';
  signal i_stu_addr       : std_logic_vector(STU_LEN-1 downto 0) := (others => '0');
  signal i_stu_data       : std_logic_vector(XLEN-1 downto 0) := (others => '0');
  signal i_stu_dep        : std_logic_vector(2**STU_LEN-1 downto 0) := (others => '0');
  signal i_mem_wr_rdy     : std_logic := '0';
  signal o_mem_wr_valid   : std_logic;
  signal o_mem_wr_addr    : std_logic_vector(XLEN-1 downto 0);
  signal o_mem_wr_qr      : std_logic_vector(LDU_LEN-1 downto 0);
  signal i_mem_rd_valid   : std_logic := '0';
  signal i_mem_rd_qr      : std_logic_vector(LDU_LEN-1 downto 0) := (others => '0');
  signal i_mem_rd_data    : std_logic_vector(XLEN-1 downto 0) := (others => '0');
  signal o_cdbw_vq        : std_logic_vector(XLEN-1 downto 0);
  signal o_cdbw_tq        : std_logic_vector(TAG_LEN-1 downto 0);
  signal o_cdbw_req       : std_logic;
  signal o_cdbw_lh        : std_logic;
  signal i_cdbw_ack       : std_logic := '0';

  ---
  -- TB CONSTANTS
  ---
  constant CLK_FREQ : real := 100.0e6;

  ---
  -- TB SIGNALS
  ---
  signal qr : std_logic_matrix(0 to 2**LDU_LEN-1)(LDU_LEN-1 downto 0);

begin

  clk_gen(i_clk, CLK_FREQ);

  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      i_srst <= RST_LEVEL;
      wait until rising_edge(i_clk);
      i_srst <= not RST_LEVEL;

      if run("VQ0_single_load") then
        i_disp_load <= '1';
        i_disp_f3 <= FUNCT3_LW;
        i_disp_va <= x"AABBCCDD";
        i_disp_ta <= (others => 'X');
        i_disp_ra <= '1';
        i_disp_tq <= "01";
        i_mem_wr_rdy <= '1';

        wait until rising_edge(i_clk);
        i_disp_load <= '0';
        wait until rising_edge(i_clk);
        check(o_mem_wr_valid = '1', "Should send a load request");
        check_equal(o_mem_wr_addr, std_logic_vector'(x"AABBCCDD"));
        qr(0) <= o_mem_wr_qr;

        wait until rising_edge(i_clk);
        check(o_mem_wr_valid = '0', "Request should have been handled");

        i_mem_rd_valid <= '1';
        i_mem_rd_qr <= qr(0);
        i_mem_rd_data <= x"1A2B3C4D";
        wait until rising_edge(i_clk);

        i_mem_rd_valid <= '0';
        wait until rising_edge(i_clk);
        check(o_cdbw_req = '1', "Should send a request since we wrote data");
        check(o_cdbw_lh = '0', "Only one value is ready");
        check_equal(o_cdbw_vq, std_logic_vector'(x"1A2B3C4D"));
        check_equal(o_cdbw_tq, std_logic_vector'("01"));

        i_cdbw_ack <= '1';
        wait until rising_edge(i_clk);

        i_cdbw_ack <= '0';
        wait until rising_edge(i_clk);
        --check(o_cdbw_req = '0', "Should not have any request after ack");

      elsif run("VQ0_cdb_wr_load") then
      elsif run("VQ0_fence_load") then
      elsif run("VQ1_store_dep") then
      elsif run("VQ1_ooo_load") then
      elsif run("VQ1_empty_full") then
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

  u_DUT:
  entity hw.ldu
  generic map (
    RST_LEVEL => RST_LEVEL,
    LDU_LEN   => LDU_LEN,
    GRP_LEN   => GRP_LEN,
    STU_LEN   => STU_LEN,
    TAG_LEN   => TAG_LEN,
    XLEN      => XLEN
  )
  port map (
    i_clk           => i_clk,
    i_arst          => i_arst,
    i_srst          => i_srst,
    o_empty         => o_empty,
    o_full          => o_full,
    i_disp_load     => i_disp_load,
    i_disp_f3       => i_disp_f3,
    i_disp_va       => i_disp_va,
    i_disp_ta       => i_disp_ta,
    i_disp_ra       => i_disp_ra,
    i_disp_tq       => i_disp_tq,
    i_cdbr_vq       => i_cdbr_vq,
    i_cdbr_tq       => i_cdbr_tq,
    i_cdbr_rq       => i_cdbr_rq,
    i_wr_grp        => i_wr_grp,
    i_rd_grp        => i_rd_grp,
    o_rd_grp_match  => o_rd_grp_match,
    i_stu_issue     => i_stu_issue,
    i_stu_addr      => i_stu_addr,
    i_stu_data      => i_stu_data,
    i_stu_dep       => i_stu_dep,
    i_mem_wr_rdy    => i_mem_wr_rdy,
    o_mem_wr_valid  => o_mem_wr_valid,
    o_mem_wr_addr   => o_mem_wr_addr,
    o_mem_wr_qr     => o_mem_wr_qr,
    i_mem_rd_valid  => i_mem_rd_valid,
    i_mem_rd_qr     => i_mem_rd_qr,
    i_mem_rd_data   => i_mem_rd_data,
    o_cdbw_vq       => o_cdbw_vq,
    o_cdbw_tq       => o_cdbw_tq,
    o_cdbw_req      => o_cdbw_req,
    o_cdbw_lh       => o_cdbw_lh,
    i_cdbw_ack      => i_cdbw_ack
  );

end architecture;
