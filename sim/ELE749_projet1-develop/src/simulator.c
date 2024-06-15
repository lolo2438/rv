/**
 * @file simulator.c
 * @author Laurent Tremblay
 * @date 2021-06-04
 * @brief: Interface to the main simulator loop
 */


#include <stdlib.h>
#include <progReader.h>
#include <print.h>
#include <procState.h>
#include <decoder.h>
#include <simulator.h>
#include <debugger.h>
#include <common.h>


static enum simulatorExecMode simulatorExecMode = SIMULATOR_STEP;
static enum simulatorState simulatorState = SIMULATOR_RUN;


static struct instruction simulatorInst;


uint32_t simulatorFetch(void)
{
	
    procReadMem(procGetPC(), &simulatorInst.inst, sizeof(simulatorInst.inst));
    return simulatorInst.inst;
	
}


void simulatorDecode(uint32_t inst)
{
	
    struct instruction i = {
            .inst = inst,
            .decodedInst = decodeInstruction(inst),
            .instType = decodeInstructionType(inst),
            .instExt = decodeInstructionLength(inst)
    };

    if (i.instExt == RVC)
        i.inst &= 0x0000FFFF;

    simulatorInst = i;
	
}


void simulatorExecute(void)
{
	
    runInstruction(simulatorInst.inst);
	
}


static void updatePC(void)
{
	
    if (simulatorInst.instType     != RV32E_J_TYPE  &&
        simulatorInst.instType     != RV32C_CJ_TYPE &&
        simulatorInst.instType     != RV32E_B_TYPE  &&
        simulatorInst.decodedInst  != RV32E_JALR    &&
        simulatorInst.decodedInst  != C_JALR        &&
        simulatorInst.decodedInst  != C_JR          &&
        simulatorInst.decodedInst  != C_BEQZ        &&
        simulatorInst.decodedInst  != C_BNEZ        &&
        simulatorInst.decodedInst  != RV32E_ECALL   &&
        simulatorState             == SIMULATOR_RUN) {

        switch (simulatorInst.instExt) {
            case RV32E:
                procUpdatePC(4);
                break;
            case RVC:
                procUpdatePC(2);
                break;
        }
    }
	
}


/**
 * @fn progSetup
 * @brief Loads in memory the appropriate data for the programs:
 *        strlen_bin.txt
 *        hexstr_bin_c.txt
 * @param filepath the filepath of the program
 */
static void progSetup(const char* filepath)
{
    char buffer[BUFFER_LEN] = {0};
    strcpy(buffer, filepath);

    char *tok = strtok(buffer,"/");
    char *lastTok = tok;
    while(tok){
        lastTok = tok;
        tok = strtok(NULL, "/");
    }

    if(strcmp(lastTok, "strlen_bin.txt") == 0) {
        const char *str = "Ecole de technologie superieure";
        procWriteMem(0x00400000, (void*)str, strlen(str)+1);

    } else if (strcmp(lastTok, "hexstr_bin_c.txt") == 0) {
        uint32_t val = 0x12345678;
        uint32_t dest = 0x00004000;
        procWriteMem(0x00400000, (void*)&val, sizeof(val));
        procWriteMem(0x00400008, (void*)&dest, sizeof(dest));
        val = 0x90ABCDEF;
        dest = 0x00004010;
        procWriteMem(0x00400004, (void*)&val, sizeof(val));
        procWriteMem(0x0040000C, (void*)&dest, sizeof(dest));
    }
}


/**
 * @fn loadProgramInMemory
 * @brief loads the program in memory
 *        programInit() -> need to be initialised
 */
static void loadProgramInMemory(void)
{
    uint32_t instCount = getInstCnt();
    uint32_t* instArr = getInstArr();
    uint8_t* instLenArr = getInstLenArr();

    uint32_t memOffset = 0;

    for(uint32_t i = 0; i < instCount; i += 1) {
        procWriteMem(memOffset, instArr+i, instLenArr[i]);
        memOffset += instLenArr[i];
    }
}


void simulatorInit(void)
{
	
    printHeader();

    printf("Enter the name of the file to read\n");
    fflush(stdout);

    char nameBuf[BUFFER_LEN] = { 0 };
    fgets(nameBuf, BUFFER_LEN, stdin);

    // Remove the '\n'
    nameBuf[strlen(nameBuf) - 1] = '\0';

    if (programInit(nameBuf)) {
        printf("Error could not load program name %s", nameBuf);
        exit(-EPROGRAM);
    }

    procInit();

    progSetup(nameBuf);

    loadProgramInMemory();

    programDestroy();
	
}


int simulatorDestroy(void)
{
	
    debuggerCmdParser("delete all --q");
    procDestroy();

    return 0;
	
}


void simulatorRun(void)
{
	
    while(simulatorState == SIMULATOR_RUN) {
        simulatorFetch();
        simulatorDecode(simulatorInst.inst);

        if (simulatorExecMode == SIMULATOR_STEP) {
            printInstruction(simulatorInst.inst);
            printRegisters();
            debuggerRun();
        }

        simulatorExecute();
        updatePC();
    }

    printInstruction(simulatorInst.inst);
    printRegisters();

    printf("Exiting simulation\n");
	
}


void simulatorSetState(enum simulatorState state)
{
	
   simulatorState = state;
   
}


void simulatorSetExecMode(enum simulatorExecMode mode)
{
	
    simulatorExecMode = mode;
	
}


struct instruction simulatorGetInstruction(void)
{
  
    return simulatorInst;
	
}
