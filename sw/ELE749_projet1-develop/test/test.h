/**
 * @file test.h
 * @brief header file for the test suite. contains the functions
 *        pointing to each module's tests
 */

#ifndef TEST_H
#define TEST_H

#include "unity/unity.h"

#include <procState.h>
#include <print.h>
#include <RV32E.h>
#include <desassembly.h>
#include <immediate.h>
#include <print.h>
#include <progReader.h>
#include <common.h>

#include <instructionsRV32E.h>
#include <instructionsRV32C.h>
#include <stdint.h>
#include <stddef.h>


//add x12 x6 x7
#define ADD_X12_X6_X7 0x00730633

//addi x11 x11 1
#define ADDI_X11_X11_1 0x00158593

//SB x24 1234(X15)
#define SB_X24_1234_X15_ 0x4D878923

//BEQ x0 x0 -16
#define BEQ_X0_X0_N16 0xfe0008e3

//BEQ x5 x0 16
#define BEQ_X5_X0_16 0x00028863

//AUIPC x11 0x400
#define AUIPC_X11_0X400 0x00400597

//JAL x1 0x14
#define JAL_X0_0X30 0x0200006f

//ECALL
#define ECALL 0x00000073


//C.EBREAK
#define C_EBREAK 0x9002

//C.ADD x4 x14
#define C_ADD_X4_X14 0x923A

//C.ADDI x15 7
#define C_ADDI_X15_7 0x079D

//C.LI x5 8
#define C_LI_X5_8 0x42A1

//C.SWSP x16 0x18(x2)
#define C_SWSP_X16_0x18_x2_ 0xCC42


//C.ADDI4SPN x8 x2 0x24
#define C_ADDI4SPN_X8_X2_0X24 0x1040


//C.LW x12 0x64(x8)
#define C_LW_X12_0X64_X8 0x5070

//C.SW x15 0x3C(x10)
#define C_SW_X15_0X3C_X10 0xDD5C

//C.AND x9 x11
#define C_AND_X9_X11 0x8CED

//C.ANDI x14 21
#define C_ANDI_X14_21 0x8B55

//C.BEQZ x12 -40
#define C_BEQZ_X12_N40 0xDE61

//C.JAL 48
#define C_JAL_48 0x201D

//Program file name for the test cases.
#define PROGRAM_FILE_TEST "../../strlen_bin.txt"


void procStateTest(void);


void printTest(void);


void desassemblyTest(void);


void immediateTest(void);


void simulatorTest(void);


void progReaderTest(void);


void instructionsRV32ETest(void);


void instructionsRV32CTest(void);


#endif //SIMULATEUR_TEST_H
