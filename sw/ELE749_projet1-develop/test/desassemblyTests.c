/**
 * @file desassemblyTests.c
 * @brief Testing the functions of the desassembly module.
 */
 
 
/* Includes ------------------------------------------------------------------*/
#include "test.h"
#include <desassembly.h>


/* Defines -------------------------------------------------------------------*/


/* Test Functions ------------------------------------------------------------*/
void rTypeInstructionsShouldBeConvertedToString(void)
{

    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    buildInstStringRv32eRtype(instTxt, ADD_X12_X6_X7);
    TEST_ASSERT_EQUAL_STRING ("ADD x12 x6 x7", instTxt);

    free(instTxt);
	
}


void iTypeInstructionsShouldBeConvertedToString(void)
{

    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    buildInstStringRv32eItype(instTxt, ADDI_X11_X11_1);
    TEST_ASSERT_EQUAL_STRING ("ADDI x11 x11 1", instTxt);

    free(instTxt);
	
}


void sTypeInstructionsShouldBeConvertedToString(void)
{

    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    buildInstStringRv32eStype(instTxt, SB_X24_1234_X15_);
    TEST_ASSERT_EQUAL_STRING ("SB x24 0x04D2(x15)", instTxt);

    free(instTxt);
}


void bTypeInstructionsShouldBeConvertedToString(void)
{

    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    buildInstStringRv32eBtype(instTxt, BEQ_X5_X0_16);
    TEST_ASSERT_EQUAL_STRING ("BEQ x5 x0 16", instTxt);

    free(instTxt);
	
}


void bTypeInstructionsWithNegativeImmediateShouldBeConvertedToString(void)
{

    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    buildInstStringRv32eBtype(instTxt, BEQ_X0_X0_N16);
    TEST_ASSERT_EQUAL_STRING ("BEQ x0 x0 -16", instTxt);

    free(instTxt);
	
}


void uTypeInstructionsShouldBeConvertedToString(void)
{

    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    buildInstStringRv32eUtype(instTxt, AUIPC_X11_0X400);
    TEST_ASSERT_EQUAL_STRING ("AUIPC x11 0x0400", instTxt);

    free(instTxt);
	
}


void jTypeInstructionsShouldBeConvertedToString(void)
{

    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    procSetPC(16);

    buildInstStringRv32eJtype(instTxt, JAL_X0_0X30);
    TEST_ASSERT_EQUAL_STRING ("JAL x0 0x30", instTxt);

    free(instTxt);
	
}


void miscTypeInstructionsShouldBeConvertedToString(void)
{

    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    buildInstStringRv32eMisctype(instTxt, ECALL);
    TEST_ASSERT_EQUAL_STRING ("ECALL", instTxt);

    free(instTxt);
	
}


void crInstructionsShouldBeConvertedToString(void)
{

    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    buildInstStringRv32eCrType(instTxt, C_ADD_X4_X14);
    TEST_ASSERT_EQUAL_STRING ("C.ADD x4 x14", instTxt);

    buildInstStringRv32eCrType(instTxt, C_EBREAK);
    TEST_ASSERT_EQUAL_STRING ("C.EBREAK", instTxt);

    free(instTxt);
	
}


void ciInstructionsShouldBeConvertedToString(void)
{

    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    buildInstStringRv32eCiType(instTxt, C_ADDI_X15_7);
    TEST_ASSERT_EQUAL_STRING ("C.ADDI x15 7", instTxt);

    buildInstStringRv32eCiType(instTxt, C_LI_X5_8);
    TEST_ASSERT_EQUAL_STRING ("C.LI x5 8", instTxt);

    free(instTxt);
	
}


void cssInstructionsShouldBeConvertedToString(void)
{

    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    buildInstStringRv32eCssType(instTxt, C_SWSP_X16_0x18_x2_);
    TEST_ASSERT_EQUAL_STRING ("C.SWSP x16 0x18(x2)", instTxt);

    free(instTxt);
	
}


void ciwInstructionsShouldBeConvertedToString(void)
{

    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    buildInstStringRv32eCiwType(instTxt, C_ADDI4SPN_X8_X2_0X24);
    TEST_ASSERT_EQUAL_STRING ("C.ADDI4SPN x8 x2 0x24", instTxt);

    free(instTxt);
	
}


void clInstructionsShouldBeConvertedToString(void)
{

    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    buildInstStringRv32eClType(instTxt, C_LW_X12_0X64_X8);
    TEST_ASSERT_EQUAL_STRING ("C.LW x12 0x64(x8)", instTxt);

    free(instTxt);
	
}


void csInstructionsShouldBeConvertedToString(void)
{

    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    buildInstStringRv32eCsType(instTxt, C_SW_X15_0X3C_X10);
    TEST_ASSERT_EQUAL_STRING ("C.SW x15 0x3C(x10)", instTxt);

    free(instTxt);
	
}


void caInstructionsShouldBeConvertedToString(void)
{

    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    buildInstStringRv32eCaType(instTxt, C_AND_X9_X11);
    TEST_ASSERT_EQUAL_STRING ("C.AND x9 x11", instTxt);

    free(instTxt);
	
}


void cbInstructionsShouldBeConvertedToString(void)
{

    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    buildInstStringRv32eCbType(instTxt, C_ANDI_X14_21);
    TEST_ASSERT_EQUAL_STRING ("C.ANDI x14 21", instTxt);

    buildInstStringRv32eCbType(instTxt, C_BEQZ_X12_N40);
    TEST_ASSERT_EQUAL_STRING ("C.BEQZ x12 -40", instTxt);

    free(instTxt);
	
}


void cjInstructionsShouldBeConvertedToString(void)
{

    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    procSetPC(0x22);

    buildInstStringRv32eCjType(instTxt, C_JAL_48);
    TEST_ASSERT_EQUAL_STRING ("C.JAL 0x48", instTxt);

    free(instTxt);
	
}


void unsignedIntegerShouldBeConvertedToDecimalStrings(void)
{

    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    uint8_t offset = longToDec(2021, instTxt, 0);
    TEST_ASSERT_EQUAL_STRING ("2021", instTxt);
    TEST_ASSERT_EQUAL_UINT8 (4, offset);

    free(instTxt);

}


void integerShouldBeConvertedToHexadecimalStrings(void)
{

    char *instTxt = (char *) malloc(CHAR_NB_BY_INST * sizeof(char));

    hexStr(3242, instTxt);
    TEST_ASSERT_EQUAL_STRING ("0CAA", instTxt);

    free(instTxt);

}


void instructionsShouldBeConvertedToString(void)
{

    char *instTxt;

    uint32_t instruction = 0x00008067;

    instTxt = buildInstString(instruction);
    procSetPC(0x18);

    TEST_ASSERT_EQUAL_STRING ("JALR x0 x1 0", instTxt);

    free(instTxt);

}


void allInstructionsShouldBeConvertedToString(void)
{

    uint32_t instTab[] = {0x00400597, 0x00058593, 0x00c000ef, 0x00050093,
                          0x0200006f, 0x00000513, 0x00058283, 0x00028863,
                          0x00150513, 0x00158593, 0xfe0008e3, 0x00008067,
                          0x00000073};

    char ** instTxtTab;

    instTxtTab = buildInstTxtTab(instTab, 13);



    TEST_ASSERT_EQUAL_STRING ("AUIPC x11 0x0400", instTxtTab[0]);
    TEST_ASSERT_EQUAL_STRING ("ADDI x11 x11 0", instTxtTab[1]);
    TEST_ASSERT_EQUAL_STRING ("JAL x1 0x14", instTxtTab[2]);
    TEST_ASSERT_EQUAL_STRING ("ADDI x1 x10 0", instTxtTab[3]);
    TEST_ASSERT_EQUAL_STRING ("JAL x0 0x30", instTxtTab[4]);

    TEST_ASSERT_EQUAL_STRING ("ADDI x10 x0 0", instTxtTab[5]);

    TEST_ASSERT_EQUAL_STRING ("LB x5 x11 0", instTxtTab[6]);
    TEST_ASSERT_EQUAL_STRING ("BEQ x5 x0 16", instTxtTab[7]);
    TEST_ASSERT_EQUAL_STRING ("ADDI x10 x10 1", instTxtTab[8]);
    TEST_ASSERT_EQUAL_STRING ("ADDI x11 x11 1", instTxtTab[9]);
    TEST_ASSERT_EQUAL_STRING ("BEQ x0 x0 -16", instTxtTab[10]);

    TEST_ASSERT_EQUAL_STRING ("JALR x0 x1 0", instTxtTab[11]);
    TEST_ASSERT_EQUAL_STRING ("ECALL", instTxtTab[12]);


    for(int i = 0; i < 13; i++){
        free(instTxtTab[i]);
    }
    free(instTxtTab);

}


void desassemblyTest(void){

    //Run all test functions
    RUN_TEST(unsignedIntegerShouldBeConvertedToDecimalStrings);
    RUN_TEST(integerShouldBeConvertedToHexadecimalStrings);
    RUN_TEST(rTypeInstructionsShouldBeConvertedToString);
    RUN_TEST(iTypeInstructionsShouldBeConvertedToString);
    RUN_TEST(sTypeInstructionsShouldBeConvertedToString);
    RUN_TEST(bTypeInstructionsShouldBeConvertedToString);
    RUN_TEST(bTypeInstructionsWithNegativeImmediateShouldBeConvertedToString);
    RUN_TEST(uTypeInstructionsShouldBeConvertedToString);
    RUN_TEST(jTypeInstructionsShouldBeConvertedToString);
    RUN_TEST(miscTypeInstructionsShouldBeConvertedToString);
    RUN_TEST(crInstructionsShouldBeConvertedToString);
    RUN_TEST(ciInstructionsShouldBeConvertedToString);
    RUN_TEST(cssInstructionsShouldBeConvertedToString);
    RUN_TEST(ciwInstructionsShouldBeConvertedToString);
    RUN_TEST(clInstructionsShouldBeConvertedToString);
    RUN_TEST(csInstructionsShouldBeConvertedToString);
    RUN_TEST(caInstructionsShouldBeConvertedToString);
    RUN_TEST(cbInstructionsShouldBeConvertedToString);
    RUN_TEST(cjInstructionsShouldBeConvertedToString);
    RUN_TEST(instructionsShouldBeConvertedToString);
    RUN_TEST(allInstructionsShouldBeConvertedToString);
}