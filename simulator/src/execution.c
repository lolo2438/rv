// µdec
// exec buffer
//      reg fetch
// exec unit
// cdb
// rob

#include "common.h"
#include "execution.h"
#include "rob.h"
#include "decoder.h"
#include "reg.h"

struct cdb {
        uint8_t dest;
        int32_t result;
        bool valid;
} cdb = {0};


struct issue_data {
        uint8_t f3, f7, op; // no need for OP
        int32_t vj, vk;
        uint8_t qj, qk;
        uint8_t dest;
        bool busy;
        bool re; // Simulates a DFF: will enable read of this instruction on next cycle
};

struct exec_unit {
        uint8_t f3, f7, op;
        int32_t vj, vk, result;
        uint8_t dest;
};

static struct issue_ctrl {

        int size;
        int cnt;

        struct issue_data *data;
} rs;

int ibu_create(int size) {

        return 0;
}

void rs_destroy() {

}

int exec_init() {
        // Create issue buffer
        ibu_create(8);

        // Create ROB
        rob_create(8);

        // Create exec units, LSU and BRU

}

int exec_issue(struct dec_inst di) {

        // FIXME robFULL?
        uint8_t rob_entry = rob_issue(di.rd);

        uint8_t qj, qk;
        uint32_t vj,vk;
        reg_read_dest(di.rs1, &qj);
        reg_read_data(di.rs1, &vj);


        // FIXME: LOAD/STORE/AUIPC,etc..
        //        should be µdecoded into ADD instrucitons
        switch(di.opcode) {
                case OP_IMM:
                case OP_LOAD:
                case OP_STORE:
                case OP_AUIPC:
                        qk = 0;
                        vk = di.immediate;
                        break;
                default:
                        reg_read_dest(di.rs2, &qk);
                        reg_read_data(di.rs2, &vk);
                        break;

        }

        reg_write_dest(di.rd, rob_entry);


        // TODO: replace operation to ADD for load/store,etc..
        for (int i = 0; i < rs.size; i++) {
                if (!rs.data[i].busy) {
                        rs.data[i] = (struct issue_data) {
                                .f3   = di.funct3,
                                .f7   = di.funct7,
                                .op   = di.opcode,
                                .qj   = qj,
                                .qk   = qk,
                                .vj   = vj,
                                .vk   = vk,
                                .dest = rob_entry,
                                .busy = 1,
                                .re   = 0
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
int exec_dispatch() {

        // Schedule
        int shed = -1;

        // Detect which rs is ready
        for (int i = 0; i < rs.size; i++) {
                // Implement algorithms here
                if (rs.data[i].re && rs.data[i].qj == 0 && rs.data[i].qk == 0)
                        shed = i;
        }

        // Dispatch
        // 1. Select which units will execute wich instruction
        // 2. Place instruction in unit

        return 0;
}



int exec_propagate() {

        for (int i = 0; i < rs.size; i++) {
                if (rs.data[i].busy && !rs.data[i].re)
                        rs.data[i].re = 1;
        }
}


void execute() {
        // 1. Issue
        // 2. Shed
        // 3. Exec
        // 4. CBD
}

