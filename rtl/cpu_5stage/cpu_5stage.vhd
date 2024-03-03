library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library riscv;
use riscv.RV32I.all;

use work.types_pkg.all;

entity cpu is
  generic(
    XLEN           : natural;
    IMEM_ADDRWIDTH : natural;
    DMEM_ADDRWIDTH : natural
  );
  port (
    -- Control Interface
    clk_i   : in  std_logic;
    rst_i   : in  std_logic;
    en_i    : in  std_logic;
    halt_o  : out std_logic;

    -- Interrupts interface
    interrupt_i : in std_logic_vector(31 downto 0);

    -- imem interface
    imem_en_i   : in  std_logic;
    imem_we_i   : in  std_logic_vector(3 downto 0);
    imem_addr_i : in  std_logic_vector(IMEM_ADDRWIDTH-1 downto 0);
    imem_data_i : in  std_logic_vector(31 downto 0);
    imem_valid_i: in  std_logic;
    imem_data_o : out std_logic_vector(31 downto 0);

    -- dmem interface
    dmem_en_i   : in  std_logic;
    dmem_we_i   : in  std_logic_vector(XLEN/8-1 downto 0);
    dmem_addr_i : in  std_logic_vector(DMEM_ADDRWIDTH-1 downto 0);
    dmem_data_i : in  std_logic_vector(XLEN-1 downto 0);
    dmem_valid_i: in std_logic;
    dmem_data_o : out std_logic_vector(XLEN-1 downto 0)
  );
end entity;

architecture rtl of cpu is

  constant NB_STAGE : natural := 5;
  signal en    : std_logic_vector(NB_STAGE-1 downto 0);
  --signal halt  : std_logic_vector(NB_STAGE-1 downto 0);
  --signal flush : std_logic_vector(NB_STAGE-1 downto 0);

  --------------------
  -- STAGE 0
  --------------------
  signal pc_0        : std_logic_vector(XLEN-1 downto 0);
  signal pc_op1_0    : unsigned(XLEN-1 downto 0);
  signal pc_op2_0    : unsigned(XLEN-1 downto 0);
  signal next_pc_0   : unsigned(XLEN-1 downto 0);

  signal imem_en_0     : std_logic;
  signal imem_we_0     : std_logic_vector(3 downto 0);
  signal imem_addr_0   : std_logic_vector(IMEM_ADDRWIDTH-1 downto 0);
  signal imem_din_0    : std_logic_vector(XLEN-1 downto 0);

  --------------------
  -- STAGE 1
  --------------------
  signal pc_1          : std_logic_vector(pc_0'range);
  signal imem_dout_1   : std_logic_vector(XLEN-1 downto 0);
  signal instruction_1 : std_logic_vector(31 downto 0);

  signal immediate_1 : std_logic_vector(XLEN-1 downto 0);
  signal funct12_1   : std_logic_vector(11 downto 0);
  signal funct7_1    : std_logic_vector(6 downto 0);
  signal rs1_1       : std_logic_vector(4 downto 0);
  signal rs2_1       : std_logic_vector(4 downto 0);
  signal rd_1        : std_logic_vector(4 downto 0);
  signal funct3_1    : std_logic_vector(2 downto 0);
  signal opcode_1    : std_logic_vector(4 downto 0);
  signal pc_inc_1    : std_logic; -- 0 = pc + 4, 1 = pc + 2
  signal illegal_1   : std_logic;
  signal hint_1      : std_logic; -- TODO custom hints

  signal reg_we_1   : std_logic;
  signal op1_1      : std_logic_vector(XLEN-1 downto 0);
  signal op2_1      : std_logic_vector(XLEN-1 downto 0);
  signal halt_1     : std_logic;

  signal branch_1 : std_logic;

  signal ras_push_1 : std_logic;
  signal ras_pop_1  : std_logic;
  signal ras_din_1  : std_logic_vector(XLEN-1 downto 0);
  signal ras_dout_1 : std_logic_vector(XLEN-1 downto 0);
  signal ras_full_1 : std_logic;
  signal ras_empty_1 : std_logic;
  signal rs1_link_1 : std_logic;
  signal rd_link_1  : std_logic;

  --------------------
  -- STAGE 2
  --------------------
  signal alu_in1     : std_logic_vector(XLEN-1 downto 0);
  signal alu_in2     : std_logic_vector(XLEN-1 downto 0);
  signal alu_out_2   : std_logic_vector(XLEN-1 downto 0);
  signal rd_2        : std_logic_vector(rd_1'range);
  signal pc_2        : std_logic_vector(pc_0'range);
  signal op1_2       : std_logic_vector(op1_1'range);
  signal op2_2       : std_logic_vector(op2_1'range);
  signal immediate_2 : std_logic_vector(immediate_1'range);

  signal funct3_2    : std_logic_vector(funct3_1'range);
  signal funct7_2    : std_logic_vector(funct7_1'range);
  signal opcode_2    : std_logic_vector(opcode_1'range);

  signal alu_funct3_2: std_logic_vector(funct3_1'range);
  signal rs1_2       : std_logic_vector(rs1_1'range);
  signal rs2_2       : std_logic_vector(rs2_1'range);

  signal op1_foward_2 : std_logic_vector(op1_1'range);
  signal op2_foward_2 : std_logic_vector(op2_1'range);

  signal reg_we_2       : std_logic;

  signal cmp_op1_2      : std_logic_vector(XLEN-1 downto 0);
  signal cmp_op2_2      : std_logic_vector(XLEN-1 downto 0);
  signal cmp_eq_2       : std_logic;
  signal cmp_lt_2       : std_logic;
  signal cmp_ltu_2      : std_logic;

  signal ras_dout_2     : std_logic_vector(ras_dout_1'range);
  signal rd_link_2      : std_logic;

  signal branch_2 : std_logic;
  signal halt_2 : std_logic;


  --------------------
  -- STAGE 3
  --------------------
  signal alu_out_3   : std_logic_vector(alu_out_2'range);
  signal funct3_3    : std_logic_vector(funct3_1'range);
  signal funct7_3    : std_logic_vector(funct7_1'range);
  signal opcode_3    : std_logic_vector(opcode_1'range);
  signal op2_3       : std_logic_vector(op2_1'range);
  signal rd_3        : std_logic_vector(rd_1'range);
  signal rs2_3       : std_logic_vector(rs2_1'range);

  signal branch_3    : std_logic;

  signal dmem_en_3   : std_logic;
  signal dmem_we_3   : std_logic_vector(XLEN/8-1 downto 0);
  signal dmem_din_3  : std_logic_vector(XLEN-1 downto 0);
  signal dmem_addr_3 : std_logic_vector(DMEM_ADDRWIDTH-1 downto 0);

  signal dmem_dsrc_3 : std_logic_vector(XLEN-1 downto 0);

  signal addr_missaligned : std_logic;

  signal foward_op1_3 : std_logic;
  signal foward_op2_3 : std_logic;

  signal reg_we_3   : std_logic;
  signal halt_3 : std_logic;
  signal mem_dvalid_3 : std_logic;

  signal cmp_eq_3 : std_logic;

  --------------------
  -- STAGE 4
  --------------------
  signal dmem_dout_4 : std_logic_vector(XLEN-1 downto 0);
  signal dmem_data_4 : std_logic_vector(XLEN-1 downto 0);
  signal alu_out_4   : std_logic_vector(alu_out_2'range);
  signal opcode_4    : std_logic_vector(opcode_1'range);
  signal rd_4        : std_logic_vector(rd_1'range);
  signal res_4       : std_logic_vector(XLEN-1 downto 0);
  signal funct3_4    : std_logic_vector(funct3_1'range);

  signal foward_op1_4 : std_logic;
  signal foward_op2_4 : std_logic;
  signal foward_mem_4 : std_logic;

  signal reg_we_4   : std_logic;
  signal halt_4 : std_logic;
  signal mem_dvalid_4 : std_logic;

begin

  ------------------------
  -- TODO LIST
  ------------------------
  -- Interrupts
  -- M extension / Zmul
  -- Mac operation
  --
  -- DECODER
  --  Change decoder to only handle illegal/hint
  --  Move C decompressor in toplevel
  --  Create instruction structure in toplevel
  --  Illegal instruction handling
  --
  -- MEMORY
  -- Move memory out of core
  -- I/D cache
  -- Wishbone interface (External memory interface)
  -- Memory missalignment error:
  --   If memory misalignment is detected: Generate another load/store instruction and stall pipeline.
  --   Combine the results and store in register in case of load.
  -----------------------

  --------------------------------------------------
  -- GLOBAL CONTROL
  --------------------------------------------------
  --TODO: HALT
  -- Pipeline Stalling
  en(0) <= '0' when (opcode_3 = OP_LOAD and unsigned(rd_3) /= 0 and (rd_3 = rs1_2 or rd_3 = rs2_2)) and mem_dvalid_4 = '0' else en_i;
  en(1) <= '0' when (opcode_3 = OP_LOAD and unsigned(rd_3) /= 0 and (rd_3 = rs1_2 or rd_3 = rs2_2)) and mem_dvalid_4 = '0' else en_i;
  en(2) <= '0' when (opcode_3 = OP_LOAD and unsigned(rd_3) /= 0 and (rd_3 = rs1_2 or rd_3 = rs2_2)) and mem_dvalid_4 = '0' else en_i;
  en(3) <= '0' when (opcode_3 = OP_LOAD and unsigned(rd_3) /= 0 and (rd_3 = rs1_2 or rd_3 = rs2_2)) and mem_dvalid_4 = '0' else en_i;
  en(4) <= en_i;

  --------------------------------------------------
  -- STAGE 0 : INSTRUCTION MEMORY
  --------------------------------------------------
  pc_op1_0 <= unsigned(pc_2) when (opcode_2 = OP_BRANCH and branch_2 = '1') else
              unsigned(op1_foward_2) when (opcode_2 = OP_JALR and cmp_eq_2 = '0') else
              unsigned(pc_1) when opcode_1 = OP_JAL else
              unsigned(pc_0);


  pc_op2_0 <= unsigned(immediate_2)           when (opcode_2 = OP_BRANCH and branch_2 = '1') or (opcode_2 = OP_JALR and cmp_eq_2 = '0') else
              unsigned(immediate_1)           when opcode_1 = OP_JAL else
              to_unsigned(2, pc_op2_0'length) when pc_inc_1 = '1' else
              to_unsigned(4, pc_op2_0'length);


  next_pc_0 <= unsigned(ras_dout_1) when opcode_1 = OP_JALR and ras_empty_1 = '0' and ras_pop_1 = '1' else
               pc_op1_0 + pc_op2_0;

  p_pc:
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        pc_0 <= (others => '0');
      elsif en(0) = '1' then
        if opcode_2 = OP_JALR and cmp_eq_2 = '0' then
          pc_0 <= std_logic_vector(next_pc_0(XLEN-1 downto 1) & '0');
        else
          pc_0 <= std_logic_vector(next_pc_0);
        end if;
      end if;
    end if;
  end process;

  -- Note: Procedure to write to memory:
  -- 1. en_i -> '0'
  -- 2. imem_wr_i -> '1'
  -- 3. imem_data_i + imem_addr_i  = values wanted

  -- FIXME: Stalling here
  -- TODO: Make cpu able to write data to instruction memory
  imem_en_0   <= imem_en_i or en(0);
  imem_we_0   <= imem_we_i when imem_en_i = '1' else (others => '0');
  imem_addr_0 <= imem_addr_i when imem_en_i = '1' else pc_0(IMEM_ADDRWIDTH-1+2 downto 2);
  imem_din_0 <= imem_data_i when imem_en_i = '1' else (others => '0');

  u_imem : entity work.mem(rtl)
  generic map(
    DATA_WIDTH => 32,
    ADDR_WIDTH => IMEM_ADDRWIDTH
  )
  port map(
    clk_i   => clk_i,
    en_i    => imem_en_0,
    we_i    => imem_we_0,
    addr_i  => imem_addr_0,
    data_i  => imem_din_0,
    data_o  => imem_dout_1
  );

  imem_data_o <= imem_dout_1;

  --------------------------------------------------
  -- STAGE 1 : DECODE, REGISTER, PC, BRANCH PREDICTION
  --------------------------------------------------
  p_s1:
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if en(1) = '1' then
        pc_1 <= pc_0;
      end if;
    end if;
  end process;

  -- Stall 1 cycle when jump
  -- Stall 2 cycles for JALR & Branch
  -- Optimizations: JALR => address stack for x1/x5
  --                BRANCH => Branch predictor + always backward branch
  instruction_1 <= INST32_NOP when opcode_2 = OP_JAL or
                                  (opcode_2 = OP_BRANCH and branch_2 = '1') or
                                  (opcode_3 = OP_BRANCH and branch_3 = '1') or
                                  (opcode_2 = OP_JALR and cmp_eq_2 = '0') or
                                  (opcode_3 = OP_JALR and cmp_eq_3 = '0') else
                   imem_dout_1;


  u_decoder: entity work.decoder(rtl)
  generic map(
    C_EXT => true,
    FLEN  => 0,
    XLEN  => XLEN
  )
  port map(
    inst_i      => instruction_1,
    imm_o       => immediate_1,
    funct12_o   => funct12_1,
    funct7_o    => funct7_1,
    rs2_o       => rs2_1,
    rs1_o       => rs1_1,
    rd_o        => rd_1,
    funct3_o    => funct3_1,
    opcode_o    => opcode_1,
    pc_inc      => pc_inc_1,
    illegal_o   => illegal_1,
    hint_o      => hint_1
  );


  u_reg : entity work.reg(rtl)
  generic map(
    RLEN => 5,
    XLEN => XLEN
  )
  port map(
    clk_i => clk_i,
    we_i  => reg_we_4,
    rs1_i => rs1_1,
    rs2_i => rs2_1,
    rd_i  => rd_4,
    res_i => res_4,
    op1_o => op1_1,
    op2_o => op2_1
  );

  with opcode_1 select
    reg_we_1 <= '1' when OP_OP | OP_IMM | OP_LUI | OP_AUIPC | OP_LOAD | OP_JAL | OP_JALR,
                '0' when others;

  -- FIXME: Not really a HALT... but will do for now
  halt_1 <= '1' when opcode_1 = OP_SYSTEM and funct12_1 = FUNCT12_ECALL else '0';


  -- Branch prediction
  -- If imm < 0 -> take the branch
  --
  -- 2 bit Branch history table
  -- [tag][history]
  -- Tag = PC[tag_width-1 downto 0]
  -- history = 00 Strong pass, 01 weak pass, 10 weak take, 11 Strong take
  --    if take/pass -> change state
  --
  -- Loop predictor:
  -- Detect if loop, store number of loop iteration, count when pc=loop
  branch_1 <= '0';


  -- RETURN ADDRESS STACK
  -- Stores the address of a link register to reduce return latency to 1 cycle
  -- Return address is verified at stage_2 to make sure it is OK
  -- If OK : override calculated jalr addr for pc+4
  -- else: : Push RAS_dout_2 back into the RAS, set instruction_1 to NOP and next_pc <= jalr addr
  rd_link_1  <= '1' when rd_1 = REG_X01 or rd_1 = REG_X05 else '0';
  rs1_link_1 <= '1' when rs1_1 = REG_X01 or rs1_1 = REG_X05 else '0';

  ras_push_1 <= '1' when (opcode_2= OP_JAL or opcode_2 = OP_JALR) and rd_link_2 = '1' else
                '1' when opcode_2 = OP_JALR and cmp_eq_2 = '0' else
                '0';

  ras_pop_1 <= '1' when opcode_1 = OP_JALR and rd_link_1 = '0' and rs1_link_1 = '1' else
               '1' when opcode_1 = OP_JALR and rd_link_1 = '1' and rs1_link_1 = '1' and rs1_1 = rd_1 else
               '0';

  ras_din_1 <= ras_dout_2 when (opcode_2 = OP_JALR and cmp_eq_2 = '0') else alu_out_2;

  u_ras : entity work.stack(rtl)
    generic map(
      DATA_WIDTH => XLEN,
      STACK_SIZE => 8
    )
    port map(
      clk_i   => clk_i,
      rst_i   => rst_i,
      data_i  => ras_din_1,
      push_i  => ras_push_1,
      pop_i   => ras_pop_1,
      full_o  => ras_full_1,
      empty_o => ras_empty_1,
      data_o  => ras_dout_1
    );

  --------------------------------------------------
  -- STAGE 2 : EXECUTION, BRANCH
  --------------------------------------------------
  p_s2:
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if en(2) = '1' then
        pc_2        <= pc_1;
        op1_2       <= op1_1;
        op2_2       <= op2_1;
        immediate_2 <= immediate_1;
        funct3_2    <= funct3_1;
        funct7_2    <= funct7_1;
        opcode_2    <= opcode_1;
        rd_2        <= rd_1;
        reg_we_2    <= reg_we_1;
        halt_2      <= halt_1;
        rs1_2       <= rs1_1;
        rs2_2       <= rs2_1;
        rd_link_2   <= rd_link_1;
        ras_dout_2  <= ras_dout_1;
      end if;
    end if;
  end process;

  op1_foward_2 <= alu_out_3 when foward_op1_3 = '1' and opcode_3 /= OP_LOAD else
                  res_4     when foward_op1_4 = '1'  else
                  op1_2;


  with opcode_2 select
    alu_in1 <=  pc_2            when OP_AUIPC | OP_BRANCH | OP_JAL | OP_JALR,
                (others => '0') when OP_LUI,
                op1_foward_2    when others;


  op2_foward_2 <= alu_out_3 when foward_op2_3 = '1' and opcode_3 /= OP_LOAD else
                  res_4     when foward_op2_4 = '1' else
                  op2_2;

  with opcode_2 select
    alu_in2 <= immediate_2 when OP_IMM | OP_AUIPC | OP_LOAD | OP_STORE,
               std_logic_vector(to_unsigned(4, alu_in2'length)) when OP_BRANCH | OP_JAL | OP_JALR,
               op2_foward_2 when others;


  with opcode_2 select
    alu_funct3_2 <= FUNCT3_ADDSUB when OP_BRANCH | OP_JAL | OP_LUI,
                    funct3_2 when others;


  u_alu : entity work.alu(rtl)
  generic map(
    XLEN  => XLEN
  )
  port map(
    clk_i   => '1',
    rst_i   => '1',
    a_i     => alu_in1,
    b_i     => alu_in2,
    c_o     => alu_out_2,
    f3_i    => alu_funct3_2,
    f7_i    => funct7_2
  );

  -- Compare Unit
  cmp_op1_2 <= op1_foward_2;


  cmp_op2_2 <= ras_dout_2 when opcode_2 = OP_JALR else
               op2_foward_2;

  cmp_eq_2  <= '1' when unsigned(cmp_op1_2) = unsigned(cmp_op2_2) else '0';
  cmp_lt_2  <= '1' when   signed(cmp_op1_2) <   signed(cmp_op2_2) else '0';
  cmp_ltu_2 <= '1' when unsigned(cmp_op1_2) < unsigned(cmp_op2_2) else '0';


  p_branch:
  with funct3_2 select
  branch_2 <=     cmp_eq_2  when FUNCT3_BEQ,
              not cmp_eq_2  when FUNCT3_BNE,
                  cmp_lt_2  when FUNCT3_BLT,
              not cmp_lt_2  when FUNCT3_BGE,
                  cmp_ltu_2 when FUNCT3_BLTU,
              not cmp_ltu_2 when FUNCT3_BGEU,
              '0'           when others;

  --------------------------------------------------
  -- STAGE 3 : DATA MEMORY
  --------------------------------------------------
  -- TODO: Optimization: si last_addr = alu_out_3 -> dmem_dout3 == deja la valeur voulu
  --       Pas besoin de stall pendant 1 cycle pour loader
  p_s3:
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if en(3) = '1' then
        alu_out_3 <= alu_out_2;
        funct3_3  <= funct3_2;
        funct7_3  <= funct7_2;
        opcode_3  <= opcode_2;
        rd_3      <= rd_2;
        reg_we_3  <= reg_we_2;
        op2_3     <= op2_foward_2;
        rs2_3     <= rs2_2;
        halt_3    <= halt_2;
        branch_3  <= branch_2;
        cmp_eq_3  <= cmp_eq_2;
      end if;
    end if;
  end process;

  dmem_en_3   <= '1' when  dmem_en_i = '1' else
                 '1' when (opcode_3 = OP_STORE or opcode_3 = OP_LOAD) else
                 -- TEMPORARY: FIXME: strlen.txt and unsigned(alu_out_3(XLEN-1 downto IMEM_ADDRWIDTH)) = 0 else
                 '0';

  dmem_dsrc_3  <= dmem_data_i when dmem_en_i = '1' else
                 res_4       when foward_mem_4 = '1' else
                 op2_3;

  -- FIXME: valid pour 2 cycle d'horloges a cause que fait en mm temps
  mem_dvalid_3 <= '1' when opcode_3 = OP_LOAD else
                  -- TEMPORARY: FIXME: strlen.txt and unsigned(alu_out_3(XLEN-1 downto IMEM_ADDRWIDTH)) = 0 else
                  '0'; --FIXME: Add External memory interface data_valid here

  process(dmem_dsrc_3, alu_out_3, funct3_3, opcode_3, dmem_en_i, dmem_we_i, alu_out_4)
  begin
    dmem_din_3 <= dmem_dsrc_3;
    dmem_we_3 <= (others => '0');

    if opcode_3 = OP_STORE then
      case funct3_3 is
        when FUNCT3_SB =>
          for i in 0 to XLEN/8-1 loop
            if i = unsigned(alu_out_3(natural(log2(real(XLEN/8)))-1 downto 0)) then
              dmem_din_3(8*(i+1)-1 downto 8*i) <= dmem_dsrc_3(7 downto 0);
            end if;
            dmem_we_3(i) <= '1';
          end loop;

        when FUNCT3_SH =>
          for i in 0 to XLEN/16-1 loop
            if i = unsigned(alu_out_4(natural(log2(real(XLEN/16)))-1 downto 0)) then
              dmem_din_3(16*(i+1)-1 downto 16*i) <= dmem_dsrc_3(15 downto 0);
            end if;

            for j in 0 to XLEN/16-1 loop
              dmem_we_3(2*i+j) <= '1';
            end loop;
          end loop;

        when FUNCT3_SW =>
          dmem_din_3 <= dmem_dsrc_3;

          -- Fixme: make this dependent to XLEN
          dmem_we_3 <= "1111";
        when others =>
      end case;
    end if;

    if dmem_en_i = '1' then
      dmem_we_3 <= dmem_we_i;
    end if;

  end process;


  -- FIXME: Addressing
  dmem_addr_3 <= dmem_addr_i when dmem_en_i = '1' else
                 alu_out_3(DMEM_ADDRWIDTH+2-1 downto 2);


  p_missaligned:
  process(alu_out_3, opcode_3, funct3_3)
  begin
    addr_missaligned <= '0';
    if opcode_3 = OP_STORE or opcode_3 = OP_LOAD then
      case funct3_3 is
        when FUNCT3_LH | FUNCT3_LHU =>
          if alu_out_3(0 downto 0) /= "0" then
            addr_missaligned <= '1';
          end if;
        when FUNCT3_LW =>
          if alu_out_3(1 downto 0) /= "00" then
            addr_missaligned <= '1';
          end if;
        when others =>
      end case;
    end if;
  end process;


  u_dmem : entity work.mem(rtl)
  generic map(
    DATA_WIDTH => XLEN,
    ADDR_WIDTH => DMEM_ADDRWIDTH
  )
  port map(
    clk_i    => clk_i,
    en_i     => dmem_en_3,
    we_i     => dmem_we_3,
    data_i   => dmem_din_3,
    addr_i   => dmem_addr_3,
    data_o   => dmem_dout_4
  );
  dmem_data_o <= dmem_dout_4;

  foward_op1_3 <= '1' when rs1_2 = rd_3 and unsigned(rd_3) /= 0 and reg_we_3 = '1' else '0';
  foward_op2_3 <= '1' when rs2_2 = rd_3 and unsigned(rd_3) /= 0 and reg_we_3 = '1' else '0';


  --------------------------------------------------
  -- STAGE 4 : WRITE_BACK
  --------------------------------------------------
  p_s4:
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if en(4) = '1' then
        alu_out_4 <= alu_out_3;
        opcode_4  <= opcode_3;
        rd_4      <= rd_3;
        reg_we_4  <= reg_we_3;
        funct3_4  <= funct3_3;
        halt_4    <= halt_3;
        mem_dvalid_4 <= mem_dvalid_3;
      end if;
    end if;
  end process;


  -- TODO: Address missalignment error
  -- NOTE: Can't do missaligned reads.
  process(dmem_dout_4, alu_out_4, funct3_4)
  begin
    case funct3_4 is
      when FUNCT3_LB =>
        for i in 0 to XLEN/8-1 loop
          if i = unsigned(alu_out_4(natural(log2(real(XLEN/8)))-1 downto 0)) then
            dmem_data_4 <= std_logic_vector(resize(signed(dmem_dout_4(8*(i+1)-1 downto 8*i)),dmem_dout_4'length));
          end if;
        end loop;

      when FUNCT3_LBU =>
        for i in 0 to XLEN/8-1 loop
          if i = unsigned(alu_out_4(natural(log2(real(XLEN/8)))-1 downto 0)) then
            dmem_data_4 <= std_logic_vector(resize(unsigned(dmem_dout_4(8*(i+1)-1 downto 8*i)),dmem_dout_4'length));
          end if;
        end loop;

      when FUNCT3_LH =>
        for i in 0 to XLEN/16-1 loop
          if i = unsigned(alu_out_4(natural(log2(real(XLEN/16)))-1 downto 0)) then
            dmem_data_4 <= std_logic_vector(resize(signed(dmem_dout_4(16*(i+1)-1 downto 16*i)),dmem_dout_4'length));
          end if;
        end loop;

      when FUNCT3_LHU =>
        for i in 0 to XLEN/16-1 loop
          if i = unsigned(alu_out_4(natural(log2(real(XLEN/16)))-1 downto 0)) then
            dmem_data_4 <= std_logic_vector(resize(unsigned(dmem_dout_4(16*(i+1)-1 downto 16*i)),dmem_dout_4'length));
          end if;
        end loop;

      when FUNCT3_LW =>
        dmem_data_4 <= dmem_dout_4;

      when others =>
        dmem_data_4 <= dmem_dout_4;

    end case;
  end process;


  with opcode_4 select
    res_4 <= alu_out_4   when OP_OP | OP_IMM | OP_AUIPC | OP_JAL | OP_JALR | OP_LUI,
             dmem_data_4 when OP_LOAD,
             (others => '0') when others;


  foward_op1_4 <= '1' when rs1_2 = rd_4 and unsigned(rd_4) /= 0 and reg_we_4 = '1' else '0';
  foward_op2_4 <= '1' when rs2_2 = rd_4 and unsigned(rd_4) /= 0 and reg_we_4 = '1' else '0';
  foward_mem_4 <= '1' when rs2_3 = rd_4 and unsigned(rd_4) /= 0 and reg_we_4 = '1' else '0';

  --------------------------------------------------
  -- OUTPUTS
  --------------------------------------------------
  halt_o <= halt_4;

end architecture;
