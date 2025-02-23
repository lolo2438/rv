#ifndef MEM_H
#define MEM_H

#include "common.h"

int mem_create(int size);

void mem_destroy(void);

int mem_write(int addr, void *data, size_t n);

int mem_read(int addr, void *data, size_t n);

#endif
