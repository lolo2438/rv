library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity grp is
  generic(
    RST_LEVEL : std_logic := '0';
    GRP_LEN   : natural
  );
  port(
    -- CONTROL I/F
    i_clk  : in  std_logic;
    i_arst : in  std_logic;
    i_srst : in  std_logic;
    o_full : out std_logic;

    -- DISPATCH I/F
    i_disp_valid : in  std_logic;
    i_disp_fence : in  std_logic;

    -- GROUP I/F
    i_stb_rd_grp_match : in std_logic;
    i_ldb_rd_grp_match : in std_logic;
    o_wr_grp : out std_logic_vector(GRP_LEN-1 downto 0);
    o_rd_grp : out std_logic_vector(GRP_LEN-1 downto 0)
  );
end entity;

architecture rtl of grp is

  signal fence : std_logic;
  signal chg_rd_grp : std_logic;
  signal grp_full : std_logic;

  signal rd_grp : unsigned(GRP_LEN-1 downto 0);
  signal next_rd_grp : unsigned(rd_grp'range);

  signal wr_grp : unsigned(GRP_LEN-1 downto 0);
  signal next_wr_grp : unsigned(wr_grp'range);

begin

  ---
  -- INPUT
  ---
  chg_rd_grp <= i_stb_rd_grp_match nor i_ldb_rd_grp_match;
  fence <= i_disp_fence and i_disp_valid;

  ---
  -- LOGIC
  ---
  p_rd_grp:
  process(i_clk, i_arst)
  begin
    if i_arst = RST_LEVEL then
      rd_grp <= (others => '0');
    elsif rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        rd_grp <= (others => '0');
      elsif chg_rd_grp = '1' and rd_grp /= wr_grp then
        rd_grp <= next_rd_grp;
      end if;
    end if;
  end process;

  next_rd_grp <= rd_grp + 1;


  p_wr_grp:
  process(i_clk, i_arst)
  begin
    if i_arst = RST_LEVEL then
      wr_grp <= (others => '0');
    elsif rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        wr_grp <= (others => '0');
      elsif fence = '1' and grp_full = '0' then
          wr_grp <= next_wr_grp;
      end if;
    end if;
  end process;

  next_wr_grp <= wr_grp + 1;


  grp_full <= '1' when rd_grp = next_wr_grp else '0';

  ---
  -- OUTPUT
  ---
  o_full <= grp_full;
  o_wr_grp <= std_logic_vector(wr_grp);
  o_rd_grp <= std_logic_vector(rd_grp);

end architecture;
