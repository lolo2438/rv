/**
 * @file procStateTest.c
 * @author Laurent Tremblay
 * @date 2021-05-19
 * @brief Unit test for the module proc_state
 */
 
 
#include "test.h"


///// PC test
void writingToPCShouldStoreTheValue(void)
{
	
    procSetPC(1337);
    TEST_ASSERT_EQUAL_UINT32(1337, procGetPC());
	
}


void updatingPCWithNegativeOffset(void)
{
	
    procSetPC(0xC);
    procUpdatePC(-4);

    TEST_ASSERT_EQUAL_UINT32(0xC - 4, procGetPC());
	
}


void settingPCToOverflowValueShouldLoopBackToStart(void)
{
	
    procSetPC(PROC_MEMSIZE + 1);
    TEST_ASSERT_EQUAL_UINT32(1, procGetPC());
	
}


void updatingPCoverflowShouldLoopBackToStart(void)
{
	
    procUpdatePC(PROC_MEMSIZE + 1);
    TEST_ASSERT_EQUAL_UINT32(1, procGetPC());
	
}


void testPC(void)
{
	
    RUN_TEST(writingToPCShouldStoreTheValue);
    RUN_TEST(updatingPCWithNegativeOffset);
    RUN_TEST(settingPCToOverflowValueShouldLoopBackToStart);
    RUN_TEST(updatingPCoverflowShouldLoopBackToStart);
	
}


///// REG Test
void writingToReg0ShouldNotWriteValueAndReturn0(void)
{
	
    TEST_ASSERT_EQUAL_UINT32(0, procWriteReg(0, 69));
    TEST_ASSERT_EQUAL_UINT32(0, procReadReg(0));
	
}


void writingAndReadingAnInvalidRegShouldReturn0(void)
{
	
    TEST_ASSERT_EQUAL_UINT32(0, procWriteReg(69,33333));
    TEST_ASSERT_EQUAL_UINT32(0, procReadReg(69));
	
}


void writingToAValidRegShouldStoreTheValueAndReturnItWhenRead(void)
{
	
    TEST_ASSERT_EQUAL_UINT32(123456, procWriteReg(5, 123456));
    TEST_ASSERT_EQUAL_UINT32(123456, procReadReg(5));
	
}


void testReg(void)
{
	
    RUN_TEST(writingToReg0ShouldNotWriteValueAndReturn0);
    RUN_TEST(writingAndReadingAnInvalidRegShouldReturn0);
    RUN_TEST(writingToAValidRegShouldStoreTheValueAndReturnItWhenRead);
	
}


///// MEM_TEST
void writingToMemoryShouldStoreValue(void)
{
	
    uint32_t t = 0xDEADBEEF;
    uint32_t r = 0;
    TEST_ASSERT_EQUAL_UINT32(sizeof(t),
                             procWriteMem(0x12345, &t, sizeof(t)));
    TEST_ASSERT_EQUAL_UINT32(sizeof(t),
                             procReadMem(0x12345, &r, sizeof(r)));
    TEST_ASSERT_EQUAL_UINT32(t, r);
	
}


void overflowingMemoryAddressShouldLoopWrite(void)
{
	
    uint32_t t = 0xFACE1234;
    TEST_ASSERT_EQUAL_UINT32(sizeof(t),
                             procWriteMem(PROC_MEMSIZE - 2,
                                          &t, sizeof(t)));
    TEST_ASSERT_EQUAL_UINT8(0x34, procGetMem()[PROC_MEMSIZE-2]);
    TEST_ASSERT_EQUAL_UINT8(0x12, procGetMem()[PROC_MEMSIZE-1]);
    TEST_ASSERT_EQUAL_UINT8(0xCE, procGetMem()[0]);
    TEST_ASSERT_EQUAL_UINT8(0xFA, procGetMem()[1]);
	
}


void memoryShouldBeStoredAsLittleEndian(void)
{
	
    uint16_t t = 0xFEED;
    TEST_ASSERT_EQUAL_UINT32(sizeof(t), procWriteMem(0x4000,
                                                     &t, sizeof(t)));
    TEST_ASSERT_EQUAL_UINT8(0xED, procGetMem()[0x4000]);
    TEST_ASSERT_EQUAL_UINT8(0xFE, procGetMem()[0x4001]);
	
}


void testMem(void)
{
	
    RUN_TEST(writingToMemoryShouldStoreValue);
    RUN_TEST(overflowingMemoryAddressShouldLoopWrite);
    RUN_TEST(memoryShouldBeStoredAsLittleEndian);
	
}


void recallingInitShouldClearProcessorStateAndNotSegFault(void)
{
	
    uint16_t t = 0xFEED;
    procWriteMem(0x4000, (uint8_t*)&t, sizeof(t));
    procSetPC(1337);
    procWriteReg(5, 123456);

    procInit();
    TEST_ASSERT_EQUAL_UINT32(0, procReadReg(5));
    TEST_ASSERT_EQUAL_UINT32(0, procGetPC());
    TEST_ASSERT_EQUAL_UINT32(0,procGetMem()[0x4000]);
	
}


void procStateTest(void){
	
    testPC();
    testReg();
    testMem();

    RUN_TEST(recallingInitShouldClearProcessorStateAndNotSegFault);
	
}