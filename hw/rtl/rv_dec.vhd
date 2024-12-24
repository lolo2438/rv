--------------------------------------------------
--! \file rv_dec.vhd
--! \author Laurent Tremblay
--! \date 2024
--! \version 1.0
--! \copyright
--
--! \brief The macro decoder module for the RISCV cpu
--------------------------------------------------
--! \par CHANGELOG
--------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library riscv;
use riscv.RV32I.all;

entity rv_dec is
  generic(
    -- TODO: Supported EXTENSIONS
    XLEN : natural
  );
  port (
    i_wed     : in std_logic; -- Enable dispatch
    i_inst    : in std_logic_vector(31 downto 0);

    o_op      : out std_logic_vector(4 downto 0);
    o_f12     : out std_logic_vector(11 downto 0);
    o_f7      : out std_logic_vector(6 downto 0);
    o_f3      : out std_logic_vector(2 downto 0);
    o_imm     : out std_logic_vector(XLEN-1 downto 0);
    o_rs1     : out std_logic_vector(4 downto 0);
    o_rs2     : out std_logic_vector(4 downto 0);
    o_rd      : out std_logic_vector(4 downto 0);

    o_rob     : out std_logic; -- Entry must be created in ROB
    o_bru     : out std_logic; -- Entry must be created in BRU
    o_lsu     : out std_logic; -- Entry must be created in LSU
    o_sys     : out std_logic; -- Entry must be created in SYS

    o_inst_v  : out std_logic -- Instruction is valid
  );
end entity;

architecture rtl of rv_dec is

  -- Instruction
  signal i   : std_logic_vector(i_inst'range);
  signal q   : std_logic_vector(1 downto 0);
  signal op  : std_logic_vector(o_op'range);
  signal f3  : std_logic_vector(o_f3'range);
  signal f7  : std_logic_vector(o_f7'range);
  signal rs1 : std_logic_vector(o_rs1'range);
  signal rs2 : std_logic_vector(o_rs2'range);
  signal rd  : std_logic_vector(o_rd'range);
  signal f12 : std_logic_vector(o_f12'range);

  signal imm : std_logic_vector(XLEN-1 downto 0);

  -- Control
  signal valid : std_logic;

begin

  i   <= i_inst;

  q   <= i(1 downto 0);
  op  <= i(6 downto 2);
  rd  <= i(11 downto 7);
  f3  <= i(14 downto 12);
  rs1 <= i(19 downto 15);
  rs2 <= i(24 downto 20);
  f7  <= i(31 downto 25);
  f12 <= i(31 downto 20);

  o_f12 <= f12;
  o_f7  <= f7;
  o_f3  <= f3;
  o_rs1 <= rs1;
  o_rs2 <= rs2;
  o_rd  <= rd;


  p_rob:
  process(op)
    variable rob : std_logic;
  begin
    rob := '0';
    case op is
      -- EXLCUDED: OP_SYSTEM
      when OP_OP | OP_IMM | OP_LUI | OP_AUIPC | OP_JAL | OP_JALR | OP_LOAD | OP_STORE | OP_BRANCH =>
        rob := '1';
      when others => -- Add extensions
    end case;

    o_rob <= rob;
  end process;


  p_bru:
  process(op)
    variable bru : std_logic;
  begin
    bru := '0';
    case op is
      when OP_BRANCH | OP_JAL | OP_JALR =>
        bru := '1';
      when others => -- Add extensions
    end case;

    o_bru <= bru;
  end process;


  p_lsu:
  process(op)
    variable lsu : std_logic;
  begin
    lsu := '0';
    case op is
      when OP_LOAD | OP_STORE | OP_MISC_MEM =>
        lsu := '1';
      when others => -- Add extensions
    end case;

    o_lsu <= lsu;
  end process;


  p_sys:
  process(op)
    variable sys : std_logic;
  begin
    sys := '0';
    case op is
      when OP_SYSTEM =>
        sys := '1';
      when others => -- Add extensions
    end case;

    o_sys <= sys;
  end process;


  p_imm:
  process(all)
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

  o_imm <= imm;


  p_valid:
  process(all)
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

      -- NOTE: At the moment, misc-mem RS1 & RD are to be IGNORED by specification for foward-compatibility
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

    if q /= "11" then -- TODO: C Extension add execption here
      valid <= '0';
    end if;
  end process;

  o_inst_v <= valid and i_wed;

end architecture;
