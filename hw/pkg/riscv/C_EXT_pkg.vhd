library ieee;
use ieee.std_logic_1164.all;

package C_EXT is

    -- Instruction ranges: only use for 'range attribute
    constant INST16_FUNCT3        : bit_vector(15 downto 13) := (others => '0');
    constant INST16_RS1P          : bit_vector(9 downto 7)   := (others => '0');
    constant INST16_RS2P          : bit_vector(4 downto 2)   := (others => '0');
    constant INST16_RDP           : bit_vector(4 downto 2)   := (others => '0');
    constant INST16_RS1           : bit_vector(11 downto 7)  := (others => '0');
    constant INST16_RS2           : bit_vector(6 downto 2)   := (others => '0');
    constant INST16_RD            : bit_vector(11 downto 7)  := (others => '0');
    constant INST16_FUNCT2_ALU_I  : bit_vector(11 downto 10) := (others => '0');
    constant INST16_FUNCT2_ALU_R  : bit_vector(6 downto 5)   := (others => '0');

    -- Quadrant 0
    constant OP_C0                          : std_logic_vector(1 downto 0) := b"00";

    constant FUNCT3_C_ADDI4SPN              : std_logic_vector(2 downto 0) := b"000";
    constant FUNCT3_C_FLD_LQ                : std_logic_vector(2 downto 0) := b"001";
    constant FUNCT3_C_LW                    : std_logic_vector(2 downto 0) := b"010";
    constant FUNCT3_C_FLW_LD                : std_logic_vector(2 downto 0) := b"011";
    constant FUNCT3_C_FSD_SQ                : std_logic_vector(2 downto 0) := b"101";
    constant FUNCT3_C_SW                    : std_logic_vector(2 downto 0) := b"110";
    constant FUNCT3_C_FSW_SD                : std_logic_vector(2 downto 0) := b"111";

    -- Quadrant 1
    constant OP_C1                          : std_logic_vector(1 downto 0) := b"01";

    constant FUNCT3_C_ADDI                  : std_logic_vector(2 downto 0) := b"000";
    constant FUNCT3_C_JAL_ADDIW             : std_logic_vector(2 downto 0) := b"001";
    constant FUNCT3_C_LI                    : std_logic_vector(2 downto 0) := b"010";
    constant FUNCT3_C_ADDI16SP_LUI          : std_logic_vector(2 downto 0) := b"011";
    constant FUNCT3_C_MISC_ALU              : std_logic_vector(2 downto 0) := b"100";
    constant FUNCT2_C_SRLI_SRLI64           : std_logic_vector(1 downto 0) := b"00";
    constant FUNCT2_C_SRAI_SRAI64           : std_logic_vector(1 downto 0) := b"01";
    constant FUNCT2_C_ANDI                  : std_logic_vector(1 downto 0) := b"10";
    constant FUNCT2_C_SUB                   : std_logic_vector(1 downto 0) := b"00";
    constant FUNCT2_C_SUBW                  : std_logic_vector(1 downto 0) := b"00";
    constant FUNCT2_C_XOR                   : std_logic_vector(1 downto 0) := b"01";
    constant FUNCT2_C_ADDW                  : std_logic_vector(1 downto 0) := b"01";
    constant FUNCT2_C_OR                    : std_logic_vector(1 downto 0) := b"10";
    constant FUNCT2_C_AND                   : std_logic_vector(1 downto 0) := b"11";
    constant FUNCT3_C_J                     : std_logic_vector(2 downto 0) := b"101";
    constant FUNCT3_C_BEQZ                  : std_logic_vector(2 downto 0) := b"110";
    constant FUNCT3_C_BNEZ                  : std_logic_vector(2 downto 0) := b"111";

    -- Quadrant 2
    constant OP_C2                          : std_logic_vector(1 downto 0) := b"10";

    constant FUNCT3_C_SLLI_SLLI64           : std_logic_vector(2 downto 0) := b"000";
    constant FUNCT3_C_FLDSP_LQSP            : std_logic_vector(2 downto 0) := b"001";
    constant FUNCT3_C_LWSP                  : std_logic_vector(2 downto 0) := b"010";
    constant FUNCT3_C_FLWSP_LDSP            : std_logic_vector(2 downto 0) := b"011";
    constant FUNCT3_C_JR_MV_EBREAK_JALR_ADD : std_logic_vector(2 downto 0) := b"100";
    constant FUNCT3_C_FSDSP_SQSP            : std_logic_vector(2 downto 0) := b"101";
    constant FUNCT3_C_SQSP                  : std_logic_vector(2 downto 0) := b"101";
    constant FUNCT3_C_SWSP                  : std_logic_vector(2 downto 0) := b"110";
    constant FUNCT3_C_FSWSP_SDSP            : std_logic_vector(2 downto 0) := b"111";

end package;
