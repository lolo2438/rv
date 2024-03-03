library ieee;
use ieee.std_logic_1164.all;

package F_EXT is

    ---- RV32F
    constant OP_LOAD_FP     : std_logic_vector(4 downto 0) := b"00001";
    constant OP_STORE_FP    : std_logic_vector(4 downto 0) := b"01001";
    constant OP_FMADD       : std_logic_vector(4 downto 0) := b"10000";
    constant OP_FMSUB       : std_logic_vector(4 downto 0) := b"10001";
    constant OP_FNMSUB      : std_logic_vector(4 downto 0) := b"10010";
    constant OP_FNMADD      : std_logic_vector(4 downto 0) := b"10011";
    constant OP_FP          : std_logic_vector(4 downto 0) := b"10100";

    constant FUNCT3_FP_W    : std_logic_vector(2 downto 0) := b"010";
    constant FMT2_S         : std_logic_vector(1 downto 0) := b"00";
--    constant FMT2_H          : std_logic_vector(1 downto 0) := b"10";

    constant RM_RNE         : std_logic_vector(2 downto 0) := b"000";
    constant RM_RTZ         : std_logic_vector(2 downto 0) := b"001";
    constant RM_RDN         : std_logic_vector(2 downto 0) := b"010";
    constant RM_RUP         : std_logic_vector(2 downto 0) := b"011";
    constant RM_RMM         : std_logic_vector(2 downto 0) := b"100";
    constant RM_DYN         : std_logic_vector(2 downto 0) := b"111";

    constant FUNCT3_FSGNJ   : std_logic_vector(2 downto 0) := b"000";
    constant FUNCT3_FNGNJN  : std_logic_vector(2 downto 0) := b"000";
    constant FUNCT3_FNGNJX  : std_logic_vector(2 downto 0) := b"000";

    constant FUNCT3_FMIN    : std_logic_vector(2 downto 0) := b"000";
    constant FUNCT3_FMAX    : std_logic_vector(2 downto 0) := b"000";

    constant FUNCT3_FEQ     : std_logic_vector(2 downto 0) := b"000";
    constant FUNCT3_FLT     : std_logic_vector(2 downto 0) := b"000";
    constant FUNCT3_FLE     : std_logic_vector(2 downto 0) := b"000";

    constant FUNCT5_FADD            : std_logic_vector(4 downto 0) := b"00000";
    constant FUNCT5_FSUB            : std_logic_vector(4 downto 0) := b"00001";
    constant FUNCT5_FMUL            : std_logic_vector(4 downto 0) := b"00010";
    constant FUNCT5_FDIV            : std_logic_vector(4 downto 0) := b"00011";
    constant FUNCT5_FSQRT           : std_logic_vector(4 downto 0) := b"01011";
    constant FUNCT5_FSGNJ           : std_logic_vector(4 downto 0) := b"00100";
    constant FUNCT5_FMIN_MAX        : std_logic_vector(4 downto 0) := b"00101";
    constant FUNCT5_FCVT_W_F        : std_logic_vector(4 downto 0) := b"11000";
    constant FUNCT5_FMV_X_W_FCLASS  : std_logic_vector(4 downto 0) := b"11100";
    constant FUNCT5_FCMP            : std_logic_vector(4 downto 0) := b"10100";
    constant FUNCT5_FCVT_F_W        : std_logic_vector(4 downto 0) := b"11010";
    constant FUNCT5_FMV_W_X         : std_logic_vector(4 downto 0) := b"11110";

    -- Floating point registers
    constant REG_F00        : std_logic_vector(4 downto 0) := b"00000";
    constant REG_F01        : std_logic_vector(4 downto 0) := b"00001";
    constant REG_F02        : std_logic_vector(4 downto 0) := b"00010";
    constant REG_F03        : std_logic_vector(4 downto 0) := b"00011";
    constant REG_F04        : std_logic_vector(4 downto 0) := b"00100";
    constant REG_F05        : std_logic_vector(4 downto 0) := b"00101";
    constant REG_F06        : std_logic_vector(4 downto 0) := b"00110";
    constant REG_F07        : std_logic_vector(4 downto 0) := b"00111";
    constant REG_F08        : std_logic_vector(4 downto 0) := b"01000";
    constant REG_F09        : std_logic_vector(4 downto 0) := b"01001";
    constant REG_F10        : std_logic_vector(4 downto 0) := b"01010";
    constant REG_F11        : std_logic_vector(4 downto 0) := b"01011";
    constant REG_F12        : std_logic_vector(4 downto 0) := b"01100";
    constant REG_F13        : std_logic_vector(4 downto 0) := b"01101";
    constant REG_F14        : std_logic_vector(4 downto 0) := b"01110";
    constant REG_F15        : std_logic_vector(4 downto 0) := b"10000";
    constant REG_F16        : std_logic_vector(4 downto 0) := b"10001";
    constant REG_F17        : std_logic_vector(4 downto 0) := b"10010";
    constant REG_F18        : std_logic_vector(4 downto 0) := b"10011";
    constant REG_F19        : std_logic_vector(4 downto 0) := b"10100";
    constant REG_F20        : std_logic_vector(4 downto 0) := b"10101";
    constant REG_F21        : std_logic_vector(4 downto 0) := b"10110";
    constant REG_F22        : std_logic_vector(4 downto 0) := b"10111";
    constant REG_F23        : std_logic_vector(4 downto 0) := b"11000";
    constant REG_F24        : std_logic_vector(4 downto 0) := b"11001";
    constant REG_F25        : std_logic_vector(4 downto 0) := b"11010";
    constant REG_F26        : std_logic_vector(4 downto 0) := b"11011";
    constant REG_F27        : std_logic_vector(4 downto 0) := b"11100";
    constant REG_F28        : std_logic_vector(4 downto 0) := b"11101";
    constant REG_F29        : std_logic_vector(4 downto 0) := b"11110";
    constant REG_F30        : std_logic_vector(4 downto 0) := b"11111";
    constant REG_F31        : std_logic_vector(4 downto 0) := b"11111";

    -- ABI Register naming
    constant REG_FT0        : std_logic_vector(4 downto 0) := REG_F00;
    constant REG_FT1        : std_logic_vector(4 downto 0) := REG_F01;
    constant REG_FT2        : std_logic_vector(4 downto 0) := REG_F02;
    constant REG_FT3        : std_logic_vector(4 downto 0) := REG_F03;
    constant REG_FT4        : std_logic_vector(4 downto 0) := REG_F04;
    constant REG_FT5        : std_logic_vector(4 downto 0) := REG_F05;
    constant REG_FT6        : std_logic_vector(4 downto 0) := REG_F06;
    constant REG_FT7        : std_logic_vector(4 downto 0) := REG_F07;
    constant REG_FS0        : std_logic_vector(4 downto 0) := REG_F08;
    constant REG_FS1        : std_logic_vector(4 downto 0) := REG_F09;
    constant REG_FA0        : std_logic_vector(4 downto 0) := REG_F10;
    constant REG_FA1        : std_logic_vector(4 downto 0) := REG_F11;
    constant REG_FA2        : std_logic_vector(4 downto 0) := REG_F12;
    constant REG_FA3        : std_logic_vector(4 downto 0) := REG_F13;
    constant REG_FA4        : std_logic_vector(4 downto 0) := REG_F14;
    constant REG_FA5        : std_logic_vector(4 downto 0) := REG_F15;
    constant REG_FA6        : std_logic_vector(4 downto 0) := REG_F16;
    constant REG_FA7        : std_logic_vector(4 downto 0) := REG_F17;
    constant REG_FS2        : std_logic_vector(4 downto 0) := REG_F18;
    constant REG_FS3        : std_logic_vector(4 downto 0) := REG_F19;
    constant REG_FS4        : std_logic_vector(4 downto 0) := REG_F20;
    constant REG_FS5        : std_logic_vector(4 downto 0) := REG_F21;
    constant REG_FS6        : std_logic_vector(4 downto 0) := REG_F22;
    constant REG_FS7        : std_logic_vector(4 downto 0) := REG_F23;
    constant REG_FS8        : std_logic_vector(4 downto 0) := REG_F24;
    constant REG_FS9        : std_logic_vector(4 downto 0) := REG_F25;
    constant REG_FS10       : std_logic_vector(4 downto 0) := REG_F26;
    constant REG_FS11       : std_logic_vector(4 downto 0) := REG_F27;
    constant REG_FT8        : std_logic_vector(4 downto 0) := REG_F28;
    constant REG_FT9        : std_logic_vector(4 downto 0) := REG_F29;
    constant REG_FT10       : std_logic_vector(4 downto 0) := REG_F30;
    constant REG_FT11       : std_logic_vector(4 downto 0) := REG_F31;

end package;
