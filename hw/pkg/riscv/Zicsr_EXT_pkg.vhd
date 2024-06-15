library ieee;
use ieee.std_logic_1164.all;

package Zicsr_EXT is

    constant FUNCT3_CSRRW   : std_logic_vector(2 downto 0) := b"001";
    constant FUNCT3_CSRRS   : std_logic_vector(2 downto 0) := b"010";
    constant FUNCT3_CSRRC   : std_logic_vector(2 downto 0) := b"011";
    constant FUNCT3_CSRRWI  : std_logic_vector(2 downto 0) := b"101";
    constant FUNCT3_CSRRSI  : std_logic_vector(2 downto 0) := b"110";
    constant FUNCT3_CSRRCI  : std_logic_vector(2 downto 0) := b"111";

end package;
