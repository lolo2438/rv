library ieee;
use ieee.std_logic_1164.all;

package RV64I is

    constant INST32_SHAMT64 : bit_vector(25 downto 20) := (others => '0');

    constant OP_OP_32       : std_logic_vector(4 downto 0) := b"01110";
    constant OP_IMM_32      : std_logic_vector(4 downto 0) := b"00110";

    constant FUNCT6_SLI64   : std_logic_vector(5 downto 0) := b"000000";
    constant FUNCT6_SAI64   : std_logic_vector(5 downto 0) := b"010000";

    -- LOAD
    constant FUNCT3_LWU     : std_logic_vector(2 downto 0) := b"110";
    constant FUNCT3_LD      : std_logic_vector(2 downto 0) := b"011";

    -- STORE
    constant FUNCT3_SD      : std_logic_vector(2 downto 0) := b"011";

end package;
