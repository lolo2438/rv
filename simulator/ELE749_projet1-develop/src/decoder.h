/**
 * @file decoder.h
 * @author Guyaume Morand
 * @brief: Instruction decoder header
 */

#ifndef DECODER_H
#define DECODER_H

#include <stdint.h>
#include "RV32E.h"
#include "RVC.h"
#include "instructionsRV32E.h"
#include "immediate.h"


typedef enum instructionSetsE
{
    BAD_FORMAT = -1,
    RV32E,
    RVC,
}instructionSets;


/**
 * @brief   This function returns the instruction set
 * @param   instruction -> An instruction in binary form
 * @return  RV32E or RVC depending on the instruction type
 */
instructionSets decodeInstructionLength(uint32_t instruction);


/**
 * @brief   This function returns instruction data type
 * @param   instruction -> An instruction in binary form
 * @return  rv32eInstructionTypes or rv32cInstructionTypes item
 */
int decodeInstructionType(uint32_t instruction);


/**
 * @brief   This function returns instruction
 * @param   instruction -> An instruction in binary form
 * @return  rv32eBaseInstructions or cInstructions item
 */
int decodeInstruction(uint32_t instruction);


/**
 * @brief   This function calls the correct function based on the instruction
 * @param   instruction -> An instruction in binary form
 * @return  0
 */
int runInstruction(uint32_t instruction);

#endif //DECODER_H
