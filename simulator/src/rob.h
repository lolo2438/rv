#ifndef __ROB_H__
#define __ROB_H__

#include "common.h"

/* \fn rob_create
 * \param size The size of the
 * \return -1 if size = 0 or current rob not deallocated
 *         -2 memory error
 * \brief
 */
int rob_create(int size);

/* \fn rob_destroy
 * \brief Deallocates the data associated to the ROB and clears it's internals
 */
void rob_destroy(void);

int rob_issue(uint8_t dest, uint8_t *src);

int rob_write(uint8_t addr, int32_t data);

int rob_read(uint8_t addr, int32_t *data);

int rob_commit(uint8_t *dest, int32_t *data);

void rob_flush(void);

int rob_full(void);

#endif
