from toml.encoder import TomlEncoder
from vunit import VUnit
import toml
import os

def _gen_vhdl_db(vu, output_file):
    """
    Generate the toml file required by rust_hdl (vhdl_ls).

    Args:
        vu: A VUnit object file.
        output_file: A string containing the path to the output file.
    """
    libs = vu.get_libraries()
    vhdl_ls = {"libraries": {}}
    # TODO File name analysis, for common paths add the * and ** symbols to make it more generic
    for lib in libs:
        vhdl_ls["libraries"].update(
            {
                lib.name: {
                    "files": [os.path.realpath(file.name) for file in lib.get_source_files()]
                }
            }
        )

    with open(output_file, "w") as f:
        toml.dump(vhdl_ls, f)


vu = VUnit.from_argv(compile_builtins=False)
vu.add_vhdl_builtins()
vu.add_osvvm()

#vu.add_compile_option("ghdl.a_flags", ["--std=19"])

# RISCV Definitions
riscv_lib = vu.add_library("riscv")
riscv_lib.add_source_files("../pkg/riscv/*.vhd")

# Common library
common_lib = vu.add_library("common");
common_lib.add_source_files("../pkg/common/*.vhd");

# Sim library
sim_lib = vu.add_library("sim")
sim_lib.add_source_files("../pkg/tb/*.vhd")
sim_lib.add_source_files("../sim/src/*.vhd", allow_empty=True)
sim_lib.add_source_files("../sim/tb/*.vhd")


# HW Library
hw_lib = vu.add_library("hw")
hw_lib.add_source_files("../src/common/*.vhd")
hw_lib.add_source_files("../src/exu/*.vhd")
hw_lib.add_source_files("../src/rgu/*.vhd")
hw_lib.add_source_files("../src/lsu/*.vhd")
hw_lib.add_source_files("../src/flt/*.vhd")
hw_lib.add_source_files("../src/*.vhd")

_gen_vhdl_db(vu, "vhdl_ls.toml")

#vu.main()

