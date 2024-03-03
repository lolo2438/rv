#include "mem.h"

uint8_t *mem;

int mem_init(int size) {
      mem = malloc(size);

      if(!mem)
              return EALLOC;

      return 0;
}


void mem_destroy(void) {
        free(mem);
        mem = NULL;
}


int mem_write(int addr, void *data, size_t n) {
    if (!data || !n || !mem)
        return 0;

    uint8_t *d = (uint8_t*)data;

    if (IS_LITTLE_ENDIAN) {
        for (uint32_t i = 0; i < n; i += 1) {
            mem[(addr + i) % MEM_SIZE] = d[i];
        }
    } else {
        for (uint32_t i = 0; i < n; i += 1) {
            mem[(addr + i) % MEM_SIZE] = d[n - 1 - i];
        }
    }
    return n;
}


int mem_read(int addr, void *data, size_t n) {
    if (!data || !n || !mem)
        return 0;

    uint8_t *d = (uint8_t*)data;

    if (IS_LITTLE_ENDIAN) {
        for (uint32_t i = 0; i < n; i += 1) {
            d[i] = mem[(addr + i) % MEM_SIZE];
        }
    } else {
        for (uint32_t i = 0; i < n; i += 1) {
            d[n - 1 - i] = mem[(addr + i) % MEM_SIZE];
        }
    }

    return n;
}
