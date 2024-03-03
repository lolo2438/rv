#include "reg.h"

static struct reg {
        int size;
        int32_t *x;
        uint8_t *d;
} reg = {0};


int reg_create(int size) {
        reg.x = malloc(sizeof(*reg.x) * size);
        if(!reg.x)
                goto CLEAN0;

        reg.d = calloc(size, sizeof(*reg.d));
        if(!reg.d)
                goto CLEAN1;


        reg.x[0] = 0;
        reg.d[0] = 0;
        reg.size = size;

        return 0;

CLEAN1:
        free(reg.x);
CLEAN0:
        return -1;
}


void reg_destroy(void) {
        if(reg.x)
                free(reg.x);

        if(reg.d)
                free(reg.d);

        reg.x = NULL;
        reg.d = NULL;
        reg.size = 0;
}


int reg_read_data(uint8_t addr, uint32_t* data) {
        if(addr >= reg.size || !data)
                return 0;

        // addr=0 hard wired to 0 no need to protect here
        *data = reg.x[addr];

        return 1;
}


int reg_write_data(uint8_t addr, uint32_t data) {
        if(addr >= reg.size || addr == 0)
                return 0;

        reg.x[addr] = data;

        return 1;
}


int reg_read_dest(uint8_t addr, uint8_t *dest) {
        if (addr >= reg.size || !dest)
                return 0;

        *dest = reg.d[addr];

        return 1;
}


int reg_write_dest(uint8_t addr, uint8_t dest) {
        if(addr >= reg.size || addr == 0)
                return 0;

        reg.d[addr] = dest;

        return 1;
}
