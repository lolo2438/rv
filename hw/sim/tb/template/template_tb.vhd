library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library hw;

library sim;
use sim.tb_pkg.clk_gen;

entity template_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of template_tb is
begin

  -- clkgen(clk, CLK_FREQ)

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
  entity hw.template_tb
  generic map()
  port map();

end architecture;
