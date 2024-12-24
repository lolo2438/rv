from vunit import VUnit
import toml

def _gen_vhdl_db(vu, output_file):
    """
    Generate the toml file required by rust_hdl (vhdl_ls).

    Args:
        vu: A VUnit object file.
        output_file: A string containing the path to the output file.
    """
    libs = vu.get_libraries()
    vhdl_ls = {"libraries": {}}
    for lib in libs:
        vhdl_ls["libraries"].update(
            {
                lib.name: {
                    "files": [file.name for file in lib.get_source_files()]
                }
            }
        )
    with open(output_file, "w") as f:
        toml.dump(vhdl_ls, f)


vu = VUnit.from_argv(compile_builtins=False)
vu.add_vhdl_builtins()
vu.add_osvvm()

# RISCV Definitions
riscv_lib = vu.add_library("riscv")
riscv_lib.add_source_files("../pkg/riscv/*.vhd")

# RTL Library
rtl_lib = vu.add_library("rtl")
rtl_lib.add_source_files("../pkg/common/*.vhd")
rtl_lib.add_source_files("../rtl/common/*.vhd")
rtl_lib.add_source_files("../rtl/flt/*.vhd")
rtl_lib.add_source_files("../rtl/*.vhd")

# Test bench library
tb_lib = vu.add_library("tb")
tb_lib.add_source_files("../pkg/tb/*.vhd")
tb_lib.add_source_files("*.vhd")

#_gen_vhdl_db(vu, "vhdl_ls.toml")

vu.main()

