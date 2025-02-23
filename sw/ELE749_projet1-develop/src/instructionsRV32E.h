/**
 * @file instructionsRV32E.h
 * @author Mathieu Nadeau
 * @date 2021-05-19
 * @brief Implements all the RV32E instructions
 */

#ifndef INSTRUCTION_RVC_H
#define INSTRUCTION_RVC_H


#include <stdio.h>
#include <stdlib.h>
#include <RV32E.h>
#include <procState.h>
#include <decoder.h>


/*********************
 * Loads instructions
 *********************/
/**
 * @brief Load a Byte from the memory to a register
 *
 * @param *data All the information needed to do the transfer
 *          between the memory and the register
 */
void loadByte (iType *data);


/**
 * @brief Load a Halfword from the memory to a register
 *
 * @param *data All the information needed to do the transfer
 *          between the memory and the register
 */
void loadHalfword (iType *data);


/**
 * @brief Load a Word from the memory to a register
 *
 * @param *data All the information needed to do the transfer
 *          between the memory and the register
 */
void loadWord (iType *data);


/**
 * @brief Load a Unsigned Byte from the memory to a register
 *
 * @param *data All the information needed to do the transfer
 *          between the memory and the register
 */
void loadByteUnsigned (iType *data);


/**
 * @brief Load a Unsigned Halfword from the memory to a register
 *
 * @param *data All the information needed to do the transfer
 *          between the memory and the register
 */
void loadHalfUnsigned (iType *data);


/*********************
 * Store instructions
 *********************/
/**
 * @brief Store a Byte from a register to the memory
 *
 * @param *data All the information needed to do the transfer
 *          between the memory and the register
 */
void storeByte (sType *data);


/**
 * @brief Store a Halfword from a register to the memory
 *
 * @param *data All the information needed to do the transfer
 *          between the memory and the register
 */
void storeHalfword (sType *data);


/**
 * @brief Store a Word from a register to the memory
 *
 * @param *data All the information needed to do the transfer
 *          between the memory and the register
 */
void storeWord (sType *data);


/**********************
 * Shifts instructions
 **********************/
/**
 * @brief Shift left the value of the register rs1 by the value of
 *          the register rs2
 *
 * @param *data All the information needed to do the operation Shift
 */
void shiftLeft (rType *data);


/**
 * @brief Shift left the value of the register rs1 by the value of
 *          an Immediate
 * @param *data All the information needed to do the operation Shift
 */
void shiftLeftImmediate (iType *data);


/**
 * @brief Shift right the value of the register rs1 by the value of
 *          the register rs2
 *
 * @param *data All the information needed to do the operation Shift
 */
void shiftRight (rType *data);


/**
 * @brief Shift right the value of the register rs1 by the value of
 *          an Immediate
 * @param *data All the information needed to do the operation Shift
 */
void shiftRightImmediate (iType *data);


/**
 * @brief Shift right the value of the register rs1 by the value of
 *          the register rs2 but keeps the signed of rs1
 * @param *data All the information needed to do the operation Shift
 */
void shiftRightArithmetic (rType *data);


/**
 * @brief Shift right the value of the register rs1 by the value of
 *          an Immediate but keeps the signed of rs1
 * @param *data All the information needed to do the operation Shift
 */
void shiftRightArithImm (iType *data);


/**************************
 * Arithmetic instructions
 **************************/

/**
 * @brief add the value of the register rs1 by the value of the register rs2
 *
 * @param *data All the information needed to do the Arithmetic operation
 */
void add (rType *data);


/**
 * @brief add the value of the register rs1 by the value of an Immediate
 *
 * @param *data All the information needed to do the Arithmetic operation
 */
void addImmediate (iType *data);


/**
 * @brief Substract the value of the register rs1 by the value of
 *          the register rs2
 *
 * @param *data All the information needed to do the Arithmetic operation
 */
void sub (rType *data);


/**
 * @brief Put an Immediate into the upper 20-bit of a 32-bit
 *          and put the lower 12-bit to zero
 *
 * @param *data All the information needed to do the Arithmetic operation
 */
void loadUpperImm (uType *data);


/**
 * @brief Put an Immediate into the upper 20-bit of a 32-bit
 *          and put the lower 12-bit to zero. Add this value
 *          to the current value of PC
 *
 * @param *data All the information needed to do the Arithmetic operation
 */
void addUpperImmToPC (uType *data);


/***********************
 * Logical instructions
 ***********************/

/**
 * @brief Do the operation XOR between the value of the register rs1 and rs2
 *
 * @param *data All the information needed to do the Logical operation
 */
void xor (rType *data);


/**
 * @brief Do the operation XOR between the value of the register rs1
 *          and Immidiate
 *
 * @param *data All the information needed to do the Logical operation
 */
void xorImmediate (iType *data);


/**
 * @brief Do the operation OR between the value of the register rs1 and rs2
 *
 * @param *data All the information needed to do the Logical operation
 */
void or (rType *data);


/**
 * @brief Do the operation OR between the value of the register rs1
 *          and Immidiate
 *
 * @param *data All the information needed to do the Logical operation
 */
void orImmediate (iType *data);


/**
 * @brief Do the operation AND between the value of the register rs1 and rs2
 *
 * @param *data All the information needed to do the Logical operation
 */
void and (rType *data);


/**
 * @brief Do the operation AND between the value of the register rs1
 *          and Immediate
 *
 * @param *data All the information needed to do the Logical operation
 */
void andImmediate (iType *data);


/**********************
 * Compare instructions
 **********************/
/**
 * @brief Compare if the value of the register rs1 is lower than the
 *          the value of the register rs2
 *
 * @param *data All the information needed to do the compare instruction
 */
void setLessThan (rType *data);


/**
 * @brief Compare if the value of the register rs1 is lower than the
 *          the value of an Immediate
 *
 * @param *data All the information needed to do the compare instruction
 */
void setLessThanImmediate (iType *data);


/**
 * @brief Compare if the absolute value of the register rs1 is lower
 *          than the absolute value of the register rs2
 *
 * @param *data All the information needed to do the compare instruction
 */
void setLessThanUnsigned (rType *data);


/**
 * @brief Compare if the absolute value of the register rs1 is lower
 *          than the absolute value of an Immediate
 *
 * @param *data All the information needed to do the compare instruction
 */
void setLessThanImmediateUnsigned (iType *data);


/**********************
 * Branch instructions
 **********************/
/**
 * @brief Compare if the value of the register rs1 is equal
 *          to the value of the register rs2
 *
 * @param *data All the information needed to do the branch instruction
 */
void branchEqual (bType *data);


/**
 * @brief Compare if the value of the register rs1 is not equal
 *          to the value of the register rs2
 *
 * @param *data All the information needed to do the branch instruction
 */
void branchNotEqual (bType *data);


/**
 * @brief Compare if the value of the register rs1 is lower
 *          than the value of the register rs2
 *
 * @param *data All the information needed to do the branch instruction
 */
void branchLessThan (bType *data);


/**
 * @brief Compare if the value of the register rs1 is higher
 *          than the value of the register rs2
 *
 * @param *data All the information needed to do the branch instruction
 */
void branchMoreOrEqual (bType *data);


/**
 * @brief Compare if the absolute value of the register rs1 is lower
 *          than the absolute value of the register rs2
 *
 * @param *data All the information needed to do the branch instruction
 */
void branchLessThanUnsigned (bType *data);


/**
 * @brief Compare if the absolute value of the register rs1 is higher
 *          than the absolute value of the register rs2
 *
 * @param *data All the information needed to do the branch instruction
 */
void branchMoreOrEqualUnsigned (bType *data);


/**************************
 * Jump & Link instructions
 **************************/
/**
 * @brief Use the Immediate to offset the PC's value
 *          and keeps the current PC+4 in the register rd
 *
 * @param *data All the information needed to do the J&L instruction
 */
void jumpAndLink (jType *data);


/**
 * @brief Use the value of the register rs1 to set the PC's value
 *          and keeps the current PC+4 in the register rd
 *
 * @param *data All the information needed to do the J&L instruction
 */
void jumpAndLinkRegister (iType *data);


/**
 * @fn ecall
 * @brief Stops the simulator by setting the state to SIMULATOR_STOP
 */
void ecall(void);


/**
 * @fn ebreak
 * @brief Gives control to the debugging environment
 */
void ebreak(void);

#endif //INSTRUCTION_RVC_H