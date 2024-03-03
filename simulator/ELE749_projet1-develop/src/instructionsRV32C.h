/**
 * @file instructionsRV32C.h
 * @author Alexis Laframboise
 * @date 2021-06-12
 * @brief Implementation of every required "C" instructions.
 *        Mainly uses the RV32E implementation, maps the registers and data.
 */

#ifndef INSTRUCTION_RV32E_H
#define INSTRUCTION_RV32E_H

#include <stdio.h>
#include <stdlib.h>
#include <RVC.h>
#include <procState.h>
#include <decoder.h>
#include <instructionsRV32E.h>
#include <common.h>


// The shift for rs1', rs2' and rd' fields of the CIW, CL, CS, CA and CB
// formats.
#define RP_SHIFT(x) (x + 8)


/**
 * Load and store instructions
 */
/**
* @brief Loads a 32-bit word from mem[4 * imm + SP] into rd.
*
* @param *data All the information contained in the cIType : funct3, imm, rd
*         and opcode.
*/
void cLoadWordStackPointer(cIType* data);


/**
* @brief Stores the content of rs2 in memory at mem[4 * imm + SP].
*
* @param *data All the information contained in the cSSType : funct3, imm, rs2
*         and opcode.
*/
void cStoreWordStackPointer(cSSType* data);


/**
* @brief Loads a 32-bit word from mem[4 * imm + rs1'] to rd'.
*
* @param *data All the information contained in the cLType : funct3, imm,
*         rs1', rd' and opcode.
*/
void cLoadWord(cLType* data);


/**
* @brief Stores a 32-bit word from rs2' to mem[4 * imm + rs1'].
*
* @param *data All the information contained in the cSType : funct3, imm,
*         rs1', rs2' and opcode.
*/
void cStoreWord(cSType* data);


/**
 * Control transfer instructions
 */
/**
* @brief Unconditionally jump to the jumptarget.
*
* @param *data All the information contained in the cJType : funct3,
*         jumptarget, and opcode.
*/
void cJump(cJType* data);


/**
* @brief Unconditionally jump to the jumptarget and write (PC+2) into LR (x1).
*
* @param *data All the information contained in the cJType : funct3,
*         jumptarget, and opcode.
*/
void cJumpAndLink(cJType* data);


/**
* @brief Unconditionally jump to the address in rs1.
*
* @param *data All the information contained in the cRType : funct3, rdRs1, rs2,
*         and opcode.
*/
void cJumpRegister(cRType* data);


/**
* @brief Unconditionally jump to the address in rs1 and write (PC+2) into LR
*         (x1).
*
* @param *data All the information contained in the cRType : funct3, rdRs1, rs2,
*         and opcode.
*/
void cJumpAndLinkRegister(cRType* data);


/**
* @brief Branch to PC+imm if the value in rs1' is equal to 0.
*
* @param *data All the information contained in the cBType : funct3, imm, rs1'
*         and opcode.
*/
void cBranchOnEqualZero(cBType* data);


/**
* @brief Branch to PC+imm if the value in rs1' is not equal to 0.
*
* @param *data All the information contained in the cBType : funct3, imm, rs1'
*         and opcode.
*/
void cBranchNotEqualZero(cBType* data);


/**
 * Integer computational instructions
 *
 * Integer constant-generation instructions
 */
/**
* @brief Loads the immediate value in rd.
*
* @param *data All the information contained in the cIType : funct3, imm, rd
*         and opcode.
*/
void cLoadImmediate(cIType* data);


/**
* @brief Loads the immediate value shifted left 12 times in rd.
*
* @param *data All the information contained in the cIType : funct3, imm, rd
*         and opcode.
*/
void cLoadUpperImmediate(cIType* data);


/**
 * Integer register-immediate operations
 */
/**
* @brief Adds the content of imm to rd and puts it in rd.
*
* @param *data All the information contained in the cIType : funct3, imm, rd
*         and opcode.
*/
void cAddImmediate(cIType* data);


/**
* @brief Adds the sign extended imm (multiple 16) to the SP (x2).
*
* @param *data All the information contained in the cIType : funct3, imm, rd
*         and opcode.
*/
void cAddi16StackPointer(cIType* data);


/**
* @brief Adds the sign extended imm (multiple 4) to the SP (x2).
*
* @param *data All the information contained in the cIWType : funct3, imm, rd'
*         and opcode.
*/
void cAddi4StackPointer(cIWType* data);


/**
* @brief Shifts rd left by a shift amount specified in imm.
*
* @param *data All the information contained in the cIType : funct3, imm, rd
*         and opcode.
*/
void cShiftLeftLogicalImmediate(cIType* data);


/**
* @brief Shifts rs1' right by a shift amount specified in imm.
*
* @param *data All the information contained in the cBType : funct3, imm, rs1'
*         and opcode.
*/
void cShiftRightLogicalImmediate(cBType* data);


/**
* @brief Shifts rs1' right by a shift amount specified in imm.
*
* @param *data All the information contained in the cBType : funct3, imm, rs1'
*         and opcode.
*/
void cShiftRightArithmeticImmediate(cBType* data);


/**
* @brief Does an And operation on rs1' and imm and puts the result in rs1'.
*
* @param *data All the information contained in the cBType : funct3, imm, rs1'
*         and opcode.
*/
void cAndImmediate(cBType* data);


/**
 * Integer register-register operations
 */
/**
* @brief Copies the value in rs2 to rd.
*
* @param *data All the information contained in the cRType : funct3, rdRs1, rs2,
*         and opcode.
*/
void cMove(cRType* data);


/**
* @brief Adds the content of rs2 to rd.
*
* @param *data All the information contained in the cRType : funct3, rdRs1, rs2,
*         and opcode.
*/
void cAdd(cRType* data);


/**
* @brief Does an And between rs2' and rs1' and puts the result in rs1' (rd).
*
* @param *data All the information contained in the cAType : funct6, funct2,
*         rs1', rs2' and opcode.
*/
void cAnd(cAType* data);


/**
* @brief Does an Or between rs2' and rs1' and puts the result in rs1' (rd).
*
* @param *data All the information contained in the cAType : funct6, funct2,
*         rs1', rs2' and opcode.
*/
void cOr(cAType* data);


/**
* @brief Does a Xor between rs2' and rs1' and puts the result in rs1' (rd).
*
* @param *data All the information contained in the cAType : funct6, funct2,
*         rs1', rs2' and opcode.
*/
void cXor(cAType* data);


/**
* @brief Subtract rs2' from rs1' and puts the result in rs1' (rd).
*
* @param *data All the information contained in the cAType : funct6, funct2,
*         rs1', rs2' and opcode.
*/
void cSub(cAType* data);

#endif //INSTRUCTION_RV32E_H
