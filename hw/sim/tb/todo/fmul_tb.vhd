library ieee;
use ieee.std_logic_1164.all;
use ieee.float_pkg.all;

use std.textio.all;
use std.env.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity fmul_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of fmul_tb is

  component fmul is
  generic(
    e : natural;
    m : natural
  );
  port (
    rm_i  : in  std_logic_vector(1 downto 0);
    overflow_o : out std_logic;
    underflow_o : out std_logic;
    inexact_o : out std_logic;
    a_i : in  std_logic_vector(e downto -m);
    b_i : in  std_logic_vector(e downto -m);
    y_o : out std_logic_vector(e downto -m)
  );
  end component;

  constant e : natural := 5;
  constant m : natural := 10;

  signal rm_i : std_logic_vector(1 downto 0);
  signal a_i : std_logic_vector(e+m downto 0);
  signal y_o : std_logic_vector(e+m downto 0);
  signal b_i : std_logic_vector(e+m downto 0);
  signal overflow_o : std_logic;
  signal underflow_o : std_logic;
  signal inexact_o : std_logic;

begin

  DUT : fmul
    generic map(
      e => e,
      m => m
    )
    port map (
      rm_i => rm_i,
      overflow_o => overflow_o,
      underflow_o => underflow_o,
      inexact_o => inexact_o,
      a_i => a_i,
      b_i => b_i,
      y_o => y_o
    );

    main :
    process
      variable a, b, y : float(e downto -m);
    begin

      test_runner_setup(runner, runner_cfg);
      while test_suite loop

        rm_i <= (others => '0');

        -- NORMAL_NORMAL_NORMAL
        if run("pnormal_x_pnormal_=_pnormal") then
          a := x"430F"; -- 3.53
          b := x"32B2"; -- 0.2093
        elsif run("pnormal_x_nnormal_=_nnormal") then
          a := x"189F"; -- 0.002257
          b := x"D89F"; -- -147.9

        -- NORMAL_NORMAL_SUBNORMAL
        elsif run("normal_x_normal_=_subnormal") then
          a := x"065A"; -- 0.00009692
          b := x"21A8"; -- 0.01105

        -- NORMAL_SUBNORMAL_NORMAL
        elsif run("pnormal_x_psubnormal_=_00_pnormal") then
          a := x"7879"; -- 36640
          b := x"0029"; -- 0.0000025
        elsif run("pnormal_x_nsubnormal_=_01_nnormal") then
          a := x"7200"; -- 12288
          b := x"8300"; -- -0.0000458
        elsif run("nsubnormal_x_nnormal_=_00_pnormal") then
          a := x"8018"; -- -0.00000144
          b := x"F807"; -- -32992
        elsif run("psubnormal_x_nnormal_=_01_nnormal") then
          a := x"03B7"; -- 0.0000567
          b := x"F36B"; -- -15192

        -- NORMAL_SUBNORMAL_SUBNORMAL
        elsif run("normal_x_subnormal_=_subnormal") then
          a := x"4250"; -- 3.517
          b := x"0015"; -- 0.0000013

        elsif run("subnormal_x_normal_=_subnormal") then
          -- TODO: changer les nombres
          b := x"0015"; -- 0.0000013
          a := x"4250"; -- 3.517


        -- OVERFLOW
        elsif run("normal_overflow") then
          a := x"7BF0"; -- 65024
          b := x"4A5A"; -- 12.71

        -- UNDERFLOW
        elsif run("normal_normal_underflow") then
          a := x"0400"; -- 2^-14
          b := x"1000"; -- 2^-11
        elsif run("subnormal_normal_underflow") then
          a := x"0005"; -- 2.99e-7
          b := x"2CFA"; -- 0.0778
        elsif run("subnormal_subnormal_underflow") then
          a := x"03FF"; -- 2*-14*0.9981
          b := x"03FF"; -- 2*-14*0.9981

        -- SPECIAL
        elsif run("pinf_x_ninf") then
          a := x"7C00"; -- inf
          b := x"FC00"; -- -inf
        elsif run("inf_x_zero") then
          a := x"7C00"; -- inf
          b := x"0000"; -- zero
        elsif run("normal_x_zero") then
          a := x"5855"; -- 138.7
          b := x"0000"; -- zero
        elsif run("subnormal_x_zero") then
          a := x"0001"; -- 5.97e-8
          b := x"0000"; -- zero
        elsif run("ninf_x_nnormal") then
          a := x"FC00"; -- ninf
          b := x"9C5C"; -- -0.00426
        elsif run("inf_x_subnormal") then
          a := x"FC00"; -- ninf
          b := x"800A"; -- -5.97e-7
        elsif run("NaN_x_normal") then
          a := x"7C01"; -- NaN
          b := x"6531"; -- 1329
        elsif run("NaN_x_inf") then
          a := x"7C01"; -- NaN
          b := x"7C00"; -- inf
        elsif run("NaN_x_subnormal") then
          a := x"7C01"; -- NaN
          b := x"0131"; -- 0.0000182
        elsif run("NaN_x_zero") then
          a := x"7C01"; -- NaN
          b := x"0000"; -- zero
        elsif run("NaN_x_NaN") then
          a := x"7C01"; -- NaN
          b := x"7C02"; -- NaN
        --elsif run("random") then
        end if;

        y := a * b;
        a_i <= to_slv(a);
        b_i <= to_slv(b);
        wait for 1 ns;
        check_equal(y_o, to_slv(y));

      end loop;
      test_runner_cleanup(runner);
    end process;

end architecture;
