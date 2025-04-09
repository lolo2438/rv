library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library riscv;
use riscv.RV32I.all;

entity cpu is
  generic(
    ROB_WIDTH : natural; -- Size of the REORDER BUFFER
    REG_LEN : natural; -- Size of the REGISTER FILE
    LDB_LEN : natural; -- Size of the load buffer
    STB_LEN : natural; -- Size of the store buffer
    BRU_LEN : natural; -- Size of the Branch Unit Buffer
    NB_ALU  : natural; -- Number of ALU instanciated (Will also impact dispatch + CDB size)
    XLEN : natural
  );
  port(
    clk_i : in std_logic;
    rst_i : in std_logic;

    -- CONTROL INTERFACE
    stall_o : out std_logic;

    -- INSTRUCTION MEMORY BUS
    imem_data_i : in  std_logic_vector(XLEN-1 downto 0);
    imem_addr_o : out std_logic_vector(XLEN-1 downto 0);
    imem_re_o   : out std_logic;

    -- DATA MEMORY BUS
    dmem_addr_o  : out std_logic_vector(XLEN-1 downto 0);
    dmem_data_i  : in  std_logic_vector(XLEN-1 downto 0);
    dmem_data_o  : out std_logic_vector(XLEN-1 downto 0);
    dmem_data_rw : out std_logic;
    dmem_data_bs : out std_logic_vector(natural(ceil(log2(real(XLEN))))-1 downto 0)
  );
end entity;

architecture rtl of cpu is

  type mem_t is array (natural range <>) of std_logic_vector;

  --
  type data_t is record
    v : std_logic_vector(XLEN-1 downto 0);    -- Value
    q : std_logic_vector(ROB_WIDTH-1 downto 0); -- Rob entry
    r : std_logic;                            -- Ready
  end record;

  -- REGFILE
  signal rs1, rs2 : data_t;
  signal reg_wed : std_logic;

  ---
  -- PROGRAM COUNTER
  ---
  signal pc : std_logic_vector(XLEN-1 downto 0);

  ----
  -- REORDER_BUFFER
  ----
  signal rob_qr : std_logic_vector(ROB_WIDTH-1 downto 0);

  signal rob_full, rob_disp, rob_issue : std_logic;
  signal rob_wer  : std_logic;
  signal rob_wr   : std_logic_vector(REG_LEN-1 downto 0);
  signal rob_res  : std_logic_vector(XLEN-1 downto 0);
  signal rob_wb   : std_logic;

  ----
  -- DISPATCH
  ----
  signal inst       : std_logic_vector(31 downto 0);
  signal inst_rdy : std_logic;

  type inst_bus_t is record
    op : std_logic_vector(5 downto 0);
    f7 : std_logic_vector(7 downto 0);
    f3 : std_logic_vector(2 downto 0);
    rs1, rs2, rd : std_logic_vector(REG_LEN-1 downto 0);
    imm : std_logic_vector(XLEN-1 downto 0);
  end record;

  signal inst_bus : inst_bus_t;


  type disp_bus_t is record
    rob : std_logic;
    bru : std_logic;
    lsu : std_logic;
    sys : std_logic;
    reg : std_logic;
    valid : std_logic;
  end record;

  signal disp_bus : disp_bus_t;

  ----
  -- EXECUTION BUFFER
  ----
  type exu_data_t is record
    vj, vk : std_logic_vector(XLEN-1 downto 0);   -- Value of the operands
    qr : std_logic_vector(ROB_WIDTH-1 downto 0);  -- Write back address in the ROB
    f3 : std_logic_vector(2 downto 0);
    f7 : std_logic_vector(6 downto 0);
    rob, ldb, stb, bru : std_logic;               -- Destination of the result
  end record;

  ----
  -- ISSUE ARBITER
  ----
  type issue_bus_t is record
    d : exu_data_t;
    valid : std_logic;                            -- Valid issue
  end record;

  signal isb : issue_bus_t;

  ----
  -- EXECUTION UNITS
  ----

  type exu_ctrl_t is record
   d : exu_data_t;
   result : std_logic_vector(XLEN-1 downto 0);
   busy : std_logic;
   done : std_logic;
   -- TODO: Exu capabilities (vectored constant)
  end record;

  signal exu : exu_ctrl_t;

  ----
  -- COMMON DATA BUS
  ----
  type cdb_data_t is record
    data  : std_logic_vector(XLEN-1 downto 0);      -- Data on bus
    qr    : std_logic_vector(ROB_WIDTH-1 downto 0); --
    rob, ldb, stb, bru : std_logic;                 -- Destination of the result
    valid : std_logic;                              -- Data is valid
  end record;

  -- TODO: Make CDB port array to connect to the cdb
  --type cdb_port_t is array (natural range <>) of cdb_data_t;

  signal cdb_port : cdb_data_t;
  signal cdb : cdb_data_t;

begin

  -- TODO: Optimization: When BRU/LSU FULL, its going to be rare that a load/store/branch is send to the exu
  --stall_o <= '1' when rob_full = '1' or lsu_full = '1' or bru_full = '1' else '0';
  ---
  -- PROGRAM COUNTER
  ---

  ---
  -- Registers
  ---

  reg_wed <= disp_bus.reg and disp_bus.valid;

  u_reg : entity work.reg(rtl)
  generic map(
    REG_LEN => REG_LEN,
    ROB_LEN => ROB_WIDTH,
    XLEN => XLEN)
  port map(
    clk_i => clk_i,
    rst_i => rst_i,

    rj_i => inst_bus.rs1,
    vj_o => rs1.v,
    qj_o => rs1.q,
    rj_o => rs1.r,

    rk_i => inst_bus.rs2,
    vk_o => rs2.v,
    qk_o => rs2.q,
    rk_o => rs2.r,

    wed_i => reg_wed,
    rd_i  => inst_bus.rd,
    qr_i  => rob_qr,

    wer_i => rob_wer,
    wr_i  => rob_wr,
    res_i => rob_res);

  ----
  -- DISPATCH
  ----

  -- Validate instruction and dispatch to the right unit
  u_udecoder : entity work.udecoder(rtl)
  generic map(
    XLEN => XLEN)
  port map(
    wed_i   => inst_rdy,
    inst_i  => inst,
    op_o    => inst_bus.op,
    f7_o    => inst_bus.f7,
    f3_o    => inst_bus.f3,
    imm_o   => inst_bus.imm,
    rs1_o   => inst_bus.rs1,
    rs2_o   => inst_bus.rs2,
    rd_o    => inst_bus.rd,
    rob_o   => disp_bus.rob,
    reg_o   => disp_bus.reg,
    bru_o   => disp_bus.bru,
    lsu_o   => disp_bus.lsu,
    sys_o   => disp_bus.sys,
    valid_o => disp_bus.valid
  );

  ----
  -- ISSUE
  ----
  rob_disp <= disp_bus.rob and disp_bus.valid;
  rob_issue <= not exu.busy;

  u_rob: entity work.rob(rtl)
  generic map (
    REG_WIDTH => REG_WIDTH,
    ROB_WIDTH => ROB_WIDTH,
    XLEN      => XLEN
  )
  port map (
    -- Control Interface
    clk_i  => clk_i,
    rst_i  => rst_i,
    full_o => rob_full,

    -- Dispatch Interface
    disp_we_i  => rob_disp,
    disp_reg_i => reg_wed,
    disp_op_i  => inst_bus.op,
    disp_rs1_i => inst_bus.rs1,
    disp_rs2_i => inst_bus.rs2,
    disp_rd_i  => inst_bus.rd,
    disp_f7_i  => inst_bus.f7,
    disp_f3_i  => inst_bus.f3,
    disp_imm_i => inst_bus.imm,
    disp_pc_i  => pc,

    -- Register Interface
    reg_vj_i => rs1.v,
    reg_qj_i => rs1.q,
    reg_rj_i => rs1.r,

    reg_vk_i => rs2.v,
    reg_qk_i => rs2.q,
    reg_rk_i => rs2.r,

    reg_we_o  => rob_wer,
    reg_rd_o  => rob_wr,
    reg_res_o => rob_res,

    -- Issue interface
    issue_re_i  => rob_issue, -- When an EXU is ready
    issue_we_o  => isb.valid,
    issue_vj_o  => isb.d.vj,
    issue_vk_o  => isb.d.vk,
    issue_qr_o  => isb.d.qr,
    issue_f3_o  => isb.d.f3,
    issue_f7_o  => isb.d.f7,
    issue_rob_o => isb.d.rob,
    issue_bru_o => isb.d.bru,
    issue_stb_o => isb.d.stb,
    issue_ldb_o => isb.d.ldb,

    -- CDB Interface
    cdb_we_i   => rob_wb,
    cdb_qr_i   => cdb.qr,
    cdb_res_i  => cdb.data
  );

  rob_wb <= cdb.valid; --and TODO: the return value is to the rob (It can go to LSU & BRU)

  -- LSU, BRU, SYSTEM, EXb

  ----
  -- EXECUTE
  ----

  p_exu_ctrl:
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        exu.busy <= '0';
        exu.done <= '1';
      else
        if isb.valid = '1' then
          if exu.busy = '0' and exu.done = '1' then
            exu.d <= isb.d;
            exu.busy <= '1';
            exu.done <= '0';
          end if;
        end if;

        -- TODO: CYCLE COUNTER FOR EXU (depends on operation),
        --       right now all ops are 1 cycle
        if exu.busy = '1' then
          exu.done <= '1';
        end if;

        if exu.busy = '1' and exu.done = '1' and cdb_port.valid = '1' and cdb_port.qr = exu.d.qr then
          exu.busy <= '0';
        end if;

      end if;
    end if;
  end process;


  u_exu1 : entity work.alu(rtl)
  generic map(
    XLEN => XLEN)
  port map(
    a_i  => exu.d.vj,
    b_i  => exu.d.vk,
    f3_i => exu.d.f3,
    f7_i => exu.d.f7,
    c_o  => exu.result
  );

  ----
  -- WRITE_BACK
  ----

  -- FIXME: Port is valid for only 1 clock cycle
  p_cdb_port:
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      cdb_port.valid <= '0';

      if exu.busy = '1' and exu.done = '1' then
        cdb_port.data   <= exu.result;
        cdb_port.qr     <= exu.d.qr;
        cdb_port.valid  <= '1';
        -- TODO: Change to a 2 bit instead of one hot
        cdb_port.rob    <= exu.d.rob;
        cdb_port.ldb    <= exu.d.ldb;
        cdb_port.stb    <= exu.d.stb;
        cdb_port.bru    <= exu.d.bru;
        cdb_port.valid  <= '1';
      end if;
    end if;
  end process;

  -- Broadcast result on CDB
  -- TODO: Select which port read/writes to cdb
  cdb.data   <= cdb_port.data;
  cdb.qr     <= cdb_port.qr;
  cdb.valid  <= cdb_port.valid;
  cdb.rob    <= exu.d.rob;
  cdb.ldb    <= exu.d.ldb;
  cdb.stb    <= exu.d.stb;
  cdb.bru    <= exu.d.bru;


end architecture;
