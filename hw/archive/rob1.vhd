library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library riscv;
use riscv.RV32I.all;

entity rob1 is
  generic(
    REG_WIDTH : natural;
    ROB_WIDTH : natural;
    XLEN      : natural
  );
  port(
    -- Control Interface
    clk_i  : in  std_logic;
    rst_i  : in  std_logic;
    full_o : out std_logic;

    -- Dispatch Interface
    disp_we_i  : in std_logic;                              -- Instruction is dispatched to the ROB
    disp_reg_i : in std_logic;                              -- Result will be written in the registers
    disp_op_i  : in std_logic_vector(5 downto 0);           -- Instruciton opcode
    disp_rs1_i : in std_logic_vector(REG_WIDTH-1 downto 0); -- Instruction rs1
    disp_rs2_i : in std_logic_vector(REG_WIDTH-1 downto 0); -- Instruction rs2
    disp_rd_i  : in std_logic_vector(REG_WIDTH-1 downto 0); -- Instruction rd
    disp_f7_i  : in std_logic_vector(6 downto 0);           -- Instruction f7
    disp_f3_i  : in std_logic_vector(2 downto 0);           -- Instruction f3
    disp_imm_i : in std_logic_vector(XLEN-1 downto 0);      -- Instruciton immediate
    disp_pc_i  : in std_logic_vector(XLEN-1 downto 0);      -- Address of instruction (Program counter)

    -- Register Interface
    reg_vj_i : in std_logic_vector(XLEN-1 downto 0);
    reg_qj_i : in std_logic_vector(ROB_WIDTH-1 downto 0);
    reg_rj_i : in std_logic;

    reg_vk_i : in std_logic_vector(XLEN-1 downto 0);
    reg_qk_i : in std_logic_vector(ROB_WIDTH-1 downto 0);
    reg_rk_i : in std_logic;

    reg_we_o  : out std_logic;                                -- Write Enable Register
    reg_rd_o  : out std_logic_vector(REG_WIDTH-1 downto 0);   -- Write Register address
    reg_res_o : out std_logic_vector(XLEN-1 downto 0);        -- Result to write in registers

    -- Issue interface
    issue_re_i  : in std_logic;                                 -- Ready to issue
    issue_we_o  : out std_logic;                                -- Read enable for issue
    issue_vj_o  : out std_logic_vector(XLEN-1 downto 0);        -- Operand j
    issue_vk_o  : out std_logic_vector(XLEN-1 downto 0);        -- Operand k
    issue_qr_o  : out std_logic_vector(ROB_WIDTH-1 downto 0);   -- Rob entry of the issueed instruction
    issue_f3_o  : out std_logic_vector(2 downto 0);
    issue_f7_o  : out std_logic_vector(6 downto 0);

    issue_rob_o : out std_logic;                                -- Result goes to REORDER BUFFER
    issue_bru_o : out std_logic;                                -- Result goes to BRANCH UNIT
    issue_stb_o : out std_logic;                                -- Result goes to STORE BUFFER
    issue_ldb_o : out std_logic;                                -- Result goes to LOAD_BUFFER

    -- CDB Interface
    cdb_we_i : in std_logic;                                  -- Write enable for result
    cdb_qr_i : in std_logic_vector(ROB_WIDTH-1 downto 0);     -- Rob address of result
    cdb_res_i  : in std_logic_vector(XLEN-1 downto 0)         -- Result from execution units
  );
end entity;

architecture rtl of rob1 is

  type unit_t is (ROB, LDB, STB, BRU);

  constant ROB_LENGTH : natural := 2**ROB_WIDTH;

  type rob_data_t is record
    f7      : std_logic_vector(6 downto 0);              -- Operation to execute (1024 possible operations)
    f3      : std_logic_vector(2 downto 0);
    vj, vk  : std_logic_vector(XLEN-1 downto 0);         -- Operands J and K
    qj, qk  : std_logic_vector(ROB_WIDTH-1 downto 0);    -- Src of J, K in the ROB
    rj, rk  : std_logic;                                 -- Ready flags for op J & K
    rd      : std_logic_vector(REG_WIDTH-1 downto 0);    -- Register address to write result to
    result  : std_logic_vector(XLEN-1 downto 0);         -- Result
    reg_we  : std_logic;                                 -- Write result in register or no
    dest    : unit_t;                                    -- Destination of the result of the operands
    spec    : std_logic;                                 -- Instruction is speculative
    busy    : std_logic;                                 -- Rob entry is busy
    exec    : std_logic;                                 -- Instruction is being executed
    done    : std_logic;                                 -- Instruction is done being executed
  end record;

  signal rob_disp : rob_data_t;

  type rob_t is array (0 to ROB_LENGTH-1) of rob_data_t;

  signal rob_mem : rob_t;

  signal commit_ptr, disp_ptr, issue_ptr : natural range 0 to ROB_LENGTH-1;

  signal disp, issue, commit, full : std_logic;

  signal rs1_zero, rs2_zero : std_logic;

  signal pc_j, imm_k : std_logic;

  signal op_rdy : std_logic_vector(ROB_LENGTH-1 downto 0);

begin
  -- OP -> str8 up F7 + F3
  -- IMM -> Convert to OP + set imm in VK
  -- BRANCH -> BEQ/BNE = SUB, BLT/BGE = SLT, BLTU/BGEU = SLTU
  -- JAL -> rd = pc + 4 (ADD PC and 4)
  -- JALR -> rd = pc + 4 (ADD PC and 4)
  -- LOAD -> res = mem[reg + imm]
  -- STORE -> mem[reg + imm] = reg
  -- LUI -> Res = imm (rdy now)
  -- AUIPC -> imm + pc
  -- If RD = x0, no need to execute the instruction
  -- IF RS1 or RS2 = X0, result can be pre-calculated

  ---
  -- INPUT
  ---

  rs1_zero <= '0' when unsigned(disp_rs1_i) = 0 else '1';
  rs2_zero <= '0' when unsigned(disp_rs2_i) = 0 else '1';

  disp <= disp_we_i and not full;
  commit <= rob_mem(commit_ptr).busy and rob_mem(commit_ptr).done;

  ---
  -- DISPATCH - EXU OPERATION
  ---
  p_op:
  process(all)
    variable f3 : std_logic_vector(2 downto 0);
    variable f7 : std_logic_vector(6 downto 0);
  begin
    f3 := FUNCT3_ADDSUB;
    f7 := FUNCT7_ADD;

    case disp_op_i is
      when OP_OP =>
        f3 := disp_f3_i;
        f7 := disp_f7_i;

      when OP_IMM =>
        f3 := disp_f3_i;
        if f3 = FUNCT3_SR or f3 = FUNCT3_SL then
          f7 := disp_f7_i;
        end if;

      when OP_BRANCH =>
        case disp_f3_i is
          when FUNCT3_BEQ | FUNCT3_BNE =>
            f7 := FUNCT7_SUB;
          when FUNCT3_BLT | FUNCT3_BGE =>
            f3 := FUNCT3_SLT;
          when FUNCT3_BLTU | FUNCT3_BGEU =>
            f3 := FUNCT3_SLTU;
          when others =>
        end case;
      when others =>
    end case;

    rob_disp.f3 <= f3;
    rob_disp.f7 <= f7;
  end process;


  ----
  -- Value comes from : ROB -> Result is not yet commited, if Ready flag = '0' must check if the result rob entry has it and foward it in the case that yes
  --                     CDB -> If ready flag = '0' and result is not in the ROB, then check if it can be fowarded from the CDB
  --                     IMMEDIATE/PC -> Instruction encodes an immediate value or requests the PC (IMM,AUIPC,LUI,ETC), which indicates that it is already ready
  --                     REG -> if Ready flag = '1', then the value of the register is valid
  -- ROB ENTRY (q) comes from registers
  -- Ready flag comes from: REG or hardcoded '1' if immediate
  ----

  ---
  -- DISPATCH - J OPERAND
  ---
  with disp_op_i select
    pc_j <= '1' when OP_AUIPC,
            '0' when others;

  p_disp_j:
  process(all)
    variable vj : std_logic_vector(XLEN-1 downto 0);
    variable rj : std_logic;
    variable pc_j : std_logic;
  begin
    rj := '0';
    if pc_j = '1' then
      vj := disp_pc_i;
      rj := '1';
    else
      if reg_rj_i = '1' then
          vj := reg_vj_i;
      else
        if cdb_we_i = '1' and cdb_qr_i = reg_qj_i then
          vj := cdb_res_i;
          rj := '1';
        else
          vj := rob_mem(to_integer(unsigned(reg_qj_i))).result;
          rj := rob_mem(to_integer(unsigned(reg_qj_i))).done;
        end if;
      end if;
    end if;

    rob_disp.vj <= vj;
    rob_disp.rj <= rj;
    rob_disp.qj <= reg_qj_i;
  end process;


  ---
  -- ISSUE - K OPERAND
  ---
  with disp_op_i select
    imm_k <= '0' when OP_OP,
             '1' when others;


  p_disp_k:
  process(all)
    variable vk : std_logic_vector(XLEN-1 downto 0);
    variable rk : std_logic;
  begin
    rk := '0';
    if imm_k = '1' then
      vk := disp_imm_i;
      rk := '1';
    else
      if reg_rk_i = '1' then
          vk := reg_vk_i;
      else
        if cdb_we_i = '1' and cdb_qr_i = reg_qk_i then
          vk := cdb_res_i;
          rk := '1';
        else
          vk := rob_mem(to_integer(unsigned(reg_qk_i))).result;
          rk := rob_mem(to_integer(unsigned(reg_qk_i))).done;
        end if;
      end if;
    end if;

    rob_disp.vk <= vk;
    rob_disp.rk <= rk;
    rob_disp.qk <= reg_qk_i;
  end process;


  ---
  -- DISPATCH - RESULT
  ---
  rob_disp.reg_we <= disp_reg_i;


  -- Safety
  rob_disp.rd <= disp_rd_i when rob_disp.reg_we = '1' else (others => '0');


  with disp_op_i select
    rob_disp.dest <= LDB when OP_LOAD,
                      STB when OP_STORE,
                      BRU when OP_BRANCH,
                      ROB when others;


  -- TODO: RESULT OPTIMISATION
  -- LUI | OP W ADD, OR, WITH RS1 OR RS2 = x0 -> Result = the non zero operand
  -- OP W AND, RS1 or RS2 = 0 -> Result = 0
  -- SLT -> RS1 = x0, result = ~RS2[31], RS2 = x0, result = RS1[31], RS1=RS2=x0 -> 0
  -- imm = 0 and use immmediate -> result already ready unless SLT
  -- FIXME: Should be @ update cuz vj or vk might not be ready @ disp
  p_disp_result:
  process(all)
    variable result : std_logic_vector(XLEN-1 downto 0) := rob_mem(disp_ptr).result;
    --variable f3 : std_logic_vector(disp_f3_i'range) := disp_f3_i;
    --variable f7 : std_logic_vector(disp_f7_i'range) := disp_f7_i;
    variable imm : std_logic_vector(disp_imm_i'range) := disp_imm_i;

    variable done : std_logic := '0';
  begin
    case disp_op_i is
      when OP_LUI =>
        result := imm;
        done := '1';

     -- when OP_OP =>
     --   if f3 = FUNCT3_ADD or f3 = FUNCT3_OR then
     --   case (rs1_zero & rs2_zero) is
     --     when "01" =>
     --       result :=
     --     when "10" =>
     --     when "11" =>
     --     when others =>
     --   end case;

     -- when OP_IMM =>
     -- when OP_JAL =>
     -- when OP_JALR =>
     -- when OP_
      when others =>
        result := (others => '0');
    end case;

    rob_disp.result <= result;

    rob_disp.done <= done; -- TODO : include execution bypass opt
    rob_disp.exec <= done; -- TODO : Include execution bypass opt
  end process;

  ---
  -- DISPATCH - CONTROL
  ---
  rob_disp.spec <= '0'; -- TODO: speculative instruction
  rob_disp.busy <= '1';


  ---
  -- ROB - MEMORY
  ---
  p_rob_mem:
  process(clk_i)
    variable wb_ptr : natural range 0 to 2**ROB_WIDTH-1;
  begin
    if rising_edge(clk_i) then
      if rst_i = '0' then
        for i in rob_mem'range loop
          rob_mem(i).busy <= '0';
        end loop;
      else
        -- dispatch
        if disp = '1' then
          rob_mem(disp_ptr) <= rob_disp;
          disp_ptr <= disp_ptr + 1;
        end if;

        -- issue
        if issue = '1' then
          rob_mem(issue_ptr).exec <= '1';
        end if;

        -- WB result and WB values to other rob entries
        if cdb_we_i = '1' then
          wb_ptr := to_integer(unsigned(cdb_qr_i));
          rob_mem(wb_ptr).result <= cdb_res_i;
          rob_mem(wb_ptr).done <= '1';

          for i in rob_mem'range loop
            if rob_mem(i).busy = '1' then
              if rob_mem(i).qj = cdb_qr_i and rob_mem(i).rj = '0' then
                rob_mem(i).vj <= cdb_res_i;
                rob_mem(i).rj <= '1';
              end if;

              if rob_mem(i).qk = cdb_qr_i and rob_mem(i).rk = '0' then
                rob_mem(i).vk <= cdb_res_i;
                rob_mem(i).rk <= '1';
              end if;
            end if;
          end loop;
        end if;

        -- Entry removal
        if commit = '1' then
          rob_mem(commit_ptr).busy <= '0';
          commit_ptr <= commit_ptr + 1;
        end if;
      end if;
    end if;
  end process;


  ---
  -- ISSU
  ---
  -- TODO:
  --       OP ready vector encoding which ops shall be executed
  --       barrel shifter using COMMIT_PTR to shift OP RDY
  --       Priority encoder on shifted OP ready vector to select OLDEST instruction
  --       Result of priority encoder = issue input

  g_op_rdy:
  for i in rob_mem'range generate
    op_rdy(i) <= rob_mem(i).rj and rob_mem(i).rk and not rob_mem(i).exec;
  end generate;

  p_issue:
  process(all)
    variable offset_rdy : std_logic_vector(op_rdy'range) := op_rdy rol commit_ptr;
  begin
    for i in ROB_LENGTH-1 downto 0 loop
      if offset_rdy(i) = '1' then
        issue_ptr <= i;
      end if;
    end loop;
  end process;

  -- Dispatch when EXEC unit is ready and at least 1 operation can be executed
  issue <= '1' when issue_re_i = '1' and (or op_rdy) = '1' else '0';

  ---
  -- FULL
  ---
  p_full:
  process(all)
    variable v_full : std_logic;
  begin
    v_full := '1';
    for i in rob_mem'range loop
      v_full := v_full and rob_mem(i).busy;
    end loop;
    full <= v_full;
  end process;


  ---
  -- OUTPUT
  ---

  -- Control
  full_o <= full;

  -- Reg
  reg_we_o <= commit;
  reg_rd_o <= rob_mem(commit_ptr).rd;
  reg_res_o <= rob_mem(commit_ptr).result;

  -- Dispatch
  issue_we_o <= issue;
  issue_vj_o <= rob_mem(issue_ptr).vj;
  issue_vk_o <= rob_mem(issue_ptr).vk;
  issue_qr_o <= std_logic_vector(to_unsigned(issue_ptr, issue_qr_o'length));
  issue_f3_o <= rob_mem(issue_ptr).f3;
  issue_f7_o <= rob_mem(issue_ptr).f7;

  issue_rob_o <= '1' when rob_mem(issue_ptr).dest = ROB else '0';
  issue_bru_o <= '1' when rob_mem(issue_ptr).dest = BRU else '0';
  issue_stb_o <= '1' when rob_mem(issue_ptr).dest = STB else '0';
  issue_ldb_o <= '1' when rob_mem(issue_ptr).dest = LDB else '0';

end architecture;
