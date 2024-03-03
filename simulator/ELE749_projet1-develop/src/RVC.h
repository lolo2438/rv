/**
 * File: RVC.h
 * Date : 2021-05
 * Description: Definitions and types used for "C" extension instructions
 *              decoding and handling.
 */

#ifndef RVC_H
#define RVC_H


#include <RV32E.h>


/*** RV32C masks ***/
#define MASK_QUADRANT   0b11
#define MASK_C_FUNCT2   0b11    << OFFSET_C_FUNCT2
#define MASK_C_FUNCT3   0b111   << OFFSET_C_FUNCT3
#define MASK_C_FUNCT4   0x0F    << OFFSET_C_FUNCT4
#define MASK_C_FUNCT6   0x3F    << OFFSET_C_FUNCT6
#define MASK_RD_RS1     0b11111 << OFFSET_RD_RS1
#define MASK_C_RS2      0b11111 << OFFSET_C_RS2
#define MASK_RD_RS1P    0b11111 << OFFSET_RD_RS1
#define MASK_C_RS2P     0b11111 << OFFSET_C_RS2
#define MASK_C_RDP      MASK_C_RS2P

#define OFFSET_C_FUNCT2 5
#define OFFSET_C_FUNCT3 13
#define OFFSET_C_FUNCT4 12
#define OFFSET_C_FUNCT6 10
#define OFFSET_RD_RS1   7
#define OFFSET_C_RS2    2
#define OFFSET_C_RDP    2

#define MASK_BIT12  0b1     << OFFSET_BIT12
#define MASK_11_10  0b11    << OFFSET_BIT10
#define MASK_6_5    0b11    << OFFSET_BIT5

#define OFFSET_BIT12    12
#define OFFSET_BIT10    10
#define OFFSET_BIT5     5

#define OP_C_000    0b000
#define OP_C_001    0b001
#define OP_C_010    0b010
#define OP_C_011    0b011
#define OP_C_100    0b100
#define OP_C_101    0b101
#define OP_C_110    0b110
#define OP_C_111    0b111


typedef enum cInstructionsE
{
    C_BAD_INSTRUCTION = 200,
    C_ADDI4SPN,
    C_LW,
    C_FSD,
    C_SW,
    C_NOP,
    C_ADDI,
    C_JAL,
    C_LI,
    C_ADDI16SP,
    C_LUI,
    C_SRLI,
    C_SRLI64,
    C_SRAI,
    C_SRAI64,
    C_ANDI,
    C_SUB,
    C_XOR,
    C_OR,
    C_AND,
    C_J,
    C_BEQZ,
    C_BNEZ,
    C_SLLI,
    C_SLLI64,
    C_LWSP,
    C_JR,
    C_MV,
    C_EBREAK,
    C_JALR,
    C_ADD,
    C_SWSP,
}cInstructions;


typedef enum rv32cInstructionTypesE
{
    RV32C_BAD_TYPE = -1,
    RV32C_CR_TYPE,
    RV32C_CI_TYPE,
    RV32C_CSS_TYPE,
    RV32C_CIW_TYPE,
    RV32C_CL_TYPE,
    RV32C_CS_TYPE,
    RV32C_CA_TYPE,
    RV32C_CB_TYPE,
    RV32C_CJ_TYPE
}rv32cInstructionTypes;


typedef enum cQuadrantsE
{
    QUADRANT_0,
    QUADRANT_1,
    QUADRANT_2,
}cQuadrants;


/**
 * RVC types definitions.
 */
typedef struct cRTypeS
{
    uint8_t funct4 : 4;
    uint8_t rdRs1 : 5;
    uint8_t rs2 : 5;
    uint8_t opcode : 2;
}cRType;


typedef struct cITypeS
{
    int32_t imm;
    uint8_t funct3 : 3;
    uint8_t rdRs1 : 5;
    uint8_t opcode : 2;
}cIType;


typedef struct cSSTypeS
{
    int32_t imm;
    uint8_t funct3 : 3;
    uint8_t rs2 : 5;
    uint8_t opcode : 2;
}cSSType;


typedef struct cIWTypeS
{
    int32_t imm;
    uint8_t funct3 : 3;
    uint8_t rdP : 3;
    uint8_t opcode : 2;
}cIWType;


typedef struct cLTypeS
{
    int32_t imm;
    uint8_t funct3 : 3;
    uint8_t rs1P : 3;
    uint8_t rdP : 3;
    uint8_t opcode : 2;
}cLType;


typedef struct cSTypeS
{
    int32_t imm;
    uint8_t funct3 : 3;
    uint8_t rs1P : 3;
    uint8_t rs2P : 3;
    uint8_t opcode : 2;
}cSType;


typedef struct cATypeS
{
    uint8_t funct6 : 6;
    uint8_t rdPRs1P : 3;
    uint8_t funct2 : 2;
    uint8_t rs2P : 3;
    uint8_t opcode : 2;
}cAType;


typedef struct cBTypeS
{
    int32_t offset;
    uint8_t funct3 : 3;
    uint8_t rs1P : 3;
    uint8_t opcode : 2;
}cBType;


typedef struct cJTypeS
{
    int32_t jumptarget;
    uint8_t funct3 : 3;
    uint8_t opcode : 2;
}cJType;

#endif //RVC_H
