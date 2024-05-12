#ifndef __EXECUTION_H__
#define __EXECUTION_H__

#include "common.h"
#include "rob.h"
#include "decoder.h"
#include "reg.h"
#include "unit.h"

struct engine_parameters {
        int exb_size;
        int rob_size;
        int reg_size;
        int cdb_size;
        int nb_units;
};

struct ibus;

int engine_init(struct engine_parameters *param);

void engine_destroy(void);

int engine_run(struct ibus *bus);

#endif
