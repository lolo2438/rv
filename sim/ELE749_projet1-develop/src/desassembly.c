/**
 * @file desassembly.h
 * @author Louis Levesque
 * @date 2021-05-23
 * @brief Contains functions required for generating the disassembly strings
 *        from the instructions value.
 */


/* Includes ------------------------------------------------------------------*/
#include <desassembly.h>


/* Public functions  ---------------------------------------------------------*/
char** buildInstTxtTab(uint32_t *instTab, int instNb)
{
    //Allocate matrix of instructions (text)
    char** instTxtTab = (char**)malloc(instNb * sizeof(char*));

    //Allocate each instruction's string
    for(int i = 0; i < instNb; i++){

        instTxtTab[i] = buildInstString(instTab[i]);

        procUpdatePC(4);

        printf("%s\n", instTxtTab[i]);
    }

    return instTxtTab;
}


char* buildInstString(uint32_t instruction)
{
    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    //Check if the instruction is a standard RV32E instruction or
    // one with the C extension
    instructionSets ext = decodeInstructionLength(instruction);

    switch (ext) {

        case RV32E:
            buildInstStringRV32E(instTxt, instruction);
            break;

        case RVC:
            buildInstStringRV32EC(instTxt, instruction);
            break;

        default:
            strcpy(instTxt, "BAD INSTRUCTION");
            break;
    }

    return instTxt;

}


void buildInstStringRV32E(char *instTxt, uint32_t instruction)
{

    if(instTxt != NULL){

        rv32eInstructionTypes type = decodeInstructionType(instruction);

        switch (type) {

            case RV32E_R_TYPE:
                buildInstStringRv32eRtype(instTxt, instruction);
                break;

            case RV32E_I_TYPE:
                buildInstStringRv32eItype(instTxt, instruction);
                break;

            case RV32E_S_TYPE:
                buildInstStringRv32eStype(instTxt, instruction);
                break;

            case RV32E_B_TYPE:
                buildInstStringRv32eBtype(instTxt, instruction);
                break;

            case RV32E_U_TYPE:
                buildInstStringRv32eUtype(instTxt, instruction);
                break;

            case RV32E_J_TYPE:
                buildInstStringRv32eJtype(instTxt, instruction);
                break;

            case RV32E_MISC_TYPE:
                buildInstStringRv32eMisctype(instTxt, instruction);
                break;

            default:
                strcpy(instTxt, "BAD INSTRUCTION");
                break;
        }
    }
}


void buildInstStringRV32EC(char *instTxt, uint32_t instruction)
{

    if(instTxt != NULL) {

        rv32cInstructionTypes instType = decodeInstructionType(instruction);

        switch (instType) {

            case RV32C_CR_TYPE:
                buildInstStringRv32eCrType(instTxt, instruction);
                break;

            case RV32C_CI_TYPE:
                buildInstStringRv32eCiType(instTxt, instruction);
                break;

            case RV32C_CSS_TYPE:
                buildInstStringRv32eCssType(instTxt, instruction);
                break;

            case RV32C_CIW_TYPE:
                buildInstStringRv32eCiwType(instTxt, instruction);
                break;

            case RV32C_CL_TYPE:
                buildInstStringRv32eClType(instTxt, instruction);
                break;

            case RV32C_CS_TYPE:
                buildInstStringRv32eCsType(instTxt, instruction);
                break;

            case RV32C_CA_TYPE:
                buildInstStringRv32eCaType(instTxt, instruction);
                break;

            case RV32C_CB_TYPE:
                buildInstStringRv32eCbType(instTxt, instruction);
                break;

            case RV32C_CJ_TYPE:
                buildInstStringRv32eCjType(instTxt, instruction);
                break;

            default:
                strcpy(instTxt, "BAD INSTRUCTION");
                break;
        }
    }
}


void buildInstStringRv32eRtype(char* instTxt, uint32_t instruction)
{

    if(instTxt != NULL) {

        rv32eBaseInstructions instName;

        int txtOffset = 0;
        uint32_t reg;

        instName = decodeInstruction(instruction);

        //Write instruction name
        switch (instName) {
            case RV32E_ADD:
                strcpy(instTxt, "ADD");
                txtOffset += 3;
                break;

            case RV32E_SUB:
                strcpy(instTxt, "SUB");
                txtOffset += 3;
                break;

            case RV32E_SLL:
                strcpy(instTxt, "SLL");
                txtOffset += 3;
                break;

            case RV32E_SLT:
                strcpy(instTxt, "SLT");
                txtOffset += 3;
                break;

            case RV32E_SLTU:
                strcpy(instTxt, "SLTU");
                txtOffset += 4;
                break;

            case RV32E_XOR:
                strcpy(instTxt, "XOR");
                txtOffset += 3;
                break;

            case RV32E_SRL:
                strcpy(instTxt, "SRL");
                txtOffset += 3;
                break;

            case RV32E_SRA:
                strcpy(instTxt, "SRA");
                txtOffset += 3;
                break;

            case RV32E_OR:
                strcpy(instTxt, "OR");
                txtOffset += 2;
                break;

            case RV32E_AND:
                strcpy(instTxt, "AND");
                txtOffset += 3;
                break;

            default:
                strcpy(instTxt, "BAD INSTRUCTION");
                return;
        }

        //Write destination register
        strcpy((instTxt + txtOffset), " x");
        txtOffset += 2;

        reg = (instruction & MASK_RD) >> OFFSET_RD;

        txtOffset += longToDec((int32_t)reg,
                               (instTxt + txtOffset), 0);


        //Write first source register
        strcpy((instTxt + txtOffset), " x");
        txtOffset += 2;

        reg = (instruction & MASK_RS1) >> OFFSET_RS1;

        txtOffset += longToDec((int32_t)reg,
                               (instTxt + txtOffset), 0);


        //Write second source register
        strcpy((instTxt + txtOffset), " x");
        txtOffset += 2;

        reg = (instruction & MASK_RS2) >> OFFSET_RS2;

        txtOffset += longToDec((int32_t)reg,
                               (instTxt + txtOffset), 0);
    }
}


void buildInstStringRv32eItype(char* instTxt, uint32_t instruction)
{

    if(instTxt != NULL) {

        rv32eBaseInstructions instName;

        int txtOffset = 0;
        uint32_t regOrImm;

        instName = decodeInstruction(instruction);

        //Write instruction name
        switch (instName) {

            case RV32E_JALR:
                strcpy(instTxt, "JALR");
                txtOffset += 4;
                break;

            case RV32E_LB:
                strcpy(instTxt, "LB");
                txtOffset += 2;
                break;

            case RV32E_LH:
                strcpy(instTxt, "LH");
                txtOffset += 2;
                break;

            case RV32E_LW:
                strcpy(instTxt, "LW");
                txtOffset += 2;
                break;

            case RV32E_LBU:
                strcpy(instTxt, "LBU");
                txtOffset += 3;
                break;

            case RV32E_LHU:
                strcpy(instTxt, "LHU");
                txtOffset += 3;
                break;

            case RV32E_ADDI:
                strcpy(instTxt, "ADDI");
                txtOffset += 4;
                break;

            case RV32E_SLTI:
                strcpy(instTxt, "SLTI");
                txtOffset += 4;
                break;

            case RV32E_SLTIU:
                strcpy(instTxt, "SLTIU");
                txtOffset += 5;
                break;

            case RV32E_XORI:
                strcpy(instTxt, "XORI");
                txtOffset += 4;
                break;

            case RV32E_ORI:
                strcpy(instTxt, "ORI");
                txtOffset += 3;
                break;

            case RV32E_ANDI:
                strcpy(instTxt, "ANDI");
                txtOffset += 4;
                break;

            case RV32E_SLLI:
                strcpy(instTxt, "SLLI");
                txtOffset += 4;
                break;

            case RV32E_SRLI:
                strcpy(instTxt, "SRLI");
                txtOffset += 4;
                break;

            case RV32E_SRAI:
                strcpy(instTxt, "SRAI");
                txtOffset += 4;
                break;

            default:
                strcpy(instTxt, "BAD INSTRUCTION");
                return;
        }

        //Write destination register
        strcpy((instTxt + txtOffset), " x");
        txtOffset += 2;

        regOrImm = (instruction & MASK_RD) >> OFFSET_RD;

        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 0);


        //Write first source register
        strcpy((instTxt + txtOffset), " x");
        txtOffset += 2;

        regOrImm = (instruction & MASK_RS1) >> OFFSET_RS1;

        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 0);


        //Write Immediate value
        instTxt[txtOffset++] = ' ';

        regOrImm = getITypeImmediate(instruction);

        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 0);


    }

}


void buildInstStringRv32eStype(char* instTxt, uint32_t instruction)
{

    if(instTxt != NULL) {

        rv32eBaseInstructions instName;

        int txtOffset = 0;
        uint32_t regOrImm;

        instName = decodeInstruction(instruction);

        //Write instruction name
        switch (instName) {

            case RV32E_SB:
                strcpy(instTxt, "SB");
                txtOffset += 2;
                break;

            case RV32E_SH:
                strcpy(instTxt, "SH");
                txtOffset += 2;
                break;

            case RV32E_SW:
                strcpy(instTxt, "SW");
                txtOffset += 2;
                break;

            default:
                strcpy(instTxt, "BAD INSTRUCTION");
                return;
        }


        //Write source register (rs2)
        strcpy((instTxt + txtOffset), " x");
        txtOffset += 2;

        regOrImm = (instruction & MASK_RS2) >> OFFSET_RS2;

        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 0);

        //Write address offset (immediate value (Address)
        strcpy((instTxt + txtOffset), " 0x");
        txtOffset +=3;

        regOrImm = getSTypeImmediate(instruction);

        txtOffset += hexStr(regOrImm, instTxt + txtOffset);


        //Write base register (rs1)
        strcpy((instTxt + txtOffset), "(x");
        txtOffset += 2;

        regOrImm = (instruction & MASK_RS1) >> OFFSET_RS1;

        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 0);

        instTxt[txtOffset++] = ')';
        instTxt[txtOffset++] = '\0';

    }

}


void buildInstStringRv32eBtype(char* instTxt, uint32_t instruction)
{

    if(instTxt != NULL) {

        rv32eBaseInstructions instName;

        int txtOffset = 0;
        uint32_t regOrImm;

        instName = decodeInstruction(instruction);

        //Write instruction name
        switch (instName) {

            case RV32E_BEQ:
                strcpy(instTxt, "BEQ");
                txtOffset += 3;
                break;

            case RV32E_BNE:
                strcpy(instTxt, "BNE");
                txtOffset += 3;
                break;

            case RV32E_BLT:
                strcpy(instTxt, "BLT");
                txtOffset += 3;
                break;

            case RV32E_BGE:
                strcpy(instTxt, "BGE");
                txtOffset += 3;
                break;

            case RV32E_BLTU:
                strcpy(instTxt, "BLTU");
                txtOffset += 4;
                break;

            case RV32E_BGEU:
                strcpy(instTxt, "BGEU");
                txtOffset += 4;
                break;

            default:
                strcpy(instTxt, "BAD INSTRUCTION");
                return;
        }

        //Write first source register (rs1)
        strcpy((instTxt + txtOffset), " x");
        txtOffset += 2;

        regOrImm = (instruction & MASK_RS1) >> OFFSET_RS1;

        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 0);


        //Write second source register (rs2)
        strcpy((instTxt + txtOffset), " x");
        txtOffset += 2;

        regOrImm = (instruction & MASK_RS2) >> OFFSET_RS2;

        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 0);


        //Write address offset (immediate value (Address)
        instTxt[txtOffset++] = ' ';

        regOrImm = getBTypeImmediate(instruction);

        txtOffset += longToDec((int32_t)regOrImm,
                               instTxt + txtOffset, 0);
    }
}


void buildInstStringRv32eUtype(char* instTxt, uint32_t instruction)
{

    if(instTxt != NULL) {

        rv32eBaseInstructions instName;

        int txtOffset = 0;
        uint32_t regOrImm;

        instName = decodeInstruction(instruction);

        //Write instruction name
        switch (instName) {

            case RV32E_LUI:
                strcpy(instTxt, "LUI");
                txtOffset += 3;
                break;

            case RV32E_AUIPC:
                strcpy(instTxt, "AUIPC");
                txtOffset += 5;
                break;

            default:
                strcpy(instTxt, "BAD INSTRUCTION");
                return;
        }

        //Write destination register
        strcpy((instTxt + txtOffset), " x");
        txtOffset += 2;

        regOrImm = (instruction & MASK_RD) >> OFFSET_RD;

        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 0);


        //Write Immediate value
        strcpy((instTxt + txtOffset), " 0x");
        txtOffset += 3;

        regOrImm = getUTypeImmediate(instruction);

        regOrImm = regOrImm >> 12;

        hexStr(regOrImm, instTxt + txtOffset);


    }

}


void buildInstStringRv32eJtype(char* instTxt, uint32_t instruction)
{

    if(instTxt != NULL) {

        rv32eBaseInstructions instName;

        int txtOffset = 0;
        uint32_t regOrImm;

        instName = decodeInstruction(instruction);

        //Write instruction name
        switch (instName) {

            case RV32E_JAL:
                strcpy(instTxt, "JAL");
                txtOffset += 3;
                break;

            default:
                strcpy(instTxt, "BAD INSTRUCTION");
                return;
        }

        //Write destination register (rd)
        strcpy((instTxt + txtOffset), " x");
        txtOffset += 2;

        regOrImm = (instruction & MASK_RD) >> OFFSET_RD;

        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 0);


        //Write address offset (immediate value)
        strcpy((instTxt + txtOffset), " 0x");
        txtOffset += 3;


        regOrImm = getJTypeImmediate(instruction);

        regOrImm += procGetPC();

        hexStr(regOrImm, instTxt + txtOffset);
    }
}


void buildInstStringRv32eMisctype(char* instTxt, uint32_t instruction)
{

    if(instTxt != NULL) {

        rv32eBaseInstructions instName;

        int txtOffset = 0;
        uint32_t regOrImm;

        instName = decodeInstruction(instruction);

        //Write instruction name
        switch (instName) {

            case RV32E_FENCE:
                strcpy(instTxt, "FENCE");
                break;

            case RV32E_ECALL:
                strcpy(instTxt, "ECALL");
                break;

            case RV32E_EBREAK:
                strcpy(instTxt, "EBREAK");
                break;

            default:
                strcpy(instTxt, "BAD INSTRUCTION");
                return;
        }
    }
}


void buildInstStringRv32eCrType(char* instTxt, uint32_t instruction)
{

    if(instTxt != NULL) {

        cInstructions instName;

        int txtOffset = 0;
        uint32_t regOrImm;
        uint8_t hasRs1 = 1;
        uint8_t hasRs2 = 1;


        instName = decodeInstruction(instruction);

        //Write instruction name
        switch (instName) {

            case C_MV:
                strcpy(instTxt, "C.MV");
                txtOffset += 4;
                break;

            case C_ADD:
                strcpy(instTxt, "C.ADD");
                txtOffset += 5;
                break;

            case C_SUB:
                strcpy(instTxt, "C.SUB");
                txtOffset += 5;
                break;

            case C_XOR:
                strcpy(instTxt, "C.XOR");
                txtOffset += 5;
                break;

            case C_OR:
                strcpy(instTxt, "C.OR");
                txtOffset += 4;
                break;

            case C_AND:
                strcpy(instTxt, "C.AND");
                txtOffset += 5;
                break;

            case C_JR:
                strcpy(instTxt, "C.JR");
                txtOffset += 4;
                hasRs2 = 0;
                break;

            case C_JALR:
                strcpy(instTxt, "C.JALR");
                txtOffset += 6;
                hasRs2 = 0;
                break;

            case C_EBREAK:
                strcpy(instTxt, "C.EBREAK");
                txtOffset += 8;
                hasRs1 = 0;
                hasRs2 = 0;
                break;

            default:
                strcpy(instTxt, "BAD INSTRUCTION");
                return;
        }
        if(hasRs1){
            //Write destination register or source register
            strcpy((instTxt + txtOffset), " x");
            txtOffset += 2;

            regOrImm = (instruction & MASK_CR_RD) >> OFFSET_CR_RD;

            txtOffset += longToDec((int32_t)regOrImm,
                                   (instTxt + txtOffset), 1);
        }

        if(hasRs2){
            //Write rs2
            strcpy((instTxt + txtOffset), " x");
            txtOffset += 2;

            regOrImm = (instruction & MASK_CR_RS2) >> OFFSET_CR_RS2;

            txtOffset += longToDec((int32_t)regOrImm,
                                   (instTxt + txtOffset), 1);
        }

    }
}


void buildInstStringRv32eCiType(char* instTxt, uint32_t instruction)
{

    if(instTxt != NULL) {

        cInstructions instName;

        int txtOffset = 0;
        uint32_t regOrImm;
        uint8_t signImmediate = 0;

        instName = decodeInstruction(instruction);

        //Write instruction name
        switch (instName) {

            case C_SLLI:
                strcpy(instTxt, "C.SLLI");
                txtOffset += 6;
                signImmediate = 1;
                break;

            case C_NOP:
                strcpy(instTxt, "C.NOP");
                txtOffset += 5;
                break;

            case C_ADDI:
                strcpy(instTxt, "C.ADDI");
                txtOffset += 6;
                break;

            case C_LI:
                strcpy(instTxt, "C.LI");
                txtOffset += 4;
                break;

            case C_LWSP:
                strcpy(instTxt, "C.LWSP");
                txtOffset += 6;
                signImmediate = 1;
                break;

            case C_ADDI16SP:
                strcpy(instTxt, "C.ADDI16SP");
                txtOffset += 10;
                break;

            default:
                strcpy(instTxt, "BAD INSTRUCTION");
                return;
        }

        //Write destination register or source register
        strcpy((instTxt + txtOffset), " x");
        txtOffset += 2;

        regOrImm = (instruction & MASK_CI_RD) >> OFFSET_CI_RD;

        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 1);


        //Write Immediate value
        strcpy((instTxt + txtOffset), " ");
        txtOffset ++;

        regOrImm = getCiImmediate(instruction);

        txtOffset += longToDec((int32_t)regOrImm,
                               instTxt + txtOffset, signImmediate);
    }
}


void buildInstStringRv32eCssType(char* instTxt, uint32_t instruction)
{

    if(instTxt != NULL) {

        cInstructions instName;

        int txtOffset = 0;
        uint32_t regOrImm;

        instName = decodeInstruction(instruction);

        //Write instruction name
        switch (instName) {

            case C_SWSP:
                strcpy(instTxt, "C.SWSP");
                txtOffset += 6;
                break;

            default:
                strcpy(instTxt, "BAD INSTRUCTION");
                return;
        }

        //Write rs2
        strcpy((instTxt + txtOffset), " x");
        txtOffset += 2;

        regOrImm = (instruction & MASK_CSS_RS2) >> OFFSET_CSS_RS2;

        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 1);


        //Write Immediate value
        strcpy((instTxt + txtOffset), " 0x");
        txtOffset += 3;

        regOrImm = getCssImmediate(instruction);

        txtOffset += hexStr(regOrImm, instTxt + txtOffset);

        strcpy((instTxt + txtOffset), "(x2)");
    }
}


void buildInstStringRv32eCiwType(char* instTxt, uint32_t instruction)
{

    if(instTxt != NULL) {

        cInstructions instName;

        int txtOffset = 0;
        uint32_t regOrImm;

        instName = decodeInstruction(instruction);

        //Write instruction name
        switch (instName) {

            case C_ADDI4SPN:
                strcpy(instTxt, "C.ADDI4SPN");
                txtOffset += 10;
                break;

            default:
                strcpy(instTxt, "BAD INSTRUCTION");
                return;
        }

        //Write rd
        strcpy((instTxt + txtOffset), " x");
        txtOffset += 2;

        regOrImm = (instruction & MASK_CIW_RD) >> OFFSET_CIW_RD;
        regOrImm = RP_SHIFT(regOrImm);

        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 1);

        strcpy((instTxt + txtOffset), " x2");
        txtOffset += 3;

        //Write Immediate value
        strcpy((instTxt + txtOffset), " 0x");
        txtOffset += 3;

        regOrImm = getCiwImmediate(instruction);

        txtOffset += hexStr(regOrImm, instTxt + txtOffset);
    }
}


void buildInstStringRv32eClType(char* instTxt, uint32_t instruction)
{

    if(instTxt != NULL) {

        cInstructions instName;

        int txtOffset = 0;
        uint32_t regOrImm;

        instName = decodeInstruction(instruction);

        //Write instruction name
        switch (instName) {

            case C_LW:
                strcpy(instTxt, "C.LW");
                txtOffset += 4;
                break;

            default:
                strcpy(instTxt, "BAD INSTRUCTION");
                return;
        }

        //Write rd
        strcpy((instTxt + txtOffset), " x");
        txtOffset += 2;

        regOrImm = (instruction & MASK_CL_RD) >> OFFSET_CL_RD;
        regOrImm = RP_SHIFT(regOrImm);

        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 1);

        //Write Immediate value
        strcpy((instTxt + txtOffset), " 0x");
        txtOffset += 3;
        regOrImm = getClImmediate(instruction);

        txtOffset += hexStr(regOrImm, instTxt + txtOffset);

        //Write rs1
        strcpy((instTxt + txtOffset), "(x");
        txtOffset += 2;

        regOrImm = (instruction & MASK_CL_RS1) >> OFFSET_CL_RS1;
        regOrImm = RP_SHIFT(regOrImm);

        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 1);

        instTxt[txtOffset++] = ')';
        instTxt[txtOffset++] = '\0';
    }
}


void buildInstStringRv32eCsType(char* instTxt, uint32_t instruction)
{

    if(instTxt != NULL) {

        cInstructions instName;

        int txtOffset = 0;
        uint32_t regOrImm;

        instName = decodeInstruction(instruction);

        //Write instruction name
        switch (instName) {

            case C_SW:
                strcpy(instTxt, "C.SW");
                txtOffset += 4;
                break;

            default:
                strcpy(instTxt, "BAD INSTRUCTION");
                return;
        }

        //Write rs2
        strcpy((instTxt + txtOffset), " x");
        txtOffset += 2;

        regOrImm = (instruction & MASK_CS_RS2) >> OFFSET_CS_RS2;
        regOrImm = RP_SHIFT(regOrImm);

        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 1);


        //Write Immediate value
        strcpy((instTxt + txtOffset), " 0x");
        txtOffset += 3;

        regOrImm = getCsImmediate(instruction);

        txtOffset += hexStr(regOrImm, instTxt + txtOffset);

        //Write rs1
        strcpy((instTxt + txtOffset), "(x");
        txtOffset += 2;

        regOrImm = (instruction & MASK_CS_RS1) >> OFFSET_CS_RS1;
        regOrImm = RP_SHIFT(regOrImm);

        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 1);

        instTxt[txtOffset++] = ')';
        instTxt[txtOffset++] = '\0';
    }
}


void buildInstStringRv32eCaType(char* instTxt, uint32_t instruction)
{

    if(instTxt != NULL) {

        cInstructions instName;

        int txtOffset = 0;
        uint32_t regOrImm;

        instName = decodeInstruction(instruction);

        //Write instruction name
        switch (instName) {

            case C_AND:
                strcpy(instTxt, "C.AND");
                txtOffset += 5;
                break;

            case C_OR:
                strcpy(instTxt, "C.OR");
                txtOffset += 4;
                break;

            case C_XOR:
                strcpy(instTxt, "C.XOR");
                txtOffset += 5;
                break;

            case C_SUB:
                strcpy(instTxt, "C.SUB");
                txtOffset += 5;
                break;

            default:
                strcpy(instTxt, "BAD INSTRUCTION");
                return;
        }

        //Write rd ou rs1
        strcpy((instTxt + txtOffset), " x");
        txtOffset += 2;

        regOrImm = (instruction & MASK_CA_RD) >> OFFSET_CA_RD;
        regOrImm = RP_SHIFT(regOrImm);

        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 1);


        //Write rs1
        strcpy((instTxt + txtOffset), " x");
        txtOffset += 2;

        regOrImm = (instruction & MASK_CA_RS2) >> OFFSET_CA_RS2;
        regOrImm = RP_SHIFT(regOrImm);

        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 1);
    }
}


void buildInstStringRv32eCbType(char* instTxt, uint32_t instruction)
{

    if(instTxt != NULL) {

        cInstructions instName;

        int txtOffset = 0;
        uint32_t regOrImm;

        instName = decodeInstruction(instruction);

        //Write instruction name
        switch (instName) {

            case C_BEQZ:
                strcpy(instTxt, "C.BEQZ");
                txtOffset += 6;
                break;

            case C_BNEZ:
                strcpy(instTxt, "C.BNEZ");
                txtOffset += 6;
                break;

            case C_SRLI:
                strcpy(instTxt, "C.SRLI");
                txtOffset += 6;
                break;

            case C_SRLI64:
                strcpy(instTxt, "C.SRLI64");
                txtOffset += 8;
                break;

            case C_SRAI:
                strcpy(instTxt, "C.SRAI");
                txtOffset += 6;
                break;

            case C_SRAI64:
                strcpy(instTxt, "C.SRAI64");
                txtOffset += 8;
                break;

            case C_ANDI:
                strcpy(instTxt, "C.ANDI");
                txtOffset += 6;
                break;

            default:
                strcpy(instTxt, "BAD INSTRUCTION");
                return;
        }

        //Write rs1
        strcpy((instTxt + txtOffset), " x");
        txtOffset += 2;

        regOrImm = (instruction & MASK_CB_RS1) >> OFFSET_CB_RS1;
        regOrImm = RP_SHIFT(regOrImm);

        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 1);


        //Write immediate value
        strcpy((instTxt + txtOffset), " ");
        txtOffset ++;

        regOrImm = getCbImmediate(instruction);


        txtOffset += longToDec((int32_t)regOrImm,
                               (instTxt + txtOffset), 0);
    }
}


void buildInstStringRv32eCjType(char* instTxt, uint32_t instruction)
{

    if(instTxt != NULL) {

        cInstructions instName;

        int txtOffset = 0;
        uint32_t regOrImm;

        instName = decodeInstruction(instruction);

        //Write instruction name
        switch (instName) {

            case C_J:
                strcpy(instTxt, "C.J");
                txtOffset += 3;
                break;

            case C_JAL:
                strcpy(instTxt, "C.JAL");
                txtOffset += 5;
                break;

            default:
                strcpy(instTxt, "BAD INSTRUCTION");
                return;
        }

        //Write immediate value
        strcpy((instTxt + txtOffset), " 0x");
        txtOffset += 3;

        regOrImm = getCjImmediate(instruction) + procGetPC();

        txtOffset += hexStr(regOrImm, (instTxt + txtOffset));
    }
}


char* strreverse(char *s)
{
    size_t i, j;
    char k;

    for(i = 0, j = strlen(s)-1; i < j; i++, j--) {
        k = s[i];
        s[i] = s[j];
        s[j] = k;
    }
    return s;
}


uint8_t longToDec(int32_t l, char* s, uint8_t isUnsigned)
{
    uint8_t i = 0;
    int sign = 0;

    if(isUnsigned){
        uint32_t ul = (uint32_t)l;

        if(ul == 0){
            s[i++] = '0';
        }
        else {
            while (ul > 0) {
                s[i++] = ul % 10 + '0';
                ul /= 10;
            }
        }
    }
    else{
        if(l < 0){
            sign = 1;
            l *= -1;
        }

        if(l == 0){
            s[i++] = '0';
        }
        else {
            while (l > 0) {
                s[i++] = l % 10 + '0';
                l /= 10;
            }
        }

        if(sign){
            s[i++] = '-';
        }
    }

    s[i] = '\0';
    strreverse(s);
    return i;
}


uint8_t hexStr(uint32_t l, char* s)
{
    int8_t i, j, bits;
    int32_t c;

    if(l <= 0xFF) bits = 8;
    else if(l <= 0xFFFF) bits = 16;
    else bits = 32;


    for(i = bits-4, j = 0; i >= 0; i -= 4) {
        c = (int32_t)((l >> i) & 0x0f) + 0x30;
        if (c > 0x39) c+= 7;
        s[j++] = c;
    }

    s[j] = '\0';
    return (bits/4);
}