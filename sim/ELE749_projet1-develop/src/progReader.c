/**
 * File: prog_reader.c
 * Author: Alexis Laframboise
 * Date : 2021-05-19
 * Description:
 * Reads the program file and hold its content in a struct for future use.
 */


#include <progReader.h>


// This structure will hold the content of the program file.
static programFileT* progHandle;


/*
 *  Private functions
 */
 /**
 * @fn readProgram
 * @brief   This function reads the program file in the progHandle->progName.
 *
 * @return  error code.       -> 0 good, other bad.
 */
uint8_t readProgram(void);


 /**
 * @fn readInstruction
 * @brief This function reads a line in the program file
 * @param program file handle, from which we will read a line.
 * @return A line in the program file, null terminated.
 */
char* readInstruction(FILE* programFile);


/*
 * Function definitions
 */
uint8_t programInit(const char* programFileName)
{
	
    uint8_t err = 0;

    progHandle = (programFileT*)malloc(sizeof(programFileT));
    progHandle->progName = (char*)calloc(strlen(programFileName)
            + 1, sizeof(char));
    strcpy(progHandle->progName, programFileName);

    progHandle->instCnt = 0;
    progHandle->instArr = NULL;
    progHandle->instStrArr = NULL;
    progHandle->instLenArr = NULL;

    err = readProgram();

    return err;
	
}


uint8_t readProgram(void)
{
	
    FILE* programFile;
    uint32_t instCnt = 0;
    uint32_t* instArr = (uint32_t*) calloc(0, sizeof(uint32_t));
    char* instStr = NULL;
    char** instStrArr = (char**) calloc(0, sizeof(char*));
    uint8_t* instLenArr = (uint8_t*) calloc(0, sizeof(uint8_t));
    uint8_t err = 0;

    //if ((fopen(progHandle->progName, "r")) == 0) {
    if ((err = fopen_s(&programFile, progHandle->progName, "r")) == 0) {
        while ((instStr = readInstruction(programFile))) {
            instArr = (uint32_t *) realloc(instArr,
                           (instCnt + 1) * sizeof(uint32_t));
            instStrArr = (char **) realloc(instStrArr,
                           (instCnt + 1) * sizeof(char*));
            instLenArr = (uint8_t *) realloc(instLenArr,
                             (instCnt + 1) * sizeof(uint8_t));

            instArr[instCnt] = strtoll(instStr, NULL, ENCODING_BITS);
            instStrArr[instCnt] = instStr;
            instLenArr[instCnt] = strlen(instStr) *
                    HEX_BITS_PER_CHAR / BITS_PER_BYTE;

            instCnt++;

        }
        fclose(programFile);

        progHandle->instCnt = instCnt;
        progHandle->instArr = instArr;
        progHandle->instStrArr = instStrArr;
        progHandle->instLenArr = instLenArr;
    }
    return err;
	
}


char* readInstruction(FILE* programFile)
{
	
    char instStr[32] = {0};
    char* pInstStr = NULL;

    if (fgets(instStr, sizeof(instStr), programFile)){

        if (instStr[strlen(instStr) - 1] == '\n')
            instStr[strlen(instStr) - 1] = '\0';

        pInstStr = (char*) calloc(strlen(instStr) +
                1, sizeof(char));
        strcpy(pInstStr, instStr);

    }

    return pInstStr;
	
}


char* getProgName(void)
{
	
    return progHandle->progName;
	
}


uint32_t getInstCnt(void)
{
	
    return progHandle->instCnt;
	
}


uint8_t* getInstLenArr(void)
{
	
    return progHandle->instLenArr;
	
}


uint32_t* getInstArr(void)
{
	
    return progHandle->instArr;
	
}


char** getInstStrArr(void)
{
	
    return progHandle->instStrArr;
	
}


void programDestroy(void)
{
	
    free(progHandle->progName);

    for (int i = 0; i < progHandle->instCnt; i++){
        free(progHandle->instStrArr[i]);
    }

    free(progHandle->instArr);
    free(progHandle->instStrArr);
    free(progHandle->instLenArr);
	
}