#include "unit.h"

#define F3_MAX 8

int32_t alu_exec(int16_t f10, int32_t a, int32_t b) {
        switch(f10) {
                //I
                case F10_ADD    : return a + b;
                case F10_SLL    : return a << b;
                case F10_SLT    : return a < b;
                case F10_SLTU   : return (uint32_t)a < (uint32_t)b;
                case F10_XOR    : return a ^ b;
                case F10_SRL    : return (uint32_t)a >> (uint32_t)b;
                case F10_OR     : return a | b;
                case F10_AND    : return a & b;
                case F10_SUB    : return a - b;
                case F10_SRA    : return a >> b;

                // M
                case F10_MUL    : return a * b;
                case F10_MULH   : return (((int64_t) a * (int64_t) b) >> 32);
                case F10_MULHSU : return (((int64_t) a * (uint64_t) b) >> 32);
                case F10_MULHU  : return (((uint64_t) a * (uint64_t) b) >> 32);
                case F10_DIV    : return a / b;
                case F10_DIVU   : return (uint32_t)a / (uint32_t)b;
                case F10_REM    : return a % b; // VERIFY: SIGN of return = SIGN OF DIVIDEND by spec
                case F10_REMU   : return (uint32_t)a % (uint32_t)b;

                default : return 0;
        }
}

int alu_get_cycle(int16_t f10) {
        switch(f10) {
                // I
                case F10_ADD  :
                case F10_SLL  :
                case F10_SLT  :
                case F10_SLTU :
                case F10_XOR  :
                case F10_SRL  :
                case F10_OR   :
                case F10_AND  :
                case F10_SUB  :
                case F10_SRA  :
                        return 1;

                // M
                case F10_MUL    :
                case F10_MULH   :
                case F10_MULHSU :
                case F10_MULHU  :
                        return MUL_LATENCY;

                case F10_DIV    :
                case F10_DIVU   :
                case F10_REM    :
                case F10_REMU   :
                        return 19;

                default :
                        return 0;
        }

}

