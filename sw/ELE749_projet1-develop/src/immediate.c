/**
 * @file immediate.h
 * @author Louis Levesque
 * @date 2021-06-19
 * @brief Contains functions required for recomposing the immediate values
 *        for given types.
 */


#include <immediate.h>


int32_t getITypeImmediate(uint32_t instruction)
{
    int32_t immediate;
    immediate = (int32_t)(instruction & MASK_ITYPE_IMM11_0) >>
            OFFSET_ITYPE_IMM11_0;

    if(decodeInstruction(instruction) == RV32E_SRAI) {
        immediate &= ~(0b1 << 30);
    }

    if(instruction & MASK_SIGN_BIT) {
        immediate |= (int32_t)0xFFFFF000;
    }
    return immediate;
}


int32_t getSTypeImmediate(uint32_t instruction)
{

    int32_t immediate;
    immediate = (int32_t)(instruction & MASK_STYPE_IMM11_5) >>
            (OFFSET_STYPE_IMM11_5 -5);
    immediate |= (int32_t)(instruction & MASK_STYPE_IMM4_0) >>
            (OFFSET_STYPE_IMM4_0);

    if(instruction & MASK_SIGN_BIT) {
        immediate |= (int32_t)0xFFFFF000;
    }
    return immediate;
}


int32_t getBTypeImmediate(uint32_t instruction)
{

    int32_t immediate;
    immediate = (int32_t)(instruction & MASK_BTYPE_IMM12) >>
            (OFFSET_BTYPE_IMM12 - 12);
    immediate |= (int32_t)(instruction & MASK_BTYPE_IMM11) <<
            (11 - OFFSET_BTYPE_IMM11);
    immediate |= (int32_t)(instruction & MASK_BTYPE_IMM10_5) >>
            (OFFSET_BTYPE_IMM10_5 -5);
    immediate |= (int32_t)(instruction & MASK_BTYPE_IMM4_1) >>
            (OFFSET_BTYPE_IMM4_1 -1);

    if(instruction & MASK_SIGN_BIT) {
        immediate |= (int32_t)0xFFFFE000;
    }
    return immediate;

}


int32_t getUTypeImmediate(uint32_t instruction)
{

    int32_t immediate;
    immediate = (int32_t)(instruction & MASK_UTYPE_IMM31_12);

    return immediate;

}


int32_t getJTypeImmediate(uint32_t instruction)
{

    int32_t immediate;
    immediate = (int32_t)(instruction & MASK_JTYPE_IMM20) >>
            (OFFSET_JTYPE_IMM20 - 20);
    immediate |= (int32_t)(instruction & MASK_JTYPE_IMM19_12);
    immediate |= (int32_t)(instruction & MASK_JTYPE_IMM11) >>
            (OFFSET_JTYPE_IMM11 -11);
    immediate |= (int32_t)(instruction & MASK_JTYPE_IMM10_1)>>
            (OFFSET_JTYPE_IMM10_1 -1);

    if(instruction & MASK_SIGN_BIT) {
        immediate |= (int32_t)0xFFE00000;
    }
    return immediate;

}


int32_t getCiImmediate(uint32_t instruction)
{

    uint32_t immediate;
    cInstructions instName = decodeInstruction(instruction);

    if((instName == C_SLLI) || (instName == C_NOP) || (instName == C_ADDI)
       || (instName == C_LI) || (instName == C_LUI)){

        immediate = ((instruction & MASK_CI_IMM5)
                >> OFFSET_CI_IMM5);
        immediate = (immediate << 5) |
                    ((instruction & MASK_CI_IMM4_0) >> OFFSET_CI_IMM4_0);

        if(instName != C_SLLI){
            if(instruction & MASK_CI_IMM5){
                immediate |= 0xFFFFFFC0;
            }
        }
    }
    else if(instName == C_LWSP) {

        immediate = ((instruction & MASK_CI_IMM7_6) >> OFFSET_CI_IMM7_6);
        immediate = (immediate << 1) |
                    ((instruction & MASK_CI_IMM5) >> OFFSET_CI_IMM5);
        immediate = (immediate << 3) |
                    ((instruction & MASK_CI_IMM4_2) >> OFFSET_CI_IMM4_2);
        immediate = immediate << 2;
    }
    else if(instName == C_ADDI16SP) {
        immediate = ((instruction & MASK_ADDI16SP_IMM9)
                >> OFFSET_ADDI16SP_IMM9);
        immediate = (immediate << 2) | ((instruction & MASK_ADDI16SP_IMM8_7)
                >> OFFSET_ADDI16SP_IMM8_7);
        immediate = (immediate << 1) | ((instruction & MASK_ADDI16SP_IMM6)
                >> OFFSET_ADDI16SP_IMM6);
        immediate = (immediate << 1) | ((instruction & MASK_ADDI16SP_IMM5)
                >> OFFSET_ADDI16SP_IMM5);
        immediate = (immediate << 1) | ((instruction & MASK_ADDI16SP_IMM4)
                >> OFFSET_ADDI16SP_IMM4);
        immediate = immediate << 4;

        if(instruction & MASK_ADDI16SP_IMM9){
            immediate |= 0xFFFFFC00;
        }

    }
    else{
        immediate = 0;
    }

    return (int32_t)immediate;
}


int32_t getCssImmediate(uint32_t instruction)
{

    uint32_t immediate;
    cInstructions instName = decodeInstruction(instruction);

    if(instName == C_SWSP){

        immediate = ((instruction & MASK_CSS_IMM7_6) >> OFFSET_CSS_IMM7_6);
        immediate = (immediate << 4) |
                    ((instruction & MASK_CSS_IMM5_2) >> OFFSET_CSS_IMM5_2);
        immediate = immediate << 2;
    }
    else{
        immediate = 0;
    }

    return (int32_t)immediate;
}


int32_t getCiwImmediate(uint32_t instruction)
{

    uint32_t immediate;
    cInstructions instName = decodeInstruction(instruction);

    if(instName == C_ADDI4SPN){

        immediate = ((instruction & MASK_CIW_IMM9_6)
                >> OFFSET_CIW_IMM9_6);
        immediate = (immediate << 4) | ((instruction & MASK_CIW_IMM5_4)
                >> OFFSET_CIW_IMM5_4);
        immediate = (immediate << 1) |((instruction & MASK_CIW_IMM3)
                >> OFFSET_CIW_IMM3);
        immediate = (immediate << 1) | ((instruction & MASK_CIW_IMM2)
                >> OFFSET_CIW_IMM2);
        immediate = immediate << 2;
    }
    else{
        immediate = 0;
    }

    return (int32_t)immediate;
}


int32_t getClImmediate(uint32_t instruction)
{

    uint32_t immediate;
    cInstructions instName = decodeInstruction(instruction);

    if(instName == C_LW) {

        immediate = ((instruction & MASK_CL_CS_IMM6)
                >> OFFSET_CL_CS_IMM6);
        immediate = (immediate << 3) |
                    ((instruction & MASK_CL_CS_IMM5_3)
                            >> OFFSET_CL_CS_IMM5_3);
        immediate = (immediate << 1) |
                    ((instruction & MASK_CL_CS_IMM2) >> OFFSET_CL_CS_IMM2);
        immediate = immediate << 2;

    }
    else{
        immediate = 0;
    }

    return (int32_t)immediate;
}


int32_t getCsImmediate(uint32_t instruction)
{

    uint32_t immediate;
    cInstructions instName = decodeInstruction(instruction);

    if(instName == C_SW) {

        immediate = ((instruction & MASK_CL_CS_IMM6)
                >> OFFSET_CL_CS_IMM6);
        immediate = (immediate << 3) |
                    ((instruction & MASK_CL_CS_IMM5_3)
                            >> OFFSET_CL_CS_IMM5_3);
        immediate = (immediate << 1) |
                    ((instruction & MASK_CL_CS_IMM2) >> OFFSET_CL_CS_IMM2);
        immediate = immediate << 2;

    }
    else{
        immediate = 0;
    }

    return (int32_t)immediate;
}


int32_t getCbImmediate(uint32_t instruction)
{

    uint32_t immediate;
    cInstructions instName = decodeInstruction(instruction);

    if((instName == C_BEQZ) || (instName == C_BNEZ)){

        immediate = ((instruction & MASK_CB_IMM8) >> OFFSET_CB_IMM8);
        immediate = (immediate << 2) |
                    ((instruction & MASK_CB_IMM7_6) >> OFFSET_CB_IMM7_6);
        immediate = (immediate << 1) |
                    ((instruction & MASK_CB_IMM5) >> OFFSET_CB_IMM5);
        immediate = (immediate << 2) |
                    ((instruction & MASK_CB_IMM4_3) >> OFFSET_CB_IMM4_3);
        immediate = (immediate << 2) |
                    ((instruction & MASK_CB_IMM2_1) >> OFFSET_CB_IMM2_1);
        immediate = immediate << 1;

        if(instruction & MASK_CB_IMM8){
            immediate |= 0xFFFFFE00;
        }
    }
    else if((instName == C_SRLI) || (instName == C_SRLI64) ||
            (instName == C_SRAI) || (instName == C_SRAI64) ||
            (instName == C_ANDI)){

        immediate = ((instruction & MASK_CI_IMM5)
                >> OFFSET_CI_IMM5);
        immediate = (immediate << 5) |
                    ((instruction & MASK_CI_IMM4_0) >> OFFSET_CI_IMM4_0);

        if(instName == C_ANDI){
            if(instruction & MASK_CI_IMM5){
                immediate |= 0xFFFFFFC0;
            }
        }

    }
    else{
        immediate = 0;
    }

    return (int32_t)immediate;
}


int32_t getCjImmediate(uint32_t instruction)
{

    uint32_t immediate;
    cInstructions instName = decodeInstruction(instruction);

    if((instName == C_JAL) || (instName == C_J)) {

        immediate = ((instruction & MASK_CJ_IMM11) >> OFFSET_CJ_IMM11);
        immediate = (immediate << 1) |
                    ((instruction & MASK_CJ_IMM10) >> OFFSET_CJ_IMM10);
        immediate = (immediate << 2) |
                    ((instruction & MASK_CJ_IMM9_8) >> OFFSET_CJ_IMM9_8);
        immediate = (immediate << 1) |
                    ((instruction & MASK_CJ_IMM7) >> OFFSET_CJ_IMM7);
        immediate = (immediate << 1) |
                    ((instruction & MASK_CJ_IMM6) >> OFFSET_CJ_IMM6);
        immediate = (immediate << 1) |
                    ((instruction & MASK_CJ_IMM5) >> OFFSET_CJ_IMM5);
        immediate = (immediate << 1) |
                    ((instruction & MASK_CJ_IMM4) >> OFFSET_CJ_IMM4);
        immediate = (immediate << 3) |
                    ((instruction & MASK_CJ_IMM3_1) >> OFFSET_CJ_IMM3_1);
        immediate = immediate << 1;

        if(instruction & MASK_CJ_IMM11){
            immediate |= 0xFFFFF000;
        }
    }
    else{
        immediate = 0;
    }

    return (int32_t)immediate;
}