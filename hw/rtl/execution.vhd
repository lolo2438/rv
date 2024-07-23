library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library riscv;
use riscv.RV32I.all;

entity execution is
  generic(
    ROB_LEN : natural; -- Size of the REORDER BUFFER
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

architecture rtl of execution is

  type mem_t is array (natural range <>) of std_logic_vector;

  --
  type data_t is record
    v : std_logic_vector(XLEN-1 downto 0);    -- Value
    q : std_logic_vector(ROB_LEN-1 downto 0); -- Rob entry
    r : std_logic;                            -- Ready
  end record;

  -- REGFILE
  signal rs1, rs2 : data_t;

  signal rob_j, rob_k : data_t;

  ---
  -- PROGRAM COUNTER
  ---
  signal pc : std_logic_vector(XLEN-1 downto 0);

  ----
  -- REORDER_BUFFER
  ----
  signal rob_qr : std_logic_vector(ROB_LEN-1 downto 0);

  signal rob_full : std_logic;
  signal rob_wer  : std_logic;
  signal rob_wr   : std_logic_vector(REG_LEN-1 downto 0);
  signal rob_res  : std_logic_vector(XLEN-1 downto 0);

  ----
  -- DISPATCH
  ----
  signal inst_rdy   : std_logic;
  signal inst       : std_logic_vector(31 downto 0);
  signal inst_valid : std_logic;

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
  end record;

  signal disp_bus : disp_bus_t;

  ----
  -- EXECUTION BUFFER
  ----

  ----
  -- ISSUE ARBITER
  ----
  signal exb_wei : std_logic;
  signal exb_qr : std_logic_vector(ROB_LEN-1 downto 0);
  signal exb_full : std_logic;

  constant DST_LEN : natural := ROB_LEN + 2;

  ----
  -- EXECUTION UNITS
  ----


  ----
  -- COMMON DATA BUS
  ----
  type cdb_data_t is record
    data  : std_logic_vector(XLEN-1 downto 0);    -- Data on bus
    qr    : std_logic_vector(ROB_LEN-1 downto 0); --
    valid : std_logic;                            -- Data is valid
  end record;

  type cdb_t is array (natural range <>) of cdb_data_t;

  signal cdb : cdb_t(0 to 0);

begin

  -- TODO: Optimization: When BRU/LSU FULL, its going to be rare that a load/store/branch is send to the exu
  stall_o <= '1' when rob_full = '1' or exb_full = '1' or lsu_full = '1' or bru_full = '1' else '0';
  ---
  -- PROGRAM COUNTER
  ---

  ---
  -- Registers
  ---
  u_reg : entity work.reg(rtl)
  generic map(
    REG_LEN => REG_LEN,
    ROB_LEN => ROB_LEN,
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

    wei_i => ,
    rd_i  => inst_bus.rd,
    qr_i  => rob_qr,

    wer_i => rob_wer,
    wr_i  => rob_wr,
    res_i => rob_res);

  ----
  -- DISPATCH
  ----

  -- Validate instruction and dispatch to the right unit
  u_dispatch: entity work.dispatch(rtl)
  generic map(
    XLEN => XLEN)
  port map(
    wed_i => inst_rdy,
    instruction_i => inst,

    op_o => inst_bus.op,
    f7_o => inst_bus.f7,
    f3_o => inst_bus.f3,
    imm_o => inst_bus.imm,
    rs1_o => inst_bus.rs1,
    rs2_o => inst_bus.rs2,
    rd_o => inst_bus.rd,

    rob_o => disp_bus.rob,
    sys_o => disp_bus.sys,
    bru_o => disp_bus.bru,
    lsu_o => disp_bus.lsu,

    valid_o => inst_valid);

  ----
  -- ISSUE
  ----

  -- System instruction are to be executed elsewhere
  exb_wei <= inst_valid and not disp_bus.sys;
  --exb_qr <= ROB when rob, lsu or bru

  u_exb : entity work.exb(rtl)
  generic map(
    EXB_LEN => EXB_LEN,
    ROB_LEN => ROB_LEN,
    XLEN => XLEN)
  port map(
    clk_i => clk_i,
    rst_i => rst_i,

    -- Dispatch interface
    op_i => inst_bus.op,
    f7_i => inst_bus.f7,
    f3_i => inst_bus.f3,
    imm_i => inst_bus.imm,
    qj_i => rs1.q,
    qk_i => rs2.q,
    qr_i => exb_qr,
    wei_i => exb_wei,

    -- Issue interface
    exu_rdy_i : std_logic;
    issue_o : std_logic;
    vj_o    : std_logic_vector(XLEN-1 downto 0);
    vk_o    : std_logic_vector(XLEN-1 downto 0);
    qr_o    : std_logic_vector(ROB_LEN-1 downto 0);

    rob_o : std_logic; -- Result goes to REORDER BUFFER
    bru_o : std_logic; -- Result goes to BRANCH UNIT
    stb_o : std_logic; -- Result goes to STORE BUFFER
    ldb_o : std_logic; -- Result goes to LOAD_BUFFER

    -- Control interface
    full_o : std_logic -- EXB is FULL
  );

  -- LSU, BRU, SYSTEM, EXb


  ----
  -- EXECUTE
  ----

  u_exu : entity work.alu(rtl)
  generic map(
    XLEN => XLEN)
  port map(
    a_i =>
    b_i =>
    f3_i =>
    f7_i =>
    c_o =>)

  ----
  -- WRITE_BACK
  ----

  -- Broadcast result on CDB
  -- Foward results from

  ----
  -- COMMIT
  ----
  rob_j.q <= rs1.q;
  rob_k.q <= rs2.q;

  u_rob : entity work.rob(rtl)
  generic map (
    REG_LEN => REG_LEN,
    ROB_LEN => ROB_LEN,
    XLEN    => XLEN)
  port map (
    clk_i => clk_i,
    rst_i => rst_i,

    -- ISSUE
    wei_i => wei,
    rd_i  => ibus.rd,
    qr_o  => rob_qr,

    -- CDB
    wres_i =>
    qr_i   =>
    res_i  =>

    -- FOWARDING
    qj_i => rob_j.q,
    vj_o => rob_j.v,
    rj_o => rob_j.r,

    qk_i => rob_k.q,
    vk_o => rob_k.v,
    rk_o => rob_k.r,

    -- REG
    wer_o  => rob_wer,
    wr_o   => rob_wr,
    res_o  => rob_res,

    -- STATUS
    full_o => rob_full
  );

end architecture;
