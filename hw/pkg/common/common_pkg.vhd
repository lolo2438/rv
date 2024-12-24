library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package common_pkg is

  ---
  -- TYPE DEFINITION
  ---

  --! \brief Type definition for a matrix of std_logic
  type std_logic_matrix is array (natural range <>) of std_logic_vector;


  ---
  -- FUNCTION DEFINITION
  ---

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
  pure function bit_reverse(val : std_logic_vector) return std_logic_vector;

end package;


package body common_pkg is

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

    return (others => 'X');
  end function;


  pure function bit_reverse(val : std_logic_vector) return std_logic_vector is
    variable out_val : std_logic_vector(val'length-1 downto 0);
  begin
    for i in val'range loop
      out_val(i) := val(out_val'length-1-i);
    end loop;
    return out_val;
  end function;

end package body;
