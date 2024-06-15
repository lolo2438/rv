/**
 * @file decoder.c
 * @author Guyaume Morand
 * @brief: Instruction decoder
 */


#include "decoder.h"
#include "desassembly.h"

instructionSets decodeInstructionLength(uint32_t instruction)
{
    if (((instruction & (MASK_QUADRANT)) == 0b11))
    {
        return RV32E;
    }
    return RVC;
}

int decodeInstructionType(uint32_t instruction)
{
    instructionSets instructionLength = decodeInstructionLength(instruction);

    if (instructionLength == RV32E) {
        switch (instruction & MASK_OPCODE) {
            case RV32E_OP:
                return RV32E_R_TYPE;

            case RV32E_OP_IMM:
                switch ((instruction & MASK_ALT_FUNCT3) >> 12) {
                    case FUNCT3_SLL:
                        return RV32E_I_TYPE;
                    case FUNCT3_SRL_SRA:
                        return RV32E_I_TYPE;
                    default:
                        return RV32E_I_TYPE;
                }

            case RV32E_OP_BRANCH:
                return RV32E_B_TYPE;

            case RV32E_OP_LUI:
                return RV32E_U_TYPE;

            case RV32E_OP_AUIPC:
                return RV32E_U_TYPE;

            case RV32E_OP_JAL:
                return RV32E_J_TYPE;

            case RV32E_OP_JALR:
                return RV32E_I_TYPE;

            case RV32E_OP_LOAD:
                return RV32E_I_TYPE;

            case RV32E_OP_STORE:
                return RV32E_S_TYPE;

            case RV32E_OP_MEM:
                return RV32E_MISC_TYPE;

            case RV32E_OP_OS:
                return RV32E_MISC_TYPE;

            default:
                return RV32E_BAD_TYPE;
        }
    }
    else
    {

        switch (instruction & MASK_QUADRANT) {
            case QUADRANT_0:
                switch((instruction & MASK_C_FUNCT3) >> OFFSET_C_FUNCT3){
                    case OP_C_000:
                        return RV32C_CIW_TYPE;
                    case OP_C_010:
                        return RV32C_CL_TYPE;
                    case OP_C_110:
                        return RV32C_CS_TYPE;
                    default:
                        return RV32C_BAD_TYPE;
                }
            case QUADRANT_1:
                switch((instruction & MASK_C_FUNCT3) >> OFFSET_C_FUNCT3) {
                    case OP_C_000:
                        return RV32C_CI_TYPE;
                    case OP_C_001:
                        return RV32C_CJ_TYPE;
                    case OP_C_010:
                        return RV32C_CI_TYPE;
                    case OP_C_011:
                        return RV32C_CI_TYPE;
                    case OP_C_100:
                        switch ((instruction & MASK_11_10) >> OFFSET_BIT10){
                            case 0b11:
                                return RV32C_CA_TYPE;
                            default:
                                return RV32C_CB_TYPE;
                        }
                    case OP_C_101:
                        return RV32C_CJ_TYPE;
                    case OP_C_110:
                        return RV32C_CB_TYPE;
                    case OP_C_111:
                        return RV32C_CB_TYPE;
                    default:
                        return RV32C_BAD_TYPE;
                }
            case QUADRANT_2:
                switch((instruction & MASK_C_FUNCT3) >> OFFSET_C_FUNCT3) {
                    case OP_C_000:
                        return RV32C_CI_TYPE;
                    case OP_C_010:
                        return RV32C_CI_TYPE;
                    case OP_C_100:
                        return RV32C_CR_TYPE;
                    case OP_C_101:
                        return RV32C_CSS_TYPE;
                    case OP_C_110:
                        return RV32C_CSS_TYPE;
                    case OP_C_111:
                        return RV32C_CSS_TYPE;
                    default:
                        return RV32C_BAD_TYPE;
                }
        }
    }
}

int decodeInstruction(uint32_t instruction) {
    instructionSets instructionLength = decodeInstructionLength(instruction);

    switch (instructionLength)
    {
        case RV32E:
            switch (instruction & MASK_OPCODE) {
                case RV32E_OP:
                    switch ((instruction & MASK_ALT_FUNCT3) >> OFFSET_FUNCT3) {
                        case FUNCT3_ADD_SUB:
                            switch ((instruction & MASK_ALT_FUNCT7)
                                    >> OFFSET_FUNCT7) {
                                case FUNCT7_ADD:
                                    return RV32E_ADD;
                                case FUNCT7_SUB:
                                    return RV32E_SUB;
                            }
                        case FUNCT3_SLL:
                            return RV32E_SLL;
                        case FUNCT3_SLT:
                            return RV32E_SLT;
                        case FUNCT3_SLTU:
                            return RV32E_SLTU;
                        case FUNCT3_XOR:
                            return RV32E_XOR;
                        case FUNCT3_SRL_SRA:
                            switch ((instruction & MASK_ALT_FUNCT7)
                                    >> OFFSET_FUNCT7) {
                                case FUNCT7_SRL:
                                    return RV32E_SRL;
                                case FUNCT7_SRA:
                                    return RV32E_SRA;
                            }
                        case FUNCT3_OR:
                            return RV32E_OR;
                        case FUNCT3_AND:
                            return RV32E_AND;
                        default:
                            return RV32E_BAD_INSTRUCTION;
                    }

                case RV32E_OP_IMM:
                    switch ((instruction & MASK_ALT_FUNCT3) >> OFFSET_FUNCT3) {
                        case FUNCT3_ADD_SUB:
                            return RV32E_ADDI;
                        case FUNCT3_SLL:
                            return RV32E_SLLI;
                        case FUNCT3_SLT:
                            return RV32E_SLTI;
                        case FUNCT3_SLTU:
                            return RV32E_SLTIU;
                        case FUNCT3_XOR:
                            return RV32E_XORI;
                        case FUNCT3_SRL_SRA:
                            switch ((instruction & MASK_ALT_FUNCT7)
                                    >> OFFSET_FUNCT7) {
                                case FUNCT7_SRL:
                                    return RV32E_SRLI;
                                case FUNCT7_SRA:
                                    return RV32E_SRAI;
                            }
                        case FUNCT3_OR:
                            return RV32E_ORI;
                        case FUNCT3_AND:
                            return RV32E_ANDI;
                        default:
                            return RV32E_BAD_INSTRUCTION;
                    }

                case RV32E_OP_BRANCH:
                    switch ((instruction & MASK_ALT_FUNCT3) >> OFFSET_FUNCT3) {
                        case FUNCT3_BEQ:
                            return RV32E_BEQ;
                        case FUNCT3_BNE:
                            return RV32E_BNE;
                        case FUNCT3_BLT:
                            return RV32E_BLT;
                        case FUNCT3_BGE:
                            return RV32E_BGE;
                        case FUNCT3_BLTU:
                            return RV32E_BLTU;
                        case FUNCT3_BGEU:
                            return RV32E_BGEU;
                        default:
                            return RV32E_BAD_INSTRUCTION;
                    }

                case RV32E_OP_LUI:
                    return RV32E_LUI;

                case RV32E_OP_AUIPC:
                    return RV32E_AUIPC;

                case RV32E_OP_JAL:
                    return RV32E_JAL;

                case RV32E_OP_JALR:
                    return RV32E_JALR;

                case RV32E_OP_LOAD:
                    switch ((instruction & MASK_ALT_FUNCT3) >> OFFSET_FUNCT3) {
                        case FUNCT3_LB_SB:
                            return RV32E_LB;
                        case FUNCT3_LH_SH:
                            return RV32E_LH;
                        case FUNCT3_LW_SW:
                            return RV32E_LW;
                        case FUNCT3_LBU:
                            return RV32E_LBU;
                        case FUNCT3_LHU:
                            return RV32E_LHU;
                        default:
                            return RV32E_BAD_INSTRUCTION;
                    }

                case RV32E_OP_STORE:
                    switch ((instruction & MASK_ALT_FUNCT3) >> OFFSET_FUNCT3) {
                        case FUNCT3_LB_SB:
                            return RV32E_SB;
                        case FUNCT3_LH_SH:
                            return RV32E_SH;
                        case FUNCT3_LW_SW:
                            return RV32E_SW;
                        default:
                            return RV32E_BAD_INSTRUCTION;
                    }

                case RV32E_OP_MEM:
                    //Should be for fence, treated as a NOP
                    break;

                case RV32E_OP_OS:
                    switch ((instruction & OS_OP_FLAG) >> OFFSET_OS_OP) {
                        case OS_OP_EBREAK:
                            return RV32E_EBREAK;
                        case OS_OP_ECALL:
                            return RV32E_ECALL;
                    }

                default:
                    return RV32E_BAD_INSTRUCTION;
            }
        case RVC:
            switch (instruction & MASK_QUADRANT) {
                case QUADRANT_0:
                    switch ((instruction & MASK_C_FUNCT3) >> OFFSET_C_FUNCT3) {
                        case OP_C_000:
                            return C_ADDI4SPN;
                        case OP_C_010:
                            return C_LW;
                        case OP_C_100:
                            return C_BAD_INSTRUCTION;
                        case OP_C_101:
                            return C_FSD;
                        case OP_C_110:
                            return C_SW;
                        default:
                            break;
                    }
                    break;
                case QUADRANT_1:
                    switch ((instruction & MASK_C_FUNCT3) >> OFFSET_C_FUNCT3) {
                        case OP_C_000:
                            switch((instruction & (0b11111 << 7) >> 7))
                            {
                                case 0:
                                    return C_NOP;
                                default:
                                    return C_ADDI;
                            }
                        case OP_C_001:
                            return C_JAL;
                        case OP_C_010:
                            return C_LI;
                        case OP_C_011:
                            switch((instruction & (0b11111 << 7) >> 7))
                            {
                                case 2:
                                    return C_ADDI16SP;
                                default:
                                    return C_LUI;
                            }
                        case OP_C_100:
                            switch((instruction & MASK_11_10) >> OFFSET_BIT10)
                            {
                                case 0b00:
                                    return C_SRLI;
                                case 0b01:
                                    return C_SRAI;
                                case 0b10:
                                    return C_ANDI;
                                case 0b11:
                                    switch((instruction & MASK_6_5)
                                    >> OFFSET_BIT5)
                                    {
                                        case 0b00:
                                            return C_SUB;
                                        case 0b01:
                                            return C_XOR;
                                        case 0b10:
                                            return C_OR;
                                        case 0b11:
                                            return C_AND;
                                        default:
                                            break;
                                    }
                                default:
                                    break;
                            }
                        case OP_C_101:
                            return C_J;
                        case OP_C_110:
                            return C_BEQZ;
                        case OP_C_111:
                            return C_BNEZ;
                        default:
                            break;
                    }
                    break;
                case QUADRANT_2:
                    switch ((instruction & MASK_C_FUNCT3) >> OFFSET_C_FUNCT3) {
                        case OP_C_000:
                            return C_SLLI;
                        case OP_C_010:
                            return C_LWSP;
                        case OP_C_100:
                            switch((instruction & MASK_BIT12) >> OFFSET_BIT12)
                            {
                                case 0:
                                    switch((instruction & (0b11111 << 2)) >> 2)
                                    {
                                        case 0:
                                            return C_JR;
                                        default:
                                            return C_MV;
                                    }
                                case 1:
                                    switch((instruction & (0b11111 << 7)) >> 7)
                                    {
                                        case 0:
                                            return C_EBREAK;
                                        default:
                                            switch((instruction &
                                            (0b11111 << 2)) >> 2)
                                            {
                                                case 0:
                                                    return C_JALR;
                                                default:
                                                    return C_ADD;
                                            }
                                    }
                            }
                        case OP_C_110:
                            return C_SWSP;
                        default:
                            break;
                    }
                    break;
            }
        default:
            break;
    }
}

int runInstruction(uint32_t instruction)
{
    instructionSets instructionLength = decodeInstructionLength(
            instruction);
    int instructionType = decodeInstructionType(
            instruction);
    int instructionInt = decodeInstruction(instruction);

    rType *rData = malloc(sizeof(rType));
    iType *iData = malloc(sizeof(iType));
    sType *sData = malloc(sizeof(sType));
    bType *bData = malloc(sizeof(bType));
    uType *uData = malloc(sizeof(uType));
    jType *jData = malloc(sizeof(jType));

    cRType *crData = malloc(sizeof(cRType));
    cIType *ciData = malloc(sizeof(cIType));
    cSSType *cssData = malloc(sizeof(cSSType));
    cIWType *ciwData = malloc(sizeof(cIWType));
    cLType *clData = malloc(sizeof(cLType));
    cSType *csData = malloc(sizeof(cSType));
    cAType *caData = malloc(sizeof(cAType));
    cBType *cbData = malloc(sizeof(cBType));
    cJType *cjData = malloc(sizeof(cJType));

    switch (instructionLength) {
        case RV32E:
            switch (instructionType) {
                case RV32E_R_TYPE:
                    rData->funct7 =
                            (instruction & MASK_ALT_FUNCT7) >> OFFSET_FUNCT7;
                    rData->rs2 = (instruction & MASK_RS2) >> OFFSET_RS2;
                    rData->rs1 = (instruction & MASK_RS1) >> OFFSET_RS1;
                    rData->funct3 =
                            (instruction & MASK_ALT_FUNCT3) >> OFFSET_FUNCT3;
                    rData->rd = (instruction & MASK_RD) >> OFFSET_RD;
                    rData->opcode = (instruction & MASK_OPCODE) >>
                            OFFSET_OPCODE;
                    break;

                case RV32E_I_TYPE:
                    iData->imm = getITypeImmediate(instruction);
                    iData->rs1 = (instruction & MASK_RS1) >> OFFSET_RS1;
                    iData->funct3 =
                            (instruction & MASK_ALT_FUNCT3) >> OFFSET_FUNCT3;
                    iData->rd = (instruction & MASK_RD) >> OFFSET_RD;
                    iData->opcode = (instruction & MASK_OPCODE)
                            >> OFFSET_OPCODE;
                    break;

                case RV32E_S_TYPE:
                    sData->imm = getSTypeImmediate(instruction);
                    sData->rs2 = (instruction & MASK_RS2) >> OFFSET_RS2;
                    sData->rs1 = (instruction & MASK_RS1) >> OFFSET_RS1;
                    sData->funct3 =
                            (instruction & MASK_ALT_FUNCT3) >> OFFSET_FUNCT3;
                    sData->opcode = (instruction & MASK_OPCODE)
                            >> OFFSET_OPCODE;
                    break;

                case RV32E_B_TYPE:
                    bData->imm = getBTypeImmediate(instruction);

                    bData->rs2 = (instruction & MASK_RS2) >> OFFSET_RS2;
                    bData->rs1 = (instruction & MASK_RS1) >> OFFSET_RS1;
                    bData->funct3 =
                            (instruction & MASK_ALT_FUNCT3) >> OFFSET_FUNCT3;
                    bData->opcode = (instruction & MASK_OPCODE)
                            >> OFFSET_OPCODE;
                    break;

                case RV32E_U_TYPE:
                    uData->imm = getUTypeImmediate(instruction);
                    uData->rd = (instruction & MASK_RD) >> OFFSET_RD;
                    uData->opcode = (instruction & MASK_OPCODE)
                            >> OFFSET_OPCODE;
                    break;

                case RV32E_J_TYPE:
                    jData->imm = getJTypeImmediate(instruction);
                    jData->rd = (instruction & MASK_RD) >> OFFSET_RD;
                    jData->opcode = (instruction & MASK_OPCODE)
                            >> OFFSET_OPCODE;
                    break;

                    // case RV32E_MISC_TYPE:
                    // case RV32E_BAD_TYPE:
                default:
                    break;
            }
            break;

        case RVC:
            switch (instructionType)
            {
                case RV32C_CR_TYPE:
                    crData->funct4 = (instruction & MASK_C_FUNCT4)
                            >> OFFSET_C_FUNCT4;
                    crData->rdRs1 = (instruction & MASK_RD_RS1) >> OFFSET_RD_RS1;
                    crData->rs2 = (instruction & MASK_C_RS2) >> OFFSET_C_RS2;
                    crData->opcode = (instruction & MASK_QUADRANT);
                    break;
                case RV32C_CI_TYPE:
                    ciData->funct3 = (instruction & MASK_C_FUNCT3)
                            >> OFFSET_C_FUNCT3;
                    ciData->imm = getCiImmediate(instruction);
                    ciData->rdRs1 = (instruction & MASK_RD_RS1) >> OFFSET_RD_RS1;
                    ciData->opcode = (instruction & MASK_QUADRANT);
                    break;
                case RV32C_CSS_TYPE:
                    cssData->funct3 = (instruction & MASK_C_FUNCT3)
                            >> OFFSET_C_FUNCT3;
                    cssData->imm = getCssImmediate(instruction);
                    cssData->rs2 = (instruction & MASK_C_RS2) >> OFFSET_C_RS2;
                    cssData->opcode = (instruction & MASK_QUADRANT);
                    break;
                case RV32C_CIW_TYPE:
                    ciwData->funct3 = (instruction & MASK_C_FUNCT3)
                            >> OFFSET_C_FUNCT3;
                    ciwData->imm = getCiwImmediate(instruction);
                    ciwData->rdP = (instruction & MASK_C_RDP) >> OFFSET_C_RDP;
                    ciwData->opcode = (instruction & MASK_QUADRANT);
                    break;
                case RV32C_CL_TYPE:
                    clData->funct3 = (instruction & MASK_C_FUNCT3)
                            >> OFFSET_C_FUNCT3;
                    clData->imm = getClImmediate(instruction);
                    clData->rs1P = (instruction & MASK_RD_RS1P)
                            >> OFFSET_RD_RS1;
                    clData->rdP = (instruction & MASK_C_RDP) >> OFFSET_C_RDP;
                    clData->opcode = (instruction & MASK_QUADRANT);
                    break;
                case RV32C_CS_TYPE:
                    csData->funct3 = (instruction & MASK_C_FUNCT3)
                            >> OFFSET_C_FUNCT3;
                    csData->imm = getCsImmediate(instruction);
                    csData->rs1P = (instruction & MASK_RD_RS1P)
                            >> OFFSET_RD_RS1;
                    csData->rs2P = (instruction & MASK_C_RS2P) >> OFFSET_C_RS2;
                    csData->opcode = (instruction & MASK_QUADRANT);
                    break;
                case RV32C_CA_TYPE:
                    caData->funct6 = (instruction & MASK_C_FUNCT6)
                            >> OFFSET_C_FUNCT6;
                    caData->rdPRs1P = (instruction & MASK_RD_RS1P)
                            >> OFFSET_RD_RS1;
                    caData->funct2 = (instruction & MASK_C_FUNCT2)
                            >> OFFSET_C_FUNCT2;
                    caData->rs2P = (instruction & MASK_C_RS2P) >> OFFSET_C_RS2;
                    caData->opcode = (instruction & MASK_QUADRANT);
                    break;
                case RV32C_CB_TYPE:
                    cbData->funct3 = (instruction & MASK_C_FUNCT3)
                            >> OFFSET_C_FUNCT3;
                    cbData->offset = getCbImmediate(instruction);
                    cbData->rs1P = (instruction & MASK_RD_RS1P)
                            >> OFFSET_RD_RS1;
                    cbData->opcode = (instruction & MASK_QUADRANT);
                    break;
                case RV32C_CJ_TYPE:
                    cjData->funct3 = (instruction & MASK_C_FUNCT3)
                            >> OFFSET_C_FUNCT3;
                    cjData->jumptarget = getCjImmediate(instruction);
                    cjData->opcode = (instruction & MASK_QUADRANT);
                    break;
                default:
                    break;
            }
    }

        switch (instructionLength)
        {
            case RV32E:
                switch (instruction & MASK_OPCODE) {
                    case RV32E_OP:
                        switch ((instruction & MASK_ALT_FUNCT3)
                                >> OFFSET_FUNCT3) {
                            case FUNCT3_ADD_SUB:
                                switch ((instruction & MASK_ALT_FUNCT7)
                                        >> OFFSET_FUNCT7) {
                                    case FUNCT7_ADD:
                                        add(rData);
                                        break;
                                    case FUNCT7_SUB:
                                        sub(rData);
                                        break;
                                }
                            case FUNCT3_SLL:
                                shiftLeft(rData);
                                break;
                            case FUNCT3_SLT:
                                setLessThan(rData);
                                break;
                            case FUNCT3_SLTU:
                                setLessThanUnsigned(rData);
                                break;
                            case FUNCT3_XOR:
                                xor(rData);
                                break;
                            case FUNCT3_SRL_SRA:
                                switch ((instruction & MASK_ALT_FUNCT7)
                                        >> OFFSET_FUNCT7) {
                                    case FUNCT7_SRL:
                                        shiftRight(rData);
                                        break;
                                    case FUNCT7_SRA:
                                        shiftRightArithmetic(rData);
                                        break;
                                }
                            case FUNCT3_OR:
                                or(rData);
                                break;
                            case FUNCT3_AND:
                                and(rData);
                                break;
                        }
                        break;

                    case RV32E_OP_IMM:
                        switch ((instruction & MASK_ALT_FUNCT3)
                                >> OFFSET_FUNCT3) {
                            case FUNCT3_ADD_SUB:
                                addImmediate(iData);
                                break;
                            case FUNCT3_SLL:
                                shiftLeftImmediate(iData);
                                break;
                            case FUNCT3_SLT:
                                setLessThanImmediate(iData);
                                break;
                            case FUNCT3_SLTU:
                                setLessThanImmediateUnsigned(iData);
                                break;
                            case FUNCT3_XOR:
                                xorImmediate(iData);
                                break;
                            case FUNCT3_SRL_SRA:
                                switch ((instruction & MASK_ALT_FUNCT7)
                                        >> OFFSET_FUNCT7) {
                                    case FUNCT7_SRL:
                                        shiftRightImmediate(iData);
                                        break;
                                    case FUNCT7_SRA:
                                        shiftRightArithImm(iData);
                                        break;
                                }
                                break;
                            case FUNCT3_OR:
                                orImmediate(iData);
                                break;
                            case FUNCT3_AND:
                                andImmediate(iData);
                                break;
                        }
                        break;

                    case RV32E_OP_BRANCH:
                        switch ((instruction & MASK_ALT_FUNCT3)
                                >> OFFSET_FUNCT3) {
                            case FUNCT3_BEQ:
                                branchEqual(bData);
                                break;
                            case FUNCT3_BNE:
                                branchNotEqual(bData);
                                break;
                            case FUNCT3_BLT:
                                branchLessThan(bData);
                                break;
                            case FUNCT3_BGE:
                                branchMoreOrEqual(bData);
                                break;
                            case FUNCT3_BLTU:
                                branchLessThanUnsigned(bData);
                                break;
                            case FUNCT3_BGEU:
                                branchMoreOrEqualUnsigned(bData);
                                break;
                        }
                        break;

                    case RV32E_OP_LUI:
                        loadUpperImm(uData);
                        break;

                    case RV32E_OP_AUIPC:
                        addUpperImmToPC(uData);
                        break;

                    case RV32E_OP_JAL:
                        jumpAndLink(jData);
                        break;

                    case RV32E_OP_JALR:
                        jumpAndLinkRegister(iData);
                        break;

                    case RV32E_OP_LOAD:
                        switch ((instruction & MASK_ALT_FUNCT3)
                                >> OFFSET_FUNCT3) {
                            case FUNCT3_LB_SB:
                                loadByte(iData);
                                break;
                            case FUNCT3_LH_SH:
                                loadHalfword(iData);
                                break;
                            case FUNCT3_LW_SW:
                                loadWord(iData);
                                break;
                            case FUNCT3_LBU:
                                loadByteUnsigned(iData);
                                break;
                            case FUNCT3_LHU:
                                loadHalfUnsigned(iData);
                                break;
                        }
                        break;

                    case RV32E_OP_STORE:
                        switch ((instruction & MASK_ALT_FUNCT3)
                                >> OFFSET_FUNCT3) {
                            case FUNCT3_LB_SB:
                                storeByte(sData);
                                break;
                            case FUNCT3_LH_SH:
                                storeHalfword(sData);
                                break;
                            case FUNCT3_LW_SW:
                                storeWord(sData);
                                break;
                        }
                        break;

                    case RV32E_OP_OS:
                        switch ((instruction & OS_OP_FLAG) >> OFFSET_OS_OP) {
                            case OS_OP_EBREAK:
                                ebreak();
                                break;

                            case OS_OP_ECALL:
                                ecall();
                                break;
                        }
                        break;

                    default:
                        break;
                }
                break;

            case RVC:
                switch (instructionInt) {
                    case C_ADDI4SPN:
                        cAddi4StackPointer(ciwData);
                        break;
                    case C_LW:
                        cLoadWord(clData);
                        break;
                    case C_FSD:
                        break;
                    case C_SW:
                        cStoreWord(csData);
                        break;
                    case C_NOP:
                        break;
                    case C_ADDI:
                        cAddImmediate(ciData);
                        break;
                    case C_JAL:
                        cJumpAndLink(cjData);
                        break;
                    case C_LI:
                        cLoadImmediate(ciData);
                        break;
                    case C_ADDI16SP:
                        cAddi16StackPointer(ciData);
                        break;
                    case C_LUI:
                        cLoadUpperImmediate(ciData);
                        break;
                    case C_SRLI:
                        cShiftRightLogicalImmediate(cbData);
                        break;
                    case C_SRAI:
                        cShiftRightArithmeticImmediate(cbData);
                        break;
                    case C_ANDI:
                        cAndImmediate(cbData);
                        break;
                    case C_SUB:
                        cSub(caData);
                        break;
                    case C_XOR:
                        cXor(caData);
                        break;
                    case C_OR:
                        cOr(caData);
                        break;
                    case C_AND:
                        cAnd(caData);
                        break;
                    case C_J:
                        cJump(cjData);
                        break;
                    case C_BEQZ:
                        cBranchOnEqualZero(cbData);
                        break;
                    case C_BNEZ:
                        cBranchNotEqualZero(cbData);
                        break;
                    case C_SLLI:
                        cShiftLeftLogicalImmediate(ciData);
                        break;
                    case C_LWSP:
                        cLoadWordStackPointer(ciData);
                        break;
                    case C_JR:
                        cJumpRegister(crData);
                        break;
                    case C_MV:
                        cMove(crData);
                        break;
                    case C_EBREAK:
                        ebreak();
                        break;
                    case C_JALR:
                        cJumpAndLinkRegister(crData);
                        break;
                    case C_ADD:
                        cAdd(crData);
                        break;
                    case C_SWSP:
                        cStoreWordStackPointer(cssData);
                        break;
                    default:
                        break;
                }
                    default:
                        break;
        }

    free(rData);
    free(iData);
    free(sData);
    free(bData);
    free(uData);
    free(jData);

    free(crData);
    free(ciData);
    free(cssData);
    free(ciwData);
    free(clData);
    free(csData);
    free(caData);
    free(cbData);
    free(cjData);

    return 0;
}
