library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library riscv;
use riscv.RV32I.all;

entity alu is
  generic(
    TAG_LEN : natural;
    XLEN    : natural
  );
  port(
    i_clk   : in  std_logic;
    i_valid : in  std_logic;
    i_tq    : in  std_logic_vector(TAG_LEN-1 downto 0);
    i_a     : in  std_logic_vector(XLEN-1 downto 0);
    i_b     : in  std_logic_vector(XLEN-1 downto 0);
    i_f3    : in  std_logic_vector(2 downto 0);
    i_f7    : in  std_logic_vector(6 downto 0);
    o_c     : out std_logic_vector(XLEN-1 downto 0);
    o_tq    : out std_logic_vector(TAG_LEN-1 downto 0);
    o_done  : out std_logic
  );
end entity;

architecture rtl of alu is

  signal a, b, c : std_logic_vector(XLEN-1 downto 0);
  signal c_add : unsigned(XLEN downto 0);

  signal csub : std_logic;
  signal csra : std_logic;

  signal add, sltu, slt, sl, sr : std_logic_vector(XLEN-1 downto 0);

begin

  csub <= '1' when (i_f3 = FUNCT3_ADDSUB and i_f7 = FUNCT7_SUB) or (i_f3 = FUNCT3_SLT) or (i_f3 = FUNCT3_SLTU) else '0';

  a <= i_a;
  b <= not(i_b) when csub = '1' else i_b;

  c_add <= resize(unsigned(a), c_add'length) + unsigned(b) + unsigned'("" & csub);

  sl   <= std_logic_vector(shift_left(unsigned(i_a), to_integer(unsigned(i_b(4 downto 0)))));

  csra <= '1' when (i_f3 = FUNCT3_SR and i_f7 = FUNCT7_SRA) else '0';
  sr   <= std_logic_vector(shift_right(signed(i_a), to_integer(unsigned(i_b(4 downto 0))))) when csra = '1' else
          std_logic_vector(shift_right(unsigned(i_a), to_integer(unsigned(i_b(4 downto 0)))));


  -- TODO: If OP32(RV64) or OP64(RV128)
  -- Sign extend from bit 32 (RV64) or bit 64(RV128)
  add <= std_logic_vector(c_add(XLEN-1 downto 0));
  slt <= (0 => c_add(XLEN), others => '0');
  sltu <= (0 => c_add(XLEN), others => '0');
  with i_f3 select
    c <= add        when FUNCT3_ADDSUB,
         sl         when FUNCT3_SL,
         slt        when FUNCT3_SLT,
         sltu       when FUNCT3_SLTU,
         a xor b    when FUNCT3_XOR,
         sr         when FUNCT3_SR,
         a or b     when FUNCT3_OR,
         a and b    when FUNCT3_AND,
         (others => '0') when others; -- Impossible


  ---
  -- OUTPUT
  ---
  o_c     <= c when rising_edge(i_clk);
  o_tq    <= i_tq when rising_edge(i_clk);
  o_done  <= i_valid when rising_edge(i_clk);

end architecture;

