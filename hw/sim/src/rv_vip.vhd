library ieee;
use ieee.std_logic_1164.all;

entity rv_vip is
  generic(
    XLEN : natural
  );
  port(
    i_clk       : std_logic;
    instruction : std_logic_vector(31 downto 0)
  );
end entity;

architecture vip of rv_vip is


begin

  -- So
  -- How to verify...
  --
  -- 1. Input = Instruction
  -- 2. Decoding
  -- 3. Execute
  -- 4. Store:
  --   4.1. Value to be written in register
  --   4.2. Register state
  --   4.3. Memory state
  -- OSVVM

end architecture;
