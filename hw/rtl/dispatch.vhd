library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library riscv;
use riscv.RV32I.all;

entity dispatch is
  generic(
    -- TODO: Supported EXTENSIONS
    XLEN : natural
  );
  port (
    wed_i         : in std_logic; -- Enable dispatch
    instruction_i : in std_logic_vector(31 downto 0);

    op_o  : out std_logic_vector(5 downto 0);
    f7_o  : out std_logic_vector(6 downto 0);
    f3_o  : out std_logic_vector(2 downto 0);
    imm_o : out std_logic_vector(XLEN-1 downto 0);
    rs1_o : out std_logic_vector(4 downto 0);
    rs2_o : out std_logic_vector(4 downto 0);
    rd_o  : out std_logic_vector(4 downto 0);

    rob_o : out std_logic;
    sys_o : out std_logic;
    bru_o : out std_logic;
    lsu_o : out std_logic;

    valid_o : out std_logic -- Instruction is valid
  );
end entity;

architecture rtl of dispatch is

  signal valid : std_logic;

  signal i : std_logic_vector(instruction_i'range);
  alias quadrant : std_logic_vector(1 downto 0) is i(1 downto 0);
  alias op : std_logic_vector(op_o'range) is i(6 downto 2);
  alias f3 : std_logic_vector(f3_o'range) is i(14 downto 12);
  alias f7 : std_logic_vector(f7_o'range) is i(31 downto 25);
  alias rs1 : std_logic_vector(rs1_o'range) is i(19 downto 15);
  alias rs2 : std_logic_vector(rs2_o'range) is i(24 downto 20);
  alias rd : std_logic_vector(rd_o'range) is i(11 downto 7);
  alias f12 : std_logic_vector(11 downto 0) is i(31 downto 20);

  signal imm : std_logic_vector(XLEN-1 downto 0);

begin


  i <= instruction_i;

  f7_o <= f7;
  f3_o <= f3;
  rs1_o <= rs1;
  rs2_o <= rs2;
  rd_o <= rd;


  with op select
    rob_o <= '1' when OP_OP | OP_IMM | OP_LUI | OP_AUIPC | OP_JAL | OP_JALR | OP_LOAD,
             '0' when others;

  with op select
    sys_o <= '1' when OP_SYSTEM,
             '0' when others;

  with op select
    bru_o <= '1' when OP_BRANCH | OP_JAL | OP_JALR,
             '0' when others;

  with op select
    lsu_o <= '1' when OP_LOAD | OP_STORE | OP_MISC_MEM,
             '0' when others;


  p_imm:
  process(i)
    variable i_imm, s_imm, b_imm, u_imm, j_imm : std_logic_vector(XLEN-1 downto 0);
  begin
    i_imm := std_logic_vector(resize(signed(i(31 downto 20)), imm'length));
    s_imm := std_logic_vector(resize(signed(i(31 downto 25) & i(11 downto 7)), imm'length));
    b_imm := std_logic_vector(resize(signed(i(31) & i(7) & i(30 downto 25) & i(11 downto 8) & '0'), imm'length));
    u_imm := i(31 downto 12) & std_logic_vector(resize(unsigned'("0"),12)) ;
    j_imm := std_logic_vector(resize(signed(i(31) & i(19 downto 12) & i(20) & i(30 downto 21) & '0'), imm'length));

    case op is
      when OP_IMM | OP_JALR | OP_LOAD =>
        imm <= i_imm;
      when OP_STORE =>
        imm <= s_imm;
      when OP_BRANCH =>
        imm <= b_imm;
      when OP_AUIPC | OP_LUI =>
        imm <= u_imm;
      when OP_JAL =>
        imm <= j_imm;
      when others => -- Add extensions here
        imm <= (others => '-');
    end case;
  end process;

  imm_o <= imm;


  p_valid:
  process(i)
  begin
    valid <= '0';

    -- RV32I, add other size here
    case op is
      when OP_OP =>
        if f7 = "0000000" or f7 = "0100000" then
          valid <= '1';
        end if;

      when OP_IMM =>
        if f3 = FUNCT3_SL then
          if f7 = "0000000" then
            valid <= '1';
          end if;
        elsif f3 = FUNCT3_SR then
          if f7 = FUNCT7_SRL or f7 = FUNCT7_SRA then
            valid <= '1';
          end if;
        end if;

      when OP_JALR =>
        if f3 = "000" then
          valid <= '1';
        end if;

      when OP_LUI | OP_AUIPC | OP_JAL => valid <= '1';

      when OP_BRANCH =>
        if not(f3 = "010" or f3 = "011") then
          valid <= '1';
        end if;

      when OP_STORE =>
        if f3 = "000" or f3 = "001" or f3 = "010" then
          valid <= '1';
        end if;

      when OP_LOAD =>
        if not ( f3 = "011" or f3 = "110" or f3 = "111") then
          valid <= '1';
        end if;

      when OP_MISC_MEM =>
        if f3 = "000" then
          valid <= '1';
        end if;

      when OP_SYSTEM =>
        if f12 = x"000" or f12 = x"001" then
          valid <= '1';
        end if;

      when others => -- Add extensions here
    end case;

    if quadrant /= "11" then
      valid <= '0';
    end if;
  end process;

  valid_o <= valid when wed_i = '1' else '0';

end architecture;
