#ifndef COMMON_H
#define COMMON_H

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <errno.h>

#define IS_LITTLE_ENDIAN (*(uint8_t *)&(uint16_t){1})

#endif
