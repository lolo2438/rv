library ieee;
use ieee.std_logic_1164.all;

library vunit_lib;
context vunit_lib.vunit_context;

use work.tb_pkg.all;

entity cache_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of cache_tb is

  component cache is
  generic(
    XLEN        : natural;
    OFFSET_SIZE : natural; -- Each ways will have rows of 2^OFFSET columns
    SET_SIZE    : natural; -- Each way will have 2^NB_SETS rows
    WAY_SIZE    : natural  -- There will be 2^NB_WAYS ways
  );
  port(
    clk_i     : in  std_logic;
    rst_i     : in  std_logic;
    we_i      : in  std_logic;
    data_i    : in  std_logic_vector(XLEN*(2**OFFSET_SIZE)-1 downto 0);
    address_i : in  std_logic_vector(XLEN-1 downto 0);
    data_o    : out std_logic_vector(XLEN-1 downto 0);
    hit_o     : out std_logic
  );
  end component;

  constant XLEN        : natural := 32;
  constant OFFSET_SIZE : natural := 1; -- Each ways will have rows of 2^OFFSET columns
  constant SET_SIZE    : natural := 4; -- Each way will have 2^NB_SETS rows
  constant WAY_SIZE    : natural := 2; -- There will be 2^NB_WAYS ways

  signal clk_i     : std_logic;
  signal rst_i     : std_logic;
  signal we_i      : std_logic;
  signal data_i    : std_logic_vector(XLEN*(2**OFFSET_SIZE)-1 downto 0);
  signal address_i : std_logic_vector(XLEN-1 downto 0);
  signal data_o    : std_logic_vector(XLEN-1 downto 0);
  signal hit_o     : std_logic;

begin

  clk_gen(clk_i, 100.0e6);

  main:
  process
  begin
    test_runner_setup(runner, runner_cfg);

    -- TODO: Test multiple configurations of the cache
    while test_suite loop
      rst_i <= '1';

      address_i <= (others => '0');
      data_i <= (others => '0');
      we_i <= '0';
      wait until rising_edge(clk_i);
      rst_i <= '0';

      if run("default") then
        address_i <= x"ABCD0000";
        wait until rising_edge(clk_i);
        check(hit_o = '0', "0. Shouldn't hit");

        -- Offset = 1 -> 64 bit input
        --
        data_i <= x"0123456789ABCDEF";
        we_i <= '1';
        wait until rising_edge(clk_i);
        -- Data should have been written
        -- Writing to the second way
        address_i <= x"DCBA0000";
        data_i <= x"FEDCBA9876543210";
        wait until rising_edge(clk_i);
        we_i <= '0';

        -- Reading the value at offset 1
        address_i <= x"ABCD0004";
        wait until rising_edge(clk_i);
        check(hit_o = '1', "1.Should hit at offset 1");
        check_equal(data_o, std_logic_vector'(x"01234567"),"Read wrong data");

        address_i <= x"DCBA0004";
        wait until rising_edge(clk_i);
        check(hit_o = '1', "2.Should hit at offset 1");
        check_equal(data_o, std_logic_vector'(x"FEDCBA98"),"Read wrong data");

        address_i <= x"DCBA0000";
        wait until rising_edge(clk_i);
        check(hit_o = '1', "3.Should hit at offset 0");
        check_equal(data_o, std_logic_vector'(x"76543210"),"Read wrong data");

        address_i <= x"DCB00000";
        wait until rising_edge(clk_i);
        check(hit_o = '0', "4.Shouldn't hit at offset");

      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

  DUT: cache
  generic map (
    XLEN => XLEN,
    OFFSET_SIZE => OFFSET_SIZE,
    SET_SIZE => SET_SIZE,
    WAY_SIZE => WAY_SIZE
  )
  port map(
    clk_i     => clk_i,
    rst_i     => rst_i,
    we_i      => we_i,
    data_i    => data_i,
    address_i => address_i,
    data_o    => data_o,
    hit_o     => hit_o
  );


end architecture;
