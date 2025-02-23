#ifndef __LSU_H__
#define __LSU_H__

#include "common.h"

struct lsu_buf {
        uint32_t value;
        uint8_t q;
        bool r;
};


enum lsu_status {
        WAIT,   // Buffer is waiting on operands
        READY,  // Buffer is ready to send a request
        //REQ,    // Request has been sent to read/write the data
        DONE    // Data has been correctly written/read and buffer is done
};


#endif
