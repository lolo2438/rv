library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library common;
use common.types.std_logic_matrix;
use common.fnct.clog2;

entity stack is
  generic(
    DATA_WIDTH : natural;
    STACK_SIZE : natural
  );
  port(
    clk_i   : in  std_logic;
    rst_i   : in  std_logic;
    data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    push_i  : in  std_logic;
    pop_i   : in  std_logic;
    full_o  : out std_logic;
    empty_o : out std_logic;
    data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end entity;

architecture rtl of stack is

  signal stack_mem : std_logic_matrix(0 to STACK_SIZE-1)(DATA_WIDTH-1 downto 0);
  signal stack_addr : unsigned(clog2(STACK_SIZE)-1 downto 0);
--  signal next_stack_addr : unsigned(stack_addr'range);

  signal full : std_logic;
  signal empty : std_logic;
  signal valid_push : std_logic;
  signal valid_pop : std_logic;

begin

  valid_push <= '1' when full = '0' and push_i = '1' and pop_i = '0' else '0';
  valid_pop <= '1' when empty = '0' and push_i = '0' and pop_i = '1' else '0';

  full <= '1' when stack_addr = STACK_SIZE-1 else '0';
  --empty <= '1' when stack_addr = 0 else '0';

  p_empty:
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        empty <= '1';
      else
        if stack_addr = 0 then
          if valid_push then
            empty <= '0';
          elsif valid_pop then
            empty <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;


  p_stack:
  process(clk_i)
    variable next_stack_addr : unsigned(stack_addr'range);
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        stack_addr <= (others => '0');
        next_stack_addr := (others => '0');
      else
        next_stack_addr := stack_addr;

        if valid_push = '1' then
          if empty = '0' then
            next_stack_addr := stack_addr + 1;
          end if;

          stack_mem(to_integer(next_stack_addr)) <= data_i;

        elsif valid_pop = '1' then
          if stack_addr /= 0 then
            next_stack_addr := stack_addr - 1;
          end if;

        elsif push_i = '1' and pop_i = '1' then
          stack_mem(to_integer(next_stack_addr)) <= data_i;
        end if;

      end if;

      stack_addr <= next_stack_addr;
    end if;
  end process;

  data_o <= stack_mem(to_integer(stack_addr));

  full_o <= full;
  empty_o <= empty;

end architecture;
