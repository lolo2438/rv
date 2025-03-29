-------------------------------------------------------------------------------
-- Title       : data_ram_tb
-- Project     : Project 2
-------------------------------------------------------------------------------
-- File        : data_ram_tb.vhd
-- Author      : Mathieu Nadeau
-- Created     : Jun 30 2021
-- Last update : Mon Jul 26 19:18:54 2021
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

library riscv;
use riscv.rv32e_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity data_ram_tb is
generic (
    runner_cfg : string
    );
end data_ram_tb;


architecture tb of data_ram_tb is

type ram_type is array(0 to 4095) of std_logic_vector(31 downto 0);
signal ram_data : ram_type;

constant CLK_PERIOD : time := 10.0 ns;
  
    signal clk     : std_logic;
    signal funct3  : std_logic_vector(2 downto 0);
    signal address : std_logic_vector(11 downto 0);
    signal data_i  : std_logic_vector(31 downto 0);
    signal data_o  : std_logic_vector(31 downto 0);
    signal sel     : std_logic;
    signal we      : std_logic;

begin

  DUT : entity work.data_ram
  port map (
    clk       => clk,
    funct3    => funct3,
    address   => address,
    data_i    => data_i,
    data_o    => data_o,
    sel       => sel,
    we        => we
  );

  ----------------------------------------------------------
  -- CLOCK GENERATOR
  ----------------------------------------------------------

  CLOCK : process

  begin

    clk <= '0';

    wait for CLK_PERIOD;

    clk <= '1';

    wait for CLK_PERIOD;

  end process CLOCK;

  ----------------------------------------------------------
  -- MAIN TESTBENCH
  ----------------------------------------------------------
  MAIN : process

    variable rd : std_logic_vector(31 downto 0);
    
    begin

      test_runner_setup(runner, runner_cfg);
      
      while test_suite loop

          if run("load byte") then
            
            sel       <= '1';
            we        <= '1';  
            address   <= x"000";
            funct3    <= FUNCT3_SW;
            data_i    <= x"03030303";

            wait until rising_edge(clk);

            sel       <= '1';
            we        <= '0';  
            address   <= x"000";
            funct3    <= FUNCT3_LB;
            rd        := x"00000003";

            wait until rising_edge(clk);

            wait until rising_edge(clk);

            check_equal(data_o, rd, "Checking data_o");

          elsif run("load Halfword") then

            sel       <= '1';
            we        <= '1';  
            address   <= x"000";
            funct3    <= FUNCT3_SW;
            data_i    <= x"03030303";

            wait until rising_edge(clk);

            sel       <= '1';
            we        <= '0';  
            address   <= x"000";
            funct3    <= FUNCT3_LH;
            rd        := x"00000303";

            wait until rising_edge(clk);

            wait until rising_edge(clk);

            check_equal(data_o, rd, "Checking data_o");

          elsif run("load Word") then
            
            sel       <= '1';
            we        <= '1';  
            address   <= x"000";
            funct3    <= FUNCT3_SW;
            data_i    <= x"03030303";

            wait until rising_edge(clk);

            sel       <= '1';
            we        <= '0';  
            address   <= x"000";
            funct3    <= FUNCT3_LW;
            rd        := x"03030303";

            wait until rising_edge(clk);

            wait until rising_edge(clk);

            check_equal(data_o, rd, "Checking data_o");

          elsif run("load Byte Unsigned") then
            
            sel       <= '1';
            we        <= '1';  
            address   <= x"000";
            funct3    <= FUNCT3_SW;
            data_i    <= x"FFFFFFFF";

            wait until rising_edge(clk);

            sel       <= '1';
            we        <= '0';  
            address   <= x"000";
            funct3    <= FUNCT3_LBU;
            rd        := x"000000FF";

            wait until rising_edge(clk);

            wait until rising_edge(clk);

            check_equal(data_o, rd, "Checking data_o");
            
          elsif run("load Halfword Unsigned") then
            
            sel       <= '1';
            we        <= '1';  
            address   <= x"000";
            funct3    <= FUNCT3_SW;
            data_i    <= x"FFFFFFFF";

            wait until rising_edge(clk);

            sel       <= '1';
            we        <= '0';  
            address   <= x"000";
            funct3    <= FUNCT3_LHU;
            rd        := x"0000FFFF";

            wait until rising_edge(clk);

            wait until rising_edge(clk);

            check_equal(data_o, rd, "Checking data_o");
            
            
          end if;

      end loop;
      test_runner_cleanup(runner);
    end process MAIN;
end tb;