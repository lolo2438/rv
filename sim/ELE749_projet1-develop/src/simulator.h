/**
 * @file simulator.h
 * @author Laurent Tremblay
 * @date 2021-06-04
 * @brief: Interface to the main simulator loop
 */

#ifndef SIMULATOR_H
#define SIMULATOR_H


#include <stdint.h>
#include <decoder.h>


struct instruction {
    uint32_t inst;
    rv32eBaseInstructions decodedInst;
    rv32eInstructionTypes instType;
    instructionSets instExt;
};


enum simulatorState {
    SIMULATOR_RUN,
    SIMULATOR_STOP
};


enum simulatorExecMode {
    SIMULATOR_STEP,
    SIMULATOR_CONTINUE
};


/**
 * @fn simulatorInit
 * @brief initialises the simulator
 * @note On failure to initialise the processor, the program will exit
 *       with -EPROGRAM exit code
 */
void simulatorInit(void);


/**
 * @fn simulatorRun
 * @brief runs the simulator until simulatorState = SIMULATOR_STOP
 * @note Update the state of the simulator using the @fn simulatorSetState
 */
void simulatorRun(void);


/**
 * @fn simulatorDestroy
 * @brief Clears any leftover resources created by the simulator
 * @return The exit code of the simulator
 */
int simulatorDestroy(void);


/**
 * @fn simulatorFetch
 * @brief Fetches the instruction at address PC and stores it internally
 *        in the simulator
 * @return the instruction fetched by the simulator
 */
uint32_t simulatorFetch(void);


/**
 * @fn simulatorDecode
 * @brief Decodes the specified and stores it internally in the simulator
 * @param inst the instruction to be decoded
 */
void simulatorDecode(uint32_t inst);


/**
 * @fn simulatorExecute
 * @brief Executes the instruction that was fetched and decoded by
 *        @fn simulatorFetch and @fn simulatorDecode
 */
void simulatorExecute(void);


/**
 * @fn simulatorSetState
 * @brief Sets the internal processor state
 *        SIMULATOR_RUN: run the simulator
 *        SIMULATOR_STOP: stops the simulator
 *
 * @param state the state to specify, values other than SIMULATOR_RUN and
 *        SIMULATOR_STOP will cause undefined behavior.
 */
void simulatorSetState(enum simulatorState state);


/**
 * @fn simulatorSetExecMode
 * @brief Sets the internal execution mode of the simulator
 *        SIMULATOR_STEP: Step through every instructions
 *        SIMULATOR_CONTINUE: Continuous execution
 *
 * @param mode the state to specify, values others that
 *        SIMULATOR_STEP and SIMULATOR_CONTINUE will cause undefined behavior.
 */
void simulatorSetExecMode(enum simulatorExecMode mode);


#endif //SIMULATOR_H