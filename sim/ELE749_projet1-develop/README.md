# ELE749_projet1

General info
Demos are found in their respective folders.
strlen -> strlen/demo_strlen.txt
hexstr -> hexstr/demo_strlen.txt
debugger -> debugger/demo_*.txt

Execution

The program ask for a filename to read the instruction from.
The file format consists of one instruction per line, in a hexadecimal format.

The simulator supports either RV32E or RV32C instructions.

When the program is loaded, you may specify any of the commands listed bellow:

-- Base commands:
step: step through the program

continue: run the program until ECALL or EBREAK instruction is reached

-- Advanced debugger functions:
break @addr place a breakpoint at specified address

delete @addr remove breakpoint at specified address.
             If "all" is specified instead of addr all the breakpoints are removed

enable @addr enables the breakpoint at specified address
             If "all" is specified instead of addr all the breakpoints are removed.

disable @addr enables the breakpoint at specified address
             If "all" is specified instead of addr all the breakpoints are removed.

print registers: prints the registers
      instructions: prints the instruction
      breakpoints: prints all the breakpoints and their status
      memory @startaddr @endaddr: prints the memory from start to end address

dump memory @startaddr @endaddr @filename: prints memory from start addr to end addr into filename

jump @addr: jumps to the specified address

write @addr @data : Write a byte to specified address

help: Prints all the command with their possible formats.

exit: exits the simulator

--
The simulator will keep executing until an ECALL instruction is reached.
