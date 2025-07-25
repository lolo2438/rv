library ieee;
use ieee.std_logic_1164.all;

package core_pkg is

  constant XLEN    : natural := 32;

  constant STU_LEN : natural := 5;
  constant LDU_LEN : natural := 5;
  constant REG_LEN : natural := 5;
  constant ROB_LEN : natural := 5;
  constant EXB_LEN : natural := 5;
  constant BRU_LEN : natural := 3;

  constant MAX_UNIT_LEN : natural := MAXIMUM((ROB_LEN, EXB_LEN, REG_LEN, LDU_LEN, STU_LEN));

  constant CDB_LEN : natural := MAX_UNIT_LEN;

  type TYPE_UNIT is (
    UNIT_EXB,
    UNIT_RGU,
    UNIT_LDU,
    UNIT_STU,
    UNIT_BRU,
    UNIT_SYS
  );

  -- TODO: Change tags with units
  constant TAG_LEN : natural := 3;
  constant TAG_EXB : std_logic_vector := "000";
  constant TAG_RGU : std_logic_vector := "001";
  constant TAG_LDU : std_logic_vector := "010";
  constant TAG_STU : std_logic_vector := "011";
  constant TAG_BRU : std_logic_vector := "100";
  constant TAG_SYS : std_logic_vector := "101";

  type TYPE_DATA_PACKET is record
    value : std_logic_vector;
    dest  : std_logic_vector;
    addr  : std_logic_vector;
  end record;

  type TYPE_SYNC_CTRL is record
    valid : std_logic;
    ready : std_logic;
  end record;

  type TYPE_ASYNC_CTRL is record
    req : std_logic;
    ack : std_logic;
  end record;

  type TYPE_SYNC_PACKET is record
    data : TYPE_DATA_PACKET;
    ctrl : TYPE_SYNC_CTRL;
  end record;

  type TYPE_ASYNC_PACKET is record
    data : TYPE_DATA_PACKET;
    ctrl : TYPE_ASYNC_CTRL;
  end record;


end package;
