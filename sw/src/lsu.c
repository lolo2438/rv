#include "lsu.h"
#include "mem.h"
#include "RV32I.h"

/* Tasks:
 * -> Buffer Store and loads
 *    Load/Store buffer:
 *      1. Push store on the L/S Buffer write pointer
 *      2. Set bits according to
 *    Function:
 *      lsu_shed_load/store()
 *
 *    In order tracker:
 *    Check for stores that are done
 *
 * -> Shedule
 *
 *
 *  If previous load at same addr new store -> Wait for load to be done
 *  If previous store ad same addr new load -> foward to load
 *
 * Store Check Mask:
 *  - When store op in Store Buffer, set SCM
 *  -
 */


/* ** STORE **
 * Instruction:
 *      sw rs2, imm(rs1)
 *
 * store buffer:
 *      Fields:
 *      ADDR            = imm + rs1
 *      DATA            = rs2
 *      DATA_SRC        = address to watch for on cdb if data not ready
 *      BUSY            = store buffer entry is used
 *      ADDR_READY      = address field is valid
 *      DATA_READY      = data field is valid
 *      ISSUED          = Store has been issued to memory, busy can be cleared
 *
 *      Logic:
 *      1. An entry is created for the store instruction in the store buffer | lsu_shed_store
 *             - if [store address is available]{
 *                 addr = store_addr, addr_ready = true
 *               } else {
 *                 addr_ready = false
 *               }
 *             - if [store data is available]{
 *                 data = store_data, data_ready = true
 *               } else {
 *                 data_src = rob_addr, data_ready = false
 *               }
 *             - busy = true, issued = false
 *             - The address of the store buffer entry is returned to be used by the issue buffer for the address µop
 *             - Clear the load_buffer.STORE_DEPENDANCE_MASK bit for the entry since it's a new store
 *
 *      2. When addr_ready = true and data_ready = true | lsu_exec
 *              - if [NOT( (younger store has no address) OR
 *                         (older store has same address AND older store not issued) OR
 *                         (L/S not executed before a fence instruction) )] {
 *                              issue the store, ISSUED=true, BUSY=false,
 *                              if [there is a load with STORE_SPECULATIVE flag AND store_addr == load_addr]
 *                                      load_buffer.DATA = store_data
 *                                      load_buffer.VALID = true
 *                         }
 *
 * ** LOAD **
 * Instruction
 *      lw rs2, imm(rs1)
 * Load buffer:
 *      Fields:
 *      ADDR = imm + rs1
 *      DATA = mem[addr]
 *      DATA_DEST = rob_entry
 *      BUSY
 *      ADDR_READY
 *      ISSUED
 *      VALID
 *      STORE_DEPENDANCE_MASK
 *      STORE_SPECULATIVE
 *
 *      Logic:
 *      1. An entry is created in the load buffer for a load instruction | lsu_shed_load
 *              - if [load addr available]{addr = load_addr, addr_ready = true} else {addr_ready = false}
 *              - busy = true, sleep = false, issued = false
 *              - store_mask = all stores that are busy
 *              - DATA_DEST = rob_entry
 *              - the address of the load buffer is returned to be used by the issue buffer for the address µop
 *
 *      2. When addr_ready = true | lsu_exec
 *              - if [address of store_dependance_mask & store_buffer AND no FENCE before] {
 *                      // Match
 *                      if [address match] {
 *                              DATA = oldest issued store_buffer.data
 *                              valid = true
 *                      } else {
 *                              issue load, issued = true;
 *                              valid = false
 *                      }
 *
 *                      // There is at least 1 older store that is unknowned
 *                      if [store_address missing] {
 *                              store_speculative = true;
 *                              valid = false;
 *                      }
 *                }
 *
 *      3. When load_buffer.data comes back to the LSU
 *              if [issued == true] {
 *                      data = mem[data]
 *              }
 *
 *              the load will now wait until store_speculative flag goes down before valid = 1
 *
 *      4. when VALID = true
 *              - busy = false
 *              - send data back to execution engine
 *
 *
 * ** FENCE **
 *
 */


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


