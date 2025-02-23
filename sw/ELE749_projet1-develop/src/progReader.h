/**
 * File: prog_reader.h
 * Author: Alexis Laframboise
 * Date : 2021-05-19
 * Description:
 * Reads the program file and hold its content in a struct for future use.
 */

#ifndef PROGREADER_H
#define PROGREADER_H


#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>


/*
 * Convenience definitions
 */
#define ENCODING_BITS       16
#define HEX_BITS_PER_CHAR   4
#define BITS_PER_BYTE       8


/*
 * Types definitions
 */
typedef struct{
    char* progName;
    uint32_t instCnt;
    uint32_t* instArr;
    char** instStrArr;
    uint8_t* instLenArr;
}programFileT;


/*
 * Function declarations
 */
/**
 * @fn programInit
 * @brief   This function reads the program file corresponding to the file
 *          name passed as parameter.
 *
 * @param   programFileName   -> program file name, a .txt file.
 * @return  error code.       -> 0 good, 1 bad.
 */
uint8_t programInit(const char* programFileName);


/**
 * @fn programDestroy
 * @brief   This function frees the struct created by programInit and its
 * content.
 */
void programDestroy(void);


/**
 * @fn getInstCnt
 *  This function returns the count of instructions in the program.
 *
 * @return  the count of instructions.
 */
uint32_t getInstCnt(void);


/**
 * @fn getInstArr
 * @brief   This function returns to its user a pointer to the table of instructions.
 *
 * @return  a table of numerical values, the program instructions.
 */
uint32_t* getInstArr(void);


/**
 * @fn getInstStrArr
 * @brief   This function returns to its user a pointer to a table of strings.
 *
 * @return  a table of strings  -> the program instructions.
 */
char** getInstStrArr(void);


/**
 * @fn getInstLenArr
 * @brief   This function returns to its user a pointer to a table of strings.
 *
 * @return  a table of uint8_t  -> the bytes count of each instruction in instArr.
 */
 uint8_t* getInstLenArr(void);


#endif //PROGREADER_H
