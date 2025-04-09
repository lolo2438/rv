library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg is
  generic(
    RST_LEVEL : std_logic := '0';
    REG_LEN   : natural;
    ROB_LEN   : natural;
    XLEN      : natural
  );
  port(
    -- CONTROL I/F
    i_clk         : in  std_logic;                              --! System clock
    i_arst        : in  std_logic;                              --! Asynchronous reset
    i_srst        : in  std_logic;                              --! Synchronous reset

    -- RJ I/F
    i_disp_rs1    : in  std_logic_vector(REG_LEN-1 downto 0);   --! Register address for OP J
    o_reg_vj      : out std_logic_vector(XLEN-1 downto 0);      --! Value of reg J
    o_reg_qj      : out std_logic_vector(ROB_LEN-1 downto 0);   --! Rob entry of reg J
    o_reg_rj      : out std_logic;                              --! Ready flag for reg J (data is available)

    -- RK I/F
    i_disp_rs2    : in  std_logic_vector(REG_LEN-1 downto 0);   --! Register address for OP K
    o_reg_vk      : out std_logic_vector(XLEN-1 downto 0);      --! Value of reg K
    o_reg_qk      : out std_logic_vector(ROB_LEN-1 downto 0);   --! Rob entry of reg K
    o_reg_rk      : out std_logic;                              --! Ready flag for reg K (Data is available)

    -- DISPATCH I/F
    i_disp_valid  : in  std_logic;
    i_disp_wb     : in  std_logic;                              --! Result will be written back in registers
    i_disp_rd     : in  std_logic_vector(REG_LEN-1 downto 0);   --! Destination register to writeback
    i_disp_qr     : in  std_logic_vector(ROB_LEN-1 downto 0);   --! Rob address that holds the result

    -- WRITEBACK I/F
    i_wb_we       : in  std_logic;                              --! Write Enable Register
    i_wb_rd       : in  std_logic_vector(REG_LEN-1 downto 0);   --! Write Register address
    i_wb_data     : in  std_logic_vector(XLEN-1 downto 0)       --! Result to write in wr
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

  signal rs1 : unsigned(i_disp_rs1'range);
  signal rs2 : unsigned(i_disp_rs2'range);

begin

  ---
  -- INPUT
  ---
  rs1 <= unsigned(i_disp_rs1);
  rs2 <= unsigned(i_disp_rs2);

  ---
  -- LOGIC
  ---
  p_reg:
  process(i_clk, i_arst)
  begin
    if i_arst = RST_LEVEL then
        for i in 1 to 2**REG_LEN-1 loop
          x(i).src <= (others => '0');
          x(i).ready <= '0';
        end loop;

    elsif rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        for i in 1 to 2**REG_LEN-1 loop
          x(i).src <= (others => '0');
          x(i).ready <= '0';
        end loop;
      else
        if i_wb_we = '1' then
          x(to_integer(unsigned(i_wb_rd))).data  <= i_wb_data;

          if i_wb_rd = x(to_integer(unsigned(i_wb_rd))).src then
            x(to_integer(unsigned(i_wb_rd))).ready <= '1';
          end if;
        end if;

        if i_disp_wb = '1' and i_disp_valid = '1' then
          x(to_integer(unsigned(i_disp_rd))).src <= i_disp_qr;
          x(to_integer(unsigned(i_disp_rd))).ready <= '0';
        end if;
      end if;
    end if;

    x(0).data   <= (others => '0');
    x(0).src    <= (others => '0');
    x(0).ready  <= '1';
  end process;

  ---
  -- OUTPUT
  ---
  o_reg_vj <= x(to_integer(rs1)).data;
  o_reg_qj <= x(to_integer(rs1)).src;
  o_reg_rj <= x(to_integer(rs1)).ready;

  o_reg_vk <= x(to_integer(rs2)).data;
  o_reg_qk <= x(to_integer(rs2)).src;
  o_reg_rk <= x(to_integer(rs2)).ready;

end architecture;
