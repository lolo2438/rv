/**
 * File: RV32E.h
 * Date : 2021-05
 * Description: Definitions and types used for RV32E instructions decoding
 *              and handling.
 */

#ifndef RV32E_H
#define RV32E_H

#include <stdint.h>


/*** RV32E OPCODE masks ***/
#define MASK_OPCODE 0b1111111

#define RV32E_OP        0b0110011
#define RV32E_OP_IMM    0b0010011
#define RV32E_OP_BRANCH 0b1100011
#define RV32E_OP_LUI    0b0110111
#define RV32E_OP_AUIPC  0b0010111
#define RV32E_OP_JAL    0b1101111
#define RV32E_OP_JALR   0b1100111
#define RV32E_OP_LOAD   0b0000011
#define RV32E_OP_STORE  0b0100011
#define RV32E_OP_MEM    0b0001111
#define RV32E_OP_OS     0b1110011


/*** RV32E Data formatting ***/
#define OFFSET_FUNCT3   12
#define OFFSET_FUNCT7   25
#define OFFSET_OS_OP    20
#define OFFSET_RS2      20
#define OFFSET_RS1      15
#define OFFSET_RD       7
#define OFFSET_OPCODE   0


/*** RV32E funct3 masks ***/
#define MASK_ALT_FUNCT3   0b111 << OFFSET_FUNCT3

#define FUNCT3_ADD_SUB    0b000
#define FUNCT3_SLL        0b001
#define FUNCT3_SLT        0b010
#define FUNCT3_SLTU       0b011
#define FUNCT3_XOR        0b100
#define FUNCT3_SRL_SRA    0b101
#define FUNCT3_OR         0b110
#define FUNCT3_AND        0b111

#define FUNCT3_BEQ        0b000
#define FUNCT3_BNE        0b001
#define FUNCT3_BLT        0b100
#define FUNCT3_BGE        0b101
#define FUNCT3_BLTU       0b110
#define FUNCT3_BGEU       0b111

#define FUNCT3_LB_SB      0b000
#define FUNCT3_LH_SH      0b001
#define FUNCT3_LW_SW      0b010
#define FUNCT3_LBU        0b100
#define FUNCT3_LHU        0b101


/*** RV32 funct7 masks ***/
#define MASK_ALT_FUNCT7   0x3F << OFFSET_FUNCT7

#define FUNCT7_ADD        0x00
#define FUNCT7_SUB        0x20
#define FUNCT7_SRL        0x00
#define FUNCT7_SRA        0x20


/*** RV32 OS OP ***/
#define OS_OP_FLAG        0b1 << OFFSET_OS_OP

#define OS_OP_EBREAK      0b1
#define OS_OP_ECALL       0b0

#define MASK_RS2        0x1F << OFFSET_RS2
#define MASK_RS1        0x1F << OFFSET_RS1
#define MASK_RD         0x1F << OFFSET_RD


typedef enum rv32eBaseInstructionsE
{
    RV32E_BAD_INSTRUCTION = -1,
    RV32E_LUI,
    RV32E_AUIPC,
    RV32E_JAL,
    RV32E_JALR,
    RV32E_BEQ,
    RV32E_BNE,
    RV32E_BLT,
    RV32E_BGE,
    RV32E_BLTU,
    RV32E_BGEU,
    RV32E_LB,
    RV32E_LH,
    RV32E_LW,
    RV32E_LBU,
    RV32E_LHU,
    RV32E_SB,
    RV32E_SH,
    RV32E_SW,
    RV32E_ADDI,
    RV32E_SLTI,
    RV32E_SLTIU,
    RV32E_XORI,
    RV32E_ORI,
    RV32E_ANDI,
    RV32E_SLLI,
    RV32E_SRLI,
    RV32E_SRAI,
    RV32E_ADD,
    RV32E_SUB,
    RV32E_SLL,
    RV32E_SLT,
    RV32E_SLTU,
    RV32E_XOR,
    RV32E_SRL,
    RV32E_SRA,
    RV32E_OR,
    RV32E_AND,
    RV32E_FENCE, //Handled as NOP
    RV32E_ECALL,
    RV32E_EBREAK,
}rv32eBaseInstructions;


typedef enum rv32eInstructionTypesE
{
    RV32E_BAD_TYPE = -1,
    RV32E_R_TYPE,
    RV32E_I_TYPE,
    RV32E_S_TYPE,
    RV32E_B_TYPE,
    RV32E_U_TYPE,
    RV32E_J_TYPE,
    RV32E_MISC_TYPE,
}rv32eInstructionTypes;


/**
 * RV32E types definitions.
 */
typedef struct rTypeS
{
    uint8_t funct7  : 7;
    uint8_t rs2     : 5;
    uint8_t rs1     : 5;
    uint8_t funct3  : 3;
    uint8_t rd      : 5;
    uint8_t opcode  : 7;
}rType;


typedef struct iTypeS
{
    int32_t imm;
    uint8_t rs1     : 5;
    uint8_t funct3  : 3;
    uint8_t rd      : 5;
    uint8_t opcode  : 7;
}iType;


typedef struct sTypeS
{
    int32_t imm;
    uint8_t rs2     : 5;
    uint8_t rs1     : 5;
    uint8_t funct3  : 3;
    uint8_t opcode  : 7;
}sType;


typedef struct bTypeS
{
    int32_t imm;
    uint8_t rs2     : 5;
    uint8_t rs1     : 5;
    uint8_t funct3  : 3;
    uint8_t opcode  : 7;
}bType;


typedef struct uTypeS
{
    uint32_t imm;
    uint8_t rd      : 5;
    uint8_t opcode  : 7;
}uType;


typedef struct jTypeS
{
    int32_t imm;
    uint8_t rd      : 5;
    uint8_t opcode  : 7;
}jType;


#endif //RV32E_H