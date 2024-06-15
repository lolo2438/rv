library ieee;
use ieee.std_logic_1164.all;

package A_EXT is

    constant OP_AMO         : std_logic_vector(4 downto 0) := b"01011";

    constant FUNCT3_AMO_W   : std_logic_vector(2 downto 0) := b"010";
    constant FUNCT3_AMO_D   : std_logic_vector(2 downto 0) := b"011";

    constant FUNCT5_LR      : std_logic_vector(4 downto 0) := b"00010";
    constant FUNCT5_SC      : std_logic_vector(4 downto 0) := b"00011";
    constant FUNCT5_AMOSWAP : std_logic_vector(4 downto 0) := b"00001";
    constant FUNCT5_AMOADD  : std_logic_vector(4 downto 0) := b"00000";
    constant FUNCT5_AMOXOR  : std_logic_vector(4 downto 0) := b"00100";
    constant FUNCT5_AMOAND  : std_logic_vector(4 downto 0) := b"01100";
    constant FUNCT5_AMOOR   : std_logic_vector(4 downto 0) := b"01000";
    constant FUNCT5_AMOMIN  : std_logic_vector(4 downto 0) := b"10000";
    constant FUNCT5_AMOMAX  : std_logic_vector(4 downto 0) := b"10100";
    constant FUNCT5_AMOMINU : std_logic_vector(4 downto 0) := b"11000";
    constant FUNCT5_AMOMAXU : std_logic_vector(4 downto 0) := b"11100";

end package;
