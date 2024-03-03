library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use work.tb_pkg.all;

library osvvm;
use osvvm.TbUtilPkg.all;

entity stack_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of stack_tb is

  constant DATA_WIDTH : natural := 8;
  constant STACK_SIZE : natural := 5;

  signal clk_i   : std_logic := '0';
  signal rst_i   : std_logic := '0';
  signal data_i  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal push_i  : std_logic := '0';
  signal pop_i   : std_logic := '0';
  signal full_o  : std_logic;
  signal empty_o : std_logic;
  signal data_o  : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

  CreateClock(clk_i, 10 ns);

  main:
  process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("data") then
        rst_i <= '1';
        WaitForClock(clk_i);
        rst_i <= '0';

        data_i <= x"AA";
        push_i <= '1';
        WaitForClock(clk_i);
        wait until data_o'event;
        check_equal(data_o, std_logic_vector'(x"AA"));

        data_i <= x"BB";
        WaitForClock(clk_i);
        wait until data_o'event;
        check_equal(data_o, std_logic_vector'(x"BB"));

        data_i <= x"CC";
        WaitForClock(clk_i);
        wait until data_o'event;
        check_equal(data_o, std_logic_vector'(x"CC"));

        data_i <= x"DD";
        pop_i <= '1';
        WaitForClock(clk_i);
        wait until data_o'event;
        check_equal(data_o, std_logic_vector'(x"DD"));

        push_i <= '0';
        WaitForClock(clk_i);
        wait until data_o'event;
        check_equal(data_o, std_logic_vector'(x"BB"));

        WaitForClock(clk_i);
        wait until data_o'event;
        check_equal(data_o, std_logic_vector'(x"AA"));

        WaitForClock(clk_i);


      elsif run("ctrl") then
        rst_i <= '1';
        WaitForClock(clk_i);
        rst_i <= '0';

        WaitForClock(clk_i);

        check(empty_o = '1', "Stack empty");
        check(full_o = '0', "Stack not full");

        data_i <= x"AB";
        push_i <= '1';

        WaitForClock(clk_i, 6);

        check(empty_o = '0', "Stack not empty");
        check(full_o = '1', "Stack full");

        -- Check overwrite protection
        data_i <= x"CC";
        waitForClock(clk_i);
        waitForClock(clk_i);
        check_equal(data_o, std_logic_vector'(x"AB"));

        push_i <= '0';
        pop_i <= '1';

        WaitForClock(clk_i, 6);

        check(empty_o = '1', "Stack empty");
        check(full_o = '0', "Stack not full");

        -- Check over-pop protection
        WaitForClock(clk_i);

        data_i <= x"BA";
        push_i <= '1';
        pop_i <= '0';
        WaitForClock(clk_i);
        wait until data_o'event;
        check_equal(data_o, std_logic_vector'(x"BA"));

        WaitForClock(clk_i);

      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

  test_runner_watchdog(runner, 10 us);

  DUT: entity work.stack(rtl)
  generic map(
    DATA_WIDTH => DATA_WIDTH,
    STACK_SIZE => STACK_SIZE
  )
  port map(
    clk_i   => clk_i,
    rst_i   => rst_i,
    data_i  => data_i,
    push_i  => push_i,
    pop_i   => pop_i,
    full_o  => full_o,
    empty_o => empty_o,
    data_o  => data_o
  );

end architecture;
