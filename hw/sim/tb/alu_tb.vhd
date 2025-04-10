library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library riscv;
use riscv.RV32I.all;

library hw;
use hw.tag_pkg.all;

library sim;
use sim.tb_pkg.clk_gen;

library vunit_lib;
context vunit_lib.vunit_context;

entity alu_tb is
	generic (runner_cfg : string);
end entity;

architecture tb of alu_tb is

  ---
  -- DUT CONSTANTS
  ---
  constant XLEN    : natural := 32;

  ---
  -- DUT SIGNALS
  ---
  signal i_clk   : std_logic := '0';
  signal i_valid : std_logic := '0';
  signal i_tq    : std_logic_vector(TAG_LEN-1 downto 0) := (others => '0');
  signal i_a     : std_logic_vector(XLEN-1 downto 0) := (others => '0');
  signal i_b     : std_logic_vector(XLEN-1 downto 0) := (others => '0');
  signal i_f3    : std_logic_vector(2 downto 0) := (others => '0');
  signal i_f7    : std_logic_vector(6 downto 0) := (others => '0');
  signal o_c     : std_logic_vector(XLEN-1 downto 0);
  signal o_tq    : std_logic_vector(TAG_LEN-1 downto 0);
  signal o_done  : std_logic;


  ---
  -- TB CONSTANTS
  ---
	constant CLK_FREQ : real := 100.0e6;


  ---
  -- TB SIGNALS
  ---

begin

  clk_gen(i_clk, CLK_FREQ);

  main :
  process
    variable in1, in2, res : signed(XLEN-1 downto 0);
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop

      --TODO: make these two values RANDOM
      in1 := x"00001234";
      in2 := x"00004321";

      if run("add") then
        res := in1 + in2;

        i_f3 <= FUNCT3_ADDSUB;

        i_a <= std_logic_vector(in1);
        i_b <= std_logic_vector(in2);

        wait until rising_edge(i_clk);
        wait until rising_edge(i_clk);
        check_equal(o_c, std_logic_vector(res));

      elsif run("sub") then
        res := in1 - in2;

        i_f7 <= FUNCT7_SUB;
        i_f3 <= FUNCT3_ADDSUB;

        i_a <= std_logic_vector(in1);
        i_b <= std_logic_vector(in2);

        wait until rising_edge(i_clk);
        wait until rising_edge(i_clk);
        check_equal(o_c, std_logic_vector(res));

      elsif run("sll") then
        res := in1 sll to_integer(in2(4 downto 0));

        i_f3 <= FUNCT3_SL;
        i_f7 <= FUNCT7_SLL;

        i_a <= std_logic_vector(in1);
        i_b <= std_logic_vector(in2);

        wait until rising_edge(i_clk);
        wait until rising_edge(i_clk);
        check_equal(o_c, std_logic_vector(res));

      elsif run("srl") then
        res := in1 srl to_integer(in2(4 downto 0));

        i_f7 <= FUNCT7_SRL;
        i_f3 <= FUNCT3_SR;

        i_a <= std_logic_vector(in1);
        i_b <= std_logic_vector(in2);

        wait until rising_edge(i_clk);
        wait until rising_edge(i_clk);
        check_equal(o_c, std_logic_vector(res));

      elsif run("sra") then
        res := in1 sra to_integer(in2(4 downto 0));

        i_f7 <= FUNCT7_SRA;
        i_f3 <= FUNCT3_SR;

        i_a <= std_logic_vector(in1);
        i_b <= std_logic_vector(in2);

        wait until rising_edge(i_clk);
        wait until rising_edge(i_clk);
        check_equal(o_c, std_logic_vector(res));

      elsif run("and") then
        res := in1 and in2;

        i_f3 <= FUNCT3_AND;

        i_a <= std_logic_vector(in1);
        i_b <= std_logic_vector(in2);

        wait until rising_edge(i_clk);
        wait until rising_edge(i_clk);
        check_equal(o_c, std_logic_vector(res));

      elsif run("or") then
        res := in1 or in2;

        i_f3 <= FUNCT3_OR;

        i_a <= std_logic_vector(in1);
        i_b <= std_logic_vector(in2);

        wait until rising_edge(i_clk);
        wait until rising_edge(i_clk);
        check_equal(o_c, std_logic_vector(res));

      elsif run("xor") then
        res := in1 xor in2;

        i_f3 <= FUNCT3_XOR;

        i_a <= std_logic_vector(in1);
        i_b <= std_logic_vector(in2);

        wait until rising_edge(i_clk);
        wait until rising_edge(i_clk);
        check_equal(o_c, std_logic_vector(res));

      elsif run("slt") then
        if in1 > in2 then
          res := to_signed(1, res'length);
        else
          res := to_signed(0, res'length);
        end if;

        i_f3 <= FUNCT3_SLT;

        i_a <= std_logic_vector(in1);
        i_b <= std_logic_vector(in2);

        wait until rising_edge(i_clk);
        wait until rising_edge(i_clk);
        check_equal(o_c, std_logic_vector(res));

      elsif run("sltu") then

        if unsigned(in1) > unsigned(in2) then
          res := to_signed(1, res'length);
        else
          res := to_signed(0, res'length);
        end if;

        i_f3 <= FUNCT3_SLTU;

        i_a <= std_logic_vector(in1);
        i_b <= std_logic_vector(in2);

        wait until rising_edge(i_clk);
        wait until rising_edge(i_clk);
        check_equal(o_c, std_logic_vector(res));

      elsif run("done") then
        i_valid <= '1';
        check_equal(o_done, '0', "t=0: done undefined");
        wait until rising_edge(i_clk);
        check_equal(o_done, '0', "t=clk1: done undefined");
        i_valid <= '0';
        wait until rising_edge(i_clk);
        check_equal(o_done, '1', "t=clk2: Valid compute");
        wait until rising_edge(i_clk);
        check_equal(o_done, '0', "t=clk2: not a valid compute ");

      elsif run("tag") then
        i_tq <= TAG_RGU;
        check_equal(o_tq, std_logic_vector'("00"));
        wait until rising_edge(i_clk);
        i_tq <= TAG_BRU;
        check_equal(o_tq, std_logic_vector'("00"));
        wait until rising_edge(i_clk);
        check_equal(o_tq, std_logic_vector'(TAG_RGU));
        wait until rising_edge(i_clk);
        check_equal(o_tq, std_logic_vector'(TAG_BRU));
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

  u_dut:
  entity hw.alu
  generic map (
    TAG_LEN => TAG_LEN,
    XLEN    => XLEN
  )
  port map (
    i_clk   => i_clk,
    i_valid => i_valid,
    i_tq    => i_tq,
    i_a     => i_a,
    i_b     => i_b,
    i_f3    => i_f3,
    i_f7    => i_f7,
    o_c     => o_c,
    o_tq    => o_tq,
    o_done  => o_done
  );

end architecture;

