library ieee;
use ieee.std_logic_1164.all;

package types is

  --! \brief Type definition for a matrix of std_logic
  type std_logic_matrix is array (natural range <>) of std_logic_vector;

end package;
