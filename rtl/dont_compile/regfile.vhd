library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.common_pkg.all;

entity regfile is
  generic (
    TLEN : natural;
    RLEN : natural;
    XLEN : natural
  );
  port (
    -- Control
    clk_i : in  std_logic;
    rst_i : in  std_logic;

    -- Read value
    rs1a_i : in  std_logic_vector(RLEN-1 downto 0);
    rs1v_o : out std_logic_vector(XLEN-1 downto 0);
    rs2a_i : in  std_logic_vector(RLEN-1 downto 0);
    rs2v_o : out std_logic_vector(XLEN-1 downto 0);

    -- Write value
    twa_i : in  std_logic_vector(TLEN-1 downto 0);
    rda_i : in  std_logic_vector(RLEN-1 downto 0);
    we_i  : in  std_logic;
    twd_i : in  std_logic_vector(TLEN-1 downto 0);
    rdw_i : in  std_logic;
    rdv_i : in  std_logic_vector(XLEN-1 downto 0)
  );
end entity;

architecture rtl of regfile is

  signal x : std_logic_array(0 to 2**RLEN-1)(XLEN-1 downto 0);
  signal t : std_logic_array(1 to 2**RLEN-1)(TLEN-1 downto 0);

begin

  p_tag:
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '0' then
        t <= (others => (others => '0'));
      elsif unsigned(rda_i) /= 0 then
        t(to_integer(unsigned(rda_i))) <= twa_i;
      end if;
    end if;
  end process;

  p_reg:
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if we_i = '1' then
        for i in 1 to 2**RLEN-1 loop
          if t(i) = twd_i then
            x(i) <= res_i;
          end if;
        end loop;
      end if;

      x(0) <= (others => '0');
    end if;
  end process;

  rs1v_o <= x(to_integer(unsigned(rs1a_i)));
  rs2v_o <= x(to_integer(unsigned(rs2a_i)));

end architecture;
