/**
 * @file common.h
 * @brief Contains common definitions for the project
 */

#ifndef COMMON_H
#define COMMON_H

#define GET_ARRAY_SIZE(array) ((sizeof(array)) / \
                                (sizeof(*(array))))

#define BUFFER_LEN 200

#define IS_LITTLE_ENDIAN (*(uint8_t *)&(uint16_t){1})


// Proc register numbers.
#define X0 0
#define X1 1
#define X2 2
#define X3 3
#define X4 4
#define X5 5
#define X6 6
#define X7 7
#define X8 8
#define X9 9
#define X10 10
#define X11 11
#define X12 12
#define X13 13
#define X14 14
#define X15 15


// Proc control register acronyms.
#define LR X1
#define SP X2


// ERRORS
#define EPROGRAM 3
#define EALLOC 420
#define EFILE 69
#define EARG 0xDEADBEEF

#endif //COMMON_H