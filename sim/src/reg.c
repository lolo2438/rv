#include "reg.h"

static struct reg {
        int size;
        int32_t *x; // Register value
        uint8_t *s; // Register src
        bool *d;    // Register dirty flag (value is not valid in register)
} reg = {0};


int reg_create(int size) {
        reg.x = malloc(sizeof(*reg.x) * size);

        reg.s = calloc(size, sizeof(*reg.s));

        reg.d = calloc(size, sizeof(*reg.d));

        if(!reg.x || !reg.s || !reg.d)
                goto CLEANUP;

        reg.x[0] = 0;
        reg.s[0] = 0;
        reg.size = size;

        return 0;

CLEANUP:
        reg_destroy();
        return -1;
}


void reg_destroy(void) {
        if (reg.x)
                free(reg.x);

        if (reg.s)
                free(reg.s);

        if (reg.d)
                free(reg.d);

        reg = (struct reg) {
                .x = NULL,
                .s = NULL,
                .size = 0,
        };
}


int reg_read_data(uint8_t addr, int32_t* data) {
        if(addr >= reg.size || !data)
                return 0;

        // addr=0 hard wired to 0 no need to protect here
        *data = reg.x[addr];

        return 1;
}


int reg_write_data(uint8_t addr, int32_t data) {
        if(addr >= reg.size || addr == 0)
                return 0;

        reg.x[addr] = data;

        // Clear dirty flag
        reg.d[addr] = 0;

        return 1;
}


int reg_read_src(uint8_t addr, uint8_t *src) {
        if (addr >= reg.size || !src)
                return 0;

        *src = reg.s[addr];

        return reg.d[addr];
}


int reg_write_src(uint8_t addr, uint8_t src) {
        if(addr >= reg.size || addr == 0)
                return 0;

        reg.s[addr] = src;

        // set dirty flag
        reg.d[addr] = 1;

        return 1;
}

void reg_print(void) {

    printf("---------------------\n");
    for(int i = 0; i < reg.size; i++)
        printf("| x%d | %0#x |\n", i, reg.x[i]);
    printf("---------------------\n");

}

