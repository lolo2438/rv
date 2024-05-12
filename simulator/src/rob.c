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
int rob_issue(uint8_t dest, uint8_t *src) {

        int issue_ptr;

        if (rob.cnt == rob.size || !src)
                return 0;

        // Issue in rob
        issue_ptr = rob.issue_ptr;
        rob.data[issue_ptr].dest = dest;
        rob.data[issue_ptr].done = 0;

        // Update rob issue ptr
        rob.issue_ptr = (rob.issue_ptr + 1) % rob.size;
        rob.cnt += 1;

        // Return the address to write to
        *src = issue_ptr;

        return 1;
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


int rob_read(uint8_t addr, int32_t *data) {
        if (addr > rob.size)
                return 0;

        *data = rob.data[addr].data;

        return rob.data[addr].done;
}


// Commits a value if it is ready
int rob_commit(uint8_t *dest, int32_t *data) {

        if (rob.cnt == 0)
                return 0;

        if (rob.data[rob.commit_ptr].done) {
                *data = rob.data[rob.commit_ptr].data;
                *dest = rob.data[rob.commit_ptr].dest;

                rob.commit_ptr = (rob.commit_ptr + 1) % rob.size;

                rob.cnt -= 1;

                return 1;
        }

        return 0;
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

