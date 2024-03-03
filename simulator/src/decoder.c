#include "RV32I.h"
#include "decoder.h"
#include "common.h"

uint32_t decompress();

struct dec_inst decode(uint32_t instruction) {

        struct dec_inst di = {0};

        char format;

        // Q decode
        // OP decode
        // Register decode
        // Sign immdiate

        if((instruction & MASK_Q) != OP_C3)
                instruction = decompress();

        di.opcode = (instruction >> OFFSET_OP) & MASK_OP;

        switch(di.opcode) {
                case OP_OP:
                        format = 'R';
                        break;

                case OP_MISC_MEM:
                case OP_SYSTEM:
                case OP_IMM:
                case OP_JALR:
                case OP_LOAD:
                        format = 'I';
                        break;

                case OP_STORE:
                        format = 'S';
                        break;

                case OP_BRANCH:
                        format = 'B';
                        break;

                case OP_LUI:
                case OP_AUIPC:
                        format = 'U';
                        break;

                case OP_JAL:
                        format = 'J';
                        break;

                // Add extensions here
                default:
                        format = 0;
        }

        //MAIN DECODER
        di.rd = (instruction >> OFFSET_RD) & MASK_REG;
        switch(format) {
                case 'R':
                        di.rs1 = (instruction >> OFFSET_RS1) & MASK_REG;
                        di.rs2 = (instruction >> OFFSET_RS2) & MASK_REG;
                        di.funct7 = (instruction >> OFFSET_FUNCT7) & MASK_FUNCT7;
                        di.funct3 = (instruction >> OFFSET_FUNCT3) & MASK_FUNCT3;
                        break;
                case 'I':
                        di.rs1 = (instruction >> OFFSET_RS1) & MASK_REG;
                        di.funct3 = (instruction >> OFFSET_FUNCT3) & MASK_FUNCT3;
                        di.immediate = (instruction >> OFFSET_I_IMM);
                        break;
                case 'S':
                        di.rs1 = (instruction >> OFFSET_RS1) & MASK_REG;
                        di.rs2 = (instruction >> OFFSET_RS2) & MASK_REG;
                        //IMM
                        break;
                case 'B':
                        di.rs1 = (instruction >> OFFSET_RS1) & MASK_REG;
                        di.rs2 = (instruction >> OFFSET_RS2) & MASK_REG;
                        di.funct3 = (instruction >> OFFSET_FUNCT3) & MASK_FUNCT3;
                        di.immediate = (instruction >> 24) | (instruction >> 7 & 0x1 << 11) | (instruction >> 25 & 0x3F << 5) | (instruction >> 8 & 0xF << 1);
                        break;
                case 'U':
                        di.immediate = instruction & MASK_IMM_U;
                        break;
                case 'J':
                        //FIXME
                        di.immediate = (instruction >> 11) | (instruction & 0x000FF000) | (instruction & 0x00100000) & (instruction & 0x0FE00000);
                        break;
        }

        return di;
}


