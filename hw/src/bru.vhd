---
--
--
--
--
--
--
-- ROLE:
-- Hold speculative branch table
-- Return address stack
-- Detect speculative error
---
library ieee;
use ieee.std_logic_1164.all;

entity bru is
  generic(
    XLEN : natural
  );
  port(
    i_clk : std_logic

  );
end entity;

architecture rtl of bru is
begin

    -- Inputs
    -- CDB:     TAG + Result, will be able to tell if branch successful
    -- DISPATCH:
    --  BRANCH,
    --  JALR


    -- LOGIC

    -- Outputs
    --
    -- SYSTEM
    -- PC to jump to
    -- stall if can't do anything
    -- speculative flag: information if the operation is speculative
    -- Rollback


end architecture;
