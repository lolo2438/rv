/**
 * @file instructionsRV32C.c
 * @author Alexis Laframboise
 * @date 2021-06-12
 * @brief Implementation of every required "C" instructions.
 *        Mainly uses the RV32E implementation, maps the registers and data.
 */


#include <instructionsRV32C.h>


/*
 * Load and store instructions
 */
void cLoadWordStackPointer(cIType* data)
{

    iType* rv32eData = malloc(sizeof(iType));

    rv32eData->imm = data->imm * 4;
    rv32eData->rs1 = SP;
    rv32eData->rd = data->rdRs1;

    loadWord(rv32eData);

    free(rv32eData);

}


void cStoreWordStackPointer(cSSType* data)
{

    sType* rv32eData = malloc(sizeof(sType));

    rv32eData->imm = data->imm * 4;
    rv32eData->rs1 = SP;
    rv32eData->rs2 = data->rs2;

    storeWord(rv32eData);

    free(rv32eData);

}


void cLoadWord(cLType* data)
{

    iType* rv32eData = malloc(sizeof(iType));

    rv32eData->imm = data->imm * 4;
    rv32eData->rs1 = RP_SHIFT(data->rs1P);
    rv32eData->rd = RP_SHIFT(data->rdP);

    loadWord(rv32eData);

    free(rv32eData);

}


void cStoreWord(cSType* data)
{

    sType* rv32eData = malloc(sizeof(sType));

    rv32eData->imm = data->imm * 4;
    rv32eData->rs1 = RP_SHIFT(data->rs1P);
    rv32eData->rs2 = RP_SHIFT(data->rs2P);

    storeWord(rv32eData);

    free(rv32eData);

}


/*
 * Control transfer instructions
 */
void cJump(cJType* data)
{

    jType* rv32eData = malloc(sizeof(jType));

    rv32eData->imm = data->jumptarget;
    rv32eData->rd = X0;

    jumpAndLink(rv32eData);

    free(rv32eData);

}


void cJumpAndLink(cJType* data)
{

    procWriteReg(LR, (int32_t)procGetPC() + 2);
    procUpdatePC(data->jumptarget);

}


void cJumpRegister(cRType* data)
{
    iType* rv32eData = malloc(sizeof(iType));

    rv32eData->imm = 0;
    rv32eData->rs1 = data->rdRs1;
    rv32eData->rd = X0;

    jumpAndLinkRegister(rv32eData);

    free(rv32eData);

}


void cJumpAndLinkRegister(cRType* data)
{

    if(data->rdRs1 == X0){
        ebreak();
    } else {
        procWriteReg(LR, (int32_t)procGetPC() + 2);
        cJumpRegister(data);
    }

}


void cBranchOnEqualZero(cBType* data)
{

    bType* rv32eData = malloc(sizeof(bType));

    rv32eData->imm = data->offset;
    rv32eData->rs1 = RP_SHIFT(data->rs1P);
    rv32eData->rs2 = X0;

    branchEqual(rv32eData);

    free(rv32eData);

}


void cBranchNotEqualZero(cBType* data)
{

    bType* rv32eData = malloc(sizeof(bType));

    rv32eData->imm = data->offset;
    rv32eData->rs1 = RP_SHIFT(data->rs1P);
    rv32eData->rs2 = X0;

    branchNotEqual(rv32eData);

    free(rv32eData);

}


/*
 * Integer computational instructions
 */
/*
 * Integer constant-generation instructions
 */
void cLoadImmediate(cIType* data)
{

    iType* rv32eData = malloc(sizeof(iType));

    rv32eData->imm = data->imm;
    rv32eData->rs1 = X0;
    rv32eData->rd = data->rdRs1;

    addImmediate(rv32eData);
    free(rv32eData);

}


void cLoadUpperImmediate(cIType* data)
{

    uType* rv32eData = malloc(sizeof(uType));

    rv32eData->imm = (data->imm << OFFSET_BIT12);
    rv32eData->rd = data->rdRs1;

    loadUpperImm(rv32eData);
    free(rv32eData);

}


/*
 * Integer register-immediate operations
 */
void cAddImmediate(cIType* data)
{

    iType* rv32eData = malloc(sizeof(iType));

    rv32eData->imm = data->imm;
    rv32eData->rs1 = data->rdRs1;
    rv32eData->rd = data->rdRs1;

    addImmediate(rv32eData);
    free(rv32eData);

}


void cAddi16StackPointer(cIType* data)
{

    iType* rv32eData = malloc(sizeof(iType));

    rv32eData->imm = data->imm;
    rv32eData->rs1 = data->rdRs1;
    rv32eData->rd = data->rdRs1;

    addImmediate(rv32eData);
    free(rv32eData);

}


void cAddi4StackPointer(cIWType* data)
{

    iType* rv32eData = malloc(sizeof(iType));

    rv32eData->imm = data->imm;
    rv32eData->rs1 = SP;
    rv32eData->rd = SP;

    addImmediate(rv32eData);

    procWriteReg(RP_SHIFT(data->rdP), procReadReg(SP));

    free(rv32eData);

}


void cShiftLeftLogicalImmediate(cIType* data)
{

    iType* rv32eData = malloc(sizeof(iType));

    rv32eData->imm = data->imm;
    rv32eData->rs1 = data->rdRs1;
    rv32eData->rd = data->rdRs1;

    shiftLeftImmediate(rv32eData);
    free(rv32eData);

}


void cShiftRightLogicalImmediate(cBType* data)
{

    iType* rv32eData = malloc(sizeof(iType));

    rv32eData->imm = data->offset;
    rv32eData->rs1 = RP_SHIFT(data->rs1P);
    rv32eData->rd = rv32eData->rs1;

    shiftRightImmediate(rv32eData);
    free(rv32eData);

}


void cShiftRightArithmeticImmediate(cBType* data)
{

    iType* rv32eData = malloc(sizeof(iType));

    rv32eData->imm = data->offset;
    rv32eData->rs1 = RP_SHIFT(data->rs1P);
    rv32eData->rd = rv32eData->rs1;

    shiftRightArithImm(rv32eData);
    free(rv32eData);

}


void cAndImmediate(cBType* data)
{

    iType* rv32eData = malloc(sizeof(iType));

    rv32eData->imm = data->offset;
    rv32eData->rs1 = RP_SHIFT(data->rs1P);
    rv32eData->rd = RP_SHIFT(data->rs1P);

    andImmediate(rv32eData);
    free(rv32eData);

}


/*
 * Integer register-register operations
 */
void cMove(cRType* data)
{

    rType* rv32eData = malloc(sizeof(rType));

    rv32eData->rs1 = X0;
    rv32eData->rs2 = data->rs2;
    rv32eData->rd = data->rdRs1;

    add(rv32eData);
    free(rv32eData);

}


void cAdd(cRType* data)
{

    rType* rv32eData = malloc(sizeof(rType));

    rv32eData->rs1 = data->rdRs1;
    rv32eData->rs2 = data->rs2;
    rv32eData->rd = data->rdRs1;

    add(rv32eData);
    free(rv32eData);

}


void cAnd(cAType* data)
{

    rType* rv32eData = malloc(sizeof(rType));

    rv32eData->rs1 = RP_SHIFT(data->rdPRs1P);
    rv32eData->rs2 = RP_SHIFT(data->rs2P);
    rv32eData->rd = RP_SHIFT(data->rdPRs1P);

    and(rv32eData);
    free(rv32eData);

}


void cOr(cAType* data)
{

    rType* rv32eData = malloc(sizeof(rType));

    rv32eData->rs1 = RP_SHIFT(data->rdPRs1P);
    rv32eData->rs2 = RP_SHIFT(data->rs2P);
    rv32eData->rd = RP_SHIFT(data->rdPRs1P);

    or(rv32eData);
    free(rv32eData);

}


void cXor(cAType* data)
{

    rType* rv32eData = malloc(sizeof(rType));

    rv32eData->rs1 = RP_SHIFT(data->rdPRs1P);
    rv32eData->rs2 = RP_SHIFT(data->rs2P);
    rv32eData->rd = RP_SHIFT(data->rdPRs1P);

    xor(rv32eData);
    free(rv32eData);

}


void cSub(cAType* data)
{

    rType* rv32eData = malloc(sizeof(rType));

    rv32eData->rs1 = RP_SHIFT(data->rdPRs1P);
    rv32eData->rs2 = RP_SHIFT(data->rs2P);
    rv32eData->rd = RP_SHIFT(data->rdPRs1P);

    sub(rv32eData);
    free(rv32eData);

}
