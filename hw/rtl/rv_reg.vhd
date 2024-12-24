library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rv_reg is
  generic(
    RST_LEVEL : std_logic := '0';
    REG_LEN   : natural;
    ROB_LEN   : natural;
    XLEN      : natural
  );
  port(
    i_clk  : in std_logic;
    i_arst : in std_logic;

    -- RJ interface
    i_rj  : in  std_logic_vector(REG_LEN-1 downto 0); -- Register address for OP J
    o_vj  : out std_logic_vector(XLEN-1 downto 0);    -- Value of reg J
    o_qj  : out std_logic_vector(ROB_LEN-1 downto 0); -- Rob entry of reg J
    o_rj  : out std_logic;                            -- Ready flag for reg J (data is available)

    -- RK interface
    i_rk  : in  std_logic_vector(REG_LEN-1 downto 0); -- Register address for OP K
    o_vk  : out std_logic_vector(XLEN-1 downto 0);    -- Value of reg K
    o_qk  : out std_logic_vector(ROB_LEN-1 downto 0); -- Rob entry of reg K
    o_rk  : out std_logic;                            -- Ready flag for reg K (Data is available)

    -- ROB interface
    i_wed : in std_logic;                            -- Write Enable Dispatch
    i_rd  : in std_logic_vector(REG_LEN-1 downto 0); -- Destination register
    i_qr  : in std_logic_vector(ROB_LEN-1 downto 0); -- Rob address

    -- WB
    i_wer : in std_logic;                            -- Write Enable Register
    i_wr  : in std_logic_vector(REG_LEN-1 downto 0); -- Write Register address
    i_res : in std_logic_vector(XLEN-1 downto 0)     -- Result to write in wr
  );
end entity;

architecture rtl of rv_reg is

  type reg_t is record
    data  : std_logic_vector(XLEN-1 downto 0);    -- Data in register
    src   : std_logic_vector(ROB_LEN-1 downto 0); -- Rob address that will produce the result
    ready : std_logic;                            -- Dirty flag to indicate data is invalid and will be produced by src rob entry
  end record;

  type regfile_t is array (natural range <>) of reg_t;

  signal x : regfile_t(0 to 2**XLEN-1);

  signal rj : unsigned(i_rj'range);
  signal rk : unsigned(i_rk'range);

begin

  p_registers:
  process(i_clk, i_arst)
  begin
    if i_arst = RST_LEVEL then
        for i in 1 to 2**REG_LEN-1 loop
          x(i).src <= (others => '0');
          x(i).ready <= '0';
        end loop;

    if rising_edge(i_clk) then
        if i_wer = '1' then
          x(to_integer(unsigned(i_wr))).data  <= i_res;
          x(to_integer(unsigned(i_wr))).ready <= '1';
        end if;

        if i_wed = '1' then
          x(to_integer(unsigned(i_rd))).src <= i_qr;
        end if;
      end if;
    end if;

    x(0).data <= (others => '0');
    x(0).src <= (others => '0');
    x(0).ready <= '1';
  end process;

  rj <= unsigned(i_rj);
  o_vj <= x(to_integer(rj)).data;
  o_qj <= x(to_integer(rj)).src;
  o_rj <= x(to_integer(rj)).ready;

  rk <= unsigned(i_rk);
  o_vk <= x(to_integer(rk)).data;
  o_qk <= x(to_integer(rk)).src;
  o_rk <= x(to_integer(rk)).ready;

end architecture;
