library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library common;
use common.types.std_logic_matrix;

entity spmem is
  generic(
    USE_INIT_FILE : boolean := false;
    INIT_FILE     : string := "";
    DATA_WIDTH    : natural;
    ADDR_WIDTH    : natural
  );
  port(
    i_clk   : in  std_logic;
    i_en    : in  std_logic;
    i_we    : in  std_logic_vector(DATA_WIDTH/8-1 downto 0);
    i_addr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    i_data  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    o_data  : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end entity spmem;

architecture rtl of spmem is

  signal mem      : std_logic_matrix(0 to (2**ADDR_WIDTH)-1)(DATA_WIDTH-1 downto 0);
  --:= if USE_INIT_FILE then init_mem_from_hex_file(INIT_FILE) end if;

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
            mem(to_integer(unsigned(i_addr)))((i+1)*8-1 downto i*8) <= i_data((i+1)*8-1 downto i*8);
          end if;
        end loop;
      end if;
    end if;
  end process;

  o_data <= mem(to_integer(unsigned(i_addr)));

end architecture rtl;
