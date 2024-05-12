#ifndef __REG_H__
#define __REG_H__

#include "common.h"

int reg_create(int size);
void reg_destroy(void);

int reg_read_data(uint8_t addr, int32_t *data);
int reg_write_data(uint8_t addr, int32_t data);

int reg_read_src(uint8_t addr, uint8_t *src);
int reg_write_src(uint8_t addr, uint8_t src);

#endif
