library ieee;
use ieee.std_logic_1164.all;

package tag_pkg is

  constant TAG_BITS   : natural := 2;

  constant TAG_RGU    : std_logic_vector(1 downto 0) := "00";
  constant TAG_LDU    : std_logic_vector(1 downto 0) := "01";
  constant TAG_STU    : std_logic_vector(1 downto 0) := "10";
  constant TAG_BRU    : std_logic_vector(1 downto 0) := "11";

  constant STB_LEN : natural := 5;
  constant LDB_LEN : natural := 5;
  constant REG_LEN : natural := 5;
  constant ROB_LEN : natural := 5;
  constant EXB_LEN : natural := 5;
  constant BRU_LEN : natural := 3;

  constant MAX_UNIT_LEN : natural := MAXIMUM((ROB_LEN, EXB_LEN, REG_LEN, LDB_LEN, STB_LEN));

  constant TAG_LEN : natural := TAG_BITS + MAX_UNIT_LEN;

  type unit is (UNIT_RGU, UNIT_LDU, UNIT_STU, UNIT_BRU);

  --! \fn format_tag
  --! \arg u   The unit that the tag is destined to
  --! \arg buf The buffer address which the value will be written back
  --! \brief Formats the tag in the correct format
  --! \note Depends on *_LEN constants, TAG_* constants, MAX_UNIT_LEN, TAG_LEN and unit type
  impure function format_tag(u : unit; buf : std_logic_vector) return std_logic_vector;

  --! \fn read_tag
  --! \arg tag the tag to read from
  --! \brief Returns the TAG_* value in the tag vector
  impure function read_tag(tag : std_logic_vector) return std_logic_vector;

  --! \fn unpack_tag
  --! \arg tag the tag to read from
  --! \brief Returns the tag address in the tag vector
  impure function unpack_tag(tag : std_logic_vector) return std_logic_vector;

end package;


package body tag_pkg is

  impure function format_tag(u : unit; buf : std_logic_vector) return std_logic_vector is
    variable resize_buf : std_logic_vector(MAX_UNIT_LEN-1 downto 0) := (others => '0');
    variable tag : std_logic_vector(TAG_LEN-1 downto 0);
  begin

    if buf'length > resize_buf'length then
      assert false report "Buffer length is greated that maximum unit buffer length" severity failure;
    end if;

    if buf'right /= 0 then
      assert false report "invalid range specified for buffer: Right parameter must be 0" severity failure;
    end if;

    resize_buf(buf'range) := buf;

    case u is
      when UNIT_RGU => tag := TAG_RGU & resize_buf;
      when UNIT_LDU => tag := TAG_LDU & resize_buf;
      when UNIT_STU => tag := TAG_STU & resize_buf;
      when UNIT_BRU => tag := TAG_BRU & resize_buf;
      when others =>
        assert false report "Invalid unit specified" severity failure;
    end case;

    return tag;
  end function;


  impure function read_tag(tag : std_logic_vector) return std_logic_vector is
  begin
    return tag(tag'left downto tag'left-TAG_BITS+1);
  end function;

  impure function unpack_tag(tag : std_logic_vector) return std_logic_vector is
  begin
    case read_tag(tag) is
      when TAG_RGU =>
        return tag(ROB_LEN-1 downto 0);
      when TAG_LDU =>
        return tag(LDB_LEN-1 downto 0);
      when TAG_STU =>
        return tag(STB_LEN-1 downto 0);
      when TAG_BRU =>
        return tag(BRU_LEN-1 downto 0);
      when others =>
    end case;

    return(others => 'X');
  end function;

end package body;
