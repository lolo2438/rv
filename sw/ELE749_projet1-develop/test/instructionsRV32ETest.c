#include "test.h"

///// Loads test

void testLoadByte(void)
{
    iType data;
    int8_t a = 0b1010;
    procWriteMem(12,&a,sizeof(a));
    procWriteReg(1,8);
    data.rs1 = 1;
    data.imm = 4;
    data.rd = 3;
    loadByte(&data);

    TEST_ASSERT_EQUAL_INT32(0b1010,procReadReg(3));
}

void testLoadHalfword(void)
{
    iType data;
    int16_t a = 0xDEAD;
    procWriteMem(12,&a,sizeof(a));
    procWriteReg(1,8);
    data.rs1 = 1;
    data.imm = 4;
    data.rd = 3;
    loadHalfword(&data);

    TEST_ASSERT_EQUAL_INT32((int16_t)0xDEAD,procReadReg(3));
}


void testLoadWord(void)
{
    iType data;
    int32_t a = 0xDEADCAFE;
    procWriteMem(12,&a,sizeof(a));
    procWriteReg(1,8);
    data.rs1 = 1;
    data.imm = 4;
    data.rd = 3;
    loadWord(&data);

    TEST_ASSERT_EQUAL_INT32(0xDEADCAFE,procReadReg(3));
}


void testLoadByteUnsigned(void)
{
    iType data;
    uint8_t a = 0xAB;
    procWriteMem(12,&a,sizeof(a));
    procWriteReg(1,8);
    data.rs1 = 1;
    data.imm = 4;
    data.rd = 3;
    loadByteUnsigned(&data);

    TEST_ASSERT_EQUAL_UINT32(0xAB,procReadReg(3));
}


void testLoadHalfUnsigned(void)
{
    iType data;
    int16_t a = 0xDEAD;
    procWriteMem(12,&a,sizeof(a));
    procWriteReg(1,8);
    data.rs1 = 1;
    data.imm = 4;
    data.rd = 3;
    loadHalfUnsigned(&data);

    TEST_ASSERT_EQUAL_UINT32(0xDEAD,procReadReg(3));
}


void testLoads(void)
{
    RUN_TEST(testLoadByte);
    RUN_TEST(testLoadHalfword);
    RUN_TEST(testLoadWord);
    RUN_TEST(testLoadByteUnsigned);
    RUN_TEST(testLoadHalfUnsigned);
}

///// Stores test

void testStoreByte(void)
{
    sType data;
    uint8_t value;
    procWriteReg(1,0xAB);
    procWriteReg(2,8);
    data.rs1 = 2;
    data.imm = 4;
    data.rs2 = 1;
    storeByte(&data);
    procReadMem(12,&value,sizeof(value));
    TEST_ASSERT_EQUAL_UINT8(0xAB,value);
}


void testStoreHalfword(void)
{
    sType data;
    uint16_t value;
    procWriteReg(1,0xABBA);
    procWriteReg(2,8);
    data.rs1 = 2;
    data.imm = 4;
    data.rs2 = 1;
    storeHalfword(&data);
    procReadMem(12,&value,sizeof(value));
    TEST_ASSERT_EQUAL_UINT16(0xABBA,value);
}


void testStoreWord(void)
{
    sType data;
    uint32_t value;
    procWriteReg(1,0xABBADEAD);
    procWriteReg(2,8);
    data.rs1 = 2;
    data.imm = 4;
    data.rs2 = 1;
    storeWord(&data);
    procReadMem(12, &value, sizeof(value));
    TEST_ASSERT_EQUAL_UINT32(0xABBADEAD,value);
}


void testStores(void){

    RUN_TEST(testStoreByte);
    RUN_TEST(testStoreHalfword);
    RUN_TEST(testStoreWord);

}

///// Shifts test

void testShiftLeft(void)
{
    rType data;
    procWriteReg(1,-12);
    procWriteReg(2,2);
    data.rs1 = 1;
    data.rs2 = 2;
    data.rd = 3;
    shiftLeft(&data);

    TEST_ASSERT_EQUAL_INT32(0b11111111111111111111111111010000,procReadReg(3));
}

void testShiftLeftImm(void)
{
    iType data;
    procWriteReg(1,0b1100);
    data.rs1 = 1;
    data.imm = 2;
    data.rd = 3;
    shiftLeftImmediate(&data);
    TEST_ASSERT_EQUAL_INT32(0b110000,procReadReg(3));

}

void testShiftRight(void)
{
    rType data;
    procWriteReg(1,-12);
    procWriteReg(2,2);
    data.rs1 = 1;
    data.rs2 = 2;
    data.rd = 3;
    shiftRight(&data);
    TEST_ASSERT_EQUAL_INT32(0b00111111111111111111111111111101,procReadReg(3));
}

void testShiftRightImm(void)
{
    iType data;
    procWriteReg(1,-12);
    data.rs1 = 1;
    data.imm = 2;
    data.rd = 3;
    shiftRightImmediate(&data);
    TEST_ASSERT_EQUAL_INT32(0b00111111111111111111111111111101,procReadReg(3));
}

void testShiftRightArithmetic(void)
{
    rType data;
    procWriteReg(1,-12);
    procWriteReg(2,2);
    data.rs1 = 1;
    data.rs2 = 2;
    data.rd = 3;
    shiftRightArithmetic(&data);
    TEST_ASSERT_EQUAL_INT32(0b11111111111111111111111111111101,procReadReg(3));
}

void testShiftRightArithmeticImm(void)
{
    iType data;
    procWriteReg(1, -12);
    data.rs1 = 1;
    data.imm = 2;
    data.rd = 3;
    shiftRightArithImm(&data);
    TEST_ASSERT_EQUAL_INT32(0b11111111111111111111111111111101, procReadReg(3));
}


void testShifts(void)
{
    RUN_TEST(testShiftLeft);
    RUN_TEST(testShiftLeftImm);
    RUN_TEST(testShiftRight);
    RUN_TEST(testShiftRightImm);
    RUN_TEST(testShiftRightArithmetic);
    RUN_TEST(testShiftRightArithmeticImm);
}

///// Arithmetic test

void testADD(void)
{
    rType data;
    procWriteReg(1,5);
    procWriteReg(2,2);
    data.rs1 = 1;
    data.rs2 = 2;
    data.rd = 3;
    add(&data);
    TEST_ASSERT_EQUAL_INT32(7, procReadReg(3));
}

void testADDImm(void)
{
    iType data;
    procWriteReg(1,5);
    data.rs1 = 1;
    data.imm = 2;
    data.rd = 3;
    addImmediate(&data);
    TEST_ASSERT_EQUAL_INT32(7, procReadReg(3));
}


void testSUB(void)
{
    rType data;
    procWriteReg(1,5);
    procWriteReg(2,2);
    data.rs1 = 1;
    data.rs2 = 2;
    data.rd = 3;
    sub(&data);
    TEST_ASSERT_EQUAL_INT32(3, procReadReg(3));
}

void testLoadUpperImm(void)
{
    uType data;
    data.imm = 2 << 12;
    data.rd = 3;

    loadUpperImm(&data);
    TEST_ASSERT_EQUAL_INT32(0x00002000, procReadReg(3));
}

void testAddUpperImmToPC(void)
{
    uType data;
    data.imm = 2 << 12;
    data.rd = 3;
    procSetPC(12);
    addUpperImmToPC(&data);
    TEST_ASSERT_EQUAL_INT32(0x0000200C, procReadReg(3));
}

void testArithmetic(void)
{
    RUN_TEST(testADD);
    RUN_TEST(testADDImm);
    RUN_TEST(testSUB);
    RUN_TEST(testLoadUpperImm);
    RUN_TEST(testAddUpperImmToPC);
}

///// Logical test

void testXOR(void)
{
    rType data;
    procWriteReg(1,0b1001);
    procWriteReg(2,0b0101);
    data.rs1 = 1;
    data.rs2 = 2;
    data.rd = 3;
    xor(&data);
    TEST_ASSERT_EQUAL_INT32(0b1100, procReadReg(3));
}


void testXORImm(void)
{
    iType data;
    procWriteReg(1,0b1100);
    data.rs1 = 1;
    data.imm = 0b1010;
    data.rd = 3;
    xorImmediate(&data);
    TEST_ASSERT_EQUAL_INT32(0b0110, procReadReg(3));
}


void testOR(void)
{
    rType data;
    procWriteReg(1,0b1100);
    procWriteReg(2,0b0101);
    data.rs1 = 1;
    data.rs2 = 2;
    data.rd = 3;
    or(&data);
    TEST_ASSERT_EQUAL_INT32(0b1101, procReadReg(3));
}


void testORImm(void)
{
    iType data;
    procWriteReg(1,0b1100);
    data.rs1 = 1;
    data.imm = 0b1010;
    data.rd = 3;
    orImmediate(&data);
    TEST_ASSERT_EQUAL_INT32(0b1110, procReadReg(3));
}


void testAND(void)
{
    rType data;
    procWriteReg(1,0b1100);
    procWriteReg(2,0b0101);
    data.rs1 = 1;
    data.rs2 = 2;
    data.rd = 3;
    and(&data);
    TEST_ASSERT_EQUAL_INT32(0b0100, procReadReg(3));
}


void testANDImm(void)
{
    iType data;
    procWriteReg(1,0b1100);
    data.rs1 = 1;
    data.imm = 0b1010;
    data.rd = 3;
    andImmediate(&data);
    TEST_ASSERT_EQUAL_INT32(0b1000, procReadReg(3));
}


void testLogical(void)
{
    RUN_TEST(testXOR);
    RUN_TEST(testXORImm);
    RUN_TEST(testOR);
    RUN_TEST(testORImm);
    RUN_TEST(testAND);
    RUN_TEST(testANDImm);
}


///// Compare test


void testSetLessThan(void)
{
    rType data;
    procWriteReg(1,-5);
    procWriteReg(2,-10);
    data.rs1 = 1;
    data.rs2 = 2;
    data.rd = 3;
    setLessThan(&data);
    //printf("%d\n", procReadReg(3));
    TEST_ASSERT_EQUAL_INT32(0, procReadReg(3));
}


void testSetLessThanImm(void)
{
    iType data;
    procWriteReg(1,5);
    data.rs1 = 1;
    data.imm = 10;
    data.rd = 3;
    setLessThanImmediate(&data);
    TEST_ASSERT_EQUAL_INT32(1, procReadReg(3));
}


void testSetLessThanUnsigned(void)
{
    rType data;
    procWriteReg(1,-5);
    procWriteReg(2,-10);
    data.rs1 = 1;
    data.rs2 = 2;
    data.rd = 3;
    setLessThanUnsigned(&data);
    TEST_ASSERT_EQUAL_UINT32(1, procReadReg(3));
}


void testSetLessThanImmUnsigned(void)
{
    iType data;
    procWriteReg(1,-5);
    data.rs1 = 1;
    data.imm = -10;
    data.rd = 3;
    setLessThanImmediateUnsigned(&data);
    TEST_ASSERT_EQUAL_UINT32(1, procReadReg(3));
}


void testCompare(void)
{
    RUN_TEST(testSetLessThan);
    RUN_TEST(testSetLessThanImm);
    RUN_TEST(testSetLessThanUnsigned);
    RUN_TEST(testSetLessThanImmUnsigned);
}


///// Branch test

void testBranchEqual(void)
{
    bType data;
    procWriteReg(1,10);
    procWriteReg(2,10);
    data.rs1 = 1;
    data.rs2 = 2;
    data.imm = 12;
    branchEqual(&data);
    TEST_ASSERT_EQUAL_INT32(12, procGetPC());
}


void testBranchNotEqual(void)
{
    bType data;
    procWriteReg(1,5);
    procWriteReg(2,10);
    data.rs1 = 1;
    data.rs2 = 2;
    data.imm = 12;
    branchNotEqual(&data);
    TEST_ASSERT_EQUAL_INT32(12, procGetPC());
}


void testBranchLessThan(void)
{
    bType data;
    procWriteReg(1,5);
    procWriteReg(2,10);
    data.rs1 = 1;
    data.rs2 = 2;
    data.imm = 12;
    branchLessThan(&data);
    TEST_ASSERT_EQUAL_INT32(12, procGetPC());
}


void testBranchMoreOrEqual(void)
{
    bType data;
    procWriteReg(1,10);
    procWriteReg(2,10);
    data.rs1 = 1;
    data.rs2 = 2;
    data.imm = 12;
    branchMoreOrEqual(&data);
    TEST_ASSERT_EQUAL_INT32(12, procGetPC());
}


void testBranchLessThanUnsigned(void)
{
    bType data;
    procWriteReg(1,-5);
    procWriteReg(2,-10);
    data.rs1 = 1;
    data.rs2 = 2;
    data.imm = 12;
    branchLessThanUnsigned(&data);
    TEST_ASSERT_EQUAL_INT32(12, procGetPC());
}


void testBranchMoreOrEqualUnsigned(void)
{
    bType data;
    procWriteReg(1,-15);
    procWriteReg(2,-10);
    data.rs1 = 1;
    data.rs2 = 2;
    data.imm = 12;
    branchMoreOrEqualUnsigned(&data);
    TEST_ASSERT_EQUAL_INT32(12, procGetPC());
}


void testBranch(void)
{
    RUN_TEST(testBranchEqual);
    RUN_TEST(testBranchNotEqual);
    RUN_TEST(testBranchLessThan);
    RUN_TEST(testBranchMoreOrEqual);
    RUN_TEST(testBranchLessThanUnsigned);
    RUN_TEST(testBranchMoreOrEqualUnsigned);
}


///// Jump&Link test

void testJumpAndLink(void)
{
    jType data;
    data.rd = 2;
    data.imm = 12;
    jumpAndLink(&data);
    TEST_ASSERT_EQUAL_INT32(12, procGetPC());
    TEST_ASSERT_EQUAL_INT32(4, procReadReg(2));
}


void testJumpAndLinkRegister(void)
{
    iType data;
    procWriteReg(1,4);
    data.rs1 = 1;
    data.rd = 2;
    data.imm = 12;
    jumpAndLinkRegister(&data);
    TEST_ASSERT_EQUAL_INT32(16, procGetPC());
    TEST_ASSERT_EQUAL_INT32(4, procReadReg(2));
}


void testJAndL(void)
{
    RUN_TEST(testJumpAndLink);
    RUN_TEST(testJumpAndLinkRegister);
}


void instructionsRV32ETest(void)
{
    testLoads();
    testStores();
    testShifts();
    testArithmetic();
    testLogical();
    testCompare();
    testBranch();
    testJAndL();
}

