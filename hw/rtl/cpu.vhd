library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library riscv;
use riscv.RV32I.all;

use work.common_pkg.all;

entity cpu_ooo is
  generic(
    XLEN           : natural;
    IMEM_ADDRWIDTH : natural;
    DMEM_ADDRWIDTH : natural
  );
  port (
    -- Control Interface
    clk_i   : in  std_logic;
    rst_i   : in  std_logic;
    en_i    : in  std_logic;
    halt_o  : out std_logic;

    -- Interrupts interface
    interrupt_i : in std_logic_vector(31 downto 0);

    -- imem interface
    imem_en_i   : in  std_logic;
    imem_we_i   : in  std_logic_vector(3 downto 0);
    imem_addr_i : in  std_logic_vector(IMEM_ADDRWIDTH-1 downto 0);
    imem_data_i : in  std_logic_vector(31 downto 0);
    imem_valid_i: in  std_logic;
    imem_data_o : out std_logic_vector(31 downto 0);

    -- dmem interface
    dmem_en_i   : in  std_logic;
    dmem_we_i   : in  std_logic_vector(XLEN/8-1 downto 0);
    dmem_addr_i : in  std_logic_vector(DMEM_ADDRWIDTH-1 downto 0);
    dmem_data_i : in  std_logic_vector(XLEN-1 downto 0);
    dmem_valid_i: in std_logic;
    dmem_data_o : out std_logic_vector(XLEN-1 downto 0)
  );
end entity;

architecture rtl of cpu_ooo is

  constant NB_REG : natural := 32;

  -- TODO: Nombre d'unités d'exécution dans le back end, trouver une façon de spécifier les untités a instancier
  -- TODO: Rendre générique...
  constant NB_ALU_UNIT : natural := 4;

  ----
  -- EXECUTION BUFFER
  ----

  ----
  -- REGFILE
  ----
  -- RESULT BUS
  ----
  ----
  -- REORDER BUFFER
  ----

begin

  -- EXB
  -- REG
  -- EXU
  -- RSB
  -- ROB

end architecture;
