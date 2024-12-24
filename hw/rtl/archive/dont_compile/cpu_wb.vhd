library ieee;
use ieee.std_logic_1164.all;

use work.wb_pkg.all;

entity cpu_wb is
  generic(
    WB_BUS_DATA_WIDTH      : natural;
    WB_BUS_ADDR_WIDTH      : natural;
    WB_BUS_DATA_TAG_WIDTH  : natural;
    WB_BUS_SEL_WIDTH       : natural;
    WB_BUS_ADDR_TAG_WIDTH  : natural;
    WB_BUS_CYCLE_TAG_WIDTH : natural
  );
  port(
    -- Wishbone interface
    wb_clk_i   : in  std_logic;
    wb_rst_i   : in  std_logic;
    wb_dat_i   : in  std_logic_vector(WB_BUS_DATA_WIDTH-1 downto 0);
    wb_dat_o   : in  std_logic_vector(WB_BUS_DATA_WIDTH-1 downto 0);
    wb_tgd_i   : in  std_logic_vector(WB_BUS_TAG_WIDTH-1 downto 0);
    wb_tgd_o   : out std_logic_vector(WB_BUS_TAG_WIDTH-1 downto 0);
    wb_ack_i   : in  std_logic;
    wb_adr_o   : out std_logic_vector(WB_BUS_ADDR_WIDTH-1 downto 0);
    wb_cyc_o   : out std_logic;
    wb_stall_i : in  std_logic;
    wb_err_i   : in  std_logic;
    wb_lock_o  : out std_logic;
    wb_rty_i   : in  std_logic;
    wb_sel_o   : out std_logic_vector(WB_BUS_SEL_WIDTH-1 downto 0);
    wb_stb_o   : out std_logic;
    wb_tga_o   : out std_logic_vector(WB_BUS_ADDR_TAG_WIDTH-1 downto 0);
    wb_tgc_o   : out std_logic_vector(WB_BUS_CYCLE_TAG_WIDTH-1 downto 0);
    wb_we_o    : out std_logic

    -- CPU interface
  );
end entity;

architecture rtl of cpu_wb is
begin

end architecture rtl;
