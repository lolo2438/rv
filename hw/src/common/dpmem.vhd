library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dpmem is
  generic(
    DATA_WIDTH : natural;
    ADDR_WIDTH : natural
  );
  port(
    i_clk    : in  std_logic;
    i_en     : in  std_logic;
    i_we     : in  std_logic_vector(DATA_WIDTH/8-1 downto 0);
    i_waddr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    i_wdata  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    i_raddr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    o_rdata  : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end entity dpmem;

architecture rtl of dpmem is

  type mem_t is array (natural range <>) of std_logic_vector(DATA_WIDTH-1 downto 0);
  signal mem_s : mem_t(0 to (2**ADDR_WIDTH)-1);

begin

  assert real(DATA_WIDTH) / 8.0 >= real(DATA_WIDTH / 8)
  report "DATA_WIDTH must be a multiple of 8"
  severity failure;

  process(i_clk)
  begin
    if rising_edge(i_clk) then
      if i_en = '1' then

        for i in 0 to i_we'length-1 loop
          if i_we(i) = '1' then
            mem_s(to_integer(unsigned(i_waddr)))((i+1)*8-1 downto i*8) <= i_wdata((i+1)*8-1 downto i*8);
          end if;
        end loop;

        o_rdata <= mem_s(to_integer(unsigned(i_raddr)));
      end if;
    end if;
  end process;

end architecture rtl;
