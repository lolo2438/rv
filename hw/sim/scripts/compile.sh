#!/bin/bash

if [ $# -lt 1 ]
then
    echo "Usage: compile.sh filename.S"
    exit
fi

f="$1"

if [ ! -f $f ]
then
    echo "ERROR: File $f does not exist"
    exit
fi

fn="${f%.*}"

echo "Extracted file name $fn"

#riscv32-unknown-elf-gcc -nostdlib -nostartfiles -T link.ld $f -o $fn.elf

echo "Compile file $f"
riscv32-unknown-elf-as $f -o $fn.elf

echo "Extract"
riscv32-unknown-elf-objcopy -O binary -j .text $fn.elf $fn.bin

echo "Create hex file"
hexdump -ve '4/1 "%02x" "\n"' $fn.bin > $fn.hex

echo "DONE"
