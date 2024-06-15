/**
 * @file desassembly.h
 * @author Louis Levesque
 * @date 2021-05-23
 * @brief Contains functions required for generating the disassembly strings
 *        from the instructions value.
 */

#ifndef DESSASSEMBLY_H
#define DESSASSEMBLY_H

/* Includes ------------------------------------------------------------------*/
#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

#include <decoder.h>
#include <RVC.h>
#include <RV32E.h>
#include <instructionsRV32C.h>
#include <immediate.h>


/* Defines -------------------------------------------------------------------*/
#define CHAR_NB_BY_INST 40

#define MASK_ITYPE_IMM11_0 0xFFF00000
#define OFFSET_ITYPE_IMM11_0 20

#define MASK_STYPE_IMM4_0 0x00000F80
#define OFFSET_STYPE_IMM4_0 7

#define MASK_STYPE_IMM11_5 0xFE000000
#define OFFSET_STYPE_IMM11_5 25

#define MASK_BTYPE_IMM4_1 0x00000F00
#define OFFSET_BTYPE_IMM4_1 8

#define MASK_BTYPE_IMM10_5 0x7E000000
#define OFFSET_BTYPE_IMM10_5 25

#define MASK_BTYPE_IMM11 0x00000080
#define OFFSET_BTYPE_IMM11 7

#define MASK_BTYPE_IMM12 0x80000000
#define OFFSET_BTYPE_IMM12 31

#define MASK_UTYPE_IMM31_12 0xFFFFF000

#define MASK_JTYPE_IMM10_1 0x7FE00000
#define OFFSET_JTYPE_IMM10_1 21

#define MASK_JTYPE_IMM11 0x00100000
#define OFFSET_JTYPE_IMM11 20

#define MASK_JTYPE_IMM19_12 0x000FF000

#define MASK_JTYPE_IMM20 0x80000000
#define OFFSET_JTYPE_IMM20 31

#define MASK_SIGN_BIT 0x80000000


/*For instructions with the C extension*/
#define MASK_CR_RD 0x0F80
#define OFFSET_CR_RD 7

#define MASK_CR_RS2 0x007C
#define OFFSET_CR_RS2 2

#define MASK_CI_RD MASK_CR_RD
#define OFFSET_CI_RD OFFSET_CR_RD

#define MASK_CSS_RS2 MASK_CR_RS2
#define OFFSET_CSS_RS2 OFFSET_CR_RS2

#define MASK_CIW_RD 0x001C
#define OFFSET_CIW_RD 2

#define MASK_CL_RD MASK_CIW_RD
#define OFFSET_CL_RD OFFSET_CIW_RD

#define MASK_CL_RS1 0x0380
#define OFFSET_CL_RS1 7

#define MASK_CS_RS2 MASK_CIW_RD
#define OFFSET_CS_RS2 OFFSET_CIW_RD

#define MASK_CS_RS1 MASK_CL_RS1
#define OFFSET_CS_RS1 OFFSET_CL_RS1

#define MASK_CA_RD 0x0380
#define OFFSET_CA_RD 7

#define MASK_CA_RS2 0x001C
#define OFFSET_CA_RS2 2

#define MASK_CB_RS1 MASK_CA_RD
#define OFFSET_CB_RS1 OFFSET_CA_RD

#define OFFSET_C_RS2 2

#define MASK_CIW_IMM3 0x0020
#define OFFSET_CIW_IMM3 5

#define MASK_CIW_IMM2 0x0040
#define OFFSET_CIW_IMM2 6

#define MASK_CIW_IMM9_6 0x0780
#define OFFSET_CIW_IMM9_6 7

#define MASK_CIW_IMM5_4 0x1800
#define OFFSET_CIW_IMM5_4 11

#define MASK_CL_CS_IMM6 0x0020
#define OFFSET_CL_CS_IMM6 5

#define MASK_CL_CS_IMM5_3 0x1C00
#define OFFSET_CL_CS_IMM5_3 10

#define MASK_CL_CS_IMM2 0x0040
#define OFFSET_CL_CS_IMM2 6

#define MASK_CJ_IMM11 0x1000
#define OFFSET_CJ_IMM11 12

#define MASK_CJ_IMM10 0x0100
#define OFFSET_CJ_IMM10 8

#define MASK_CJ_IMM9_8 0x0600
#define OFFSET_CJ_IMM9_8 9

#define MASK_CJ_IMM7 0x0040
#define OFFSET_CJ_IMM7 6

#define MASK_CJ_IMM6 0x0080
#define OFFSET_CJ_IMM6 7

#define MASK_CJ_IMM5 0x0004
#define OFFSET_CJ_IMM5 2

#define MASK_CJ_IMM4 0x0800
#define OFFSET_CJ_IMM4 11

#define MASK_CJ_IMM3_1 0x0038
#define OFFSET_CJ_IMM3_1 3

#define MASK_CB_IMM8 0x1000
#define OFFSET_CB_IMM8 12

#define MASK_CB_IMM7_6 0x0060
#define OFFSET_CB_IMM7_6 5

#define MASK_CB_IMM5 0x0004
#define OFFSET_CB_IMM5 2

#define MASK_CB_IMM4_3 0x0C00
#define OFFSET_CB_IMM4_3 10

#define MASK_CB_IMM2_1 0x0018
#define OFFSET_CB_IMM2_1 3

#define MASK_CI_IMM5 0x1000
#define OFFSET_CI_IMM5 12

#define MASK_CI_IMM4_0 0x007C
#define OFFSET_CI_IMM4_0 2

#define MASK_CI_IMM7_6 0x000C
#define OFFSET_CI_IMM7_6 2

#define MASK_CI_IMM4_2 0x0070
#define OFFSET_CI_IMM4_2 4

#define MASK_ADDI16SP_IMM9 0x1000
#define OFFSET_ADDI16SP_IMM9 12

#define MASK_ADDI16SP_IMM8_7 0x0018
#define OFFSET_ADDI16SP_IMM8_7 3

#define MASK_ADDI16SP_IMM6 0x0020
#define OFFSET_ADDI16SP_IMM6 5

#define MASK_ADDI16SP_IMM5 0x0004
#define OFFSET_ADDI16SP_IMM5 2

#define MASK_ADDI16SP_IMM4 0x0040
#define OFFSET_ADDI16SP_IMM4 6

#define MASK_CSS_IMM7_6 0x0180
#define OFFSET_CSS_IMM7_6 7

#define MASK_CSS_IMM5_2 0x1E00
#define OFFSET_CSS_IMM5_2 9


/* Type definitions ----------------------------------------------------------*/


/* Function prototypes ------------------------------------------------------ */
/**
 * @brief   This function builds an array of strings of the instructions
 *          received in an array
 * @param   instTab -> An array where each element is an instruction
 *          in the binary form
 * @param   instNb -> The number of instructions found in the array "instTab"
 * @retval  An array with all the instructions taken from instTab
 *          but in text form
 */
char** buildInstTxtTab(uint32_t *instTab, int instNb);


/**
 * @brief   This function takes an instruction in its binary form and convert
 *          it to a text form (Example : 0x00730633 -> ADD x12 x6 x7)
 * @param   instruction -> An instruction in binary form
 * @return  A string that represents the instruction received
 */
char* buildInstString(uint32_t instruction);


/**
 * @brief   This function converts a RV32E instruction from a binary form to
 *          a text form
 * @param   instTxt -> The string to be modified to put the instruction
 *          in text form (This string should be already allocated)
 * @param   instruction -> The instruction in binary form
 * @return  None
 */
void buildInstStringRV32E(char *instTxt, uint32_t instruction);


/**
 * @brief   This function converts a RV32EC instruction from a binary form
 *          to a text form
 * @param   instTxt -> The string to be modified to put the instruction
 *          in text form (This string should be already allocated)
 * @param   instruction -> The instruction in binary form
 * @return  None
 */
void buildInstStringRV32EC(char *instTxt, uint32_t instruction);


/**
 * @brief   This function converts a RV32E instruction of R type from a binary
 *          form to a text form
 * @param   instTxt -> The string to be modified to put the instruction
 *          in text form (This string should be already allocated)
 * @param   instruction -> The instruction in binary form
 * @return  None
 */
void buildInstStringRv32eRtype(char* instTxt, uint32_t instruction);


/**
 * @brief   This function converts a RV32E instruction of I type from a binary
 *          form to a text form
 * @param   instTxt -> The string to be modified to put the instruction
 *          in text form (This string should be already allocated)
 * @param   instruction -> The instruction in binary form
 * @return  None
 */
void buildInstStringRv32eItype(char* instTxt, uint32_t instruction);


/**
 * @brief   This function converts a RV32E instruction of S type from a binary
 *          form to a text form
 * @param   instTxt -> The string to be modified to put the instruction
 *          in text form (This string should be already allocated)
 * @param   instruction -> The instruction in binary form
 * @return  None
 */
void buildInstStringRv32eStype(char* instTxt, uint32_t instruction);


/**
 * @brief   This function converts a RV32E instruction of B type from a binary
 *          form to a text form
 * @param   instTxt -> The string to be modified to put the instruction
 *          in text form (This string should be already allocated)
 * @param   instruction -> The instruction in binary form
 * @return  None
 */
void buildInstStringRv32eBtype(char* instTxt, uint32_t instruction);


/**
 * @brief   This function converts a RV32E instruction of U type from a binary
 *          form to a text form
 * @param   instTxt -> The string to be modified to put the instruction
 *          in text form (This string should be already allocated)
 * @param   instruction -> The instruction in binary form
 * @return None
 */
void buildInstStringRv32eUtype(char* instTxt, uint32_t instruction);


/**
 * @brief   This function converts a RV32E instruction of J type from a binary
 *          form to a text form
 * @param   instTxt -> The string to be modified to put the instruction
 *          in text form (This string should be already allocated)
 * @param   instruction -> The instruction in binary form
 * @return None
 */
void buildInstStringRv32eJtype(char* instTxt, uint32_t instruction);


/**
 * @brief   This function converts a RV32E instruction that doesn't fit
 *          in the other types from a binary form to a text form
 * @param   instTxt -> The string to be modified to put the instruction
 *          in text form (This string should be already allocated)
 * @param   instruction -> The instruction in binary form
 * @return  None
 */
void buildInstStringRv32eMisctype(char* instTxt, uint32_t instruction);


/**
 * @brief   This function converts a RV32EC of Cr Type
 *          from a binary form to a text form
 * @param   instTxt -> The string to be modified to put the instruction
 *          in text form (This string should be already allocated)
 * @param   instruction -> The instruction in binary form
 * @return  None
 */
void buildInstStringRv32eCrType(char* instTxt, uint32_t instruction);


/**
 * @brief   This function converts a RV32EC of Ci Type
 *          from a binary form to a text form
 * @param   instTxt -> The string to be modified to put the instruction
 *          in text form (This string should be already allocated)
 * @param   instruction -> The instruction in binary form
 * @return  None
 */
void buildInstStringRv32eCiType(char* instTxt, uint32_t instruction);

/**
 * @brief   This function converts a RV32EC of Css Type
 *          from a binary form to a text form
 * @param   instTxt -> The string to be modified to put the instruction
 *          in text form (This string should be already allocated)
 * @param   instruction -> The instruction in binary form
 * @return  None
 */
void buildInstStringRv32eCssType(char* instTxt, uint32_t instruction);

/**
 * @brief   This function converts a RV32EC of Ciw Type
 *          from a binary form to a text form
 * @param   instTxt -> The string to be modified to put the instruction
 *          in text form (This string should be already allocated)
 * @param   instruction -> The instruction in binary form
 * @return  None
 */
void buildInstStringRv32eCiwType(char* instTxt, uint32_t instruction);


/**
 * @brief   This function converts a RV32EC of Cl Type
 *          from a binary form to a text form
 * @param   instTxt -> The string to be modified to put the instruction
 *          in text form (This string should be already allocated)
 * @param   instruction -> The instruction in binary form
 * @return  None
 */
void buildInstStringRv32eClType(char* instTxt, uint32_t instruction);


/**
 * @brief   This function converts a RV32EC of Cs Type
 *          from a binary form to a text form
 * @param   instTxt -> The string to be modified to put the instruction
 *          in text form (This string should be already allocated)
 * @param   instruction -> The instruction in binary form
 * @return  None
 */
void buildInstStringRv32eCsType(char* instTxt, uint32_t instruction);


/**
 * @brief   This function converts a RV32EC of Ca Type
 *          from a binary form to a text form
 * @param   instTxt -> The string to be modified to put the instruction
 *          in text form (This string should be already allocated)
 * @param   instruction -> The instruction in binary form
 * @return  None
 */
void buildInstStringRv32eCaType(char* instTxt, uint32_t instruction);


/**
 * @brief   This function converts a RV32EC of Cb Type
 *          from a binary form to a text form
 * @param   instTxt -> The string to be modified to put the instruction
 *          in text form (This string should be already allocated)
 * @param   instruction -> The instruction in binary form
 * @return  None
 */
void buildInstStringRv32eCbType(char* instTxt, uint32_t instruction);


/**
 * @brief   This function converts a RV32EC of Cj Type
 *          from a binary form to a text form
 * @param   instTxt -> The string to be modified to put the instruction
 *          in text form (This string should be already allocated)
 * @param   instruction -> The instruction in binary form
 * @return  None
 */
void buildInstStringRv32eCjType(char* instTxt, uint32_t instruction);


/**
 * @brief   This function converts a signed or unsigned 32 bits value
 *          to a string of the equivalent value in decimal
 * @param   l -> The value to be converted (This parameter is a int32_t
 *          but it can also be a uint32_t if you put 1 in the 3rd parameter)
 * @param   s -> The string who will receive the decimal value
 * @param   isUnsigned -> 0 if the value to be converted is signed
 *          and 1 if it is unsigned
 * @return  The number of character added to the string s
 */
uint8_t longToDec(int32_t l, char* s, uint8_t isUnsigned);


/**
 * @brief   This function converts an unsigned 32 bits value
 *          to a string of the equivalent value in hexadecimal
 * @param   l -> The value to be converted
 * @param   s -> The string who will receive the hexadecimal value
 * @return  The number of character added to the string s
 */
uint8_t hexStr(uint32_t l, char* s);

#endif //DESSASSEMBLY_H