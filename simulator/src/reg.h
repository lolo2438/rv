#ifndef __REG_H__
#define __REG_H__

#include "common.h"

int reg_create(int size);
void reg_destroy(void);

int reg_read_data(uint8_t addr, uint32_t *data);
int reg_write_data(uint8_t addr, uint32_t data);

int reg_read_dest(uint8_t addr, uint8_t *dest);
int reg_write_dest(uint8_t addr, uint8_t dest);

#endif
