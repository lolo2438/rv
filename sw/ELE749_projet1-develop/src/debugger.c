/**
 * @file debugger.c
 * @author Laurent Tremblay
 * @date 2021-06-16
 * @brief Implements the debugger for the RISCV32EC simulator
 *
 * @paragraph
 * Multiple commands are offered to the user. Most of them are standard and can
 * be identified at runtime by running the "help" command.
 *
 * Commands have multiple ways to be called. For instance, calling breakpoint
 * can be achieved by writing either breakpoint, br or b followed by the address
 * of the break point.
 *
 * The way the debugger works is by storing an EBREAK instruction at the
 * address specified, and then storing the real instruction into a "breaklist"
 * which is a single linked list containing all the instructions
 *
 * The decoding of the the commands works using the principle that the enum
 * debuggerBaseCmd is essentially an index for the debuggerBaseCmdStr array
 * that contains all the possible commands.
 *
 * Adding a command works like this:
 * 1. Update the enum debuggerBaseCmd with the new command
 * 2. add your commandStr[] containing all the possible names for this command
 * 3. insert your commandStr in the debuggerBaseCmdStr at the same location that
 * it is inserted in the enum debuggerBaseCmd
 * 4. Create a function to execute your new command, format is nameCmd();
 * 5. Add the command to the switch case of the function getCmdNbNames & cmdExec
 */


#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <ctype.h>

#include "common.h"
#include "debugger.h"
#include "print.h"
#include "procState.h"
#include "decoder.h"
#include "simulator.h"
#include "desassembly.h"

#define MAX_CMD_ARG 5

#define EBREAK 0x00100073
#define C_EBREAK 0x9002


/**
 * Definition of the commands
 */
static const char *breakBaseCmdStr[] = {
        "break",
        "br",
        "b"
};


static const char *jumpBaseCmdStr[] = {
        "jump",
        "jmp",
        "j"
};


static const char *deleteBaseCmdStr[] = {
        "delete",
        "del",
        "d"
};


static const char *disableBaseCmdStr[] = {
        "disable",
        "dis"
};


static const char *enableBaseCmdStr[] = {
        "enable",
        "ena",
        "en"
};


static const char *printBaseCmdStr[] = {
        "print",
        "p"
};


static const char *dumpBaseCmdStr[] = {
        "dump",
        "dmp"
};


static const char *stepBaseCmdStr[] = {
        "step",
        "s"
};


static const char *continueBaseCmdStr[] = {
        "continue",
        "c"
};


static const char *helpBaseCmdStr[] = {
        "help",
        "h"
};


static const char *exitBaseCmdStr[] = {
        "exit",
        "stop",
        "quit",
        "q"
};


static const char *writeBaseCmdStr[] = {
        "write",
        "wr",
        "w"
};


/**
 * Must be in the same order as the debuggerBaseCmd enum
 */
static const char **debuggerBaseCmdStr[] = {
        breakBaseCmdStr,
        jumpBaseCmdStr,
        deleteBaseCmdStr,
        disableBaseCmdStr,
        enableBaseCmdStr,
        printBaseCmdStr,
        dumpBaseCmdStr,
        stepBaseCmdStr,
        continueBaseCmdStr,
        helpBaseCmdStr,
        exitBaseCmdStr,
        writeBaseCmdStr
};


/**
 * Break list containing all the break points
 */
static struct breakNode {
    struct breakNode* next;
    uint32_t addr;
    uint32_t inst;
    uint8_t instLen;
    uint8_t isEnabled;
}*breakList = { 0 };


/**
 * Global struct for the debugger
 */
static struct debuggerCmd {
    enum debuggerBaseCmd cmd;
    int argc;
    char *argv[MAX_CMD_ARG];
}debuggerCmd = { 0 };


/**
 * @brief Functions associated with their relative command
 */
static void breakCmd(void);
static void jumpCmd(void);
static void deleteCmd(void);
static void disableCmd(void);
static void enableCmd(void);
static void printCmd(void);
static void dumpCmd(void);
static void stepCmd(void);
static void continueCmd(void);
static void helpCmd(void);
static void exitCmd(void);
static void writeCmd(void);


/**
 * Local function
 */
/**
 * @fn breakNodeCreate
 * @brief creates a node and stores the instruction associated with the
 *        specified address.
 * @note It does not verify if the instruction is RV32E or RV32C.. TODO
 * @param addr the address of the instruction
 * @return A pointer to a valid breakNode structure or NULL if allocation failed
 */
static struct breakNode *breakNodeCreate(uint32_t addr)
{
    struct breakNode *newNode = malloc(sizeof(*newNode));
    if(!newNode)
        goto exit;

    uint32_t inst;
    procReadMem(addr, &inst, sizeof(inst));

    *newNode = (struct breakNode) {
            .next = NULL,
            .addr = addr,
            .inst = inst,
            .instLen = sizeof(inst),
            .isEnabled = 1
    };

    exit:
    return newNode;
}


/**
 * @fn printBreakPoints
 * @brief prints all the breakpoints in the breaklist alongside if
 *        the breakpoint is enabled or not
 */
static void breakListPrint(void)
{
    struct breakNode *node = breakList;
    while (node) {
        char *instStr = buildInstString(node->inst);
        printf("Breakpoint at address %08x: %s ", node->addr, instStr);
        if (node->isEnabled)
            printf("(enabled)\n");
        else
            printf("(disabled)\n");

        free(instStr);
        node = node->next;
    }
}


/**
 * @fn breakListAppend
 * @brief appends the node to the end of the breaklist
 * @param newNode the node to append
 */
static void breakListAppend(struct breakNode *newNode)
{
    if (breakList) {
        struct breakNode *node = breakList;

        while(node->next)
            node = node->next;

        node->next = newNode;

    } else {
        breakList = newNode;
    }
}


/**
 * @fn debuggerGetInstruction
 * @param addr an address where there is an EBREAK instruction
 * @return the instruction stored in the breaklist associated with the address
 *         or 0 if there is no breakpoint at this address
 */
static uint32_t breakListGetInstruction(uint32_t addr)
{
    struct breakNode *node = breakList;
    while(node){
        if (node->addr == addr)
            return node->inst;

        node = node->next;
    }

    return 0;
}


/**
 * @fn breakListRemove
 * @brief removes the node associated with the address from the breaklist
 * @param addr the address in memory of the instruction associated with the
 *        breakpoint
 * @return 1 Successfully removed node
 *         0 Could not remove the node
 */
static int breakListRemove(uint32_t addr)
{
    if (breakList) {
        if (breakList->addr == addr) {
            procWriteMem(addr, &breakList->inst, breakList->instLen);

            struct breakNode *freenode = breakList;
            breakList = breakList->next;
            free(freenode);

            return 1;

        } else {
            struct breakNode *node = breakList;

            while (node->next) {
                if (node->next->addr == addr) {
                    procWriteMem(addr, &node->next->inst, node->next->instLen);

                    struct breakNode *freenode = node->next;
                    node->next = node->next->next;
                    free(freenode);

                    return 1;
                }
                node = node->next;
            }
        }
    }
    return 0;
}


/**
 * @fn breakListRemoveAll
 * @brief removes all node in the breaklist
 */
static void breakListRemoveAll(void)
{
    struct breakNode *node = breakList;
    struct breakNode *next_node;

    while (node) {
        procWriteMem(node->addr, &node->inst, node->instLen);

        next_node = node->next;
        free(node);
        node = next_node;
    }
    breakList = NULL;
}


/**
 * @fn breakListDisableAll
 * @brief Disables all the breakpoints in the breaklist
 *        and places the instruction back in memory
 * @return 0 No breakpoints
 *         1 Disabled all
 */
static int breakListDisableAll(void)
{
    if (!breakList)
        return 0;

    struct breakNode *node = breakList;

    while (node) {
        node->isEnabled = 0;
        node = node->next;
    }
    return 1;
}


/**
 * @fn breakListDisable
 * @brief Disables the breakpoint at the specified address if it exists in the
 *        breaklist
 * @param addr the address
 * @return 0: The breakpoint is already enabled
 *         1: The breakpoint was disabled
 *        -1: No breakpoint found at the specified address
 */
static int breakListDisable(uint32_t addr)
{
    struct breakNode *node = breakList;

    while (node) {
        if (node->addr == addr) {
            if (!node->isEnabled)
                return 0;

            node->isEnabled = 0;
            procWriteMem(addr, &node->inst, node->instLen);

            return 1;
        }
        node = node->next;
    }
    return -1;
}


/**
 * @fn breakListEnableAll
 * @brief Enable all the breakpoints and places ebreaks at the correct address
 *        if it exists in the list
 * @return 0 No breakpoints
 *         1 Enabled all
 */
static int breakListEnableAll(void)
{
    if (!breakList)
        return 0;

    struct breakNode *node = breakList;

    while (node) {
        node->isEnabled = 1;
        node = node->next;
    }
    return 1;
}


/**
 * @fn breakListEnable
 * @brief Enables the breakpoint at the specified address if it exists in the
 *        list
 * @param addr the address of the breakpoint to enable
 * @return 0: The breakpoint is already enabled
 *         1: The breakpoint was enabled
 *        -1: No breakpoint found at the specified address
 */
static int breakListEnable(uint32_t addr)
{
    struct breakNode *node = breakList;

    while (node) {
        if (node->addr == addr) {
            if (node->isEnabled)
                return 0;

            node->isEnabled = 1;
            uint32_t eBreak = node->instLen == sizeof(uint32_t) ? EBREAK : C_EBREAK;
            procWriteMem(addr, &eBreak, node->instLen);
            return 1;
        }
        node = node->next;
    }
    return -1;
}


/**
 * @fn isAddrValid
 * @brief This functions verifies that the address specified to the debugger
 *        can be used without any problems
 * @param addr the address to verify
 * @return 0 -> invalid
 *         1 -> valid
 */
static int isAddrValid(uint32_t addr)
{
    uint32_t inst;
    procReadMem(addr, &inst, sizeof(inst));

    if (addr > PROC_MEMSIZE - 1) {
        return 0;
    } else if (addr & 0b1) {
        return 0;
    }

    return 1;
}


/**
 * @fn getNbPossibleCommands
 * @brief This function returns the number of commands associated
 * @param cmd
 * @return The number of different names the command has
 */
static unsigned int getCmdNbNames(enum debuggerBaseCmd cmd)
{
    unsigned int nbCmd;
    switch (cmd) {
        case BREAK:
            nbCmd = GET_ARRAY_SIZE(breakBaseCmdStr);
            break;

        case JUMP:
            nbCmd = GET_ARRAY_SIZE(jumpBaseCmdStr);
            break;

        case DELETE:
            nbCmd = GET_ARRAY_SIZE(deleteBaseCmdStr);
            break;

        case DISABLE:
            nbCmd = GET_ARRAY_SIZE(disableBaseCmdStr);
            break;

        case ENABLE:
            nbCmd = GET_ARRAY_SIZE(enableBaseCmdStr);
            break;

        case PRINT:
            nbCmd = GET_ARRAY_SIZE(printBaseCmdStr);
            break;

        case DUMP:
            nbCmd = GET_ARRAY_SIZE(dumpBaseCmdStr);
            break;

        case STEP:
            nbCmd = GET_ARRAY_SIZE(stepBaseCmdStr);
            break;

        case CONTINUE:
            nbCmd = GET_ARRAY_SIZE(continueBaseCmdStr);
            break;

        case HELP:
            nbCmd = GET_ARRAY_SIZE(helpBaseCmdStr);
            break;

        case EXIT:
            nbCmd = GET_ARRAY_SIZE(exitBaseCmdStr);
            break;

        case WRITE:
            nbCmd = GET_ARRAY_SIZE(writeBaseCmdStr);
            break;

        default:
            nbCmd = 0;
    }
    return nbCmd;
}


/**
 * @fn cmdExec
 * @brief Executes the command specified in the struct debuggerCmd
 * @return The command that was executed
 */
static enum debuggerBaseCmd cmdExec(void)
{
    switch (debuggerCmd.cmd) {
        case BREAK:
            breakCmd();
            break;

        case JUMP:
            jumpCmd();
            break;

        case DELETE:
            deleteCmd();
            break;

        case DISABLE:
            disableCmd();
            break;

        case ENABLE:
            enableCmd();
            break;

        case PRINT:
            printCmd();
            break;

        case DUMP:
            dumpCmd();
            break;

        case STEP:
            stepCmd();
            break;

        case CONTINUE:
            continueCmd();
            break;

        case HELP:
            helpCmd();
            break;

        case EXIT:
            exitCmd();
            break;

        case WRITE:
            writeCmd();

        case NOT_A_CMD:
            break;
    }

    return debuggerCmd.cmd;
}


/**
 * BREAK COMMAND:
 * @brief creates a breakpoint and stores it at the specified address with the
 *        EBREAK instruction.
 */
static void breakCmd(void)
{
    if (debuggerCmd.argc < 2) {
        printf("Error: not enough arguments\n");
        return;
    }

    uint32_t addr = strtol(debuggerCmd.argv[1], NULL, 16);

    if (!isAddrValid(addr)) {
        printf("Invalid address specified\n");
        return;
    }

    if(breakListGetInstruction(addr)) {
        printf("There is already a breakpoint at address %08x\n", addr);
        return;
    }

    struct breakNode *newNode = breakNodeCreate(addr);
    if(!newNode){
        printf("Out of memory\n");
        return;
    }

    uint32_t eBreak;
    switch (decodeInstructionLength(newNode->inst)) {
        case RV32E:
            eBreak = EBREAK;
            procWriteMem(newNode->addr, &eBreak, newNode->instLen);
            break;

        case RVC:
            newNode->inst &= 0x0000FFFF;
            newNode->instLen = sizeof(uint16_t);
            eBreak = C_EBREAK;
            procWriteMem(newNode->addr, &eBreak, newNode->instLen);
            break;

        case BAD_FORMAT:
            printf("Invalid instruction\n");
            free(newNode);
            return;
    }

    breakListAppend(newNode);

    printf("Added breakpoint at address: %08x\n", newNode->addr);
}


/**
 * JUMP COMMAND:
 * @brief Jump to specified address by setting the PC accordingly.
 *        Updates the simulator instructions to the ones at the new location.
 */
static void jumpCmd(void)
{
    if (debuggerCmd.argc < 2) {
        printf("Error: not enough arguments\n");
        return;
    }

    uint32_t addr = strtol(debuggerCmd.argv[1], NULL, 16);

    if(!isAddrValid(addr)) {
        printf("Invalid address specified\n");
        return;
    }

    procSetPC(addr);
    simulatorDecode(simulatorFetch());
    printf("Jumped to address %08x\n", addr);
}


/**
 * DELETE COMMAND:
 * @brief Removes the breakpoint associated with the specified address
 *        and writes back the instruction to memory.
 *        If all is specified, all breakpoints are removed.
 *        --q for quiet deletion of "all" option
 */
static void deleteCmd(void)
{
    if (debuggerCmd.argc < 2){
        printf("Error: not enough arguments\n");
        return;
    }

    if (strcmp(debuggerCmd.argv[1], "all") == 0) {

        breakListRemoveAll();

        if (debuggerCmd.argc == 3)
            if (strcmp(debuggerCmd.argv[2], "--q") == 0)
                return;

        printf("All breakpoints removed\n");

    } else {
        uint32_t addr = strtol(debuggerCmd.argv[1], NULL, 16);

        if (breakListRemove(addr))
            printf("Removed breakpoint at address %08x\n", addr);
        else
            printf("No breakpoint at address %08x\n", addr);
    }
}


/**
 * DISABLE COMMAND:
 * @brief Puts the instruction in memory, but keeps the breakNode. Sets the
 *        break node to disabled
 */
static void disableCmd(void)
{
    if (debuggerCmd.argc != 2) {
        printf("Error: not enough arguments\n");
        return;
    }

    if (strcmp(debuggerCmd.argv[1], "all") == 0) {
        if (breakListDisableAll())
            printf("All breakpoints disabled\n");
        else
            printf("No breakpoints found\n");

    } else {
        uint32_t addr = strtol(debuggerCmd.argv[1], NULL, 16);

        switch(breakListDisable(addr)){
            case 0:
                printf("Breakpoint at address %08x is already disabled!\n", addr);
                break;
            case 1:
                printf("Disabled breakpoint at address %08x\n", addr);
                break;
            case -1:
                printf("No breakpoint found at address %08x\n", addr);
                break;
        }
    }
}


/**
 * ENABLE COMMAND
 * @brief Puts back the ebreak in memory from the breakList and enables the
 *        breakpoint in the breaklist
 */
static void enableCmd(void)
{
    if (debuggerCmd.argc != 2) {
        printf("Error: not enough arguments\n");
        return;
    }

    if (strcmp(debuggerCmd.argv[1], "all") == 0) {
        if (breakListEnableAll())
            printf("All breakpoints enabled\n");
        else
            printf("No breakpoints found\n");

    } else {
        uint32_t addr = strtol(debuggerCmd.argv[1], NULL, 16);

        switch(breakListEnable(addr)){
            case 0:
                printf("Breakpoint at address %08x is already enabled!\n", addr);
                break;
            case 1:
                printf("Enabled breakpoint at address %08x\n", addr);
                break;
            case -1:
                printf("No breakpoint found at address %08x\n", addr);
                break;
        }
    }
}


/**
 * PRINT COMMAND
 * @brief prints the specified item to the terminal
 */
static void printCmd(void)
{
    if (debuggerCmd.argc < 2) {
        printf("Error: not enough arguments\n");
        return;
    }

    if (strcmp(debuggerCmd.argv[1], "memory") == 0) {
        if (debuggerCmd.argc != 4) {
            printf("Error: not enough arguments\n");
            return;
        }
        uint32_t startAddr = strtol(debuggerCmd.argv[2], NULL, 16);
        uint32_t endAddr = strtol(debuggerCmd.argv[3], NULL, 16);

        printMemory(NULL, startAddr, endAddr);

    } else if (strcmp(debuggerCmd.argv[1], "registers") == 0) {
        printRegisters();

    } else if (strcmp(debuggerCmd.argv[1], "instruction") == 0) {
        uint32_t inst = breakListGetInstruction(procGetPC());
        if (!inst)
            procReadMem(procGetPC(), &inst, sizeof(inst));

        printInstruction(inst);

    } else if (strcmp(debuggerCmd.argv[1], "breakpoints") == 0) {
        breakListPrint();
    }
}


/**
 * DUMP COMMAND
 * @brief Dumps memory into specified file
 */
static void dumpCmd(void)
{
    if (debuggerCmd.argc != 5) {
        printf("Error: not enough arguments\n");
        return;
    }

    uint32_t startAddr = strtol(debuggerCmd.argv[2], NULL, 16);
    uint32_t endAddr = strtol(debuggerCmd.argv[3], NULL, 16);

    printMemory(debuggerCmd.argv[4], startAddr, endAddr);
}


/**
 * STEP COMMAND
 * @brief Executes the instruction at PC only if it is a breakpoint
 *        sets the simulator state into 's' step mode
 */
static void stepCmd(void)
{
    uint32_t inst = breakListGetInstruction(procGetPC());
    if (inst)
        runInstruction(inst);

    simulatorSetExecMode(SIMULATOR_STEP);
}


/**
 * CONTINUE COMMAND
 * @brief Executes the instruction at PC only if it is a breakpoint
 *        sets the simulator state into 'c' continue mode
 */
static void continueCmd(void)
{
    uint32_t inst = breakListGetInstruction(procGetPC());
    if (inst)
        runInstruction(inst);

    simulatorSetExecMode(SIMULATOR_CONTINUE);
}


/**
 * HELP COMMAND
 * @brief Prints out the help command for user
 */
static void helpCmd(void)
{
    const char *help[] = {
        "BREAKPOINTS: Places a breakpoint at address addr",
        "CMD:[break, br, b] [addr]",
        "",
        "JUMP: jumps to address addr",
        "[jump, jmp, j] [addr]",
        "",
        "DELETE: deletes breakpoint at addr or all the breakpoints",
        "[delete, del, d] [all, addr]",
        "",
        "DISABLE: disables the breakpoint at addr or all of them",
        "[disable, dis] [all, addr]",
        "",
        "ENABLE: enables the breakpoint at addr or all of them",
        "[enable, ena, en] [all, addr]",
        "",
        "PRINT: Prints various status items",
        "[print, p] [memory, registers, instruction, breakpoints] "
        "[startAddress(memory)] [endAddress(memory)]",
        "",
        "DUMP: Dumps the memory into a file",
        "[dump, dmp] [memory] [startAddress] [endAddress] [filename]",
        "",
        "STEP: steps the program to the next instruction",
        "[step, s]",
        "",
        "CONTINUE: continues the program execution until next breakpoint",
        "[continue, c]",
        "",
        "HELP: Show this help",
        "[help, h]",
        "",
        "EXIT: Exit from the simulation",
        "[exit, stop, quit, q]",
        "",
        "WRITE: Writes a byte to memory",
        "[write, wr, w] [addr] [data]"
    };

    for (int i = 0; i < GET_ARRAY_SIZE(help); i += 1) {
        printf("%s\n", help[i]);
    }
}


/**
 * @brief Sets the simulator state to STOP
 */
static void exitCmd(void)
{
    simulatorSetState(SIMULATOR_STOP);
}


/**
 * @brief write the value in memory
 */
static void writeCmd(void)
{
    if (debuggerCmd.argc != 3) {
        printf("Error: not enough arguments\n");
        return;
    }

    uint32_t addr = strtol(debuggerCmd.argv[1], NULL, 16);
    uint8_t data = strtol(debuggerCmd.argv[2], NULL, 16);

    procWriteMem(addr, &data, sizeof(data));
}


/**
 * Interface functions
 */
void debuggerRun(void)
{
    enum debuggerBaseCmd ret;
    char inputBuffer[BUFFER_LEN];

    do {
        putc('>', stdout);
        fgets(inputBuffer, BUFFER_LEN, stdin);
        ret = debuggerCmdParser(inputBuffer);
    } while (ret != STEP && ret != CONTINUE && ret != EXIT);
}


enum debuggerBaseCmd debuggerCmdParser(const char *cmdStr)
{
    char buffer[BUFFER_LEN] = { 0 };
    strcpy(buffer, cmdStr);

    for (char* p = buffer; *p; ++p)
        *p = tolower(*p);

    char *arg = strtok(buffer," \n");
    if(!arg)
        goto NAC;

    for (enum debuggerBaseCmd cmd = 0; cmd < GET_ARRAY_SIZE(debuggerBaseCmdStr); cmd += 1) {
        unsigned int nbCmd = getCmdNbNames(cmd);

        for (unsigned int i = 0; i < nbCmd; i +=1) {
            if(strcmp(arg, debuggerBaseCmdStr[cmd][i]) == 0) {
                debuggerCmd.cmd = cmd;
                debuggerCmd.argc = 0;

                do {
                    debuggerCmd.argv[debuggerCmd.argc++] = arg;
                    arg = strtok(NULL, " \n");
                } while (arg && debuggerCmd.argc < MAX_CMD_ARG);

                return cmdExec();
            }
        }
    }

    NAC:
    printf("Unknown command %s\n", arg);
    return NOT_A_CMD;
}