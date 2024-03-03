#include "dff.h"

struct clk_network {
        struct dff **dff;
        int nb_dff;
        int size;
} clk;

struct dff {
        int32_t D, Q;
};


inline void dff_write(struct dff *u, int32_t value) { u->D = value; }
inline int32_t dff_read(struct dff *u) { return u->Q; }
inline void dff_update(struct dff *u) { u->Q = u->D; }

static int dff_create_clk_network(struct clk_network *clk) {

        clk->size = 10;
        clk->nb_dff = 0;
        clk->dff = malloc(sizeof(clk->dff) * clk->size);
        if (!clk->dff)
                return -1;

        return 0;
}


static void dff_destroy_clk_network(struct clk_network *clk) {
        if(clk->dff)
                free(clk->dff);

        clk->dff = NULL;
        clk->nb_dff = 0;
        clk->size = 0;
}

// Add dff to update chain
static int dff_add_to_clk_network(struct dff *u, struct clk_network *clk) {

        if(clk->nb_dff == clk->size) {
                clk->size += 10;
                clk->dff = realloc(clk->dff, sizeof(struct dff*) * clk->size);
                if (!clk->dff)
                        return -1;
        }

        clk->dff[clk->nb_dff++] = u;

        return 0;
}

static void dff_update_clk_network(struct clk_network *clk) {
        for(int i = 0; i < clk->nb_dff; i++) {
                dff_update(clk->dff[i]);
        }
}


int dff_create_clock(void) {
        return dff_create_clk_network(&clk);
}

void dff_destroy_clock(void) {
        dff_destroy_clk_network(&clk);
}

int dff_add_network(struct dff*u) {
        return dff_add_to_clk_network(u, &clk);
}

void dff_update_all(void) {
        dff_update_clk_network(&clk);
}








