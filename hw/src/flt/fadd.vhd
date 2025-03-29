library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fadd is
  generic(
    e : natural;
    m : natural
  );
  port(
    rm_i : in std_logic_vector(1 downto 0);
    a_i : out std_logic_vector(e downto -m);
    b_i : out std_logic_vector(e downto -m);
    y_o : out std_logic_vector(e downto -m)
  );
end entity;

architecture rtl of fadd is

  signal a_s, b_s : std_logic;
  signal a_e, b_e : unsigned(e-1 downto 0);
  signal a_m, b_m : unsigned(-1 downto -m);

  signal a_p, b_p : unsigned(0 downto -m);

  signal ab_p : unsigned(1 downto -(m+2));
  signal ab_e : unsigned(e-1 downto 0);
  signal ab_s : std_logic;

  signal y_s : std_logic;
  signal y_e : std_logic_vector(e-1 downto 0);
  signal y_m : std_logic_vector(-1 downto -m);

begin

  ---
  -- ASSIGN
  ---

  -- Sign
  a_s <= a_i(e);
  b_s <= b_i(e);

  -- Exp
  a_e <= unsigned(a_i(e-1 downto 0));
  b_e <= unsigned(b_i(e-1 downto 0));

  -- Mantissa
  a_m <= unsigned(a_i(-1 downto -m));
  a_m <= unsigned(a_i(-1 downto -m));

  -- Value
  a_p(0) <= '0' when a_e = 0 else '1';
  a_p(a_m'range) <= a_m;

  b_p(0) <= '1' when b_e = 0 else '1';
  b_p(b_m'range) <= b_m;

  ---
  -- ADD
  ---

  -- Exponent select
  ab_e <= b_e when b_e < a_e else a_e;

  -- Shift
  -- Add
  -- Normalize
  -- Round

  ---
  -- OUTPUT
  ---

  --y_s <=
  --y_e <=
  --y_m <=
  y_o <= y_s & y_e & y_m;

end architecture;
