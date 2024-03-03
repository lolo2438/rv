#ifndef __DFF_H__
#define __DFF_H__

#include "common.h"

struct dff;

int dff_create_clock(void);

void dff_destroy_clock(void);

int dff_add_network(struct dff*u);

void dff_update_all(void);

inline void dff_write(struct dff *u, int32_t value);

inline int32_t dff_read(struct dff *u);

inline void dff_update(struct dff *u);


#endif
