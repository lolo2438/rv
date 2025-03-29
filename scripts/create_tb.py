"""
Goal

The goal of this program is to take a design and generate a VUnit template for verification
"""

from dataclasses import dataclass
import sys
import argparse

@dataclass
class vhdl_generic:
    name        : str
    type_desc   : str
    init_value  : str

@dataclass
class vhdl_port:
    name        : str
    direction   : str
    type_desc   : str


class vhdl_entity:
    name        : str
    generics    : list[vhdl_generic]
    ports :     : list[vhdl_port]

    def parse_entity(self, file : str):
        f = open(sys.argv[1], 'r')


        # Find "entity" declaration
        loop = True
        while loop:
            line = f.readline().lower()
            if line = None:
                loop = False
            else:
                loop = (line.find("entity") != -1)

        self.name = line.split()[1]

        # Read until "end entity" is found
        loop = True
        while loop:
            line = f.readline().lower()

            if line.find("generic") != -1:
                loop2 = True
                while loop2:


                    loop2 = False




            if line.find("end entity") != -1:
                loop = False;

        f.close()

    def create_tb(self, file : str)




parser = argparse.ArgumentParser("TB Creator");
parser.add_argument("i", "input_file", help="Input vhdl file to scan an create the tb")
parser.add_argument("o", "output_file")
args = parser.parse_args()





