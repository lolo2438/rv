library vunit_lib;
context vunit_lib.vunit_context;

library ieee;
use ieee.std_logic_1164.all;

library common;
use common.cnst.BYTE;

library sim;
use sim.tb_pkg.all;

entity vmem_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of vmem_tb is

  signal mem_en : boolean := true;

  constant ADDR_LEN : natural := 8;
  constant DATA_LEN : natural := 32;

  signal i_clk    : std_logic;
  signal i_we     : std_logic_vector(DATA_LEN/BYTE-1 downto 0);   --! Byte wide write enable
  signal i_addr   : std_logic_vector(ADDR_LEN-1 downto 0);        --! Memory address
  signal i_data   : std_logic_vector(DATA_LEN-1 downto 0);        --! Input Data to write
  signal o_data   : std_logic_vector(DATA_LEN-1 downto 0);        --! Output data to read
begin

  clk_gen(i_clk, 100.0e6);

  -- DUT
  u_dut:
  entity sim.vmem
  generic map (
    FILE_NAME   => "test.bin",
    ADDR_LEN    => ADDR_LEN,
    DATA_LEN    => DATA_LEN
  )
  port map (
    i_en      => mem_en,
    i_clk     => i_clk,
    i_we      => i_we,
    i_addr    => i_addr,
    i_data    => i_data,
    o_data    => o_data
  );

  -- Main
  main:
  process
  begin
    test_runner_setup(runner,runner_cfg);


    while test_suite loop
      i_we    <= (others => '0');
      i_addr  <= (others => '0');
      i_data  <= (others => '0');
      wait for 0;

      if run("test_write") then
        i_addr <= x"10";
        i_data <= x"DEADBEEF";
        i_we <= x"F";
        wait until rising_edge(i_clk);
        i_we <= x"0";
        wait until rising_edge(i_clk);
        check_equal(o_data, x"DEADBEEF");

      elsif run("test_byte_write") then
        i_addr <= x"20";
        i_data <= x"1A2B3C4D";
        i_we <= b"1010";
        wait until rising_edge(i_clk);
        i_we <= b"0101";
        wait until rising_edge(i_clk);
        check_equal(o_data, x"1A003C00");
        wait until rising_edge(i_clk);
        check_equal(o_data, x"1A2B3C4D");

      elsif run("test_write_read") then
        i_addr <= x"30";
        i_data <= x"AABBCCDD";
        i_we <= x"F";
        wait until rising_edge(i_clk);
        check_equal(o_data, x"00000000");
      end if;
    end loop;

    mem_en <= false;
    wait for 0;

    test_runner_cleanup(runner);
  end process;


end architecture;
