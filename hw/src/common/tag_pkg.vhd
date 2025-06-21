library ieee;
use ieee.std_logic_1164.all;

package tag_pkg is

  constant TAG_BITS     : natural := 3;

  constant UNIT_RGU_ROB : std_logic_vector(TAG_BITS-1 downto 0) := "000";
  --constant UNIT_RGU_REG : std_logic_vector(TAG_BITS-1 downto 0) := "001";
  constant UNIT_LSU_LDU : std_logic_vector(TAG_BITS-1 downto 0) := "010";
  constant UNIT_LSU_STU : std_logic_vector(TAG_BITS-1 downto 0) := "011";
  --constant UNIT_BRU_BRP : std_logic_vector(TAG_BITS-1 downto 0) := "100";
  --constant UNIT_BRU_RAS : std_logic_vector(TAG_BITS-1 downto 0) := "101";
  --constant UNIT_SYS     : std_logic_vector(TAG_BITS-1 downto 0) := "110";
  --constant UNIT_SYS_CSR : std_logic_vector(TAG_BITS-1 downto 0) := "111";

  constant STU_LEN : natural := 5;
  constant LDU_LEN : natural := 5;
  constant REG_LEN : natural := 5;
  constant ROB_LEN : natural := 5;
  constant EXB_LEN : natural := 5;
  constant BRU_LEN : natural := 3;

  constant MAX_UNIT_LEN : natural := MAXIMUM((ROB_LEN, EXB_LEN, REG_LEN, LDU_LEN, STU_LEN));

  constant TAG_LEN : natural := TAG_BITS + MAX_UNIT_LEN;

  -- Derived constants for decoding
  constant TAG_UNIT_HIGH : natural := TAG_LEN - 1;
  constant TAG_UNIT_LOW  : natural := TAG_UNIT_HIGH - TAG_BITS;

  constant TAG_ADDR_HIGH : natural := TAG_UNIT_LOW - 1;
  constant TAG_ADDR_LOW  : natural := 0;


  --! \arg unit the unit to encode in the tag
  --! \arg addr the address to encode in the tag
  --! \brief Formats the tag in the correct format
  --! \note unit should be a UNIT_* constant
  pure function tag_format(unit : std_logic_vector; addr : std_logic_vector) return std_logic_vector;

  --! \arg
  --! \brief
  impure function tag_read_unit(tag : std_logic_vector) return std_logic_vector;

  --! \arg
  --! \brief
  impure function tag_read_addr(tag : std_logic_vector) return std_logic_vector;

end package;


package body tag_pkg is

  pure function tag_format(unit : std_logic_vector; addr : std_logic_vector) return std_logic_vector is
  begin
    return unit & addr;
  end function;

  impure function tag_read_unit(tag : std_logic_vector) return std_logic_vector is
  begin
    return tag(TAG_UNIT_HIGH downto TAG_UNIT_LOW);
  end function;


  impure function tag_read_addr(tag : std_logic_vector) return std_logic_vector is
  begin
    return tag(TAG_ADDR_HIGH downto TAG_ADDR_LOW);
  end function;

end package body;
