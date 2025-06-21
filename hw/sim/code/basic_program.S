#.section text
#.globl _start
#
#_start:
addi x1, x0, 1
slli x2, x1, 8
sub x3, x2, x1
sw x3, 0(x0)
lw x4, 0(x0)
sw x4, 4(x0)
ecall

