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
  pure function clog2 (x : positive) return positive;

  --! \param input an input vector encoded with binary addressing
  --! \return a one hot encoded version of the vector
  --! \brief Converts an address (b"10") to a one hot encoded version (b"0100")
  pure function one_hot_encoder(input : std_logic_vector) return std_logic_vector;

  --! \param input an input vector encoded with left most bit having more priority
  --! \return the address of the bit with the most priority
  --! \brief
  --!        Ascending: b"1000" -> b"00"
  --!        Descending: b"1000" -> b"11"
  pure function priority_encoder(input : std_logic_vector) return std_logic_vector;

  --! \param input an input vector containing the bits to be reversed
  --! \return The reversed vector
  --! \brief Reverses the vector : b"0100" -> b"0010"
  pure function bit_reverse(input : std_logic_vector) return std_logic_vector;

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


  pure function clog2 (x : positive) return positive is
  begin
    return positive(ceil(log2(real(x))));
  end function;


  pure function one_hot_encoder(input : std_logic_vector) return std_logic_vector is
  constant ENCODING_SIZE : natural := 2**input'length;
  variable enc_out : std_logic_vector(ENCODING_SIZE-1 downto 0) := (others => '0');
  begin
    for i in 0 to ENCODING_SIZE-1 loop
      if to_integer(unsigned(input)) = i then
        if input'ascending then
          enc_out(ENCODING_SIZE-1-i) := '1';
        else
          enc_out(i) := '1';
        end if;
        return enc_out;
      end if;
    end loop;

    enc_out := (others => 'X');
    return enc_out;
  end function;


  pure function priority_encoder(input : std_logic_vector) return std_logic_vector is
  constant ret_len : natural := clog2(input'length);
  constant enc_out : std_logic_vector(ret_len-1 downto 0) := (others => 'X');
  begin
    if input'ascending then
      for i in 0 to input'length-1 loop
        if input(i) = '1' then
          return std_logic_vector(to_unsigned(i, ret_len));
        end if;
      end loop;
    else
      for i in input'length-1 downto 0 loop
        if input(i) = '1' then
          return std_logic_vector(to_unsigned(i, ret_len));
        end if;
      end loop;
    end if;

    return enc_out;
  end function;


  pure function bit_reverse(input : std_logic_vector) return std_logic_vector is
    variable output : std_logic_vector(input'length-1 downto 0);
  begin
      for i in 0 to input'length-1 loop
        if input'ascending then
          output(i) := input(i);
        else
          output(i) := input(input'length-1-i);
        end if;
      end loop;

    return output;
  end function;

end package body;
