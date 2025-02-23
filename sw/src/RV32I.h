#ifndef RV32I_H
#define RV32I_H

#define REG_WIDTH 5

#define OFFSET_FUNCT7 25
#define OFFSET_RS2 20
#define OFFSET_RS1 15
#define OFFSET_FUNCT3 12
#define OFFSET_RD 7
#define OFFSET_OP 2
#define OFFSET_SHAMT32 20

#define OFFSET_FM 28
#define OFFSET_PRED 24
#define OFFSET_SUCC 20
#define OFFSET_I_IMM 20
#define OFFSET_FUNCT12 20
#define OFFSET_U_J_IMM 12

#define MASK_Q      0x3
#define MASK_FUNCT7 0x7F
#define MASK_REG    0x1F
#define MASK_FUNCT3 0x7
#define MASK_OP     0x1F
#define MASK_IMM_I  0xFFF
#define MASK_IMM_U  0xFFFFF000


// OPCODES
#define OP_C3 0b11

#define OP_OP       0b01100
#define OP_JALR     0b11001
#define OP_IMM      0b00100
#define OP_LUI      0b01101
#define OP_AUIPC    0b00101
#define OP_JAL      0b11011
#define OP_BRANCH   0b11000
#define OP_STORE    0b01000
#define OP_LOAD     0b00000
#define OP_MISC_MEM 0b00011
#define OP_SYSTEM   0b11100

// R and I FUNCT
#define FUNCT3_ADDSUB 0b000
#define FUNCT3_SL     0b001
#define FUNCT3_SLT    0b010
#define FUNCT3_SLTU   0b011
#define FUNCT3_XOR    0b100
#define FUNCT3_SR     0b101
#define FUNCT3_OR     0b110
#define FUNCT3_AND    0b111

#define FUNCT3_JALR 0b000

#define FUNCT7_ADD 0b0000000
#define FUNCT7_SUB 0b0100000
#define FUNCT7_SLL 0b0000000
#define FUNCT7_SRL 0b0000000
#define FUNCT7_SRA 0b0100000

// STORE
#define FUNCT3_SB 0b000
#define FUNCT3_SH 0b001
#define FUNCT3_SW 0b010

// LOAD
#define FUNCT3_LB  0b000
#define FUNCT3_LH  0b001
#define FUNCT3_LW  0b010
#define FUNCT3_LBU 0b100
#define FUNCT3_LHU 0b101

// BRANCH
#define FUNCT3_BEQ  0b000
#define FUNCT3_BNE  0b001
#define FUNCT3_BLT  0b100
#define FUNCT3_BGE  0b101
#define FUNCT3_BLTU 0b110
#define FUNCT3_BGEU 0b111

// SYSTEM
#define FUNCT12_ECALL   0b000000000000
#define FUNCT12_EBREAK0 0b000000000001
#define FUNCT3_PRIV     0b000

// MEMORY
#define FM_NORMAL    0b0000
#define FM_TSO       0b1000
#define FUNCT3_FENCE 0b000

// REGISTERS NAME
#define REG_X00 0b00000
#define REG_X01 0b00001
#define REG_X02 0b00010
#define REG_X03 0b00011
#define REG_X04 0b00100
#define REG_X05 0b00101
#define REG_X06 0b00110
#define REG_X07 0b00111
#define REG_X08 0b01000
#define REG_X09 0b01001
#define REG_X10 0b01010
#define REG_X11 0b01011
#define REG_X12 0b01100
#define REG_X13 0b01101
#define REG_X14 0b01110
#define REG_X15 0b10000
#define REG_X16 0b10001
#define REG_X17 0b10010
#define REG_X18 0b10011
#define REG_X19 0b10100
#define REG_X20 0b10101
#define REG_X21 0b10110
#define REG_X22 0b10111
#define REG_X23 0b11000
#define REG_X24 0b11001
#define REG_X25 0b11010
#define REG_X26 0b11011
#define REG_X27 0b11100
#define REG_X28 0b11101
#define REG_X29 0b11110
#define REG_X30 0b11111
#define REG_X31 0b11111

// ABI REGISTER NAME
#define REG_ZERO  REG_X00
#define REG_RA    REG_X01
#define REG_SP    REG_X02
#define REG_GP    REG_X03
#define REG_TP    REG_X04
#define REG_T0    REG_X05
#define REG_T1    REG_X06
#define REG_T2    REG_X07
#define REG_S0_FP REG_X08
#define REG_S1    REG_X09
#define REG_A0    REG_X10
#define REG_A1    REG_X11
#define REG_A2    REG_X12
#define REG_A3    REG_X13
#define REG_A4    REG_X14
#define REG_A5    REG_X15
#define REG_A6    REG_X16
#define REG_A7    REG_X17
#define REG_S2    REG_X18
#define REG_S3    REG_X19
#define REG_S4    REG_X20
#define REG_S5    REG_X21
#define REG_S6    REG_X22
#define REG_S7    REG_X23
#define REG_S8    REG_X24
#define REG_S9    REG_X25
#define REG_S10   REG_X26
#define REG_S11   REG_X27
#define REG_T3    REG_X28
#define REG_T4    REG_X29
#define REG_T5    REG_X30
#define REG_T6    REG_X31

#endif
