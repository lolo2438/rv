library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

package RV32I is

    -- Instruction section range
    constant INST32_FUNCT7        : bit_vector(31 downto 25) := (others => '0');
    constant INST32_RS2           : bit_vector(24 downto 20) := (others => '0');
    constant INST32_RS1           : bit_vector(19 downto 15) := (others => '0');
    constant INST32_FUNCT3        : bit_vector(14 downto 12) := (others => '0');
    constant INST32_RD            : bit_vector(11 downto 7)  := (others => '0');
    constant INST32_OPCODE        : bit_vector(6 downto 2)   := (others => '0');
    constant INST32_QUADRANT      : bit_vector(1 downto 0)   := (others => '0');
    constant INST32_SHAMT32       : bit_vector(24 downto 20) := (others => '0');

    constant INST32_FM            : bit_vector(31 downto 28) := (others => '0');
    constant INST32_PRED          : bit_vector(27 downto 24) := (others => '0');
    constant INST32_SUCC          : bit_vector(23 downto 20) := (others => '0');

    constant INST32_I_IMM         : bit_vector(31 downto 20) := (others => '0');
    constant INST32_FUNCT12       : bit_vector(31 downto 20) := (others => '0');
    constant INST32_U_J_IMM       : bit_vector(31 downto 12) := (others => '0');

    constant INST32_NOP           : std_logic_vector := x"00000013";

    -- OPCODES
    constant OP_C3          : std_logic_vector(1 downto 0) := b"11";

    constant OP_OP          : std_logic_vector(4 downto 0) := b"01100";
    constant OP_JALR        : std_logic_vector(4 downto 0) := b"11001";
    constant OP_IMM         : std_logic_vector(4 downto 0) := b"00100";
    constant OP_LUI         : std_logic_vector(4 downto 0) := b"01101";
    constant OP_AUIPC       : std_logic_vector(4 downto 0) := b"00101";
    constant OP_JAL         : std_logic_vector(4 downto 0) := b"11011";
    constant OP_BRANCH      : std_logic_vector(4 downto 0) := b"11000";
    constant OP_STORE       : std_logic_vector(4 downto 0) := b"01000";
    constant OP_LOAD        : std_logic_vector(4 downto 0) := b"00000";
    constant OP_MISC_MEM    : std_logic_vector(4 downto 0) := b"00011";
    constant OP_SYSTEM      : std_logic_vector(4 downto 0) := b"11100";

    -- R-type and I-type functs
    constant FUNCT3_ADDSUB  : std_logic_vector(2 downto 0) := b"000";
    constant FUNCT3_SL      : std_logic_vector(2 downto 0) := b"001";
    constant FUNCT3_SLT     : std_logic_vector(2 downto 0) := b"010";
    constant FUNCT3_SLTU    : std_logic_vector(2 downto 0) := b"011";
    constant FUNCT3_XOR     : std_logic_vector(2 downto 0) := b"100";
    constant FUNCT3_SR      : std_logic_vector(2 downto 0) := b"101";
    constant FUNCT3_OR      : std_logic_vector(2 downto 0) := b"110";
    constant FUNCT3_AND     : std_logic_vector(2 downto 0) := b"111";

    constant FUNCT3_JALR    : std_logic_vector(2 downto 0) := b"000";

    constant FUNCT7_ADD     : std_logic_vector(6 downto 0) := b"0000000";
    constant FUNCT7_SUB     : std_logic_vector(6 downto 0) := b"0100000";
    constant FUNCT7_SLL     : std_logic_vector(6 downto 0) := b"0000000";
    constant FUNCT7_SRL     : std_logic_vector(6 downto 0) := b"0000000";
    constant FUNCT7_SRA     : std_logic_vector(6 downto 0) := b"0100000";

    -- STORE
    constant FUNCT3_SB      : std_logic_vector(2 downto 0) := b"000";
    constant FUNCT3_SH      : std_logic_vector(2 downto 0) := b"001";
    constant FUNCT3_SW      : std_logic_vector(2 downto 0) := b"010";

    -- LOAD
    constant FUNCT3_LB      : std_logic_vector(2 downto 0) := b"000";
    constant FUNCT3_LH      : std_logic_vector(2 downto 0) := b"001";
    constant FUNCT3_LW      : std_logic_vector(2 downto 0) := b"010";
    constant FUNCT3_LBU     : std_logic_vector(2 downto 0) := b"100";
    constant FUNCT3_LHU     : std_logic_vector(2 downto 0) := b"101";

    -- BRANCH
    constant FUNCT3_BEQ     : std_logic_vector(2 downto 0) := b"000";
    constant FUNCT3_BNE     : std_logic_vector(2 downto 0) := b"001";
    constant FUNCT3_BLT     : std_logic_vector(2 downto 0) := b"100";
    constant FUNCT3_BGE     : std_logic_vector(2 downto 0) := b"101";
    constant FUNCT3_BLTU    : std_logic_vector(2 downto 0) := b"110";
    constant FUNCT3_BGEU    : std_logic_vector(2 downto 0) := b"111";

    -- SYSTEM
    constant FUNCT12_ECALL  : std_logic_vector(11 downto 0) := b"000000000000";
    constant FUNCT12_EBREAK : std_logic_vector(11 downto 0) := b"000000000001";
    constant FUNCT3_PRIV    : std_logic_vector(2  downto 0) := b"000";

    -- MEMORY
    constant FM_NORMAL      : std_logic_vector(3 downto 0) := b"0000";
    constant FM_TSO         : std_logic_vector(3 downto 0) := b"1000";
    constant FUNCT3_FENCE   : std_logic_vector(2 downto 0) := b"000";

    -- REGISTERS NAME
    constant REG_X00        : std_logic_vector(4 downto 0) := b"00000";
    constant REG_X01        : std_logic_vector(4 downto 0) := b"00001";
    constant REG_X02        : std_logic_vector(4 downto 0) := b"00010";
    constant REG_X03        : std_logic_vector(4 downto 0) := b"00011";
    constant REG_X04        : std_logic_vector(4 downto 0) := b"00100";
    constant REG_X05        : std_logic_vector(4 downto 0) := b"00101";
    constant REG_X06        : std_logic_vector(4 downto 0) := b"00110";
    constant REG_X07        : std_logic_vector(4 downto 0) := b"00111";
    constant REG_X08        : std_logic_vector(4 downto 0) := b"01000";
    constant REG_X09        : std_logic_vector(4 downto 0) := b"01001";
    constant REG_X10        : std_logic_vector(4 downto 0) := b"01010";
    constant REG_X11        : std_logic_vector(4 downto 0) := b"01011";
    constant REG_X12        : std_logic_vector(4 downto 0) := b"01100";
    constant REG_X13        : std_logic_vector(4 downto 0) := b"01101";
    constant REG_X14        : std_logic_vector(4 downto 0) := b"01110";
    constant REG_X15        : std_logic_vector(4 downto 0) := b"10000";
    constant REG_X16        : std_logic_vector(4 downto 0) := b"10001";
    constant REG_X17        : std_logic_vector(4 downto 0) := b"10010";
    constant REG_X18        : std_logic_vector(4 downto 0) := b"10011";
    constant REG_X19        : std_logic_vector(4 downto 0) := b"10100";
    constant REG_X20        : std_logic_vector(4 downto 0) := b"10101";
    constant REG_X21        : std_logic_vector(4 downto 0) := b"10110";
    constant REG_X22        : std_logic_vector(4 downto 0) := b"10111";
    constant REG_X23        : std_logic_vector(4 downto 0) := b"11000";
    constant REG_X24        : std_logic_vector(4 downto 0) := b"11001";
    constant REG_X25        : std_logic_vector(4 downto 0) := b"11010";
    constant REG_X26        : std_logic_vector(4 downto 0) := b"11011";
    constant REG_X27        : std_logic_vector(4 downto 0) := b"11100";
    constant REG_X28        : std_logic_vector(4 downto 0) := b"11101";
    constant REG_X29        : std_logic_vector(4 downto 0) := b"11110";
    constant REG_X30        : std_logic_vector(4 downto 0) := b"11111";
    constant REG_X31        : std_logic_vector(4 downto 0) := b"11111";

    -- ABI REGISTER NAME
    constant REG_ZERO       : std_logic_vector(4 downto 0) := REG_X00;
    constant REG_RA         : std_logic_vector(4 downto 0) := REG_X01;
    constant REG_SP         : std_logic_vector(4 downto 0) := REG_X02;
    constant REG_GP         : std_logic_vector(4 downto 0) := REG_X03;
    constant REG_TP         : std_logic_vector(4 downto 0) := REG_X04;
    constant REG_T0         : std_logic_vector(4 downto 0) := REG_X05;
    constant REG_T1         : std_logic_vector(4 downto 0) := REG_X06;
    constant REG_T2         : std_logic_vector(4 downto 0) := REG_X07;
    constant REG_S0_FP      : std_logic_vector(4 downto 0) := REG_X08;
    constant REG_S1         : std_logic_vector(4 downto 0) := REG_X09;
    constant REG_A0         : std_logic_vector(4 downto 0) := REG_X10;
    constant REG_A1         : std_logic_vector(4 downto 0) := REG_X11;
    constant REG_A2         : std_logic_vector(4 downto 0) := REG_X12;
    constant REG_A3         : std_logic_vector(4 downto 0) := REG_X13;
    constant REG_A4         : std_logic_vector(4 downto 0) := REG_X14;
    constant REG_A5         : std_logic_vector(4 downto 0) := REG_X15;
    constant REG_A6         : std_logic_vector(4 downto 0) := REG_X16;
    constant REG_A7         : std_logic_vector(4 downto 0) := REG_X17;
    constant REG_S2         : std_logic_vector(4 downto 0) := REG_X18;
    constant REG_S3         : std_logic_vector(4 downto 0) := REG_X19;
    constant REG_S4         : std_logic_vector(4 downto 0) := REG_X20;
    constant REG_S5         : std_logic_vector(4 downto 0) := REG_X21;
    constant REG_S6         : std_logic_vector(4 downto 0) := REG_X22;
    constant REG_S7         : std_logic_vector(4 downto 0) := REG_X23;
    constant REG_S8         : std_logic_vector(4 downto 0) := REG_X24;
    constant REG_S9         : std_logic_vector(4 downto 0) := REG_X25;
    constant REG_S10        : std_logic_vector(4 downto 0) := REG_X26;
    constant REG_S11        : std_logic_vector(4 downto 0) := REG_X27;
    constant REG_T3         : std_logic_vector(4 downto 0) := REG_X28;
    constant REG_T4         : std_logic_vector(4 downto 0) := REG_X29;
    constant REG_T5         : std_logic_vector(4 downto 0) := REG_X30;
    constant REG_T6         : std_logic_vector(4 downto 0) := REG_X31;

end package;
