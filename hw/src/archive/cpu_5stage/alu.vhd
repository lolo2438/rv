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
    clk_i   : in  std_logic;
    rst_i   : in  std_logic;
    a_i     : in  std_logic_vector(XLEN-1 downto 0);
    b_i     : in  std_logic_vector(XLEN-1 downto 0);
    f3_i    : in  std_logic_vector(2 downto 0);
    f7_i    : in  std_logic_vector(6 downto 0);
    c_o     : out std_logic_vector(XLEN-1 downto 0)
  );
end entity;

architecture rtl of alu is

  signal alu_add : std_logic_vector(XLEN-1 downto 0);
  signal alu_sl  : std_logic_vector(XLEN-1 downto 0);
  signal alu_slt : std_logic_vector(XLEN-1 downto 0);
  signal alu_sltu: std_logic_vector(XLEN-1 downto 0);
  signal alu_xor : std_logic_vector(XLEN-1 downto 0);
  signal alu_sr  : std_logic_vector(XLEN-1 downto 0);
  signal alu_or  : std_logic_vector(XLEN-1 downto 0);
  signal alu_and : std_logic_vector(XLEN-1 downto 0);

begin

  alu_add  <= std_logic_vector(resize(signed(a_i) - signed(b_i), alu_add'length)) when f3_i = FUNCT3_ADDSUB and f7_i = FUNCT7_SUB else
              std_logic_vector(resize(signed(a_i) + signed(b_i), alu_add'length)) when f3_i = FUNCT3_ADDSUB and f7_i = FUNCT7_ADD else
              (others => '0');

  alu_sl   <= std_logic_vector(shift_left(unsigned(a_i), to_integer(unsigned(b_i)))) when f3_i = FUNCT3_SL and F7_i = FUNCT7_SLL else (others => '0');

  alu_slt  <= std_logic_vector(to_unsigned(1 ,alu_slt'length)) when f3_i = FUNCT3_SLT  and signed(a_i)   < signed(b_i)   else (others => '0');
  alu_sltu <= std_logic_vector(to_unsigned(1, alu_slt'length)) when f3_i = FUNCT3_SLTU and unsigned(a_i) < unsigned(b_i) else (others => '0');

  alu_xor  <= a_i xor b_i when f3_i = FUNCT3_XOR else (others => '0');

  alu_sr   <= std_logic_vector(shift_right(signed(a_i), to_integer(unsigned(b_i)))) when f3_i = FUNCT3_SR and f7_i = FUNCT7_SRA else
              std_logic_vector(shift_right(unsigned(a_i), to_integer(unsigned(b_i)))) when f3_i = FUNCT3_SR and f7_i = FUNCT7_SRL else
              (others => '0');

  alu_or   <= a_i or  b_i when f3_i = FUNCT3_OR  else (others => '0');
  alu_and  <= a_i and b_i when f3_i = FUNCT3_AND else (others => '0');

  -- TODO: If OP32(RV64) or OP64(RV128)
  -- Sign extend from bit 32 (RV64) or bit 64(RV128)
  with f3_i select
    c_o <= alu_add  when FUNCT3_ADDSUB,
           alu_sl   when FUNCT3_SL,
           alu_slt  when FUNCT3_SLT,
           alu_sltu when FUNCT3_SLTU,
           alu_xor  when FUNCT3_XOR,
           alu_sr   when FUNCT3_SR,
           alu_or   when FUNCT3_OR,
           alu_and  when FUNCT3_AND,
           (others => '0') when others;

end architecture;

