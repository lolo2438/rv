/**
 * @file procState.c
 * @author Laurent Tremblay
 * @date 2021-05-19
 * @brief: Implements the processor states and the function
 *         to access the registers and memory.
 */
 
 
#include <stdlib.h>
#include <string.h>
#include <procState.h>
#include <common.h>


struct procState {
    uint32_t pc;
    int32_t x[PROC_REGSIZE];
    uint8_t *mem;
};


// Holds the state of the processor
static struct procState proc = { 0 };


int procInit(void)
{
	
    proc.pc = 0;
    memset(proc.x, 0, PROC_REGSIZE * sizeof(*(proc.x)));

    if (proc.mem != NULL) {
        memset(proc.mem, 0, PROC_MEMSIZE * sizeof(*(proc.mem)));
        return 0;
    }

    proc.mem = calloc(PROC_MEMSIZE, sizeof(*(proc.mem)));
    if (!proc.mem)
        return -EALLOC;

    return 0;
	
}


void procDestroy(void)
{
	
    proc.pc = 0;
    memset(proc.x, 0, PROC_REGSIZE);
    free(proc.mem);
    proc.mem = NULL;
	
}


int32_t procWriteReg(uint8_t reg,
                     int32_t val)
{
	
    if (reg <= 0 || reg >= PROC_REGSIZE)
        return 0;

    proc.x[reg] = val;

    return val;
	
}


int32_t procReadReg(uint8_t reg)
{
	
    if (reg >= PROC_REGSIZE)
        return 0;

    return proc.x[reg];
	
}


// Little endian -> 0A0B0C0D ->
// [0A, 0B, 0C, 0D] -> [ 0D, 0C, 0B, 0A ]
uint32_t procWriteMem(uint32_t addr,
                      void *data,
                      size_t n)
{
	
    if (data == NULL || n == 0 || proc.mem == 0)
        return 0;

    uint8_t *d = (uint8_t*)data;

    if (IS_LITTLE_ENDIAN) {
        for (uint32_t i = 0; i < n; i += 1) {
            proc.mem[(addr + i) % PROC_MEMSIZE] = d[i];
        }
    } else {
        for (uint32_t i = 0; i < n; i += 1) {
            proc.mem[(addr + i) % PROC_MEMSIZE] = d[n - 1 - i];
        }
    }
    return n;
	
}


// Little endian [ 0D, 0C, 0B, 0A ] ->
// [0A, 0B, 0C, 0D] -> 0A0B0C0D
uint32_t procReadMem(uint32_t addr,
                     void *data,
                     size_t n)
{
	
    if (data == NULL || n == 0 || proc.mem == 0)
        return 0;

    uint8_t *d = (uint8_t*)data;

    if (IS_LITTLE_ENDIAN) {
        for (uint32_t i = 0; i < n; i += 1) {
            d[i] = proc.mem[(addr + i) % PROC_MEMSIZE];
        }
    } else {
        for (uint32_t i = 0; i < n; i += 1) {
            d[n - 1 - i] = proc.mem[(addr + i) % PROC_MEMSIZE];
        }
    }

    return n;
	
}


uint32_t procGetPC(void)
{
	
    return proc.pc;
	
}


uint32_t procSetPC(uint32_t new_pc)
{
	
    proc.pc = new_pc % PROC_MEMSIZE;
    return new_pc;
	
}


uint32_t procUpdatePC(int32_t offset)
{
	
    return procSetPC((procGetPC() + offset) % PROC_MEMSIZE);
	
}


const uint8_t *procGetMem(void)
{
	
    return (const uint8_t*)proc.mem;
	
}


const uint32_t *procGetRegs(void)
{
	
    return (const uint32_t*)proc.x;
	
}