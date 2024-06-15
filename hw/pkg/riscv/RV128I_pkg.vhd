library ieee;
use ieee.std_logic_1164.all;

package RV128I is

    constant INST32_SHAMT128 : bit_vector(26 downto 20) := (others => '0');

    constant OP_OP_64       : std_logic_vector(4 downto 0) := b"11110";
    constant OP_IMM_64      : std_logic_vector(4 downto 0) := b"10110";

    constant FUNCT5_SLI     : std_logic_vector(4 downto 0) := b"00000";
    constant FUNCT5_SAI     : std_logic_vector(4 downto 0) := b"01000";

    -- LOAD
    constant FUNCT3_LDU     : std_logic_vector(2 downto 0) := b"111";

    -- NOTE: Now under MISC-MEM
    constant FUNCT3_LQ      : std_logic_vector(2 downto 0) := b"010";

    -- STORE
    constant FUNCT3_SQ      : std_logic_vector(2 downto 0) := b"100";

end package;
