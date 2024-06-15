/**
 * @file debugger.h
 * @author Laurent Tremblay
 * @date 2021-06-16
 * @brief The interface for the RISCV32EC debugger
 */
#ifndef DEBUGGER_H
#define DEBUGGER_H

enum debuggerBaseCmd {
    BREAK,
    JUMP,
    DELETE,
    DISABLE,
    ENABLE,
    PRINT,
    DUMP,
    STEP,
    CONTINUE,
    HELP,
    EXIT,
    WRITE,
    NOT_A_CMD
};


/**
 * @fn debuggerRun
 * @brief Executes the debugger runtime:
 *        Asks the user for a command and loop
 *        until either a step, continue or exit command
 *        has been executed.
 */
void debuggerRun(void);


/**
 * @fn debuggerCmdParser
 * @brief Reads a string containing a command for the debugger and
 *        executes it if it is valid.
 *
 * @note Use debuggerRun function unless you need to specify a command directly
 *       to the debugger at compile time.
 *
 * @param cmdStr The command to execute
 * @return The command executed
 */
enum debuggerBaseCmd debuggerCmdParser(const char *cmdStr);

#endif //DEBUGGER_H