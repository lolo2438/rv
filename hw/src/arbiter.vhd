library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library common;
use common.fnct.all;

entity arbiter is
  generic(
    RST_LEVEL : std_logic;
    N         : natural
  );
  port(
    i_clk     : in  std_logic;
    i_srst    : in  std_logic;
    i_arst    : in  std_logic;
    i_req     : in  std_logic_vector(N-1 downto 0);
    o_ack     : out std_logic_vector(N-1 downto 0)
  );
end entity;

architecture round_robin of arbiter is

  signal rotl_req : std_logic_vector(i_req'range);
  signal rotr_req : std_logic_vector(i_req'range);

  signal valid : std_logic;
  signal rotate : unsigned(clog2(N)-1 downto 0);

  signal token : std_logic_vector(N-1 downto 0);
  signal mask_token : std_logic_vector(N-1 downto 0);

begin


  ---
  -- INPUT
  ---
  valid <= or (i_req);

  rotl_req <= i_req rol to_integer(rotate);

  ---
  -- LOGIC
  ---
  rotr_req <= one_hot_encoder(priority_encoder(rotl_req)) ror to_integer(rotate);

  p_token:
  process(i_clk)
  begin
    if i_arst = RST_LEVEL then
      token     <= (others => '0');
      token(0)  <= '1';
    elsif rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        token     <= (others => '0');
        token(0)  <= '1';
      elsif valid = '1' then
        token <= rotr_req;
      end if;
    end if;
  end process;

  rotate <= unsigned(one_hot_decoder(token rol 1));

  mask_token <= token and i_req;

  ---
  -- OUTPUT
  ---
  o_ack <= mask_token;

end architecture;
