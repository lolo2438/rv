/**
 * @file instructionsRV32E.c
 * @author Mathieu Nadeau
 * @date 2021-05-19
 * @brief: Implements all the RV32E instructions
 */


#include <instructionsRV32E.h>
#include <simulator.h>
#include <debugger.h>
#include <print.h>


/**
 * Loads
 */
void loadByte(iType *data)
{

    uint32_t add;
    int8_t value;
    add = data->imm + procReadReg(data->rs1);
    procReadMem(add, &value, sizeof(value));
    procWriteReg(data->rd, value);

}


void loadHalfword(iType *data)
{

    uint32_t add;
    int16_t value;
    add = data->imm + procReadReg(data->rs1);
    procReadMem(add, &value, sizeof(value));
    procWriteReg(data->rd, value);

}


void loadWord(iType *data)
{

    uint32_t add;
    int32_t value;
    add = data->imm + procReadReg(data->rs1);
    procReadMem(add, &value, sizeof(value));
    procWriteReg(data->rd, value);

}


void loadByteUnsigned(iType *data)
{

    uint32_t add;
    uint8_t value;
    add = data->imm + procReadReg(data->rs1);
    procReadMem(add, &value, sizeof(value));
    procWriteReg(data->rd, value);

}


void loadHalfUnsigned(iType *data)
{

    uint32_t add;
    uint16_t value;
    add = data->imm + procReadReg(data->rs1);
    procReadMem(add, &value, sizeof(value));
    procWriteReg(data->rd, value);

}


/**
 * Store
 */
void storeByte(sType *data)
{
	
    uint32_t addr = (data->imm + procReadReg(data->rs1));
    uint8_t regVal = (uint8_t)procReadReg(data->rs2);
    procWriteMem(addr, &regVal, sizeof(regVal));
	
}


void storeHalfword(sType *data)
{
	
    uint32_t addr = (data->imm + procReadReg(data->rs1));
    uint16_t regVal = (uint16_t)procReadReg(data->rs2);
    procWriteMem(addr, &regVal, sizeof(regVal));

}


void storeWord(sType *data)
{
	
    uint32_t addr;
    addr = (data->imm + procReadReg(data->rs1));
    uint32_t regval = procReadReg(data->rs2);
    procWriteMem(addr, &regval, sizeof(regval));

}


/**
 * Shifts
 */
void shiftLeft(rType *data)
{

    int32_t value;
    value = procReadReg(data->rs1) << procReadReg(data->rs2);
    procWriteReg(data->rd, value);

}


void shiftLeftImmediate(iType *data)
{

    int32_t value;
    value = procReadReg(data->rs1) << data->imm;
    procWriteReg(data->rd, value);

}


void shiftRight(rType *data)
{

    uint32_t value = (uint32_t)procReadReg(data->rs1);
    value = value >> procReadReg(data->rs2);
    procWriteReg(data->rd, (int32_t)value);

}


void shiftRightImmediate(iType *data)
{

    uint32_t value = (uint32_t)procReadReg(data->rs1);
    value = value >> data->imm;
    procWriteReg(data->rd, (int32_t)value);

}


void shiftRightArithmetic(rType *data)
{

    int32_t value = procReadReg(data->rs1);
    value = value >> procReadReg(data->rs2);
    procWriteReg(data->rd, value);

}


void shiftRightArithImm(iType *data)
{

    int32_t value = procReadReg(data->rs1);
    value = value >> data->imm;
    procWriteReg(data->rd, value);

}


/**
 * Arithmetic
 */
void add(rType *data)
{

    int32_t value;
    value = procReadReg(data->rs1) + procReadReg(data->rs2);
    procWriteReg(data->rd, value);

}


void addImmediate(iType *data)
{

    int32_t value;
    value = procReadReg(data->rs1) + data->imm;
    procWriteReg(data->rd, value);

}


void sub(rType *data)
{

    int32_t value;
    value = procReadReg(data->rs1) - procReadReg(data->rs2);
    procWriteReg(data->rd, value);

}


void loadUpperImm(uType *data)
{

    procWriteReg(data->rd, (int32_t)data->imm);

}


void addUpperImmToPC(uType *data)
{

    uint32_t value;
    value =  data->imm + procGetPC();
    procWriteReg(data->rd, (int32_t)value);

}


/**
 * Logical
 */
void xor(rType *data)
{

    int32_t value;
    value = procReadReg(data->rs1) ^ procReadReg(data->rs2);
    procWriteReg(data->rd, value);

}


void xorImmediate(iType *data)
{

    int32_t value;
    value = procReadReg(data->rs1) ^ data->imm;
    procWriteReg(data->rd, value);

}


void or(rType *data)
{

    int32_t value;
    value = procReadReg(data->rs1) | procReadReg(data->rs2);
    procWriteReg(data->rd, value);

}


void orImmediate(iType *data)
{

    int32_t value;
    value = procReadReg(data->rs1) | data->imm;
    procWriteReg(data->rd, value);

}


void and(rType *data)
{

    int32_t value;
    value = procReadReg(data->rs1) & procReadReg(data->rs2);
    procWriteReg(data->rd, value);

}


void andImmediate(iType *data)
{

    int32_t value;
    value = procReadReg(data->rs1) & data->imm;
    procWriteReg(data->rd, value);

}


/**
 * Compare
 */
void setLessThan(rType *data)
{

    if(procReadReg(data->rs1) < procReadReg(data->rs2)){

        procWriteReg(data->rd, 1);

    }else{

        procWriteReg(data->rd, 0);

    }

}


void setLessThanImmediate(iType *data)
{

    if(procReadReg(data->rs1) < data->imm){

        procWriteReg(data->rd, 1);

    }else{

        procWriteReg(data->rd, 0);

    }

}


void setLessThanUnsigned(rType *data)
{

    if(abs(procReadReg(data->rs1)) < abs(procReadReg(data->rs2))){

        procWriteReg(data->rd, 1);

    }else{

        procWriteReg(data->rd, 0);

    }

}


void setLessThanImmediateUnsigned(iType *data)
{

    if(abs(procReadReg(data->rs1)) < abs(data->imm)){

        procWriteReg(data->rd, 1);

    }else{

        procWriteReg(data->rd, 0);

    }

}


/**
 * Branch
 */
void branchEqual (bType *data)
{

	if(procReadReg(data->rs1) == procReadReg(data->rs2)){

		procUpdatePC(data->imm);

	} else {
		procUpdatePC(4);
	}

}


void branchNotEqual (bType *data)
{

    if(procReadReg(data->rs1) != procReadReg(data->rs2)){

        procUpdatePC(data->imm);

    } else {
        procUpdatePC(4);
    }

}


void branchLessThan (bType *data)
{

    if(procReadReg(data->rs1) < procReadReg(data->rs2)){

        procUpdatePC(data->imm);

    } else {
        procUpdatePC(4);
    }

}


void branchMoreOrEqual (bType *data)
{

    if(procReadReg(data->rs1) >= procReadReg(data->rs2)){

        procUpdatePC(data->imm);

    } else {
        procUpdatePC(4);
    }

}


void branchLessThanUnsigned (bType *data)
{

    if(abs(procReadReg(data->rs1)) < abs(procReadReg(data->rs2))){

        procUpdatePC(data->imm);

    } else {
        procUpdatePC(4);
    }

}


void branchMoreOrEqualUnsigned (bType *data)
{

    if(abs(procReadReg(data->rs1)) >= abs(procReadReg(data->rs2))){

        procUpdatePC(data->imm);

    } else {
        procUpdatePC(4);
    }

}


/**
 * Jump & Link
 */
void jumpAndLink (jType *data)
{

    procWriteReg(data->rd,(int32_t)procGetPC() + 4);
    procUpdatePC(data->imm);

}


void jumpAndLinkRegister (iType *data)
{

    procWriteReg(data->rd, (int32_t)procGetPC() + 4);
    procSetPC(data->imm + procReadReg(data->rs1));

}


void ecall(void)
{
	
    simulatorSetState(SIMULATOR_STOP);
	
}


void ebreak(void)
{
	
    printf("Reached breakpoint at address %08x\n", procGetPC());
    debuggerCmdParser("print instruction");
    debuggerCmdParser("print registers");
    debuggerRun();
	
}