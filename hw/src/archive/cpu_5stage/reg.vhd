library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types_pkg.all;

entity reg is
  generic (
    RLEN : natural;
    XLEN : natural
  );
  port (
    clk_i : in  std_logic;
    we_i  : in  std_logic;
    rs1_i : in  std_logic_vector(RLEN-1 downto 0);
    rs2_i : in  std_logic_vector(RLEN-1 downto 0);
    rd_i  : in  std_logic_vector(RLEN-1 downto 0);
    res_i : in  std_logic_vector(XLEN-1 downto 0);
    op1_o : out std_logic_vector(XLEN-1 downto 0);
    op2_o : out std_logic_vector(XLEN-1 downto 0)
  );
end entity;

architecture rtl of reg is

  signal x : std_logic_array(0 to 2**RLEN-1)(XLEN-1 downto 0);

begin

  p_reg:
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if we_i = '1' then
        x(to_integer(unsigned(rd_i))) <= res_i;
      end if;

      x(0) <= (others => '0');
    end if;
  end process;

  op1_o <= x(to_integer(unsigned(rs1_i)));
  op2_o <= x(to_integer(unsigned(rs2_i)));

end architecture;
