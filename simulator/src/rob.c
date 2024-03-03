/* Useage
 * INIT: rob_create
 * FREE: rob_destroy
 *
 * issue & get addr
 * write -> commit -> propagate
 */

#include "rob.h"

struct rob_data {
        uint8_t dest; // Address to write the data in the regfile (RD)
        int32_t data; // Data to write in the register
        bool done;    // If the data is ready
        bool re;
};


static struct rob_ctrl {
        // Control
        int commit_ptr;
        int issue_ptr;

        // Stats
        int size;
        int cnt;
        bool w;

        // Data
        struct rob_data *data;
} rob = {0};


// Creates the rob structure
int rob_create(int size) {
        if (rob.size != 0 || size == 0)
                return -1;

        rob.data = malloc(sizeof(struct rob_data) * size);
        if (!rob.data)
                return -2;

        return 0;
}

// Destroy the rob structure
void rob_destroy(void) {
        if (rob.data)
                free(rob.data);

        rob = (struct rob_ctrl) {0};
}


// Allocates a space in the rob & returns the address of the rob entry
int rob_issue(uint8_t dest) {

        int issue_ptr;

        if (rob.cnt == rob.size)
                return 0;

        // Issue in rob
        issue_ptr = rob.issue_ptr;
        rob.data[issue_ptr].dest = dest;
        rob.data[issue_ptr].done = 0;
        rob.data[issue_ptr].re = 0;

        // Update rob issue ptr
        rob.issue_ptr = (rob.issue_ptr + 1) % rob.size;
        rob.cnt += 1;

        // Return the address to write to
        return issue_ptr;
}


// Writes the data at the specified address in the rob
int rob_write(uint8_t addr, int32_t data) {
        if (addr > rob.size)
                return 0;

        rob.data[addr].data = data;
        rob.data[addr].done = 1;

        rob.w = 1;

        return 1;
}


// Commits a value if it is ready
int rob_commit(uint8_t *dest, int32_t *data) {

        if (rob.cnt == 0)
                return 0;

        if (rob.data[rob.commit_ptr].done && rob.data[rob.commit_ptr].re) {
                *data = rob.data[rob.commit_ptr].dest;
                *dest = rob.data[rob.commit_ptr].dest;

                rob.commit_ptr = (rob.commit_ptr + 1) % rob.size;

                rob.cnt -= 1;

                return 1;
        }

        return 0;
}


// Simulates a FF using a re flag, return number of value that
// were propagated if there we wrote to the rob
int rob_propagate(void) {
        int n;

        if (!rob.w)
                return 0;

        // Update read enable flags
        for (int i = 0; i < rob.size; i++) {
                if(rob.data[i].done && !rob.data[i].re) {
                        rob.data[i].re = 1;
                        n++;
                }
        }

        rob.w = 0;

        return n;
}


void rob_flush(void) {
        rob.cnt -= rob.issue_ptr - rob.commit_ptr;
        rob.commit_ptr = rob.issue_ptr;
}


int rob_full(void) {
        if (rob.size == rob.cnt)
                return 1;

        return 0;
}

