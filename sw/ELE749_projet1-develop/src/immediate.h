/**
 * @file immediate.h
 * @author Louis Levesque
 * @date 2021-06-19
 * @brief Contains functions required for recomposing the immediate values
 *        for given types.
 */

#ifndef IMMEDIATE_H
#define IMMEDIATE_H

#include <desassembly.h>


/**
 * @brief   This function decodes the immediate value in a I Type instruction
 *          and return it
 * @param   instruction -> The instruction in binary form
 * @return  The immediate value
 */
int32_t getITypeImmediate(uint32_t instruction);


/**
 * @brief   This function decodes the immediate value in a S Type instruction
 *          and return it
 * @param   instruction -> The instruction in binary form
 * @return  The immediate value
 */
int32_t getSTypeImmediate(uint32_t instruction);


/**
 * @brief   This function decodes the immediate value in a B Type instruction
 *          and return it
 * @param   instruction -> The instruction in binary form
 * @return  The immediate value
 */
int32_t getBTypeImmediate(uint32_t instruction);


/**
 * @brief   This function decodes the immediate value in a U Type instruction
 *          and return it
 * @param   instruction -> The instruction in binary form
 * @return  The immediate value
 */
int32_t getUTypeImmediate(uint32_t instruction);


/**
 * @brief   This function decodes the immediate value in a J Type instruction
 *          and return it
 * @param   instruction -> The instruction in binary form
 * @return  The immediate value
 */
int32_t getJTypeImmediate(uint32_t instruction);


/**
 * @brief   This function decodes the immediate value in a CI Type instruction
 *          and return it
 * @param   instruction -> The instruction in binary form
 * @return  The immediate value
 */
int32_t getCiImmediate(uint32_t instruction);


/**
 * @brief   This function decodes the immediate value in a CSS Type instruction
 *          and return it
 * @param   instruction -> The instruction in binary form
 * @return  The immediate value
 */
int32_t getCssImmediate(uint32_t instruction);


/**
 * @brief   This function decodes the immediate value in a CIW Type instruction
 *          and return it
 * @param   instruction -> The instruction in binary form
 * @return  The immediate value
 */
int32_t getCiwImmediate(uint32_t instruction);


/**
 * @brief   This function decodes the immediate value in a CL Type instruction
 *          and return it
 * @param   instruction -> The instruction in binary form
 * @return  The immediate value
 */
int32_t getClImmediate(uint32_t instruction);


/**
 * @brief   This function decodes the immediate value in a CS Type instruction
 *          and return it
 * @param   instruction -> The instruction in binary form
 * @return  The immediate value
 */
int32_t getCsImmediate(uint32_t instruction);


/**
 * @brief   This function decodes the immediate value in a CB Type instruction
 *          and return it
 * @param   instruction -> The instruction in binary form
 * @return  The immediate value
 */
int32_t getCbImmediate(uint32_t instruction);


/**
 * @brief   This function decodes the immediate value in a CJ Type instruction
 *          and return it
 * @param   instruction -> The instruction in binary form
 * @return  The immediate value
 */
int32_t getCjImmediate(uint32_t instruction);

#endif //IMMEDIATE_H