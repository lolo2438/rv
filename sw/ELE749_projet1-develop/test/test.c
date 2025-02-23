/**
 * @file test.c
 * @brief header file for the test suite. contains the functions
 *        pointing to each module's tests
 */

#include "test.h"


void setUp(void)
{
    // set stuff up here
    procInit();
    programInit(PROGRAM_FILE_TEST);
	
}


void tearDown(void)
{
  
    // clean stuff up here
    procDestroy();
    programDestroy();
	
}


void suiteSetUp(void)
{
    //add code to be set a beginning of test suite
}


int suiteTearDown(int num_failures)
{
	
    //add code to be teared down at the end of the test suite
    return num_failures;
	
}


void test_suite(void)
{
	
    procStateTest();
    printTest();
    desassemblyTest();
    progReaderTest();
    instructionsRV32ETest();
    instructionsRV32CTest();
	
}


int main(void)
{
	
    UNITY_BEGIN();
    test_suite();
    return UNITY_END();
	
}