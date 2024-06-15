library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

package common_pkg is

  function clog2 (x : integer) return integer;

  type std_logic_array is array (natural range <>) of std_logic_vector;

end package;


package body common_pkg is

  function clog2 (x : integer) return integer is
  begin
    return integer(ceil(log2(real(x))));
  end function;

end package body;
