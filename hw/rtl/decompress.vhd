library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library riscv;
use riscv.RV32I.all;
use riscv.RV64I.all;
use riscv.RV128I.all;

use riscv.C_EXT.all;
use riscv.F_EXT.all;
use riscv.D_EXT.all;

entity decompress is
  generic(
    XLEN : natural;
    FLEN : natural
  );
  port(
    inst16_i : in  std_logic_vector(15 downto 0);
    inst32_o : out std_logic_vector(31 downto 0);
    hint_o   : out std_logic;
    illegal_o: out std_logic
  );
end entity;


architecture rtl of decompress is

  signal i16 : std_logic_vector(inst16_i'range);
  signal i32 : std_logic_vector(inst32_o'range);
  signal hint : std_logic;
  signal illegal : std_logic;

begin

  i16 <= inst16_i;

  process(i16)
    variable j_imm : std_logic_vector(20 downto 1);
    variable ci_imm : std_logic_vector(5 downto 0);
    variable ci_addi16sp_imm : std_logic_vector(9 downto 4);
    variable cj_imm : std_logic_vector(11 downto 1);
    variable ciw_imm: std_logic_vector(9 downto 2);
    variable cb_imm: std_logic_vector(8 downto 1);

    variable cl_cs_32_imm   : std_logic_vector(6 downto 2);
    variable cl_cs_64_imm   : std_logic_vector(7 downto 3);
    variable cl_cs_128_imm  : std_logic_vector(8 downto 4);

    variable rs1, rs2, rd : std_logic_vector(4 downto 0);
    variable rs1p, rs2p, rdp: std_logic_vector(4 downto 0);

  begin
    -- Helper variables to cleanup code
    ci_imm          := i16(12) & i16(6 downto 2);
    ci_addi16sp_imm := i16(12) & i16(4 downto 3) & i16(5) & i16(2) & i16(6);
    cj_imm          := i16(12) & i16(8) & i16(10) & i16(9) & i16(6) & i16(7) & i16(2) & i16(11) & i16(5 downto 3);
    j_imm           := std_logic_vector(resize(signed(cj_imm), j_imm'length));
    ciw_imm         := i16(10 downto 7) & i16(12) & i16(11) & i16(5) & i16(6);
    cb_imm          := i16(12) & i16(6) & i16(5) & i16(3) & i16(11) & i16(10) & i16(4) & i16(3);
    cl_cs_32_imm    := i16(5) & i16(12 downto 10) & i16(6);
    cl_cs_64_imm    := i16(6) & i16(5) & i16(12 downto 10);
    cl_cs_128_imm   := i16(10) & i16(6) & i16(5) & i16(12) & i16(11);

    rs1   := i16(INST16_RS1'range);
    rs2   := i16(INST16_RS2'range);
    rd    := i16(INST16_RD'range);

    rs1p  := b"01" & i16(INST16_RS1P'range);
    rs2p  := b"01" & i16(INST16_RS2P'range);
    rdp   := b"01" & i16(INST16_RDP'range);

    -- C decompressor
    i32 <= (others => '-');
    i32(INST32_QUADRANT'range)  <= OP_C3;

    hint <= '0';
    illegal <= '0';

    case i16(INST32_QUADRANT'range) is
      when OP_C0 =>
        i32(INST32_RS2'range) <= rs2p;
        i32(INST32_RS1'range) <= rs1p;
        i32(INST32_RD'range)  <= rdp;

        case i16(INST16_FUNCT3'range) is
          when FUNCT3_C_ADDI4SPN =>
            i32(INST32_I_IMM'range)  <= "00" & ciw_imm & "00";
            i32(INST32_RS1'range)    <= REG_SP;
            i32(INST32_FUNCT3'range) <= FUNCT3_ADDSUB;
            i32(INST32_OPCODE'range) <= OP_IMM;

            if ciw_imm = std_logic_vector(to_unsigned(0, ciw_imm'length)) then
              illegal <= '1';
              i32 <= (others => '-');
            end if;

          when FUNCT3_C_FLD_LQ =>
            if XLEN = 128 then
              i32(INST32_I_IMM'range)  <= "000" & cl_cs_128_imm & "0000";
              i32(INST32_FUNCT3'range) <= FUNCT3_LQ;
              i32(INST32_OPCODE'range) <= OP_MISC_MEM;
            else
              if FLEN >= 64 then
                i32(INST32_I_IMM'range)  <= "0000" & cl_cs_64_imm & "000";
                i32(INST32_FUNCT3'range) <= FUNCT3_LD;
                i32(INST32_OPCODE'range) <= OP_LOAD_FP;
              else
                illegal <= '1';
                i32 <= (others => '-');
              end if;
            end if;

          when FUNCT3_C_LW =>
            i32(INST32_I_IMM'range)  <= "00000" & cl_cs_32_imm & "00";
            i32(INST32_FUNCT3'range) <= FUNCT3_LW;
            i32(INST32_OPCODE'range) <= OP_LOAD;

          when FUNCT3_C_FLW_LD =>
            if XLEN = 32 then
              if FLEN >= 32 then
                i32(INST32_I_IMM'range)  <= "00000" & cl_cs_32_imm & "00";
                i32(INST32_FUNCT3'range) <= FUNCT3_LW;
                i32(INST32_OPCODE'range) <= OP_LOAD_FP;
              else
                illegal <= '1';
                i32 <= (others => '-');
              end if;
            else
              i32(INST32_I_IMM'range)  <= "0000" & cl_cs_64_imm & "000";
              i32(INST32_FUNCT3'range) <= FUNCT3_LD;
              i32(INST32_OPCODE'range) <= OP_LOAD;
            end if;

          when FUNCT3_C_FSD_SQ =>
            if XLEN = 128 then
              i32(INST32_FUNCT7'range) <= "000" & cl_cs_128_imm(8 downto 5);
              i32(INST32_FUNCT3'range) <= FUNCT3_SQ;
              i32(INST32_RD'range)     <= cl_cs_128_imm(4) & "0000";
              i32(INST32_OPCODE'range) <= OP_STORE;
            else
              if FLEN >= 64 then
                i32(INST32_FUNCT7'range) <= "0000" & cl_cs_64_imm(7 downto 5);
                i32(INST32_FUNCT3'range) <= FUNCT3_SD;
                i32(INST32_RD'range)     <= cl_cs_64_imm(4 downto 3) & "000";
                i32(INST32_OPCODE'range) <= OP_STORE_FP;
              else
                illegal <= '1';
                i32 <= (others => '-');
              end if;
            end if;

          when FUNCT3_C_SW =>
            i32(INST32_FUNCT7'range) <= "00000" & cl_cs_32_imm(6 downto 5);
            i32(INST32_FUNCT3'range) <= FUNCT3_SW;
            i32(INST32_RD'range)     <= cl_cs_32_imm(4 downto 2) & "00";
            i32(INST32_OPCODE'range) <= OP_STORE;

          when FUNCT3_C_FSW_SD =>
            if XLEN = 32 then
              if FLEN >= 32 then
                i32(INST32_FUNCT7'range) <= "00000" & cl_cs_32_imm(6 downto 5);
                i32(INST32_FUNCT3'range) <= FUNCT3_SW;
                i32(INST32_RD'range)     <= cl_cs_32_imm(4 downto 2) & "00";
                i32(INST32_OPCODE'range) <= OP_STORE_FP;
              else
                illegal <= '1';
                i32 <= (others => '-');
              end if;

            else
              i32(INST32_FUNCT7'range) <= "0000" & cl_cs_64_imm(7 downto 5);
              i32(INST32_FUNCT3'range) <= FUNCT3_SD;
              i32(INST32_RD'range)     <= cl_cs_64_imm(4 downto 3) & "000";
              i32(INST32_OPCODE'range) <= OP_STORE;
            end if;

          when others =>
            -- Illegal 100 state
            illegal <= '1';
            i32 <= (others => '-');
        end case;

      when OP_C1 =>
        -- Default value
        i32(INST32_I_IMM'range)  <= std_logic_vector(resize(signed(ci_imm), INST32_I_IMM'length));
        i32(INST32_RS1'range)    <= rs1;
        i32(INST32_FUNCT3'range) <= FUNCT3_ADDSUB;
        i32(INST32_RD'range)     <= rd;
        i32(INST32_OPCODE'range) <= OP_IMM;

        case i16(INST16_FUNCT3'range) is
          when FUNCT3_C_ADDI =>

            if ci_imm = std_logic_vector(to_unsigned(0, ci_imm'length)) xor
               rd = REG_ZERO then
              hint <= '1';
            end if;

          when FUNCT3_C_JAL_ADDIW =>
            if XLEN = 32 then
              i32(INST32_U_J_IMM'range) <= j_imm(20) & j_imm(10 downto 1) & j_imm(11) & j_imm(19 downto 12);
              i32(INST32_RD'range)      <= REG_RA;
              i32(INST32_OPCODE'range)  <= OP_JAL;
            else
              i32(INST32_OPCODE'range) <= OP_IMM_32;

              if rd = REG_ZERO then
                illegal <= '1';
                i32 <= (others => '-');
              end if;
            end if;

          when FUNCT3_C_LI =>
            i32(INST32_RS1'range) <= REG_ZERO;

            if rd = std_logic_vector(to_unsigned(0,rd'length)) then
              hint <= '1';
            end if;

          when FUNCT3_C_ADDI16SP_LUI =>

            if rd = std_logic_vector(to_unsigned(2, rd'length)) then
              i32(INST32_I_IMM'range) <= std_logic_vector(resize(signed(ci_addi16sp_imm & x"0"), INST32_I_IMM'length));

              if ci_addi16sp_imm = std_logic_vector(to_unsigned(0, ci_addi16sp_imm'length)) then
                illegal <= '1';
                i32 <= (others => '-');
              end if;

            else
              i32(INST32_U_J_IMM'range) <= std_logic_vector(resize(signed(ci_imm), INST32_U_J_IMM'length));
              i32(INST32_OPCODE'range)  <= OP_LUI;

              if ci_imm = std_logic_vector(to_unsigned(0, ci_imm'length)) then
                illegal <= '1';
                i32 <= (others => '-');
              end if;

            end if;

            if rd = REG_ZERO then
              hint <= '1';
            end if;

          when FUNCT3_C_MISC_ALU =>
            i32(INST32_RS1'range) <= rs1p;
            i32(INST32_RD'range)  <= rs1p;

            case i16(INST16_FUNCT2_ALU_I'range) is
              when FUNCT2_C_SRLI_SRLI64 | FUNCT2_C_SRAI_SRAI64 =>

                if i16(INST16_FUNCT2_ALU_I'range) = FUNCT2_C_SRAI_SRAI64 then
                  i32(INST32_FUNCT7'range) <= FUNCT7_SRA;
                else
                  i32(INST32_FUNCT7'range) <= FUNCT7_SRL;
                end if;

                i32(INST32_FUNCT3'range) <= FUNCT3_SR;

                if XLEN = 128 then
                  if ci_imm = std_logic_vector(to_unsigned(0, ci_imm'length)) then
                    i32(INST32_SHAMT128'range) <= std_logic_vector(to_unsigned(64, INST32_SHAMT128'length));
                  else
                    i32(INST32_SHAMT128'range) <= ci_imm(5) & ci_imm(5 downto 0);
                  end if;

                else
                  if XLEN = 64 then
                    i32(INST32_SHAMT64'range) <= ci_imm;
                  else -- XLEN = 32
                    i32(INST32_SHAMT32'range) <= ci_imm(4 downto 0);
                    if ci_imm(5) = '1' then
                      illegal <= '1';
                      i32 <= (others => '-');
                    end if;
                  end if;

                  if ci_imm = std_logic_vector(to_unsigned(0, ci_imm'length)) then
                    hint <= '1';
                  end if;

                end if;

              when FUNCT2_C_ANDI =>
                i32(INST32_FUNCT3'range)  <= FUNCT3_AND;

              when others =>
                i32(INST32_RS2'range)     <= rs2p;
                i32(INST32_FUNCT7'range)  <= (others => '0');

                if i16(12) = '0' then
                  i32(INST32_OPCODE'range)  <= OP_OP;

                  case i16(INST16_FUNCT2_ALU_R'range) is
                    when FUNCT2_C_SUB =>
                      i32(INST32_FUNCT7'range) <= FUNCT7_SUB;
                    when FUNCT2_C_XOR =>
                      i32(INST32_FUNCT3'range) <= FUNCT3_XOR;
                    when FUNCT2_C_OR  =>
                      i32(INST32_FUNCT3'range) <= FUNCT3_OR;
                    when FUNCT2_C_AND =>
                      i32(INST32_FUNCT3'range) <= FUNCT3_AND;
                    when others => -- impossible
                  end case;

                else
                  if XLEN /= 32 then
                    i32(INST32_OPCODE'range) <= OP_OP_32;

                    case i16(INST16_FUNCT2_ALU_R'range) is
                      when FUNCT2_C_SUBW =>
                        i32(INST32_FUNCT7'range) <= FUNCT7_SUB;
                      when FUNCT2_C_ADDW =>
                      when others =>
                        illegal <= '1';
                        i32 <= (others => '-');
                    end case;

                  else
                    illegal <= '1';
                    i32 <= (others => '-');
                  end if;
                end if;

            end case;

          when FUNCT3_C_J =>
            i32(INST32_U_J_IMM'range) <= j_imm(20) & j_imm(10 downto 1) & j_imm(11) & j_imm(19 downto 12);
            i32(INST32_RD'range)      <= REG_ZERO;
            i32(INST32_OPCODE'range)  <= OP_JAL;

          when FUNCT3_C_BEQZ | FUNCT3_C_BNEZ =>

            i32(INST32_FUNCT7'range)  <= std_logic_vector(resize(signed(cb_imm(8 downto 5)), INST32_FUNCT7'length));
            i32(INST32_RS2'range)     <= REG_ZERO;
            i32(INST32_RS1'range)     <= rs1p;

            if i16(INST16_FUNCT3'range) = FUNCT3_C_BEQZ then
              i32(INST32_FUNCT3'range)  <= FUNCT3_BEQ;
            else
              i32(INST32_FUNCT3'range)  <= FUNCT3_BNE;
            end if;

            i32(INST32_RD'range)      <= cb_imm(4 downto 1) & cb_imm(8);
            i32(INST32_OPCODE'range)  <= OP_BRANCH;

          when others => -- Not possible

        end case;

      when OP_C2 =>
        -- Default values
        i32(INST32_RS1'range) <= REG_SP;
        i32(INST32_RD'range)  <= rd;
        i32(INST32_RS2'range) <= rs2;

        case i16(INST16_FUNCT3'range) is
          when FUNCT3_C_SLLI_SLLI64 =>
            i32(INST32_FUNCT7'range) <= FUNCT7_SLL;
            i32(INST32_RS1'range)    <= rs1;
            i32(INST32_FUNCT3'range) <= FUNCT3_SL;
            i32(INST32_OPCODE'range) <= OP_IMM;

            if rd = REG_ZERO then
              hint <= '1';
            end if;

            if XLEN = 128 then
              if ci_imm = std_logic_vector(to_unsigned(0, ci_imm'length)) then
                i32(INST32_SHAMT128'range) <= std_logic_vector(to_unsigned(64, INST32_SHAMT128'length));
              else
                i32(INST32_SHAMT128'range) <= '0' & ci_imm(5 downto 0);
              end if;

            else
              if XLEN = 64 then
                i32(INST32_SHAMT64'range) <= ci_imm;

                if ci_imm = std_logic_vector(to_unsigned(0, ci_imm'length)) then
                  hint <= '1';
                end if;

              else -- XLEN = 32
                i32(INST32_SHAMT32'range) <= ci_imm(4 downto 0);
                if ci_imm(5) = '1' then
                  hint <= '0';
                  illegal <= '1';
                  i32 <= (others => '-');
                elsif ci_imm = std_logic_vector(to_unsigned(0, ci_imm'length)) then
                  hint <= '1';
                end if;

              end if;
            end if;

          when FUNCT3_C_FLDSP_LQSP =>
            if XLEN = 128 then
              i32(INST32_I_IMM'range)  <= "00" & i16(5 downto 2) & i16(12) & i16(6) & "0000";
              i32(INST32_FUNCT3'range) <= FUNCT3_LQ;
              i32(INST32_OPCODE'range) <= OP_MISC_MEM;
              if rd = REG_ZERO then
                illegal <= '1';
                i32 <= (others => '-');
              end if;
            else
              if FLEN >= 64 then
                i32(INST32_I_IMM'range)  <= "000" & i16(4 downto 2) & i16(12) & i16(6) & i16(5) & "000";
                i32(INST32_FUNCT3'range) <= FUNCT3_LD;
                i32(INST32_OPCODE'range) <= OP_LOAD_FP;
              else
                illegal <= '1';
                i32 <= (others => '-');
              end if;
            end if;

          when FUNCT3_C_LWSP =>
            i32(INST32_I_IMM'range)  <= "0000" & i16(3) & i16(2) & i16(12) & i16(6 downto 4) & "00";
            i32(INST32_FUNCT3'range) <= FUNCT3_LW;
            i32(INST32_OPCODE'range) <= OP_LOAD;

            if rd = REG_ZERO then
              illegal <= '1';
              i32 <= (others => '-');
            end if;

          when FUNCT3_C_FLWSP_LDSP =>
            if XLEN = 32 then
              if FLEN >= 32 then
                i32(INST32_I_IMM'range)  <= "0000" & i16(3) & i16(2) & i16(12) & i16(6 downto 4) & "00";
                i32(INST32_FUNCT3'range) <= FUNCT3_LW;
                i32(INST32_OPCODE'range) <= OP_LOAD_FP;
              else
                illegal <= '1';
                i32 <= (others => '-');
              end if;
            else
              i32(INST32_I_IMM'range)  <= "000" & i16(4 downto 2) & i16(12) & i16(6) & i16(5) & "000";
              i32(INST32_FUNCT3'range) <= FUNCT3_LD;
              i32(INST32_OPCODE'range) <= OP_LOAD;

              if rd = REG_ZERO then
                illegal <= '1';
                i32 <= (others => '-');
              end if;
            end if;

          when FUNCT3_C_JR_MV_EBREAK_JALR_ADD =>

            if rs2 = std_logic_vector(to_unsigned(0, rs2'length)) then
              if rs1 = std_logic_vector(to_unsigned(0, rs1'length)) then
                if i16(12) = '1' then -- EBREAK
                  i32(INST32_FUNCT12'range) <= FUNCT12_EBREAK;
                  i32(INST32_RS1'range) <= (others => '0');
                  i32(INST32_FUNCT3'range) <= FUNCT3_PRIV;
                  i32(INST32_RD'range) <= (others => '0');
                  i32(INST32_OPCODE'range) <= OP_SYSTEM;
                else
                  illegal <= '1';
                  i32 <= (others => '-');
                end if;
              else
                i32(INST32_I_IMM'range)  <= (others => '0');
                i32(INST32_RS1'range)    <= rs1;
                i32(INST32_FUNCT3'range) <= FUNCT3_JALR;
                i32(INST32_OPCODE'range) <= OP_JALR;

                if i16(12) = '1' then --JALR
                  i32(INST32_RD'range) <= REG_RA;
                else --JR
                  i32(INST32_RD'range) <= REG_ZERO;
                end if;
              end if;

            else
              i32(INST32_FUNCT7'range) <= FUNCT7_ADD;
              i32(INST32_FUNCT3'range) <= FUNCT3_ADDSUB;
              i32(INST32_OPCODE'range) <= OP_OP;

              if i16(12) = '1' then -- ADD
                i32(INST32_RS1'range) <= rs1;
              else -- MV
                i32(INST32_RS1'range) <= REG_ZERO;
              end if;

              if rd = REG_ZERO then
                hint <= '1';
              end if;
            end if;

          when FUNCT3_C_FSDSP_SQSP =>
            if XLEN = 128 then
              i32(INST32_FUNCT7'range) <= "00" & i16(10 downto 7) & i16(12);
              i32(INST32_FUNCT3'range) <= FUNCT3_SQ;
              i32(INST32_RD'range)     <= i16(11) & "0000";
              i32(INST32_OPCODE'range) <= OP_STORE;
            else
              if FLEN >= 64 then
                i32(INST32_FUNCT7'range)  <= "000" & i16(9 downto 7) & i16(12);
                i32(INST32_FUNCT3'range)  <= FUNCT3_SD;
                i32(INST32_RD'range)      <= i16(11 downto 10) & "000";
                i32(INST32_OPCODE'range)  <= OP_STORE_FP;
              else
                illegal <= '1';
                i32 <= (others => '-');
              end if;
            end if;

          when FUNCT3_C_SWSP =>
            i32(INST32_FUNCT7'range)  <= "0000" & i16(8) & i16(7) & i16(12);
            i32(INST32_FUNCT3'range)  <= FUNCT3_SW;
            i32(INST32_RD'range)      <= i16(11 downto 9) & "00";
            i32(INST32_OPCODE'range)  <= OP_STORE;

          when FUNCT3_C_FSWSP_SDSP =>
            if XLEN = 32 then
              if FLEN >= 32 then
                i32(INST32_FUNCT7'range)  <= "0000" & i16(8) & i16(7) & i16(12);
                i32(INST32_FUNCT3'range)  <= FUNCT3_SW;
                i32(INST32_RD'range)      <= i16(11 downto 9) & "00";
                i32(INST32_OPCODE'range)  <= OP_STORE_FP;
              else
                illegal <= '1';
                i32 <= (others => '-');
              end if;

            else
              i32(INST32_FUNCT7'range)  <= "000" & i16(9 downto 7) & i16(12);
              i32(INST32_FUNCT3'range)  <= FUNCT3_SD;
              i32(INST32_RD'range)      <= i16(11 downto 10) & "000";
              i32(INST32_OPCODE'range)  <= OP_STORE;
            end if;
          when others =>
        end case;

      when others => -- OP_C3
        i32 <= (others => '-');

    end case;

    -- Illegal instruction overwrite
    if i16 ?= (x"0000" or x"FFFF") then
      illegal <= '1';
      i32 <= (others => '-');
    end if;


  end process;

  hint_o    <= hint;
  illegal_o <= illegal;
  inst32_o  <= i32;

end architecture;
