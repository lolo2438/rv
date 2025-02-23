/**
 * @file main.c
 * @date 2021-05-19
 * @brief: Runs the simulator.
 */


#include <simulator.h>


int main(int argc, char **argv)
{
	
    simulatorInit();
    simulatorRun();
    return simulatorDestroy();
	
}