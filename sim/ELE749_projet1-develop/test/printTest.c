/**
 * @file printTest.c
 * @author Laurent Tremblay
 * @date 2021-05-29
 * @brief Tests to validate the print module
 */


#include "test.h"


void printHeaderIsInExpectedFormat(void)
{
	
    printHeader();
	
}


void printingInstructionShowsCorrectString(void)
{
	
    printInstruction(ADD_X12_X6_X7);
	
}


void printingToRegistersShowsCorrectFormatAndOutputsCorrectValues(void)
{
	
    procWriteReg(3, 0x3FF);
    printRegisters();

    procSetPC(procGetPC() + 4);
    procWriteReg(15, 0xDEADBEEF);
    printRegisters();

    procSetPC(procGetPC() + 4);
    procWriteReg(3, procReadReg(3) + 0x001);
    printRegisters();

    procSetPC(procGetPC() + 4);
    procWriteReg(1, 0xFACE);
    printRegisters();
	
}


void printingToInvalidMemoryReturnsEARGS(void)
{
	
    TEST_ASSERT_EQUAL(-EARG, printMemory(0, 0xFF, 0x00));
    TEST_ASSERT_EQUAL(-EARG, printMemory(0, 0x00, PROC_MEMSIZE + 1));
	
}


void printingMemoryWithoutOutputFilePrintsToConsole(void)
{
	
    uint8_t startAddr = 0x00;
    uint8_t endAddr = 0x1A;

    printMemory(0, startAddr, endAddr);

    uint8_t data8 = 0x32;
    procWriteMem(0x10, &data8, 1);

    uint32_t data32 = 0xDEADBEEF;
    procWriteMem(0x16, (uint8_t*)&data32, sizeof(uint32_t));

    printMemory(0, startAddr, endAddr);
	
}


void printingToValidMemoryWritesCorrectOutputToFile(void)
{
	
    uint8_t data8 = 0x32;
    procWriteMem(0x10, &data8, 1);

    uint32_t data32 = 0xDEADBEEF;
    procWriteMem(0x16, (uint8_t*)&data32, sizeof(uint32_t));

    uint8_t startAddr = 0x00;
    uint8_t endAddr = 0x1A;
    const char *fName = "test_mem.txt";
    printMemory(fName, startAddr, endAddr);

    char sbuf[50] = { 0 };
    char exp[50] = { 0 };
    uint8_t expData;

    FILE *f = fopen(fName, "r"); // remove header
    fgets(sbuf, 50, f);
    for (uint8_t addr = startAddr; addr < endAddr; addr += 1) {
        fgets(sbuf, 50, f);

        if (addr == 0x10) {
            expData = data8;
        } else if (addr >= 0x16 && addr <= 0x16 + sizeof(uint32_t)){
            if (IS_LITTLE_ENDIAN)
                expData = ((uint8_t*)&data32)[addr - 0x16];
            else
                expData = ((uint8_t*)&data32)[(sizeof(uint32_t) - 1) -
                                              (addr - 0x16)];
        } else {
            expData = 0;
        }

        sprintf(exp, "%08x: [%02x]\n", addr, expData);
        TEST_ASSERT_EQUAL_STRING(exp, sbuf);
    }

    fclose(f);
	
}


void printTest(void)
{
	
    RUN_TEST(printHeaderIsInExpectedFormat);
    RUN_TEST(printingInstructionShowsCorrectString);
    RUN_TEST(printingToRegistersShowsCorrectFormatAndOutputsCorrectValues);
    RUN_TEST(printingToInvalidMemoryReturnsEARGS);
    RUN_TEST(printingMemoryWithoutOutputFilePrintsToConsole);
    RUN_TEST(printingToValidMemoryWritesCorrectOutputToFile);
	
}