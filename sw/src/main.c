/*
 *
 *
 */

#include "common.h"
#include "mem.h"
#include "elf.h"
#include "engine.h"
#include <stdio.h>

struct elf_file ef;
int retval = 0;

// TODO:
// argument --config: Specify a configuration file for engine parameters
// no arguments : name of the program to execute
int main(int argc, char *argv[]) {

        // TODO: Verify ARGUMENTS
        //elf_open(argv[0], &ef);

        struct engine_parameters ep = {
                .mem_size = 0x400,
                .exb_size = 8,
                .rob_size = 64,
                .reg_size = 32,
                .cdb_size = 1,
                .nb_units = 2,
                .program = argv[1]
        };
        engine_init(&ep);

        while((retval = engine_run()) == 0);


CLEANUP:
//        elf_close(&ef);
        mem_destroy();
        engine_destroy();

        return retval;
}


