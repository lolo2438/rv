library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library std;
use std.textio.all;

use work.types.all;
use work.cnst.all;

package fnct is

  --! \param x The input value
  --! \return clog2(x)
  --! \brief Computes the clog2 of an integer
  pure function clog2 (x : positive) return natural;

  --! \param input an input vector encoded with binary addressing
  --! \return a one hot encoded version of the vector
  --! \brief Converts an address (b"10") to a one hot encoded version (b"0100")
  pure function one_hot_encoder(input : std_ulogic_vector) return std_ulogic_vector;

  --! \param input an input vector encoded with left most bit having more priority
  --! \return the address of the bit with the most priority
  --! \brief
  --!        Ascending: b"1000" -> b"00"
  --!        Descending: b"1000" -> b"11"
  pure function priority_encoder(input : std_ulogic_vector) return std_ulogic_vector;

  --! \param input an input vector containing the bits to be reversed
  --! \return The reversed vector
  --! \brief Reverses the vector : b"0100" -> b"0010"
  pure function bit_reverse(input : std_ulogic_vector) return std_ulogic_vector;

  --! \param[in] file_name The file
  --! \param[out] mem The memory to initialize
  --! \brief Intializes the content of mem with the content of the hexadecimal file specified
  --! \note The content of the file MUST be in hexadecimal and MUST match the size of the memory
  --pure function init_mem_from_hex_file(file_name : in string) return std_logic_matrix;

end package;


package body fnct is


  --pure function init_mem_from_hex_file(file_name : in string) return std_logic_matrix
  --is
  --  file f : text;
  --  variable l : line;
  --  variable status : file_open_status;
  --  variable i : natural := 0;
  --  variable mem : std_logic_matrix;
  --begin
  --  file_open(status, f, file_name, READ_MODE);
  --  if status /= OPEN_OK then
  --    report "Invalid file specified to initialize memory" severity note;
  --    return;
  --  end if;

  --  while not endfile(f) loop
  --    assert i < mem'length
  --    report "Specified memory file " & file_name & " is greater than current memory size"
  --    severity failure;

  --    readline(f, l);

  --    -- There should be 2 hexadecimal character per bytes
  --    assert l'length * BYTE/2 = mem(i)'length
  --    report "Invalid length of data specified to initialize memory in file " & file_name & " at line " & to_string(i)
  --    severity failure;

  --    hread(l, mem(i));
  --    i := i + 1;
  --  end loop;
  --  file_close(f);

  --  return mem;
  --end function;


  pure function clog2 (x : positive) return natural is
  begin
    return natural(ceil(log2(real(x))));
  end function;


  pure function one_hot_encoder(input : std_ulogic_vector) return std_ulogic_vector is
    constant ENCODING_SIZE : natural := 2**input'length;
    constant INVALID_RETURN : std_logic_vector(ENCODING_SIZE-1 downto 0) := (others => 'X');
    variable enc_out : std_logic_vector(ENCODING_SIZE-1 downto 0) := (others => '0');
  begin
    if is_x(input) then
      assert NO_WARNING
        report "COMMON.FNCT."">"": metavalue detected, returning X"
        severity warning;

      return INVALID_RETURN;
    end if;

    if input'ascending then
      -- There seem to be a bug in the body definition of to_integer
      -- A vector (0 to 3) = 0101 will return the value 0x5 instead of 0xA
      -- Thus we need to "bit_reverse" to patch this wrongful behaviour
      enc_out(ENCODING_SIZE - 1 - to_integer(unsigned(bit_reverse(input)))) := '1';
    else
      enc_out(to_integer(unsigned(input))) := '1';
    end if;

    return enc_out;
  end function;


  pure function priority_encoder(input : std_ulogic_vector) return std_ulogic_vector is
    constant RETURN_LENGTH : natural := clog2(input'length);
    constant INVALID_RETURN : std_ulogic_vector(RETURN_LENGTH-1 downto 0) := (others => 'X');
  begin
    if is_x(input) then
      assert NO_WARNING
        report "COMMON.FNCT."">"": metavalue detected, returning X"
        severity warning;

      return INVALID_RETURN;
    end if;

    for i in input'range loop
      if input(i) = '1' then
        return std_ulogic_vector(to_unsigned(i, RETURN_LENGTH));
      end if;
    end loop;

    assert NO_WARNING
      report "COMMON.FNCT."">"": no encoding found, returning X"
      severity warning;

    return INVALID_RETURN;
  end function;


  pure function bit_reverse(input : std_ulogic_vector) return std_ulogic_vector is
    variable output : std_ulogic_vector(input'length-1 downto 0);
  begin
      for i in input'range loop
        if input'ascending then
          output(i) := input(i);
        else
          output(i) := input(input'length-1-i);
        end if;
      end loop;

    return output;
  end function;

end package body;
