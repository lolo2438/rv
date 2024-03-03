library ieee;
use ieee.std_logic_1164.all;

package M_EXT is

    ---- RV32M
    constant FUNCT7_MULDIV  : std_logic_vector(6 downto 0) := b"0000001";

    constant FUNCT3_MUL     : std_logic_vector(2 downto 0) := b"000";
    constant FUNCT3_MULH    : std_logic_vector(2 downto 0) := b"001";
    constant FUNCT3_MULHSU  : std_logic_vector(2 downto 0) := b"010";
    constant FUNCT3_MULHU   : std_logic_vector(2 downto 0) := b"011";
    constant FUNCT3_DIV     : std_logic_vector(2 downto 0) := b"100";
    constant FUNCT3_DIVU    : std_logic_vector(2 downto 0) := b"101";
    constant FUNCT3_REM     : std_logic_vector(2 downto 0) := b"110";
    constant FUNCT3_REMU    : std_logic_vector(2 downto 0) := b"111";

    ---- RV64M
    constant FUNCT3_MULW    : std_logic_vector(2 downto 0) := b"000";
    constant FUNCT3_DIVW    : std_logic_vector(2 downto 0) := b"100";
    constant FUNCT3_DIVUW   : std_logic_vector(2 downto 0) := b"101";
    constant FUNCT3_REMW    : std_logic_vector(2 downto 0) := b"110";
    constant FUNCT3_REMUW   : std_logic_vector(2 downto 0) := b"111";

end package;
