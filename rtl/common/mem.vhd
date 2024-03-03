library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem is
  generic(
    DATA_WIDTH : natural;
    ADDR_WIDTH : natural
  );
  port(
    clk_i   : in  std_logic;
    en_i    : in  std_logic;
    we_i    : in  std_logic_vector(DATA_WIDTH/8-1 downto 0);
    addr_i  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end entity mem;

architecture rtl of mem is

  type mem_t is array (natural range <>) of std_logic_vector(DATA_WIDTH-1 downto 0);
  signal mem_s : mem_t(0 to (2**ADDR_WIDTH)-1);

begin

  assert real(DATA_WIDTH) / 8.0 >= real(DATA_WIDTH / 8)
  report "DATA_WIDTH must be a multiple of 8"
  severity failure;

  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if en_i = '1' then

        for i in 0 to we_i'length-1 loop
          if we_i(i) = '1' then
            mem_s(to_integer(unsigned(addr_i)))((i+1)*8-1 downto i*8) <= data_i((i+1)*8-1 downto i*8);
          end if;
        end loop;

        data_o <= mem_s(to_integer(unsigned(addr_i)));
      end if;
    end if;
  end process;

end architecture rtl;
