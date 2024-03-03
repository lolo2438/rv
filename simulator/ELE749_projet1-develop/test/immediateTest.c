/**
 * @file immediateTests.c
 * @brief Testing the functions of the desassembly module.
 */
 

#include "test.h"


void iTypeInstructionsImmediatesShouldBeDecoded(void)
{

    int32_t imm = getITypeImmediate(ADDI_X11_X11_1);
    TEST_ASSERT_EQUAL(1, imm);
	
}


void sTypeInstructionsImmediatesShouldBeDecoded(void)
{

    uint32_t imm = getSTypeImmediate(SB_X24_1234_X15_);
    TEST_ASSERT_EQUAL(0x04D2, imm);
	
}


void bTypeInstructionsImmediatesShouldBeDecoded(void)
{

    int32_t imm = getBTypeImmediate(BEQ_X5_X0_16);
    TEST_ASSERT_EQUAL(16, imm);
	
}


void bTypeInstructionsWithNegativeImmediatesShouldBeDecoded(void)
{

    int32_t imm = getBTypeImmediate(BEQ_X0_X0_N16);
    TEST_ASSERT_EQUAL(-16, imm);
	
}


void uTypeInstructionsImmediatesShouldBeDecoded(void)
{

    uint32_t imm = getUTypeImmediate(AUIPC_X11_0X400);
    TEST_ASSERT_EQUAL(0x400000, imm);
	
}


void jTypeInstructionsImmediatesShouldBeDecoded(void)
{

    uint32_t imm = getJTypeImmediate(JAL_X0_0X30);
    TEST_ASSERT_EQUAL(0x20, imm);
	
}


void ciInstructionsImmediatesShouldBeDecoded(void)
{

    int32_t imm = getCiImmediate(C_ADDI_X15_7);
    TEST_ASSERT_EQUAL(7, imm);
	
}


void cssInstructionsImmediatesShouldBeDecoded(void)
{

    uint32_t imm = getCssImmediate(C_SWSP_X16_0x18_x2_);
    TEST_ASSERT_EQUAL(0x18, imm);
	
}


void ciwInstructionsImmediatesShouldBeDecoded(void)
{

    uint32_t imm = getCiwImmediate(C_ADDI4SPN_X8_X2_0X24);
    TEST_ASSERT_EQUAL(0x24, imm);
	
}


void clInstructionsImmediatesShouldBeDecoded(void)
{

    uint32_t imm = getClImmediate(C_LW_X12_0X64_X8);
    TEST_ASSERT_EQUAL(0x64, imm);
	
}


void csInstructionsImmediatesShouldBeDecoded(void)
{

    uint32_t imm = getCsImmediate(C_SW_X15_0X3C_X10);
    TEST_ASSERT_EQUAL(0x3C, imm);
	
}


void cbInstructionsImmediatesShouldBeDecoded(void)
{

    int32_t imm = getCbImmediate(C_BEQZ_X12_N40);
    TEST_ASSERT_EQUAL(-40, imm);
	
}


void cjInstructionsImmediatesShouldBeDecoded(void)
{

    uint32_t imm = getCjImmediate(C_JAL_48);
    TEST_ASSERT_EQUAL(0x48-0x22, imm);
	
}


void immediateTest(void){

    //Run all test functions
    RUN_TEST(iTypeInstructionsImmediatesShouldBeDecoded);
    RUN_TEST(sTypeInstructionsImmediatesShouldBeDecoded);
    RUN_TEST(bTypeInstructionsImmediatesShouldBeDecoded);
    RUN_TEST(bTypeInstructionsWithNegativeImmediatesShouldBeDecoded);
    RUN_TEST(uTypeInstructionsImmediatesShouldBeDecoded);
    RUN_TEST(jTypeInstructionsImmediatesShouldBeDecoded);
    RUN_TEST(ciInstructionsImmediatesShouldBeDecoded);
    RUN_TEST(cssInstructionsImmediatesShouldBeDecoded);
    RUN_TEST(ciwInstructionsImmediatesShouldBeDecoded);
    RUN_TEST(clInstructionsImmediatesShouldBeDecoded);
    RUN_TEST(csInstructionsImmediatesShouldBeDecoded);
    RUN_TEST(cbInstructionsImmediatesShouldBeDecoded);
    RUN_TEST(cjInstructionsImmediatesShouldBeDecoded);
	
}