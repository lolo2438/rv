library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library hw;

library common;
use common.types.std_logic_matrix;

library sim;
use sim.tb_pkg.clk_gen;

entity otm_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of otm_tb is

    constant ADDR_LEN  : natural := 2;
    constant RST_LEVEL : std_logic := '0';
    constant TCQ       : time := 0.6 ns;
    constant CLK_FREQ  : real := 100.0e6;

    signal i_clk      : std_logic := '0';
    signal i_arst     : std_logic := '0';
    signal i_srst     : std_logic := '0';
    signal i_we       : std_logic := '0';
    signal i_re       : std_logic := '0';
    signal i_wr_addr  : std_logic_vector(ADDR_LEN-1 downto 0) := (others => '0');
    signal i_rd_mask  : std_logic_vector(2**ADDR_LEN-1 downto 0) := (others => '0');
    signal o_rd_addr  : std_logic_vector(ADDR_LEN-1 downto 0);
    signal o_rd_valid : std_logic;
    signal o_empty    : std_logic;
    signal o_full     : std_logic;

begin

  clk_gen(i_clk, CLK_FREQ);

  main : process
    variable result_table : std_logic_matrix(0 to 2**ADDR_LEN-1)(ADDR_LEN-1 downto 0);
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop

      -- Reset DUT
      i_arst <= RST_LEVEL;
      wait until rising_edge(i_clk);
      wait for TCQ;
      i_arst <= not RST_LEVEL;

      -- Run Tests
      if run("V0_4x4_write_read") then
        check(o_empty = '1', "Should be empty at begining");
        check(o_full = '0', "Should not be full at begining");
        check(o_rd_valid = '0', "Out address should not be valid");

        -- Write
        i_we <= '1';
        for i in 2**ADDR_LEN-1 downto 0 loop
          i_wr_addr <= std_logic_vector(to_unsigned(i, i_wr_addr'length));
          check(o_full = '0', "Should be empty while writing");

          wait until rising_edge(i_clk);
          wait for TCQ;
          check(o_rd_valid = '0', "Out address should not be valid when writing");
          check(o_empty = '0', "Should not be empty when writing");
        end loop;

        wait until rising_edge(i_clk);
        wait for TCQ;
        check(o_full = '1', "Should be full after writing");
        check(o_empty = '0', "Should not be empty after writing");
        check(o_rd_valid = '0', "Out address should not be valid after writing");

        i_we <= '0';
        -- Read
        i_re <= '1';
        i_rd_mask <= x"5";
        for i in 0 to 2**ADDR_LEN-1 loop
          wait until rising_edge(i_clk);
          check(o_rd_valid = '1', "Out address should be valid when reading");
          check(o_empty = '0', "Should not be empty when reading");
          i_rd_mask <= not (i_rd_mask);
          result_table(i) := o_rd_addr;

          wait for TCQ;
          check(o_full = '0', "Should not be full when reading");
        end loop;
        check(o_rd_valid = '0', "Out address should not be valid after reading");
        check(o_empty = '1', "Should  be empty after reading");
        check(o_full = '0', "Should not be full when reading");

        check_equal(result_table(0), std_logic_vector'("10"));
        check_equal(result_table(1), std_logic_vector'("11"));
        check_equal(result_table(2), std_logic_vector'("00"));
        check_equal(result_table(3), std_logic_vector'("01"));

      elsif run("V0_4x4_write_and_read") then
      elsif run("V1_32x32_write_read") then
      elsif run("V1_32x32_write_and_read") then
      elsif run("V1_reset_high") then
      elsif run("V2_read_empty") then
      elsif run("V2_write_full") then
      elsif run("V2_Overwriting") then
      elsif run("V2_OverReading") then
      end if;
    end loop;


    test_runner_cleanup(runner);
  end process;


  DUT: entity hw.otm
  generic map( RST_LEVEL => RST_LEVEL,
               ADDR_LEN => ADDR_LEN
  )
  port map(
    i_clk      => i_clk,
    i_arst     => i_arst,
    i_srst     => i_srst,
    o_empty    => o_empty,
    o_full     => o_full,
    i_we       => i_we,
    i_re       => i_re,
    i_wr_addr  => i_wr_addr,
    i_rd_mask  => i_rd_mask,
    o_rd_addr  => o_rd_addr,
    o_rd_valid => o_rd_valid
  );

end architecture;
