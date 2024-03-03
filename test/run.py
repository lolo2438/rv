from vunit import VUnit

vu = VUnit.from_argv(compile_builtins=False)
vu.add_vhdl_builtins()
vu.add_osvvm()

riscv_lib = vu.add_library("riscv")
riscv_lib.add_source_files("../pkg/riscv/*.vhd")

cpu = vu.add_library("cpu")
# Pkgs
cpu.add_source_files("../pkg/*.vhd")

# SRC
cpu.add_source_files("../rtl/common/*.vhd")
cpu.add_source_files("../rtl/flt/*.vhd")
cpu.add_source_files("../rtl/*.vhd")

# TB sources
cpu.add_source_files("*.vhd")

vu.main()
