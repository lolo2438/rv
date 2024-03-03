#ifndef __ROB_H__
#define __ROB_H__

#include "common.h"

int rob_create(int size);

void rob_destroy(void);

int rob_issue(uint8_t dest);

int rob_write(uint8_t addr, int32_t data);

int rob_commit(uint8_t *dest, int32_t *data);

int rob_propagate(void);

void rob_flush(void);

int rob_full(void);

#endif
