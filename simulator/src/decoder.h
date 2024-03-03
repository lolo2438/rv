#ifndef DECODER_H
#define DECODER_H

#include "common.h"

// R & I -> OPTYPE = ALU, OPALU = OP, OPARG = ARG, IMM = MUX IMM, RV32 -> OPLEN = WORD
// J -> NONE
// B -> BEQ -> SUB + ZERO CHECK, BLT -> SLT + 1 CHECK, BGE -> SLT + 0 check, BLTU = ARG=UNSIGNED + SLT
// AUIPC -> ADD + MUX PC
// STORE -> ADD + STORE FLAG + OPLEN
// LOAD -> ADD + LOAD FLAG + OPLEN
// SYSTEM -> NONE
// MISC_MEM
// LUI -> OPTYPE, already ready

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


struct dec_inst {
        uint8_t opcode, rd, rs1, rs2, funct7, funct3;
        int32_t immediate;
};

#endif
