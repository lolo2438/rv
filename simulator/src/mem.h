#ifndef MEM_H
#define MEM_H

#define MEM_SIZE 0x01000000

#include "common.h"

int mem_init(int size);

void mem_destroy(void);

int mem_write(int addr, void *data, size_t n);

int mem_read(int addr, void *data, size_t n);

#endif
