library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.log2;

library riscv;
use riscv.RV32I.all;
use riscv.RV64I.all;
use riscv.RV128I.all;

use riscv.C_EXT.all;
use riscv.F_EXT.all;
use riscv.D_EXT.all;
use riscv.Q_EXT.all;


entity decoder is
  generic (
    C_EXT : boolean;
    FLEN  : natural;
    XLEN  : natural
  );
  port (
    inst_i      : in  std_logic_vector(31 downto 0);
    imm_o       : out std_logic_vector(XLEN-1 downto 0);
    funct12_o   : out std_logic_vector(11 downto 0);
    funct7_o    : out std_logic_vector(6 downto 0);
    rs2_o       : out std_logic_vector(4 downto 0);
    rs1_o       : out std_logic_vector(4 downto 0);
    rd_o        : out std_logic_vector(4 downto 0);
    funct3_o    : out std_logic_vector(2 downto 0);
    opcode_o    : out std_logic_vector(4 downto 0);
    pc_inc      : out std_logic; -- 0 = pc + 4, 1 = pc + 2
    illegal_o   : out std_logic;
    hint_o      : out std_logic -- TODO custom hints
  );
end entity;

architecture rtl of decoder is

  -- Generic signals
  signal inst       : std_logic_vector(inst_i'range);

  signal funct7     : std_logic_vector(31 downto 25);
  signal rs2        : std_logic_vector(24 downto 20);
  signal rs1        : std_logic_vector(19 downto 15);
  signal funct3     : std_logic_vector(14 downto 12);
  signal rd         : std_logic_vector(11 downto 7);
  signal opcode     : std_logic_vector(6 downto 2);
  signal imm        : std_logic_vector(XLEN-1 downto 0);

  -- imm formater
  signal op_i       : std_logic;
  signal op_u       : std_logic;
  signal op_s       : std_logic;
  signal op_b       : std_logic;
  signal op_j       : std_logic;
  signal i_imm      : std_logic_vector(imm'range);
  signal u_imm      : std_logic_vector(imm'range);
  signal s_imm      : std_logic_vector(imm'range);
  signal b_imm      : std_logic_vector(imm'range);
  signal j_imm      : std_logic_vector(imm'range);

  signal illegal32  : std_logic;
  signal hint32     : std_logic;

  signal illegal16  : std_logic;
  signal hint16     : std_logic;

  -- C extension
  signal c_valid    : std_logic;
  signal c_inst     : std_logic_vector(inst_i'range);

  component decompress is
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
  end component;

begin

  c_valid <= '1' when inst_i(INST32_QUADRANT'range) /= OP_C3 and illegal32 /= '1' and C_EXT = true else '0';

  p_inst_select:
  process(inst_i, c_inst, c_valid)
  begin
    inst <= inst_i;
    if C_EXT = true then
      if c_valid = '1' then
        inst <= c_inst;
      end if;
    end if;
  end process;

  opcode <= inst(INST32_OPCODE'range);
  rd     <= inst(INST32_RD'range);
  funct3 <= inst(INST32_FUNCT3'range);
  rs1    <= inst(INST32_RS1'range);
  rs2    <= inst(INST32_RS2'range);
  funct7 <= inst(INST32_FUNCT7'range);

  -- Immediate formater
  op_i <= '1' when (opcode = OP_IMM)  or
                   (opcode = OP_JALR) or
                   (opcode = OP_LOAD) or
                   (opcode = OP_IMM_32 and XLEN >= 64)  or
                   (opcode = OP_IMM_64 and XLEN = 128)  or
                   (opcode = OP_LOAD_FP and FLEN >= 32) else
                   '0';

  i_imm    <= std_logic_vector(resize(signed(inst(31 downto 31)), 21)) & inst(30 downto 25) & inst(24 downto 21) & inst(20);

  op_s <= '1' when opcode = OP_STORE or (opcode = OP_STORE_FP and FLEN >= 32) else '0';
  s_imm    <= std_logic_vector(resize(signed(inst(31 downto 31)), 21)) & inst(30 downto 25) & inst(11 downto 8) & inst(7);

  op_b <= '1' when opcode = OP_BRANCH else '0';
  b_imm    <= std_logic_vector(resize(signed(inst(31 downto 31)), 20)) & inst(7) & inst(30 downto 25) & inst(11 downto 8) & '0';

  op_u <= '1' when opcode = OP_LUI or opcode = OP_AUIPC else '0';
  u_imm    <= inst(31) & inst(30 downto 20) & inst(19 downto 12) & std_logic_vector(to_signed(0,12));

  op_j <= '1' when opcode = OP_JAL else '0';
  j_imm    <= std_logic_vector(resize(signed(inst(31 downto 31)), 12)) & inst(19 downto 12) & inst(20) & inst(30 downto 25) & inst(24 downto 21) & '0';

  imm <= i_imm when op_i = '1' else
         s_imm when op_s = '1' else
         b_imm when op_b = '1' else
         u_imm when op_u = '1' else
         j_imm when op_j = '1' else
         (others => '-');


  p_illegal_hint_decoder:
  process(inst_i)
    variable op_v   : std_logic_vector(INST32_OPCODE'range);
    variable rd_v   : std_logic_vector(INST32_RD'range);
    variable f3_v   : std_logic_vector(INST32_FUNCT3'range);
    variable rs1_v  : std_logic_vector(INST32_RS1'range);
    variable rs2_v  : std_logic_vector(INST32_RS2'range);
    variable f7_v   : std_logic_vector(INST32_FUNCT7'range);
    variable f12_v  : std_logic_vector(INST32_FUNCT12'range);
    variable fm_v   : std_logic_vector(INST32_FM'range);

  begin
    op_v := inst_i(INST32_OPCODE'range);
    rd_v := inst_i(INST32_RD'range);
    f3_v := inst_i(INST32_FUNCT3'range);
    rs1_v:= inst_i(INST32_RS1'range);
    rs2_v:= inst_i(INST32_RS2'range);
    f7_v := inst_i(INST32_FUNCT7'range);
    f12_v:= inst_i(INST32_FUNCT12'range);
    fm_v := inst_i(INST32_FM'range);

    -- DEFAULT
    illegal32 <= '0';
    hint32 <= '0';

    -- RV32I - Base ISA
    -- Minimum value of XLEN MUST be at least 32
    if XLEN >= 32 then

      case op_v is
        when OP_OP => -- R_TYPE
          if unsigned(f7_v) /= 0 or f7_v /= b"0100000" then
            illegal32 <= '1';
          end if;

          if rd_v = REG_ZERO then
            illegal32 <= '0';
            hint32 <= '1';
          end if;

        when OP_IMM =>
          if f3_v = FUNCT3_SL or f3_v = FUNCT3_SR then
            if unsigned(f7_v) /= 0 or unsigned(f7_v) /= b"0100000" then
              illegal32 <= '1';
            end if;
          -- Custom hints if rd=0
          end if;

          if rd_v = REG_ZERO then
            illegal32 <= '0';
            hint32 <= '1';

            if f3_v = FUNCT3_ADDSUB then
              if unsigned(inst_i(INST32_I_IMM'range)) = 0 then
                hint32 <= '0';
              end if;
            end if;
          else
            if f3_v = FUNCT3_ADDSUB then
              if unsigned(inst_i(INST32_I_IMM'range)) = 0 then
                hint32 <= '1';
              end if;
            end if;
          end if;


        when OP_JALR =>
          if f3_v /= FUNCT3_JALR then
            illegal32 <= '1';
          end if;

        when OP_LOAD =>
          case f3_v is
            when FUNCT3_LB | FUNCT3_LBU =>
            when FUNCT3_LH | FUNCT3_LHU =>
            when FUNCT3_LW =>
            when others =>
              illegal32 <= '1';
          end case;

        when OP_MISC_MEM =>
          if f3_v /= FUNCT3_FENCE or
             fm_v /= FM_NORMAL or
             fm_v /= FM_TSO or
             unsigned(rd_v) /= 0 or
             unsigned(rs1_v) /= 0 then

            illegal32 <= '1';
          end if;

          if unsigned(inst_i(INST32_PRED'range)) = 0 or unsigned(inst_i(INST32_SUCC'range)) = 0 then
            hint32 <= '1';
          end if;

        when OP_SYSTEM =>
          if f3_v /= FUNCT3_PRIV or
             f12_v /= FUNCT12_ECALL or
             f12_v /= FUNCT12_EBREAK or
             unsigned(rd_v) /= 0 or
             unsigned(rs1_v) /= 0 then

            illegal32 <= '1';
          end if;

        when OP_STORE => -- S_TYPE
          case f3_v is
            when FUNCT3_SB | FUNCT3_SH | FUNCT3_SW =>
            when others =>
              illegal32 <= '1';
          end case;

        when OP_BRANCH => -- B_TYPE
          case f3_v is
            when FUNCT3_BEQ | FUNCT3_BNE | FUNCT3_BLT | FUNCT3_BGE | FUNCT3_BLTU | FUNCT3_BGEU =>
            when others =>
              illegal32 <= '1';
          end case;

        when OP_LUI | OP_AUIPC =>
          if rd_v = REG_ZERO then
            hint32 <= '1';
          end if;

        when OP_JAL =>

        when others => -- Unknown opcode
          illegal32 <= '1';

      end case;

    end if;

    -- RV64I includes RV32I
    if XLEN >= 64 then
      -- New valid opcodes: OP_IMM_32 and OP_OP_32
      -- SLLIW,SRLIW and SRAIW -> imm[5] = 1 is reserved
      -- OP_LOAD : Add FUNCT3_LD, FUNCT3_LWU
      -- OP_STORE : Add FUNCT3_SD
      -- Support of FMV.X.Q and FMV.Q.X and FCVT for 128 bits if FLEN=128 present..
      case op_v is
        when OP_IMM_32 | OP_OP_32 =>
          illegal32 <= '0';

        when OP_LOAD =>
          if f3_v = FUNCT3_LD or f3_v = FUNCT3_LW then
            illegal32 <= '0';
          end if;

        when OP_STORE =>
          if f3_v = FUNCT3_SD then
            illegal32 <= '0';
          end if;

        when others =>

      end case;

    end if;

    -- RV128I, includes RV32I & RV64I
    if XLEN = 128 then
      -- New Valid opcodes: OP_IMM_64 and OP_OP_64
      -- OP_LOAD: Add FUNCT3_LDU,
      -- OP_MISC_MEM : Add add LQ, not specified in spec
      -- OP_STORE : Add SQ
      -- Support of FMV.X.Q and FMV.Q.X and FCVT for 128 bits if FLEN=128 present..
      case op_v is
        when OP_IMM_64 | OP_OP_64 =>
          illegal32 <= '0';
        when OP_LOAD =>
          if f3_v = FUNCT3_LDU then
            illegal32 <= '0';
          end if;
        when OP_MISC_MEM =>
          if f3_v = FUNCT3_LQ then
            illegal32 <= '0';
          end if;
        when OP_STORE =>
          if f3_v = FUNCT3_SQ then
            illegal32 <= '0';
          end if;
        when others =>
      end case;
    end if;

  end process;


  gen_c_decompressor:
  if C_EXT = true generate
    u_c_decompressor: decompress
      generic map(
        XLEN => XLEN,
        FLEN => FLEN
      )
      port map(
        inst16_i  => inst_i(15 downto 0),
        inst32_o  => c_inst,
        hint_o    => hint16,
        illegal_o => illegal16
      );
  end generate;


  -- Output asigment
  funct12_o  <= funct7 & rs2;
  funct7_o   <= funct7;
  rs2_o      <= rs2;
  rs1_o      <= rs1;
  funct3_o   <= funct3;
  rd_o       <= rd;
  opcode_o   <= opcode;
  imm_o      <= imm;

  illegal_o <= illegal16 when c_valid = '1' else illegal32;
  hint_o    <= hint16 when c_valid = '1' else hint32;
  pc_inc    <= c_valid;

end architecture rtl;
