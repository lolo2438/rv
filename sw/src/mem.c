#include "mem.h"

static uint8_t *mem;
static int mem_size=0;

int mem_create(int size) {
      mem = malloc(size);

      mem_size = size;

      if(!mem)
              return ENOMEM;

      return 0;
}


void mem_destroy(void) {
        free(mem);
        mem = NULL;
        mem_size = 0;
}


int mem_write(int addr, void *data, size_t n) {
    if (!data || !n || !mem)
        return 0;

    uint8_t *d = (uint8_t*)data;

    if (IS_LITTLE_ENDIAN) {
        for (uint32_t i = 0; i < n; i += 1) {
            mem[(addr + i) % mem_size] = d[i];
        }
    } else {
        for (uint32_t i = 0; i < n; i += 1) {
            mem[(addr + i) % mem_size] = d[n - 1 - i];
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
            d[i] = mem[(addr + i) % mem_size];
        }
    } else {
        for (uint32_t i = 0; i < n; i += 1) {
            d[n - 1 - i] = mem[(addr + i) % mem_size];
        }
    }

    return n;
}
