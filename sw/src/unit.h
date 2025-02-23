/* UNIT
 * Contains operations for the executions units
 * EU, LSU and BRU
 *
 */
#ifndef __UNIT_H__
#define __UNIT_H__

#include "common.h"


// I
#define F10_ADD         0x000
#define F10_SLL         0x001
#define F10_SLT         0x002
#define F10_SLTU        0x003
#define F10_XOR         0x004
#define F10_SRL         0x005
#define F10_OR          0x006
#define F10_AND         0x007
#define F10_SUB         0x200
#define F10_SRA         0x205

// M
#define F10_MUL         0x008
#define F10_MULH        0x009
#define F10_MULHSU      0x00A
#define F10_MULHU       0x00B
#define F10_DIV         0x00C
#define F10_DIVU        0x00D
#define F10_REM         0x00E
#define F10_REMU        0x00F

#define MUL_LATENCY 4
#define DIV_LATENCY 19


enum INT_EXTENSION {
        M = 1,
        A = 2,
        B,


};

int32_t alu_exec(int16_t f10, int32_t a, int32_t b);

int alu_get_cycle(int16_t f10);

#endif
