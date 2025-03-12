--------------------------------------------------
--! \file dec.vhd
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

entity dec is
  generic(
    -- TODO: Supported EXTENSIONS
    XLEN : natural
  );
  port (
    -- DISPATCH I/F
    i_inst_disp   : in  std_logic;                           --! Dispatch a new instruction
    i_inst        : in  std_logic_vector(31 downto 0);       --! Instruction
    o_disp_op     : out std_logic_vector(4 downto 0);        --! Opcode
    o_disp_f3     : out std_logic_vector(2 downto 0);        --! Funct3
    o_disp_f7     : out std_logic_vector(6 downto 0);        --! Funct7
    o_disp_imm    : out std_logic_vector(XLEN-1 downto 0);   --! Immediate value for exu
    o_disp_rs1    : out std_logic_vector(4 downto 0);        --! RS1 address
    o_disp_rs2    : out std_logic_vector(4 downto 0);        --! RS2 address
    o_disp_rd     : out std_logic_vector(4 downto 0);        --! RD address
    o_disp_f12    : out std_logic_vector(11 downto 0);       --! F12 for system operation
    o_hint        : out std_logic;                           --! Specified instruction is a hint
    o_illegal     : out std_logic                            --! Specified instruction is illegal
  );
end entity;

architecture rtl of dec is

  -- Instruction
  signal q   : std_logic_vector(1 downto 0);
  signal op  : std_logic_vector(4 downto 0);
  signal f3  : std_logic_vector(2 downto 0);
  signal f7  : std_logic_vector(6 downto 0);
  signal rs1 : std_logic_vector(4 downto 0);
  signal rs2 : std_logic_vector(4 downto 0);
  signal rd  : std_logic_vector(4 downto 0);
  signal f12 : std_logic_vector(11 downto 0);
  signal imm : std_logic_vector(XLEN-1 downto 0);


  -- Control
  signal hint : std_logic;
  signal valid : std_logic;

begin

  q   <= i_inst(1 downto 0);
  op  <= i_inst(6 downto 2);
  f3  <= i_inst(14 downto 12);
  f7  <= i_inst(31 downto 25);

  o_disp_op <= op;
  o_disp_f3 <= f3;
  o_disp_f7 <= f7;

  ---
  -- BRU DECODER
  ---
  --o_bru_branch  <= '1' when op = OP_BRANCH else '0';
  --o_bru_jalr    <= '1' when op = OP_JALR else '0';
  --o_bru_jal     <= '1' when op = OP_JAL else '0';

  ---
  -- SYSTEM DECODER
  ---
  f12 <= i_inst(31 downto 20);
  o_disp_f12 <= f12;
  --o_sys <= '1' when op = OP_SYSTEM else '0';


  ---
  -- REGISTER DECODER
  ---
  rd  <= i_inst(11 downto 7);
  rs1 <= i_inst(19 downto 15);
  rs2 <= i_inst(24 downto 20);

  --o_reg_wb  <= reg_wb;

  o_disp_rs1 <= rs1;
  o_disp_rs2 <= rs2;
  o_disp_rd  <= rd;


  ---
  -- EXB DECODER
  ---
--  o_rob_lui     <= '1' when op = OP_LUI   else '0';


  ---
  -- IMMEDIATE DECODER
  ---
  p_imm:
  process(all)
    variable i_imm, s_imm, b_imm, u_imm, j_imm : std_logic_vector(XLEN-1 downto 0);
  begin
    i_imm := std_logic_vector(resize(signed(i_inst(31 downto 20)), imm'length));
    s_imm := std_logic_vector(resize(signed(i_inst(31 downto 25) & i_inst(11 downto 7)), imm'length));
    b_imm := std_logic_vector(resize(signed(i_inst(31) & i_inst(7) & i_inst(30 downto 25) & i_inst(11 downto 8) & '0'), imm'length));
    u_imm := i_inst(31 downto 12) & std_logic_vector(resize(unsigned'("0"),12)) ;
    j_imm := std_logic_vector(resize(signed(i_inst(31) & i_inst(19 downto 12) & i_inst(20) & i_inst(30 downto 21) & '0'), imm'length));

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

  o_disp_imm <= imm;


  ---
  -- ILLEGAL DECODER
  ---
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

  o_illegal <= (not valid) and i_inst_disp;


  ---
  -- HINT DECODER
  ---
  hint <= '0';
  o_hint <= hint;

end architecture;
