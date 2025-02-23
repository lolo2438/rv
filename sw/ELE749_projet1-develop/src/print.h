/**
 * @file print.h
 * @author Laurent Tremblay
 * @date 2021-05-29
 * @brief Utility printing functions to output the status of the processor
 *        to a user
 */

#ifndef PRINT_H
#define PRINT_H


#include <stdint.h>


#define PRJ_NAME "Simulateur RISC-V RV32EC"

#define COPYRIGHT "(C) 2021"

#define NB_REG_PER_LINE 4


/**
 * @brief prints the name of the project,
 *        the copyright and the authors
 */
void printHeader(void);


/**
 * @brief Prints the instructions in its hexadecimal form
 *        alongside it's dissassembled form
 *
 * @param inst the instruction to be printed
 */
void printInstruction(uint32_t inst);


/**
 * @brief Prints the value inside theregisters to the screen
 *        Replaces the register 0 with PC since x0 always = 0
 */
void printRegisters(void);


/**
 * @brief prints the memory from startAddress to endAddress
 *
 * @param fileName register to read from
 * @param startAddress the first address in memory to print
 * @param endAddress the last address in memory to print
 *
 * @return 0 on success,
 *         -EARG if startAddress > endAddress and endAddress > PROC_MEMSIZE
 *         -EFILE if file could not be opened
 */
int printMemory(const char *fileName, uint32_t startAddress, uint32_t endAddress);


#endif //PRINT_H