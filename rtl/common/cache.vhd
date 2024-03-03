library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.common_pkg.all; -- Todo, change to COMMON and add clog2 fnct

entity cache is
  generic(
    XLEN        : natural;
    OFFSET_SIZE : natural; -- Each ways will have rows of 2^OFFSET columns
    SET_SIZE    : natural; -- Each way will have 2^NB_SETS rows
    WAY_SIZE    : natural  -- There will be 2^NB_WAYS ways
  );
  port(
    clk_i     : in  std_logic;
    rst_i     : in  std_logic;
    we_i      : in  std_logic;
    data_i    : in  std_logic_vector(XLEN*(2**OFFSET_SIZE)-1 downto 0);
    address_i : in  std_logic_vector(XLEN-1 downto 0);
    data_o    : out std_logic_vector(XLEN-1 downto 0);
    hit_o     : out std_logic
  );
end entity;

architecture rtl of cache is

  -- Cache addressing
  constant BYTE_OFFSET : natural := natural(ceil(log2(real(XLEN / 8))));
  constant OFFSET_WIDTH : natural := OFFSET_SIZE + BYTE_OFFSET;
  alias offset : std_logic_vector(OFFSET_SIZE - 1 downto 0) is address_i(OFFSET_WIDTH - 1 downto BYTE_OFFSET);

  constant INDEX_WIDTH : natural := SET_SIZE;
  alias index : std_logic_vector(INDEX_WIDTH-1 downto 0) is address_i(INDEX_WIDTH + OFFSET_WIDTH - 1 downto OFFSET_WIDTH);

  constant TAG_WIDTH : natural := XLEN - INDEX_WIDTH - OFFSET_WIDTH;
  alias tag : std_logic_vector(TAG_WIDTH-1 downto 0) is address_i(XLEN - 1 downto INDEX_WIDTH + OFFSET_WIDTH);

  -- Cache signals
  type cache_row_t is record
    valid : std_logic;
    tag   : std_logic_vector(TAG_WIDTH-1 downto 0);
    data  : std_logic_array(0 to 2**OFFSET_SIZE-1)(XLEN-1 downto 0);
  end record;

  type cache_col_t is array (0 to 2**SET_SIZE-1) of cache_row_t;

  type cache_t is array (0 to 2**WAY_SIZE-1) of cache_col_t;

  signal c : cache_t;

  signal current_way : unsigned(WAY_SIZE-1 downto 0);
  signal hit : std_logic_vector(2**WAY_SIZE-1 downto 0);
  signal hit_sel : unsigned(WAY_SIZE-1 downto 0);

begin


  p_cache:
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then

        for i in cache_t'range loop
          for j in cache_col_t'range loop
            c(i)(j).valid <= '0';
          end loop;
        end loop;

        current_way <= (others => '0');
      else
        if we_i = '1' then
          for i in 0 to 2**OFFSET_SIZE-1 loop
            c(to_integer(current_way))(to_integer(unsigned(index))).data(i) <= data_i(XLEN*(i+1)-1 downto XLEN*i);
          end loop;
            c(to_integer(current_way))(to_integer(unsigned(index))).tag <= tag;
            c(to_integer(current_way))(to_integer(unsigned(index))).valid <= '1';

          -- Note:
          -- Here is where the "next overwitten logic" should be added:
          -- Possibles: LRU, Random, Fifo
          -- According to stats:
          --    LRU better for Low sized cache
          --    Random && LRU same for big caches
          --    Fifo easiest to implement
          -- Current: Fifo
          current_way <= current_way + 1;
        end if;
      end if;
    end if;
  end process;


  p_hit_logic:
  for i in cache_t'range generate
    hit(i) <= '1' when c(i)(to_integer(unsigned(index))).tag = tag and c(i)(to_integer(unsigned(index))).valid = '1' else '0';
  end generate;


  p_hit_encoder:
  process(hit)
  begin
    hit_sel <= (others => '0');
    for i in hit'range loop
      if hit(i) = '1' then
        hit_sel <= to_unsigned(i, hit_sel'length);
      end if;
    end loop;
  end process;

  data_o <= c(to_integer(hit_sel))(to_integer(unsigned(index))).data(to_integer(unsigned(offset)));

  hit_o <= or hit;

end architecture;
