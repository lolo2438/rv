--------------------------------------------------------------------------------
-- Title       : Registers_tb
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : registers_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Jun 30 15:52:22 2021
-- Last update : Mon Jul 26 21:07:04 2021
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Copyright (c) 2021 User Company Name
-------------------------------------------------------------------------------
-- Description:
--------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

--library demo_lib;
-----------------------------------------------------------

entity registers_tb is
	generic (runner_cfg : string);
end entity registers_tb;

-----------------------------------------------------------

architecture testbench of registers_tb is

	-- Testbench DUT ports
	signal Rs1          : std_logic_vector(3 downto 0);
	signal Rs2          : std_logic_vector(3 downto 0);
	signal Rd           : std_logic_vector(3 downto 0);
	signal Rd_Value     : std_logic_vector(31 downto 0);
	signal Write_Enable : std_logic;
	signal Clock        : std_logic;
	signal Rs1_Value    : std_logic_vector(31 downto 0);
	signal Rs2_Value    : std_logic_vector(31 downto 0);

	-- Other constants
	constant C_CLK_PERIOD : real := 10.0e-9; -- NS

begin
	----------------------------------------------------------
	-- Clocks and Reset
	-----------------------------------------------------------
	CLK_GEN : process
	begin
		Clock <= '1';
		wait for C_CLK_PERIOD / 2.0 * (1 SEC);
		Clock <= '0';
		wait for C_CLK_PERIOD / 2.0 * (1 SEC);
	end process CLK_GEN;

	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------

	main : process
    begin

	    test_runner_setup(runner, runner_cfg);

	 	wait for C_CLK_PERIOD / 2.0 * (1 SEC);

	    Rd_Value <= X"00000001";						--1
	    Rd <= "1000";									--x8
	    Write_Enable <= '1';

	    wait for C_CLK_PERIOD * (1 SEC);

	    Write_Enable <= '0';
	    Rs1 <= "1000";									--x8
	    Rs2 <= "0000";									--x0
	    wait for C_CLK_PERIOD / 1000.0 * (1 SEC);
	    check_equal(Rs1_Value, 1, "1 in register x8");
	    check_equal(Rs2_Value, 0, "Always 0 in register x0");


	    Rd_Value <= X"0000000F";						--15
	    Rd <= "1000";									--x8
	    Write_Enable <= '1';

	    wait for C_CLK_PERIOD * (1 SEC);

	    Write_Enable <= '0';
	    Rs1 <= "1000";									--x8
	    wait for C_CLK_PERIOD / 1000.0 * (1 SEC);
	    check_equal(Rs1_Value, 15, "15 in register x8");


	    Rd_Value <= X"000000FF";						--15
	    Rd <= "0000";									--x0
	    Write_Enable <= '1';

	    wait for C_CLK_PERIOD * (1 SEC);

	    Write_Enable <= '0';
	    Rs1 <= "0000";									--x0
	    Rs2 <= "1000";									--x8
	    wait for C_CLK_PERIOD / 1000.0 * (1 SEC);
	    check_equal(Rs1_Value, 0, "Always 0 in register x0");
	    check_equal(Rs2_Value, 15, "15 in register x8");


		Rd_Value <= X"000000FF";						--255
	    Rd <= "1111";									--x15
	    Write_Enable <= '1';

	    wait for C_CLK_PERIOD * (1 SEC);

	    Write_Enable <= '0';
	    Rs1 <= "1111";									--x15
	    Rs2 <= "1111";									--x15
	    wait for C_CLK_PERIOD / 1000.0 * (1 SEC);
	    check_equal(Rs1_Value, 255, "255 in register x15");
	    check_equal(Rs2_Value, 255, "255 in register x15");


		Rd_Value <= X"00000010";						--16
	    Rd <= "1111";									--x2
	    								   --No write enable

	    wait for C_CLK_PERIOD * (1 SEC);

	    Rs2 <= "1111";									--x15
	    wait for C_CLK_PERIOD / 1000.0 * (1 SEC);
	    check_equal(Rs2_Value, 255, "255 in register x15");


		wait for 5.0*C_CLK_PERIOD * (1 SEC);

		test_runner_cleanup(runner);

  	end process;

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
	DUT : entity work.registers
		port map (
			Rs1          => Rs1,
			Rs2          => Rs2,
			Rd           => Rd,
			Rd_Value     => Rd_Value,
			Write_Enable => Write_Enable,
			Clock        => Clock,
			Rs1_Value    => Rs1_Value,
			Rs2_Value    => Rs2_Value
		);

end architecture testbench;
