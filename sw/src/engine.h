#ifndef __ENGINE_H__
#define __ENGINE_H__

#include "common.h"
#include "rob.h"
#include "decoder.h"
#include "reg.h"
#include "unit.h"
#include "mem.h"

struct engine_parameters {
        int mem_size;
        int exb_size;
        int rob_size;
        int reg_size;
        int cdb_size;
        int nb_units;
        char *program;
};

int engine_init(const struct engine_parameters *param);

void engine_destroy(void);

int engine_run(void);

#endif
