/*
 *
 */
#include "engine.h"

static uint32_t PC = 0;
static uint32_t instruction;

// ---
// LOCAL STRUCT
// ---
static struct cdb {
        int nb_lanes;
        int nb_active_lanes;
        struct cdb_data {
                uint8_t qr;
                int32_t result;
                bool valid;
        } *lane;
} cdb = {0};


static struct exu {
        int nb_units;
        struct exu_data {
                int32_t result;
                uint8_t qr;
                int cycle_left;
                bool busy;
                int capabilities; // TODO : Information on operations that the unit can do
        } *units;

        int *ready_list;
        int nb_rdy;

        int *done_list;
        int nb_done;
} exu = {0};


static struct exb {
        int buf_size;
        int buf_cnt;
        struct exb_data {
                uint16_t f10;   // Operation executed
                int32_t vj, vk; // Values of the operands
                uint8_t qj, qk; // Rob entry of the operands
                uint8_t qr;     // Rob entry of the destination
                bool rj, rk;    // Ready flag for operands j and k
                bool dirty;     // Dirty flag for speculative execution
                bool busy;      // Entry is busy in the exec buf
        } *buf;

        int *ready_list;
        int nb_rdy;
} exb = {0};

// ------------------ BRU
static struct {
        int a;
} bru;


// ---
// LOCAL FUNCTIONS
// ---
// EXB
static void exb_destroy(void) {

        if(exb.buf) free(exb.buf);
        if(exb.ready_list) free(exb.ready_list);

        exb = (struct exb) {
                .buf_size = 0,
                .buf = NULL,
                .ready_list = NULL,
                .buf_cnt = 0,
                .nb_rdy = 0
        };
}


static int exb_create(int size) {

        exb = (struct exb) {
                .buf_size = size,
                .buf = malloc(sizeof(*exb.buf) * size),
                .ready_list = malloc(sizeof(*exb.ready_list) * size),
                .buf_cnt = 0,
                .nb_rdy = 0
        };

        if(!exb.buf || !exb.ready_list)
                goto CLEANUP;

        // Reset ROB
        for(int i = 0; i < exb.buf_size; i++)
                exb.buf[i].busy = false;

        return 0;

CLEANUP:
        exb_destroy();
        return -1;
}


// EXU
static void exu_destroy(void) {
        if(exu.units) free(exu.units);
        if(exu.ready_list) free(exu.ready_list);
        if(exu.done_list) free(exu.done_list);

        exu = (struct exu) {
                .nb_units = 0,
                .nb_rdy = 0,
                .nb_done = 0,
                .units = NULL,
                .ready_list = NULL,
                .done_list = NULL,
        };
}


static int exu_create(int nb_units) {
        exu = (struct exu) {
                .nb_units = nb_units,
                .nb_rdy = 0,
                .nb_done = 0,
                .units = malloc(sizeof(*exu.units) * nb_units),
                .ready_list = malloc(sizeof(*exu.ready_list) * nb_units),
                .done_list = malloc(sizeof(*exu.done_list) * nb_units),
        };

        if(!exu.units || !exu.ready_list || !exu.done_list)
                goto CLEANUP;

        for(int i = 0; i < exu.nb_units; i++)
                exu.units[i].busy = 0;

        return 0;

CLEANUP:
        exu_destroy();
        return -1;
}


// CDB
static void cdb_destroy(void) {
        if(cdb.lane)
                free(cdb.lane);

        cdb = (struct cdb) {
                .nb_lanes = 0,
                .lane = NULL,
                .nb_active_lanes = 0,
        };
}


static int cdb_create(int nb_lanes) {

        cdb = (struct cdb) {
                .nb_lanes = nb_lanes,
                .lane = malloc(sizeof(*cdb.lane) * nb_lanes),
                .nb_active_lanes = 0,
        };

        if(!cdb.lane)
                goto CLEANUP;

        return 0;

CLEANUP:
        cdb_destroy();
        return -1;
}


// EXECUTION
static int dispatch() {

        // TODO: Make a global instruction bus
        //       Make a dispatcher that masks the instruction lanes according to the thingy

        // TODO: Check if instruction is valid
        if (instruction == 0)
                return -1;

        struct inst_field inst = decode(instruction);


        if (rob_full())
                return -1;

        uint8_t qr;
        rob_issue(inst.rd, &qr);

        uint16_t f10 = 0; // Default operation is ADD

        uint8_t qj, qk;
        int32_t vj,vk;
        bool rj = true, rk = true;

        // If operand is in registers go fetch it,
        // else the value might be on the CDB or in the ROB,
        //      if it is not available then
        if (!reg_read_src(inst.rs1, &qj)) {
                reg_read_data(inst.rs1, &vj);
        } else {
                for(int i = 0; i < cdb.nb_lanes; i++) {
                        if(cdb.lane[i].valid && cdb.lane[i].qr == qj) {
                                vj = cdb.lane[i].result;
                                goto OP_J_DONE;
                        }
                }
                if(rob_read(qj, &vj))
                        goto OP_J_DONE;

                // could not find operand, therefore need to wait
                rj = false;
        }

OP_J_DONE:

        switch(inst.opcode) {
                case OP_IMM:
                        f10 = inst.funct3;
                case OP_LOAD:
                case OP_STORE:
                case OP_AUIPC:
                        qk = 0;
                        vk = inst.immediate;
                        break;
                default:
                        f10 = (inst.funct7 << 3) | inst.funct3;

                        if (!reg_read_src(inst.rs2, &qk)) {
                                reg_read_data(inst.rs2, &vk);
                        } else {
                                for(int i = 0; i < cdb.nb_lanes; i++) {
                                        if(cdb.lane[i].valid && cdb.lane[i].qr == qk) {
                                                vk = cdb.lane[i].result;
                                                goto OP_K_DONE;
                                        }
                                }

                                if(rob_read(qk, &vj)) {
                                        goto OP_K_DONE;
                                }
                                rk = false;
                        }

                        break;
        }

OP_K_DONE:

        reg_write_src(inst.rd, qr);

        for (int i = 0; i < exb.buf_size; i++) {
                if (!exb.buf[i].busy) {
                        exb.buf[i] = (struct exb_data) {
                                .f10    = f10,
                                .qj     = qj,
                                .qk     = qk,
                                .qr     = qr,
                                .vj     = vj,
                                .vk     = vk,
                                .rj     = rj,
                                .rk     = rk,
                                .dirty  = false,
                                .busy  = true,
                        };
                        break;
                }
        }

        // LSU: Create entry for instruction
        // BRU: Create entry for instruction

        return 0;
}


// Algorithm :
// 1. Detect which ops are rdy
// 2. If multiples : Select according to type of sheduler: Random, Oldest, etc..
// 3. Dispatch to execution units
static int issue(void) {

        int nb_issue;

        // Detect which exb is ready
        exb.nb_rdy = 0;
        for (int i = 0; i < exb.buf_size; i++) {
                if (exb.buf[i].busy && exb.buf[i].rj && exb.buf[i].rk)
                        exb.ready_list[exb.nb_rdy++] = i;
        }

        // Detect which exu are ready
        exu.nb_rdy = 0;
        for (int i = 0; i < exu.nb_units; i++) {
                if (!exu.units[i].busy)
                        exu.ready_list[exu.nb_rdy++] = i;
        }

        // Selection algorithm
        // FIXME: add capabilities detection algorithm to select right instructions/stuff
        // TODO: Round robbin units ?
        if(exb.nb_rdy > exu.nb_rdy)
                nb_issue = exu.nb_rdy;
        else
                nb_issue = exb.nb_rdy;

        int unit_index;
        int exb_index;
        for(int i = 0; i < nb_issue; i++) {
                //TODO: Select which to use, for now only the first ones
                unit_index = exu.ready_list[i];
                exb_index = exb.ready_list[i];

                // Load in unit
                exu.units[unit_index].result = alu_exec(exb.buf[exb_index].f10, exb.buf[exb_index].vj, exb.buf[exb_index].vk);
                exu.units[unit_index].cycle_left = alu_get_cycle(exb.buf[exb_index].f10);
                exu.units[unit_index].busy = true;
                exu.units[unit_index].qr = exb.buf[exb_index].qr;

                // Reset exb entry
                exb.buf[exb_index].busy = false;
        }

        return nb_issue;
}


static int execute(void) {

        //1. For all exec units
        //2. Propagate values
        for(int i=0; i < exu.nb_units; i++) {
                if (exu.units[i].busy && exu.units[i].cycle_left != 0)
                        exu.units[i].cycle_left -= 1;
        }

        //3. Execute LSU

        //4. Execute BRU

        return 0;
}


// Do in reverse order to simulate FF
// 1. Propagate results in CBD structure
// 2. Read ROB
// 3. Commit ROB to regfile
static int write_back(void) {

        // ---
        // READ CBD AND STORE IN ROB
        // ---
        for(int i = 0; i < cdb.nb_lanes; i++)
                if(cdb.lane[i].valid)
                        rob_write(cdb.lane[i].qr, cdb.lane[i].result);

        // ---
        // PUT UNIT RESULTS IN CDB
        // ---

        // Reset cbd
        for (int i = 0; i < cdb.nb_lanes; i++)
                cdb.lane[i].valid = 0;

        // Check all EXU
        exu.nb_done = 0;
        for(int i = 0; i < exu.nb_units; i++) {
                if(exu.units[i].busy && exu.units[i].cycle_left == 0)
                        exu.done_list[exu.nb_done++] = i;
        }
        //TODO Check LSU

        // SELECT what unit -> cdb lane
        if (exu.nb_done > cdb.nb_lanes)
                cdb.nb_active_lanes = cdb.nb_lanes;
        else
                cdb.nb_active_lanes = exu.nb_done;

        // TODO: mix between exu/lsu
        // TODO: algorithm so the index selected is not always the first one
        for(int i = 0; i < exu.nb_done; i++) {
                int exu_index = exu.done_list[i];

                // Store exu result in the CDB
                cdb.lane[i] = (struct cdb_data) {
                        .qr = exu.units[exu_index].qr,
                        .result = exu.units[exu_index].result,
                        .valid = true
                };

                // Clear the EXU
                exu.units[exu_index].busy = false;
        }

        // Foward the results to EXB
        for (int i = 0; i < exb.buf_size; i++) {
                if(exb.buf[i].busy) {
                        if(!exb.buf[i].rj) {
                                for(int j = 0; j < cdb.nb_lanes; j++) {
                                        if(cdb.lane[j].valid) {
                                                if (exb.buf[i].qj == cdb.lane[j].qr) {
                                                        exb.buf[i].vj = cdb.lane[j].result;
                                                        exb.buf[i].rj = true;
                                                        break;
                                                }
                                        }
                                }
                        }

                        if(!exb.buf[i].rk) {
                                for(int j = 0; j < cdb.nb_lanes; j++) {
                                        if(cdb.lane[j].valid) {
                                                if (exb.buf[i].qk == cdb.lane[j].qr) {
                                                        exb.buf[i].vk = cdb.lane[j].result;
                                                        exb.buf[i].rk = true;
                                                        break;
                                                }
                                        }
                                }
                        }
                }
        }

        return 0;
}


static void commit(void) {
        int32_t result;
        uint8_t rd, rob_addr;

        if (rob_commit(&rob_addr, &rd, &result)) {
                // Propagate result from ROB to REG
                reg_write_data(rd, result);

                // Foward result to EXB
                for (int i = 0; i < exb.buf_size; i++) {
                        if (exb.buf[i].busy) {
                                if (!exb.buf[i].rj) {
                                        if (exb.buf[i].qj == rob_addr) {
                                                exb.buf[i].vj = result;
                                                exb.buf[i].rj = true;
                                                break;
                                        }
                                }

                                if (!exb.buf[i].rk) {
                                        if (exb.buf[i].qk == rob_addr) {
                                                exb.buf[i].vk = result;
                                                exb.buf[i].rk = true;
                                                break;
                                        }
                                }
                        }
                }
        }
}


// TODO: Determine file extension: .txt = str like else elf file
static int load_program(const char *fn) {

        // FIXME: only support .txt for now
        FILE * f = fopen(fn, "r");
        if (!f)
                return -1;

        // Instruction = 8 characters + newline + NULL
        char buf[10];
        uint32_t inst;

        int a = 0;
        while(fgets(buf, 10, f)) {
                buf[8] = 0;

                //convert to hexadecimal number
                inst = strtol(buf, NULL, 16);

                //write to memory
                mem_write(a, &inst, sizeof(inst));
                a += sizeof(inst);
        }

        fclose(f);

        return 0;
}


// ---
// GLOBAL FUNCTIONS
// ---
void engine_destroy(void) {

        exb_destroy();
        rob_destroy();
        reg_destroy();
        exu_destroy();
        cdb_destroy();
        mem_destroy();
}


int engine_init(const struct engine_parameters *param) {
        int retval;

        // Create exec buffers
        if((retval = exb_create(param->exb_size))) goto CLEANUP;

        // Create ROB
        if((retval = rob_create(param->rob_size))) goto CLEANUP;

        // Create registers
        if((retval = reg_create(param->reg_size))) goto CLEANUP;

        // Create exec units, LSU and BRU
        if((retval = exu_create(param->nb_units))) goto CLEANUP;

        // Create cdb
        if((retval = cdb_create(param->cdb_size))) goto CLEANUP;

        // Create Memory
        if((retval = mem_create(param->mem_size))) goto CLEANUP;

        // Load Program into memory
        if((retval = load_program(param->program))) goto CLEANUP;

        return 0;

CLEANUP:
        engine_destroy();
        return retval;
}


int engine_run(void) {

        mem_read(PC, &instruction, sizeof(instruction));

        // Backend
        commit();
        write_back();
        execute();
        issue();
        dispatch();

        // Frontend

        //reg_print();
        //printf("\n");

        // PC logic
        PC += 4;

        return 0;
}

