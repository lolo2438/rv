/**
 * File: instructionsRV32CTest.c
 * Author: Alexis Laframboise
 * Date : 2021-06-12
 * Description:
 * Unit tests for the RV "C" instructions.
 */
#include "test.h"

/*
 * Load and store instructions tests.
 */
void testCLoadWordStackPointer(void){

    // Setting up initial conditions.
    cIType data;
    int32_t memVal = (int32_t)0xCAFECAFE;
    procWriteMem(10, &memVal, sizeof(memVal));
    procWriteReg(SP, 2);

    // Calling the operation.
    data.imm = 2;
    data.rdRs1 = X15;

    cLoadWordStackPointer(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT32(memVal, procReadReg(X15));

}


void testCStoreWordStackPointer(void){

    // Setting up initial conditions.
    cSSType data;
    int32_t regVal = (int32_t)0xCAFECAFE;
    int32_t memVal;
    procWriteReg(SP, 2);
    procWriteReg(X15, regVal);

    // Calling the operation.
    data.imm = 2;
    data.rs2 = X15;

    cStoreWordStackPointer(&data);

    // Checking the result.
    procReadMem(10, &memVal, sizeof(memVal));

    TEST_ASSERT_EQUAL_INT32(procReadReg(X15), memVal);

}


void testCLoadWord(void){

    // Setting up initial conditions.
    cLType data;
    int32_t memVal = (int32_t)0xCAFECAFE;
    procWriteMem(43, &memVal, sizeof(memVal));
    procWriteReg(X8, 3);

    // Calling the operation.
    data.imm = 10;
    data.rs1P = X0;
    data.rdP = X7;

    cLoadWord(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT32(memVal, procReadReg(X15));

}


void testCStoreWord(void){

    // Setting up initial conditions.
    cSType data;
    int32_t regVal = (int32_t)0xCAFECAFE;
    int32_t memVal;
    procWriteReg(X8, 4);
    procWriteReg(X9, regVal);

    // Calling the operation.
    data.imm = 2;
    data.rs1P = X0;
    data.rs2P = X1;

    cStoreWord(&data);

    // Checking the result.
    procReadMem(12, &memVal, sizeof(memVal));

    TEST_ASSERT_EQUAL_INT32(memVal, procReadReg(X9));

}


/*
 * Control transfer instructions tests.
 */
void testCJump(void){

    // Setting up initial conditions.
    cJType data;
    int32_t pc = 0xCAFE;
    procSetPC(0x0);

    // Calling the operation.
    data.jumptarget = pc;

    cJump(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT32(data.jumptarget, (int32_t)procGetPC());
}


void testCJumpAndLink(void){

    // Setting up initial conditions.
    cJType data;
    int32_t pc = 0xC01D;
    procSetPC(0x0);

    // Calling the operation.
    data.jumptarget = pc;

    cJumpAndLink(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT32((int32_t)procGetPC(), data.jumptarget);
    TEST_ASSERT_EQUAL_INT32(2, procReadReg(LR));

}


void testCJumpRegister(void){


    // Setting up initial conditions.
    cRType data;
    uint32_t pc = 0x001DCAFE;
    procSetPC(0x0);

    procWriteReg(X3, pc);

    // Calling the operation.
    data.rdRs1 = X3;

    cJumpRegister(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_UINT32(0x001DCAFE, procGetPC());
}


void testCJumpAndLinkRegister(void){

    // Setting up initial conditions.
    cRType data;
    uint32_t pc = 0x001DCAFE;
    procSetPC(0x0);

    procWriteReg(X3, pc);

    // Calling the operation.
    data.rdRs1 = X3;
    cJumpAndLinkRegister(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_UINT32(0x001DCAFE, procGetPC());
    TEST_ASSERT_EQUAL_UINT32(0 + 2, procReadReg(LR));
}


void testCBranchOnEqualZero(void){

    cBType data;

    // Calling the operation.
    data.rs1P = X0;
    data.offset = 0xBEEF;

    cBranchOnEqualZero(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT(data.offset, (int32_t)procGetPC());

    // Calling the operation.
    data.rs1P = X3;
    procWriteReg(RP_SHIFT(X3), 1);
    data.offset = 0xCAFE;

    cBranchOnEqualZero(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT(0xBEEF + 4, (int32_t)procGetPC());

}


void testCBranchNotEqualZero(void){

    cBType data;

    // Calling the operation.
    data.rs1P = X0;
    data.offset = 0xBEEF;

    cBranchNotEqualZero(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT(4, (int32_t)procGetPC());

    // Calling the operation.
    data.rs1P = X4;
    procWriteReg(RP_SHIFT(X4), 1);
    data.offset = 0xC01D;

    cBranchNotEqualZero(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT(0xC01D + 4, (int32_t)procGetPC());

}


/*
 * Integer computational instructions tests.
 */
/*
 * Integer constant-generation instructions tests.
 */
void testCLoadImmediate(void){

    cIType data;

    // Calling the operation.
    data.imm = 0b101010;
    data.rdRs1 = X10;

    cLoadImmediate(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT(data.imm, procReadReg(data.rdRs1));

}


void testCLoadUpperImmediate(void){

    cIType data;

    // Calling the operation.
    data.imm = 0b101010;
    data.rdRs1 = X10;

    cLoadUpperImmediate(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT(data.imm << 12, procReadReg(data.rdRs1));

}


/*
 * Integer register-immediate operations tests.
 */
void testCAddImmediate(void){

    cIType data;

    // Calling the operation.
    data.imm = 0b101010;
    data.rdRs1 = X10;
    procWriteReg(data.rdRs1, data.imm);

    cAddImmediate(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT(data.imm * 2, procReadReg(data.rdRs1));

}


void testCAddi16StackPointer(void){

    cIType data;

    // Calling the operation.
    data.imm = 0b101010;
    data.rdRs1 = SP;
    int32_t sp = procReadReg(SP);

    cAddi16StackPointer(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT(sp + data.imm, procReadReg(SP));

}


void testCAddi4StackPointer(void){

    cIWType data;

    // Calling the operation.
    data.imm = 40;
    data.rdP = X4;
    procWriteReg(SP, data.imm);

    cAddi4StackPointer(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT(data.imm * 2, procReadReg(SP));
    TEST_ASSERT_EQUAL_INT(data.imm * 2, procReadReg(RP_SHIFT(data.rdP)));

}


void testCShiftLeftLogicalImmediate(void){

    cIType data;

    // Calling the operation.
    data.imm = 4;
    data.rdRs1 = X5;
    procWriteReg(data.rdRs1, 1);

    cShiftLeftLogicalImmediate(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT(1 << data.imm, procReadReg(X5));

}


void testCShiftRightLogicalImmediate(void){

    cBType data;

    // Calling the operation.
    data.offset = 4;
    data.rs1P = X5;
    procWriteReg(RP_SHIFT(data.rs1P), 0b10000);

    cShiftRightLogicalImmediate(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT(0b10000 >> data.offset, procReadReg(RP_SHIFT(data.rs1P)));

}


void testCShiftRightArithmeticImmediate(void){

    cBType data;

    // Calling the operation.
    data.offset = 4;
    data.rs1P = X5;
    procWriteReg(RP_SHIFT(data.rs1P), 0b10000);

    cShiftRightArithmeticImmediate(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT(0b10000 >> data.offset, procReadReg(RP_SHIFT(data.rs1P)));

}


void testCAndImmediate(void){

    cBType data;

    // Calling the operation.
    data.offset = 0b11111;
    data.rs1P = X3;
    procWriteReg(RP_SHIFT(X3), 0b10101);

    cAndImmediate(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT(0b10101, procReadReg(RP_SHIFT(data.rs1P)));

}


/*
 * Integer register-register operations tests.
 */
void testCMove(void){

    cRType data;

    // Calling the operation.
    data.rdRs1 = X10;
    data.rs2 = X5;
    procWriteReg(data.rs2, (int32_t)0xDEADBEEF);

    cMove(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT(procReadReg(data.rs2), procReadReg(data.rdRs1));

}


void testCAdd(void){

    cRType data;

    // Calling the operation.
    data.rdRs1 = X10;
    data.rs2 = X5;
    procWriteReg(data.rs2, 15);

    cAdd(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT(procReadReg(data.rs2), procReadReg(data.rdRs1));

    // Calling the operation.

    cAdd(&data);
    // Checking the result.
    TEST_ASSERT_EQUAL_INT(procReadReg(data.rs2) * 2, procReadReg(data.rdRs1));

}


void testCAnd(void){

    cAType data;

    // Calling the operation.
    data.rdPRs1P = X7;
    data.rs2P = X6;
    procWriteReg(RP_SHIFT(data.rdPRs1P), (int32_t)0x5A5A5A5A);
    procWriteReg(RP_SHIFT(data.rs2P), (int32_t)0xA5A5A5A5);

    cAnd(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT(0, procReadReg(RP_SHIFT(data.rdPRs1P)));

}


void testCOr(void){

    cAType data;

    // Calling the operation.
    data.rdPRs1P = X7;
    data.rs2P = X6;
    procWriteReg(RP_SHIFT(data.rdPRs1P), (int32_t)0x5A5A5A5A);
    procWriteReg(RP_SHIFT(data.rs2P), (int32_t)0xA5A5A5A5);

    cOr(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT((int32_t)0xFFFFFFFF, procReadReg(RP_SHIFT(data.rdPRs1P)));

}


void testCXor(void){

    cAType data;

    // Calling the operation.
    data.rdPRs1P = X7;
    data.rs2P = X6;
    procWriteReg(RP_SHIFT(data.rdPRs1P), (int32_t)0x5A5AFF00);
    procWriteReg(RP_SHIFT(data.rs2P), (int32_t)0xA5A50FF0);

    cXor(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT((int32_t)0xFFFFF0F0, procReadReg(RP_SHIFT(data.rdPRs1P)));

}


void testCSub(void){

    cAType data;

    // Calling the operation.
    data.rdPRs1P = X7;
    data.rs2P = X6;
    procWriteReg(RP_SHIFT(data.rdPRs1P), 123456789);
    procWriteReg(RP_SHIFT(data.rs2P), 112345678);

    cSub(&data);

    // Checking the result.
    TEST_ASSERT_EQUAL_INT(11111111, procReadReg(RP_SHIFT(data.rdPRs1P)));

}


/*
 * Tests runners.
 */
void runTestsLoadAndStore(void){
    RUN_TEST(testCLoadWordStackPointer);
    RUN_TEST(testCStoreWordStackPointer);
    RUN_TEST(testCLoadWord);
    RUN_TEST(testCStoreWord);
}


void runTestsControlTransfer(void){
    RUN_TEST(testCJump);
    RUN_TEST(testCJumpAndLink);
    RUN_TEST(testCJumpRegister);
    RUN_TEST(testCJumpAndLinkRegister);
    RUN_TEST(testCBranchOnEqualZero);
    RUN_TEST(testCBranchNotEqualZero);
}


void runTestsIntegerConstantGeneration(void){
    RUN_TEST(testCLoadImmediate);
    RUN_TEST(testCLoadUpperImmediate);
}


void runTestsIntegerRegisterImmediate(void){
    RUN_TEST(testCAddImmediate);
    RUN_TEST(testCAddi16StackPointer);
    RUN_TEST(testCAddi4StackPointer);
    RUN_TEST(testCShiftLeftLogicalImmediate);
    RUN_TEST(testCShiftRightLogicalImmediate);
    RUN_TEST(testCShiftRightArithmeticImmediate);
    RUN_TEST(testCAndImmediate);
}


void runTestsIntegerRegisterRegister(void){
    RUN_TEST(testCMove);
    RUN_TEST(testCAdd);
    RUN_TEST(testCAnd);
    RUN_TEST(testCOr);
    RUN_TEST(testCXor);
    RUN_TEST(testCSub);
}


void instructionsRV32CTest(void){
    runTestsLoadAndStore();
    runTestsControlTransfer();
    runTestsIntegerConstantGeneration();
    runTestsIntegerRegisterImmediate();
    runTestsIntegerRegisterRegister();
}