/**
 * @file procState.h
 * @author Laurent Tremblay
 * @date 2021-05-19
 * @brief Interface with the processor to access the memory,
 *        the registers and the program counter.
 */

#ifndef PROCSTATE_H
#define PROCSTATE_H


#include <stdint.h>
#include <stdio.h>
#include <stddef.h>


#define PROC_MEMSIZE 0x01000000
#define PROC_REGSIZE 16


/**
 * @brief Initialise processor state
 * pc = 0, reg = { 0 }, mem = { 0 }
 * After first call, all subsequent calls will reinitialize
 * the processor's registers and memory
 */
int procInit(void);


 /**
 * @brief Frees and resets the ressources allocated by proc_init
 */
void procDestroy(void);


/**
 * @brief Writes a value to the register
 *
 * @param reg register to write to
 * @param val value to write to the register
 * @return the value written to the register, 0 in case of invalid reg
 */
int32_t procWriteReg(uint8_t reg,
                     int32_t val);



/**
 * @brief Reads the register value and returns it.
 *
 * @param reg register to read from
 * @return the value in the register, 0 if reg is invalid
 */
int32_t procReadReg(uint8_t reg);


/**
 * @brief Writes a data_size byte value in memory from a starting addr
 *
 * @param addr the address to write to
 * @param data an array of byte containing the values
 *          to write in the memory
 * @param n the size in bytes of the data to be written
 * @return The number of bytes written in memory
 */
uint32_t procWriteMem(uint32_t addr,
                      void *data,
                      size_t n);


/**
 * @brief Reads a n byte value in memory from a starting addr
 *
 * @param addr the address to write to
 * @param data an array of byte containing the values
 *          to write in the memory
 * @param n the size in bytes of the data to be written
 * @return the number of bytes read from memory
 */
uint32_t procReadMem(uint32_t addr,
                     void *data,
                     size_t n);


/**
 * @brief Returns the value of the program counter
 *
 * @return the program counter
 */
uint32_t procGetPC(void);


/**
 * @brief Sets the new value of the program counter
 *
 * @param new_pc the new value of the program counter
 * @return the value written to the program counter
 */
uint32_t procSetPC(uint32_t new_pc);


/**
 * @brief Updates the pc according to the specified offset
 *
 * @param offset offset to add to the PC
 * @return the value written to the program counter
 */
uint32_t procUpdatePC(int32_t offset);


/**
 * @brief Get the pointer to the processor's memory.
 * The size of the memory is defined by the constant PROC_MEMSIZE
 * This access to memory should be only used as a way to quickly dump memory
 *
 * @return The first address of the processor's memory
 */
const uint8_t *procGetMem(void);


/**
 * @brief Get the pointer to the processor's registers.
 * The number of registers is defined by the constant PROC_REGSIZE
 * This access to the registers should be only used as a way to quickly dump the
 * values stored inside them.
 *
 * @return The first address of the processor's register file
 */
const uint32_t *procGetRegs(void);


#endif //PROCSTATE_H