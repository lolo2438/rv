--!
--! todo
--!
--!
library ieee;
use ieee.std_logic_1164.all;

entity fifo is
  generic (
    RST_LEVEL  : std_logic;
    FIFO_WIDTH : natural;
    DATA_WIDTH : natural
  );
  port (
    i_clk       : in  std_logic;                                --! Input clock port
    i_arst      : in  std_logic;                                --! Input asynchronous reset
    i_srst      : in  std_logic;                                --! Input synchronous reset

    i_we        : in  std_logic;                                --! Write enable
    i_re        : in  std_logic;                                --! Read enable
    i_data      : in  std_logic_vector(DATA_WIDTH-1 downto 0);  --! Input data

    o_full      : out std_logic;                                --! Full flag
    o_empty     : out std_logic;                                --! Empty flag
    o_valid     : out std_logic;                                --! Output Data read valid flag
    o_data      : out std_logic_vector(DATA_WIDTH-1 downto 0)   --! Output data
  );
end entity;

architecture rtl of fifo is

  constant FIFO_SIZE : natural := 2**FIFO_WIDTH;

  type mem_t is array (natural range <>) of std_logic_vector;

  signal mem : mem_t;

  signal rd_ptr : natural range 0 to FIFO_SIZE-1;
  signal next_rd_ptr : natural range rd_ptr'range;

  signal wr_ptr : natural range 0 to FIFO_SIZE-1;
  signal next_wr_ptr : natural range wr_ptr'range;

  signal full, empty : std_logic;
  signal we, re : std_logic;

begin

  next_wr_ptr <= wr_ptr + 1;
  next_rd_ptr <= rd_ptr + 1;

  full <= '1' when next_wr_ptr = rd_ptr else '0';
  empty <= '1' when wr_ptr = rd_ptr else '0';

  we <= i_we and not full;
  re <= i_re and not empty;

  p_fifo:
  process(i_clk, i_arst)
  begin
    if i_arst = RST_LEVEL then
      rd_ptr <= 0;
      wr_ptr <= 0;
    elsif rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        rd_ptr <= 0;
        wr_ptr <= 0;
      else
        if we = '1' then
          mem(wr_ptr) <= i_data;
          wr_ptr <= next_wr_ptr;
        end if;

        if re = '1' then
          rd_ptr <= next_rd_ptr;
        end if;
      end if;
    end if;
  end process;

  o_data  <= mem(rd_ptr);
  o_valid <= re;

  o_full <= full;
  o_empty <= empty;

end architecture;
