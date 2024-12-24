library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library riscv;
use riscv.RV32I.all;

entity alu is
  generic(
    XLEN  : natural
  );
  port(
    a_i     : in  std_logic_vector(XLEN-1 downto 0);
    b_i     : in  std_logic_vector(XLEN-1 downto 0);
    f3_i    : in  std_logic_vector(2 downto 0);
    f7_i    : in  std_logic_vector(6 downto 0);
    c_o     : out std_logic_vector(XLEN-1 downto 0)
  );
end entity;

architecture rtl of alu is

  signal a, b, c : std_logic_vector(XLEN-1 downto 0);
  signal c_add : unsigned(XLEN downto 0);

  signal csub : std_logic;
  signal csra : std_logic;

  signal add, sltu, slt, sl, sr : std_logic_vector(XLEN-1 downto 0);

begin

  csub <= '1' when (f3_i = FUNCT3_ADDSUB and f7_i = FUNCT7_SUB) or (f3_i = FUNCT3_SLT) or (f3_i = FUNCT3_SLTU) else '0';

  a <= a_i;
  b <= not(b_i) when csub = '1' else b_i;

  c_add <= resize(unsigned(a), c_add'length) + unsigned(b) + unsigned'("" & csub);

  sl   <= std_logic_vector(shift_left(unsigned(a_i), to_integer(unsigned(b_i))));

  csra <= '1' when (f3_i = FUNCT3_SR and f7_i = FUNCT7_SRA) else '0';
  sr   <= std_logic_vector(shift_right(signed(a_i), to_integer(unsigned(b_i)))) when csra = '1' else
          std_logic_vector(shift_right(unsigned(a_i), to_integer(unsigned(b_i))));

  -- TODO: If OP32(RV64) or OP64(RV128)
  -- Sign extend from bit 32 (RV64) or bit 64(RV128)
  add <= std_logic_vector(c_add(XLEN-1 downto 0));
  slt <= (others => '0', 0 => add(XLEN-1));
  sltu <= (others => '0', 0 => add(XLEN));
  with f3_i select
    c <= add        when FUNCT3_ADDSUB,
         sl         when FUNCT3_SL,
         slt        when FUNCT3_SLT,
         sltu       when FUNCT3_SLTU,
         a xor b    when FUNCT3_XOR,
         sr         when FUNCT3_SR,
         a or b     when FUNCT3_OR,
         a and b    when FUNCT3_AND,
         (others => '0') when others; -- Impossible

  c_o <= c;

end architecture;

