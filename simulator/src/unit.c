#include "unit.h"

#define F3_MAX 8

// M Operations


static int nb_units;

static struct unit {
        struct result_bus res;
        int nb_cycle_left;
        int busy;
} * units;


// ** LOCAL FUNCTION **
static int32_t execute_operation(int16_t f10, int32_t a, int32_t b) {
        switch(f10) {
                // I
                case F10_ADD    : return a + b;
                case F10_SLL    : return a << b;
                case F10_SLT    : return a < b;
                case F10_SLTU   : return (uint32_t)a < (uint32_t)b;
                case F10_XOR    : return a ^ b;
                case F10_SRL    : return (uint32_t)a >> (uint32_t)b;
                case F10_OR     : return a | b;
                case F10_AND    : return a & b;
                case F10_SUB    : return a - b;
                case F10_SRA    : return a >> b;

                // M
                case F10_MUL    : return a * b;
                case F10_MULH   : return (((int64_t) a * (int64_t) b) >> 32);
                case F10_MULHSU : return (((int64_t) a * (uint64_t) b) >> 32);
                case F10_MULHU  : return (((uint64_t) a * (uint64_t) b) >> 32);
                case F10_DIV    : return a / b;
                case F10_DIVU   : return (uint32_t)a / (uint32_t)b;
                case F10_REM    : return a % b; // VERIFY: SIGN of return = SIGN OF DIVIDEND by spec
                case F10_REMU   : return (uint32_t)a % (uint32_t)b;

                default : return 0;
        }
}

static int get_nb_exec_cycle(int16_t f10) {
        switch(f10) {
                // I
                case F10_ADD  :
                case F10_SLL  :
                case F10_SLT  :
                case F10_SLTU :
                case F10_XOR  :
                case F10_SRL  :
                case F10_OR   :
                case F10_AND  :
                case F10_SUB  :
                case F10_SRA  :
                        return 1;

                // M
                case F10_MUL    :
                case F10_MULH   :
                case F10_MULHSU :
                case F10_MULHU  :
                        return MUL_LATENCY;

                case F10_DIV    :
                case F10_DIVU   :
                case F10_REM    :
                case F10_REMU   :
                        return DIV_LATENCY;

                default :
                        return 0;
        }

}


static int unit_check_done(int unit) {
        if (units[unit].busy && units[unit].nb_cycle_left == 0)
                return 1;

        units[unit].nb_cycle_left -= 1;

        return 0;
}


// ** GLOBAL FUNCTIONS **
int create_exec_units(int nb) {

}

int get_free_unit(void) {

        for(int i = 0; i < nb_units; i++) {
                if(!units[i].busy) {
                        return i;
                }
        }

        return -1;
}

int unit_execute(struct data_bus *data, int unit_nb) {
        struct unit *unit = &units[unit_nb];

        int32_t res;
        int32_t a = data->vj;
        int32_t b = data->vk;

        uint16_t f10 = (data->f7 << 3 | data->f3);

        // TODO: Check here if operation is supported by the unit

        unit->res.result = execute_operation(f10, a, b);
        unit->nb_cycle_left = get_nb_exec_cycle(f10);
        unit->res.dest = data->dest;
        unit->busy = 1;

        return 0;
}


int unit_get_result(int unit, struct result_bus *results) {

        if (unit_check_done(unit)) {
               *results = units[unit].res;
               units[unit].busy = 0;

               return 1;
        }

        return 0;
}

