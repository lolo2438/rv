library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg is
  generic(
    REG_LEN : natural;
    ROB_LEN : natural;
    XLEN : natural
  );
  port(
    clk_i : in std_logic;
    rst_i : in std_logic;

    -- RJ interface
    rj_i : in  std_logic_vector(REG_LEN-1 downto 0);  -- Register address for OP J
    vj_o  : out std_logic_vector(XLEN-1 downto 0);    -- Value of reg J
    qj_o  : out std_logic_vector(ROB_LEN-1 downto 0); -- Rob entry of reg J
    rj_o  : out std_logic;                            -- Ready flag for reg J (data is available)

    -- RK interface
    rk_i : in  std_logic_vector(REG_LEN-1 downto 0);  -- Register address for OP K
    vk_o  : out std_logic_vector(XLEN-1 downto 0);    -- Value of reg K
    qk_o  : out std_logic_vector(ROB_LEN-1 downto 0); -- Rob entry of reg K
    rk_o  : out std_logic;                            -- Ready flag for reg K (Data is available)

    -- ROB interface
    wei_i: in std_logic;                            -- Write Enable Issue
    rd_i : in std_logic_vector(REG_LEN-1 downto 0); -- Destination register
    qr_i : in std_logic_vector(ROB_LEN-1 downto 0); -- Rob address

    -- WB
    wer_i : in std_logic;                            -- Write Enable Register
    wr_i  : in std_logic_vector(REG_LEN-1 downto 0); -- Write Register address
    res_i : in std_logic_vector(XLEN-1 downto 0)     -- Result to write in wr
  );
end entity;

architecture rtl of reg is

  type reg_t is record
    data  : std_logic_vector(XLEN-1 downto 0);    -- Data in register
    src   : std_logic_vector(ROB_LEN-1 downto 0); -- Rob address that will produce the result
    ready : std_logic;                            -- Dirty flag to indicate data is invalid and will be produced by src rob entry
  end record;

  type regfile_t is array (natural range <>) of reg_t;

  signal x : regfile_t(0 to 2**XLEN-1);

  signal rj : unsigned(rj_i'range);
  signal rk : unsigned(rk_i'range);

begin

  p_registers:
  process(clk_i, rst_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '0' then
        for i in 1 to 2**REG_LEN-1 loop
          x(i).src <= (others => '0');
          x(i).ready <= '0';
        end loop;

     else
        if wer_i = '1' then
          x(to_integer(unsigned(wr_i))).data <= res_i;
        end if;

        if wei_i = '1' then
          x(to_integer(unsigned(rd_i))).src <= qr_i;
        end if;
      end if;
    end if;

    x(0).data <= (others => '0');
    x(0).src <= (others => '0');
    x(0).ready <= '1';
  end process;

  rj <= unsigned(rj_i);
  vj_o <= x(to_integer(rj)).data;
  qj_o <= x(to_integer(rj)).src;
  rj_o <= x(to_integer(rj)).ready;

  rk <= unsigned(rk_i);
  vk_o <= x(to_integer(rk)).data;
  qk_o <= x(to_integer(rk)).src;
  rk_o <= x(to_integer(rk)).ready;

end architecture;
