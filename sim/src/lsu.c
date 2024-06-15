#include "lsu.h"
#include "mem.h"
#include "RV32I.h"

static struct lsu_t{

        int lb_size;
        int lb_nb;
        struct load_buf {
                struct lsu_buf addr;
                uint32_t data;
                uint8_t f3; // Type of load operation
                bool busy;  // Entry is valid in the load buffer
                enum lsu_status status;
        } *lb;

        int sb_size;
        int sb_nb;
        int sb_read_ptr;
        int sb_write_ptr;
        struct store_buf {
                struct lsu_buf addr, data;
                uint8_t f3;
                bool busy;
                enum lsu_status status;
        } *sb;

} lsu = {0};


// Load
// 1. Place in buffer
// 2. If addr in store_buf, foward value to load buf
// 3. else Depending on where the data is in memory (L? cache, Dram) wait a number of cycles until

static int load() {

        return 0;
}

// Store
static int store() {
        return 0;
}


// ------- Global Functions -------- //

void lsu_destroy(void) {
        if (lsu.lb)
                free(lsu.lb);

        if (lsu.sb)
                free(lsu.sb);

        lsu = (struct lsu_t) {0};
}


int lsu_create(int load_size, int store_size) {
        // create load buffer
        lsu.lb = malloc(sizeof(*lsu.lb) * load_size);
        lsu.lb_size = load_size;
        lsu.lb_nb = 0;

        // create store buffer
        lsu.sb = malloc(sizeof(*lsu.sb) * store_size);
        lsu.sb_size = load_size;
        lsu.sb_nb = 0;
        lsu.sb_write_ptr = 0;
        lsu.sb_read_ptr = 0;

        if(!lsu.lb || !lsu.sb)
                goto CLEANUP;

        // Checks
        return 0;

CLEANUP:
        lsu_destroy();
        return ENOMEM;
}


int lsu_sched_load(struct lsu_buf addr, uint8_t f3) {
        if (lsu.lb_size == lsu.lb_nb)
                return 0;

        for(int i = 0; i < lsu.lb_size; i++) {
                if(!lsu.lb[i].busy) {
                        lsu.lb[i].addr = addr;
                        lsu.lb[i].busy = true;
                        lsu.lb[i].f3 = f3;
                        lsu.lb[i].status = addr.r ? WAIT : READY;

                        lsu.lb_nb++;
                        goto SHEDULED;
                }
        }

        // TODO: ERROR if we arrive here
        return 0;
SHEDULED:
        return 1;
}

int lsu_sched_store(struct lsu_buf addr, struct lsu_buf data, uint8_t f3) {
        if (lsu.sb_size == lsu.sb_nb)
                return 0;

        lsu.sb[lsu.sb_write_ptr++] = (struct store_buf) {
                .addr = addr,
                .data = data,
                .busy = true,
                .f3 = f3,
                .status = (addr.r | data.r) ? WAIT : READY,
        };

        lsu.sb_nb++;
        lsu.sb_write_ptr %= lsu.sb_size;

        return 1;
}

int lsu_exec(void) {

        //RVWMO =
        // Writes have less precedence than loads
        // Reads to same address must be in order
        // Thread can read own it's writes early (store fowarding to load)

        // Load buffer
        // Load must be sent ASAP
        for(int i = 0; i < lsu.lb_size; i++) {
                if(lsu.lb[i].busy && lsu.lb[i].status == READY) {
                        //TODO: Here it should be "REQ", but skipping cuz need
                        //      infrastructure to model memory hierarchy

                        // Is value in STORE buf?
                        for(int j = 0; j < lsu.sb[i].

                        // Go fetch in memory
                        int n = 1;
                        switch(lsu.lb[i].f3) {
                                case FUNCT3_LB:
                                case FUNCT3_LBU:
                                        n=1;
                                        break;
                                case FUNCT3_LHU:
                                case FUNCT3_LH:
                                        n=2;
                                        break;
                                case FUNCT3_LW:
                                        n=4;
                                        break;
                        };
                        mem_read(lsu.lb[i].addr.value, &lsu.lb[i].data, n);
                        lsu.lb[i].status = DONE;
                }
        }

        // Store buffer
        // NOTE: Store must be send in program order, the sb must therefore be a fifo
        for(int i = 0; i < lsu.sb_size; i++) {
                if(lsu.sb[i].busy && lsu.sb[i].status == READY) {
                        int n = 1;
                        switch(lsu.lb[i].f3) {
                                case FUNCT3_LB:
                                case FUNCT3_LBU:
                                        n=1;
                                        break;
                                case FUNCT3_LHU:
                                case FUNCT3_LH:
                                        n=2;
                                        break;
                                case FUNCT3_LW:
                                        n=4;
                                        break;
                        };
                }
        }

}

int lsu_wb(struct cdb_data data) {

}
