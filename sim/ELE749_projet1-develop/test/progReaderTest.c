/**
 * @file procReaderTest.c
 * @author Alexis Laframboise
 * @date 2021-06-06
 * @brief Unit test for the module progReader
 */
 
 
#include "test.h"


void progInstShouldMatchInstStr(uint32_t inst, char* instStr)
{

    TEST_ASSERT_EQUAL_UINT32(inst, strtoll(instStr, NULL, ENCODING_BITS));
	
}


void InstArrAndInstArrStrShouldMatch(void)
{

    uint32_t instCnt = getInstCnt();
    uint32_t* instArr = getInstArr();
    char** instStrArr = getInstStrArr();

    for (int i = 0; i < instCnt; i++) {
        progInstShouldMatchInstStr(instArr[i], instStrArr[i]);
    }
	
}


void progReaderTest(void)
{

    RUN_TEST(InstArrAndInstArrStrShouldMatch);
	
}