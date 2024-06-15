library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity fmul is
  generic(
    e : natural;
    m : natural
  );
  port (
    rm_i : in  std_logic_vector(1 downto 0);
    overflow_o : out std_logic;
    underflow_o : out std_logic;
    inexact_o : out std_logic;
    a_i : in  std_logic_vector(e downto -m);
    b_i : in  std_logic_vector(e downto -m);
    y_o : out std_logic_vector(e downto -m)
  );
end entity;

architecture rtl of fmul is

  constant e_max : natural := 2**e-1;

  signal a_s, b_s : std_logic;
  signal a_e, b_e : unsigned(e-1 downto 0);
  signal a_m, b_m : unsigned(-1 downto -m);
  signal a_p, b_p : unsigned(0 downto -m);

  signal y_s : std_logic;
  signal y_e : std_logic_vector(e-1 downto 0);
  signal y_m : std_logic_vector(m-1 downto 0);

  signal ab_et: unsigned(e downto 0);
  signal ab_es: unsigned(e-1 downto 0);
  signal ab_e : unsigned(e-1 downto 0);
  signal ab_p : unsigned(1 downto -2*m);
  signal ab_v : unsigned(1 downto -2*m);
  signal ab_lzd : unsigned(natural(ceil(log2(real(m))))-1 downto 0);

  signal ab_n : unsigned(-1 downto -(m+1));
  signal ab_r : unsigned(-1 downto -(m+1));

  signal norm_shift : natural; -- TODO: limit the range

  signal normal : std_logic;
  signal round : std_logic;

  signal a_zero : std_logic;
  signal b_zero : std_logic;

  signal a_e_zero : std_logic;
  signal b_e_zero : std_logic;

  signal a_e_max : std_logic;
  signal b_e_max : std_logic;

  signal a_m_zero : std_logic;
  signal b_m_zero : std_logic;

  signal a_inf : std_logic;
  signal b_inf : std_logic;

  signal a_nan : std_logic;
  signal b_nan : std_logic;

  signal subnormal : std_logic;
  signal overflow : std_logic;  -- '1' si
  signal underflow : std_logic; -- '1' si
  signal inexact : std_logic;   -- '1' dans le cas où si on avait pas de limite sur E et M la valeur pourrait etre encode, sinon '0'

begin

  a_m <= unsigned(a_i(-1 downto -m));
  b_m <= unsigned(b_i(-1 downto -m));

  a_m_zero <= '1' when a_m = 0 else '0';
  b_m_zero <= '1' when b_m = 0 else '0';

  -- Exponent:
  a_e <= unsigned(a_i(e-1 downto 0));
  b_e <= unsigned(b_i(e-1 downto 0));

  a_e_zero <= '1' when a_e = 0 else '0';
  b_e_zero <= '1' when b_e = 0 else '0';

  a_e_max <= '1' when a_e = 2**e-1 else '0';
  b_e_max <= '1' when b_e = 2**e-1 else '0';

  -- Special cases, maybe use conditions instead
  a_zero <= '1' when a_e = 0 and a_m = 0 else '0';
  b_zero <= '1' when b_e = 0 and b_m = 0 else '0';

  a_inf <= '1' when a_e = e_max and a_m = 0 else '0';
  b_inf <= '1' when b_e = e_max and b_m = 0 else '0';

  a_nan <= '1' when a_e = e_max and a_m /= 0 else '0';
  b_nan <= '1' when b_e = e_max and b_m /= 0 else '0';

  normal <= '1' when a_e /= 0 and b_e /= 0 else '0';


  ab_et <= ("0" & a_e) + ("0" & b_e) + 1;

  process(normal, ab_et)
  begin
    subnormal <= '0';
    overflow <= '0';

    if normal = '1' then
      case ab_et(e downto e-1) is
        when "00" =>
          subnormal <= '1';
        when "11" =>
          overflow <= '1';
        when others =>
      end case;
    else
      subnormal <= '1';
    end if;
  end process;


  subnormal <= '1' when ab_et(e downto e-1) = "00" else '0';
  overflow <= '1' when ab_et(e downto e-1) = "11" else '0';

  ab_e(e-1) <= ab_et(e);
  ab_e(e-2 downto 0) <= ab_et(e-2 downto 0);

  -- SIGN
  a_s <= a_i(e);
  b_s <= b_i(e);

  -- MANTISSA
  a_p(0) <= '0' when a_e = 0 else '1';
  a_p(-1 downto -m) <= unsigned(a_i(-1 downto -m));

  b_p(0) <= '0' when b_e = 0 else '1';
  b_p(-1 downto -m) <= unsigned(b_i(-1 downto -m));

  -- Multiply
  ab_p <= a_p * b_p;

  ab_es <= ab_e;

  -- Normal = 1, subnormal = 0
  -- * (NORMAL_X_NORMAL_=_NORMAL)
  --   1. Shift right by 1 if ab_p(1) = '1' else do notheing
  --   2. Ey += ab_p(1);
  -- Normal = 1, subnormal = 1
  -- * (NORMAL_X_NORMAL_=_SUBNORMAL)
  --   1. Calculer Ey-Emin = shift
  --   2. shift_right(m, shift)
  --   3. Ey = Emin
  -- Normal = 0, subnormal = 1
  -- * (NORMAL_X_SUBNORMAL_=_NORMAL)
  --   1. Calculer le nombre de zero avant le leading 1 (NLZ)
  --   2. Calculer Ey+NLZ
  --   3. Si Ey+NLZ > EMIN -> normal
  --   4. Shift gauche de NLZ
  --   5. Ey += NLZ (verifier)
  -- * (NORMAL_X_SUBNORMAL_=_SUBNORMAL)
  --   1. Calculer Ey-Emin pour connaitre le shift
  --   2. shift_right(m,shift)
  --   3. Ey=Emin
  -- * (SUBNORMAL_X_SUBONORMAL_=_SUBNORMAL/ZERO)
  --   1.
  --
  -- Si E[e:e-1] = 00 ->
  -- Si E[e:e-1] = 01 ->

  p_lzd:
  process(ab_p)
    variable lzd : natural;
  begin
    for i in -m to 0 loop
      if ab_p(i) = '1' then
        lzd := i;
      end if;
    end loop;
    ab_lzd <= to_unsigned(lzd, ab_lzd'length);
  end process;

  norm_shift <=

               1 when normal = '1' and subnormal = '0' and ab_p(1) = '1' else -- Normal operation, normalize by 1 if there is a carry
                to_integer(ab_es(e-2 downto 0)) when subnormal = '1' else -- E - E = e1 - e2 + (bias - bias) : 2^-14 = 1
                0;

  ab_v <= shift_right(ab_p, norm_shift);

  ab_n <= ab_v(ab_n'range);

  --with ab_p(1) select
  --  ab_n <= ab_p(0 downto -m)      when '1',
  --          ab_p(-1 downto -(m+1)) when others;

  -- Round
  with rm_i select
  round <= '1'     when "00",   -- Round to nearest even
           not y_s when "01",   -- Round towards + inf
           y_s     when "10",   -- Round towards - inf
           '0'     when others; -- Round to zero

  ab_r <= ab_n + round;

  -- OUTPUT
  y_s <= a_s xor b_s;

  -- TODO: Shift right by EXP+1 - 14 when subnormal detected
  --underflow <= '1' when subnormal = '1' and (ab_e - 2**(e-1)-1 > m) else '0';
  -- inexact = '1' when overflow = '1' or underflow = '1' or lsb de la multiplication /= 0 else '0';

  -- Resolutions: (priority)
  -- 1. Nan * anything -> NaN
  -- 2. Zero * inf -> NaN
  -- 3. Zero * anything -> 0
  -- 4. inf * anything -> inf
  y_e <= (others => '1') when (a_nan = '1' or b_nan = '1') else
         (others => '0') when (a_zero = '1' and b_inf = '0') or (b_zero = '1' and a_inf = '0') else
         (others => '1') when a_inf = '1' or b_inf = '1' else
         (others => '1') when overflow = '1' else
         (others => '0') when subnormal = '1' else
         std_logic_vector(ab_e + ab_p(1)); -- Incr by 1 if normalized

  y_m <= std_logic_vector(a_m) when a_nan = '1' else
         std_logic_vector(b_m) when b_nan = '1' else
         std_logic_vector(to_unsigned(1,y_m'length)) when (a_zero = '1' and b_inf = '1') or (b_zero = '1' and a_inf = '1') else
         (others => '0') when (a_zero = '1' or b_zero = '1' or a_inf = '1' or b_inf = '1') else
         (others => '0') when overflow = '1' else
         std_logic_vector(ab_r(-1 downto -m));

  y_o <= y_s & y_e & y_m;

  overflow_o <= overflow;
  underflow_o <= underflow;
  inexact_o <= inexact; --TODO

end architecture;
