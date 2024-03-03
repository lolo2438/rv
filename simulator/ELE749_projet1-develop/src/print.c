/**
 * @file print.c
 * @author Laurent Tremblay
 * @date 2021-05-29
 * @brief: Implementation of the Utility printing functions to output
 *         the status of the processor to a user.
 */


#include <stdio.h>
#include <math.h>
#include <stdint.h>
#include <stdlib.h>
#include <print.h>
#include <procState.h>
#include <desassembly.h>
#include <common.h>


static char *authors[] = {
        "Laurent",
        "Guyaume",
        "Louis",
        "Mathieu",
        "Alexis"
};


void printHeader(void)
{
	
    printf(PRJ_NAME);
    putc(' ', stdout);

    printf(COPYRIGHT);
    putc('\n', stdout);

    unsigned int authorCount = sizeof(authors)/sizeof(*authors);

    int i;
    printf("Authors: ");
    for(i = 0; i < authorCount - 1; i += 1) {
        printf("%s, ",authors[i]);
    }
    printf("%s\n", authors[i]);
    fflush(stdout);
	
}


void printInstruction(uint32_t inst)
{
	
    char *dInst = buildInstString(inst);
    printf("Instruction = %08x ", inst);
    printf("[%s]\n", dInst);
    free(dInst);
    fflush(stdout);
	
}


void printRegisters(void)
{
	
    uint32_t regVal;
    int c;

    // 1 for x
    // 1 + log(reg size) -> 1 + log(15) = 2,27 -> 2, 1 + log(100) -> 3
    int nbRegCharacter = 1 + (int)(1 + log(PROC_REGSIZE));

    for (unsigned int i = 0; i < PROC_REGSIZE; i += 1) {
        if (i != 0) {
            c = printf("x%d:", i);
            regVal = procGetRegs()[i];
        } else {
            c = printf("PC:");
            regVal = procGetPC();
        }

        for(; c < nbRegCharacter; c += 1) {
            putc(' ', stdout);
        }

        printf("[%08x]", regVal);

        if (i % NB_REG_PER_LINE == NB_REG_PER_LINE - 1)
            putc('\n', stdout);
        else
            putc(' ', stdout);
    }

    putc('\n', stdout);
    fflush(stdout);
	
}


int printMemory(const char *fileName, uint32_t startAddress,
                uint32_t endAddress)
{
	
    if (endAddress > PROC_MEMSIZE - 1 || startAddress > endAddress)
        return -EARG;

    FILE* f;
    if (fileName) {
        f = fopen(fileName, "w");
        if (!f)
            return -EFILE;
    } else {
        f = stdout;
    }

    fprintf(f, "Address   Data\n");
    for(uint32_t addr = startAddress; addr <= endAddress; addr += 1) {
        fprintf(f,"%08x: ", addr);
        fprintf(f,"[%02x]\n", procGetMem()[addr]);
    }

    putc('\n', f);

    if(f != stdout)
        fclose(f);

    return 0;
	
}