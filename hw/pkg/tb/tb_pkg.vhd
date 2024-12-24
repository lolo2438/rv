library ieee;
use ieee.std_logic_1164.all;


package tb_pkg is

  --! @fn Procedure clk_gen
  --! @param clk the clock signal to drive
  --! @param FREQ the frequency of the driven clock signal
  --! @param PHASE Initial phase of the clock
  --! @brief Generates a clock signal of FREQ
  procedure clk_gen(signal clk      : out std_logic;
                    constant FREQ   : real;
                    constant PHASE  : time := 0 fs);

end package;


package body tb_pkg is

  procedure clk_gen(signal clk      : out std_logic;
                    constant FREQ   : real;
                    constant PHASE  : time := 0 fs) is
    constant PERIOD    : time := 1 sec / FREQ;        -- Full period
    constant HIGH_TIME : time := PERIOD / 2;          -- High time
    constant LOW_TIME  : time := PERIOD - HIGH_TIME;  -- Low time; always >= HIGH_TIME
  begin
    -- Check the arguments
    assert (HIGH_TIME /= 0 fs)
    report "clk_gen: High time is zero; time resolution to large for frequency"
    severity FAILURE;

    -- Clock generator
    clk <= '0';
    wait for PHASE;

    loop
      clk <= '1';
      wait for HIGH_TIME;
      clk <= '0';
      wait for LOW_TIME;
    end loop;
  end procedure;

end package body;
