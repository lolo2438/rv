library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library riscv;
use riscv.RV32I.all;

library hw;
use hw.tag_pkg.all;
--use hw.core_pkg.all;

library common;
use common.fnct.clog2;
use common.fnct.one_hot_decoder;

entity core is
  generic(
    -- EXTENSIONS
    RST_LEVEL : std_logic := '0';
    REG_LEN   : natural;
    XLEN      : natural
  );
  port(
    -- CONTROL I/F
    i_clk           : in  std_logic;                            --! Core clock
    i_arst          : in  std_logic;                            --! Asynchronous reset
    i_srst          : in  std_logic;                            --! Synchronous reset
    i_en            : in  std_logic;                            --! Enable the processor
    i_restart       : in  std_logic;                            --! Restart the core when state is DEBUG and HALTED
    i_step          : in  std_logic;                            --! Step the core with one instruction when in DEBUG and HALTED

    -- STATUS I/F
    o_stall         : out std_logic;                            --! Core is not accepting new instructions
    o_halt          : out std_logic;                            --! Core is halted
    o_debug         : out std_logic;                            --! Core is in debug mode, Combined to halt indicates that EBREAK was executed

    -- REG I/F
    --i_reg_rd_addr  : in  std_logic_vector(REG_LEN-1 downto 0); --! DEBUG: Register address to read from
    --o_reg_rd_data  : out std_logic_vector(XLEN-1 downto 0);    --! DEBUG: Data from the register
    --o_reg_rd_valid : out std_logic;                            --! DEBUG: Data read is valid

    --i_reg_wr_addr  : in  std_logic_vector(REG_LEN-1 downto 0); --! DEBUG: Register address to write to
    --i_reg_wr_data  : in  std_logic_vector(XLEN-1 downto 0);    --! DEBUG: Data to write in register
    --i_reg_wr_valid : in  std_logic;                            --! DEBUG: Data to write is valid,
    --o_reg_wr_ready : out std_logic;                            --! DEBUG: Ready signal is o_debug and o_halt

    -- IMEM I/F
    o_imem_addr     : out std_logic_vector(31 downto 0);        --! Address to read instruction from
    o_imem_avalid   : out std_logic;                            --! Address read is valid
    i_imem_rdy      : in  std_logic;                            --! IMEM is ready
    i_imem_data     : in  std_logic_vector(31 downto 0);        --! Instruction
    i_imem_dvalid   : in  std_logic;                            --! IMEM is date valid

    -- DMEM RD I/F
    i_dmem_rrdy     : in  std_logic;                            --! Memory is ready for read operation
    o_dmem_raddr    : out std_logic_vector(XLEN-1 downto 0);    --! Address to read from memory
    o_dmem_ravalid  : out std_logic;                            --! Processor Read operation is valid
    i_dmem_rdata    : in  std_logic_vector(XLEN-1 downto 0);    --! Data read from memory
    i_dmem_rdvalid  : in  std_logic;                            --! Data from memory is valid

    -- DMEM WR I/F
    o_dmem_wvalid   : out std_logic;                            --! Processor write operation is valid
    i_dmem_wrdy     : in  std_logic;                            --! Memory is ready for write operation
    o_dmem_we       : out std_logic_vector(XLEN/8-1 downto 0);  --! Byte write enable for store operation
    o_dmem_waddr    : out std_logic_vector(XLEN-1 downto 0);    --! Memory address to read/write from
    o_dmem_wdata    : out std_logic_vector(XLEN-1 downto 0)     --! Data to write to memory
  );
end entity;

architecture rtl of core is

  constant ZERO               : std_logic_vector(XLEN-1 downto 0) := (others => '0');

  signal pc                   : std_logic_vector(XLEN-1 downto 0);

  signal inst                 : std_logic_vector(31 downto 0);
  signal inst_valid           : std_logic;


  ---
  -- DISP
  ---

  signal disp_op              : std_logic_vector(4 downto 0);
  signal disp_f3              : std_logic_vector(2 downto 0);
  signal disp_f7              : std_logic_vector(6 downto 0);
  signal disp_f12             : std_logic_vector(11 downto 0);
  signal disp_rs1             : std_logic_VECTOR(REG_LEN-1 downto 0);
  signal disp_rs2             : std_logic_VECTOR(REG_LEN-1 downto 0);
  signal disp_rd              : std_logic_VECTOR(REG_LEN-1 downto 0);
  signal disp_imm             : std_logic_vector(XLEN-1 downto 0);
  signal disp_illegal         : std_logic;
  signal disp_valid           : std_logic;


  ---
  -- SYS
  ---

  signal sys_full             : std_logic;
  signal sys_empty            : std_logic;
  signal sys_stall            : std_logic;
  signal sys_halt             : std_logic;
  signal sys_debug            : std_logic;


  ---
  -- EXU
  ---

  signal exu_vj_src           : std_logic;
  signal exu_vk_src           : std_logic;
  signal exu_vj               : std_logic_vector(XLEN-1 downto 0);
  signal exu_tj               : std_logic_vector(TAG_LEN-1 downto 0);
  signal exu_rj               : std_logic;
  signal exu_vk               : std_logic_vector(XLEN-1 downto 0);
  signal exu_tk               : std_logic_vector(TAG_LEN-1 downto 0);
  signal exu_rk               : std_logic;
  signal exu_tq               : std_logic_vector(TAG_LEN-1 downto 0);

  signal exu_empty            : std_logic;
  signal exu_full             : std_logic;


  ---
  -- LSU
  ---

  signal lsu_va               : std_logic_vector(XLEN-1 downto 0);
  signal lsu_ta               : std_logic_vector(TAG_LEN-1 downto 0);
  signal lsu_ra               : std_logic;
  signal lsu_vd               : std_logic_vector(XLEN-1 downto 0);
  signal lsu_td               : std_logic_vector(TAG_LEN-1 downto 0);
  signal lsu_rd               : std_logic;

  signal ldu_qr               : std_logic_vector(LDU_LEN-1 downto 0);
  signal ldu_empty            : std_logic;
  signal ldu_full             : std_logic;

  signal stu_empty            : std_logic;
  signal stu_full             : std_logic;
  signal stu_qr               : std_logic_vector(STU_LEN-1 downto 0);

  signal grp_full             : std_logic;

  -- TODO: this pointer is a q address to write back to the data from the read
  --       for now it is looped back on the lsu cuz single read tests, but in
  --       the future it is expected to be associated to out of order multi issue reads
  signal dmem_ptr             : std_logic_vector(LDU_LEN-1 downto 0);


  ---
  -- RGU
  ---

  signal rgu_tq               : std_logic_vector(TAG_LEN-1 downto 0);
  signal rgu_vj               : std_logic_vector(XLEN-1 downto 0);
  signal rgu_tj               : std_logic_vector(TAG_LEN-1 downto 0);
  signal rgu_rj               : std_logic;
  signal rgu_vk               : std_logic_vector(XLEN-1 downto 0);
  signal rgu_tk               : std_logic_vector(TAG_LEN-1 downto 0);
  signal rgu_rk               : std_logic;

  signal rob_empty            : std_logic;
  signal rob_full             : std_logic;


  ---
  -- CBD
  ---

  signal cdbr_vq              : std_logic_vector(XLEN-1 downto 0);
  signal cdbr_tq              : std_logic_vector(TAG_LEN-1 downto 0);
  signal cdbr_rq              : std_logic;

  type cdbw_sig is record
    vq : std_logic_vector(XLEN-1 downto 0);
    tq : std_logic_vector(TAG_LEN-1 downto 0);
    req : std_logic;
    lh  : std_logic;
    ack : std_logic;
  end record;

  type cdbw_array is array (natural range <>) of cdbw_sig;

  signal cdbw_exu : cdbw_sig;
  signal cdbw_lsu : cdbw_sig;

  constant NB_CDB_INITIATOR : natural := 2;
  signal cdbw_initiators : cdbw_array(NB_CDB_INITIATOR-1 downto 0);
  signal cdbw_req : std_logic_vector(NB_CDB_INITIATOR-1 downto 0);
  signal cdbw_ack : std_logic_vector(NB_CDB_INITIATOR-1 downto 0);

  --procedure connect_cdbw_client(
  --    signal client : inout cdbw_sig;
  --    signal host   : inout cdbw_sig
  --  ) is
  --begin
  --  host.vq <= client.vq;
  --  host.tq <= client.tq;
  --  host.req <= client.req;
  --  host.lh <= client.lh;

  --  client.ack <= host.ack;
  --end procedure;


begin

  ---
  -- Configurations
  ---

  ---
  -- INPUT
  ---
  -- i_imem_rdy
  inst        <= i_imem_data;
  inst_valid  <= i_imem_dvalid and not sys_stall;

  ---
  -- LOGIC
  ---
  u_dec:
  entity hw.dec
  generic map(
    XLEN => XLEN
  )
  port map (
    i_inst_disp   => inst_valid,
    i_inst        => inst,
    o_disp_op     => disp_op,
    o_disp_f3     => disp_f3,
    o_disp_f7     => disp_f7,
    o_disp_imm    => disp_imm,
    o_disp_rs1    => disp_rs1,
    o_disp_rs2    => disp_rs2,
    o_disp_rd     => disp_rd,
    o_disp_f12    => disp_f12,
    o_hint        => open,
    o_illegal     => disp_illegal
  );

  disp_valid <= not disp_illegal;

  sys_full <= ldu_full or stu_full or grp_full or exu_full or rob_full;
  sys_empty <= ldu_empty and stu_empty and exu_empty and rob_empty;

  u_sys:
  entity hw.sys
  generic map(
    RST_LEVEL => RST_LEVEL,
    XLEN      => XLEN
  )
  port map(
    i_clk         => i_clk,
    i_srst        => i_srst,
    i_arst        => i_arst,
    i_disp_valid  => disp_valid,
    i_disp_op     => disp_op,
    i_disp_f12    => disp_f12,
    i_en          => i_en or i_imem_rdy,
    i_step        => i_step,
    i_restart     => i_restart,
    i_full        => sys_full,
    i_empty       => sys_empty,
    o_stall       => sys_stall,
    o_halt        => sys_halt,
    o_debug       => sys_debug,
    o_pc          => pc
  );


  u_rgu:
  entity hw.rgu
  generic map(
    RST_LEVEL => RST_LEVEL,
    ROB_LEN   => ROB_LEN,
    REG_LEN   => REG_LEN,
    TAG_LEN   => TAG_LEN,
    XLEN      => XLEN
  )
  port map(
    i_clk         => i_clk,
    i_srst        => i_srst,
    i_arst        => i_arst,
    o_rob_full    => rob_full,
    o_rob_empty   => rob_empty,
    i_disp_valid  => disp_valid,
    i_disp_op     => disp_op,
    i_disp_rs1    => disp_rs1,
    i_disp_rs2    => disp_rs2,
    i_disp_rd     => disp_rd,
    o_disp_tq     => rgu_tq,
    o_data_vj     => rgu_vj,
    o_data_tj     => rgu_tj,
    o_data_rj     => rgu_rj,
    o_data_vk     => rgu_vk,
    o_data_tk     => rgu_tk,
    o_data_rk     => rgu_rk,
    i_cdbr_vq     => cdbr_vq,
    i_cdbr_tq     => cdbr_tq,
    i_cdbr_rq     => cdbr_rq
  );


  -- FIXME: When SYS op is done, should not do anything
  -- TODO: System consideration, tags for units that are not related to the ROB can be managed independant of any physical structures
  --       The only consideration is to have a way to know which "tags" have been used and which one are free to be used
  --       I believe that the tag structure should be reworked to be better optimized with the reality of a CPU
  --
  --       Proposed structure
  --       [TAG_LEN-1              ...     0]
  --
  --       [1][ROB_LEN-1           ...     0] -> Rob activation bit
  --       [0][XX][ other structures tbd    ] --> Other structures: LDU, STU, BRU, SYS
  --
  --       Why? Because usually the rob will mostly be greater than other structures
  --       In this scheme, other structures will have 4 time less entries than the ROB.
  --       The issue might be that a typical
  --
  --
  -- TODO: It would be nice to find a way to be able to scheme this structure in a "variable way"
  --       What should it be able to do :
  --       * Register a priority scheme
  --       * Handle multiple tags and sub tags
  --
  --       Example
  --       [R][L .. 0][B .. 0][ ... ]
  --       Here it should first check for R, then for L, then for B and act accordingly
  --       This should be in a core_config_pkg.vhd file
  with disp_op select
    exu_tq <= rgu_tq when OP_OP | OP_IMM | OP_AUIPC | OP_LUI | OP_JAL | OP_JALR,
              --lsu_tq when OP_LOAD | OP_STORE,
              --bru_tq when OP_BRANCH,
              --sys_tq when OP_SYSTEM,
              --format_tag(UNIT_LDU, ldu_qr) when
              --format_tag(UNIT_STU, stu_qr)
              (others => 'X') when others;

  exu_vj_src <= '1' when disp_op = OP_AUIPC else '0';

  exu_vj <= pc               when exu_vj_src = '1' else rgu_vj;
  exu_tj <= (others => 'X')  when exu_vj_src = '1' else rgu_tj;
  exu_rj <= '1'              when exu_vj_src = '1' else rgu_rj;

  exu_vk_src <= '0' when disp_op = OP_OP or disp_op = OP_BRANCH else '1';

  exu_vk <= disp_imm         when exu_vk_src = '1' else rgu_vk;
  exu_tk <= (others => 'X')  when exu_vk_src = '1' else rgu_tk;
  exu_rk <= '1'              when exu_vk_src = '1' else rgu_rk;

  u_exu:
  entity hw.exu
  generic map(
    RST_LEVEL   => RST_LEVEL,
    EXB_LEN     => EXB_LEN,
    TAG_LEN     => TAG_LEN,
    XLEN        => XLEN
  )
  port map(
    i_clk         => i_clk,
    i_srst        => i_srst,
    i_arst        => i_arst,
    o_exu_full    => exu_full,
    o_exu_empty   => exu_empty,
    i_disp_valid  => disp_valid,
    i_disp_op     => disp_op,
    i_disp_f3     => disp_f3,
    i_disp_f7     => disp_f7,
    i_disp_vj     => exu_vj,
    i_disp_tj     => exu_tj,
    i_disp_rj     => exu_rj,
    i_disp_vk     => exu_vk,
    i_disp_tk     => exu_tk,
    i_disp_rk     => exu_rk,
    i_disp_tq     => exu_tq,
    o_cdbw_vq     => cdbw_exu.vq,
    o_cdbw_tq     => cdbw_exu.tq,
    o_cdbw_req    => cdbw_exu.req,
    o_cdbw_lh     => cdbw_exu.lh,
    i_cdbw_ack    => cdbw_exu.ack,
    i_cdbr_vq     => cdbr_vq,
    i_cdbr_tq     => cdbr_tq,
    i_cdbr_rq     => cdbr_rq
  );


  ---
  -- LSU
  ---
  lsu_ra <= '1' when disp_rs1 = ZERO(disp_rs1'range) else '0';
  lsu_va <= disp_imm when lsu_ra = '1' else (others => 'X');
  lsu_ta <= exu_tq;

  lsu_rd <= '1' when disp_rs2 = ZERO(disp_rs2'range) else '0';
  lsu_vd <= (others => '0') when lsu_rd = '1' else (others => 'X');
  lsu_td <= rgu_tk;



  u_lsu:
  entity hw.lsu
  generic map (
    RST_LEVEL => RST_LEVEL,
    STU_LEN   => STU_LEN,
    LDU_LEN   => LDU_LEN,
    TAG_LEN   => TAG_LEN,
    XLEN      => XLEN
  )
  port map (
    i_clk           => i_clk,
    i_arst          => i_arst,
    i_srst          => i_srst,
    o_stu_empty     => stu_empty,
    o_ldu_empty     => ldu_empty,
    o_stu_full      => stu_full,
    o_ldu_full      => ldu_full,
    o_grp_full      => grp_full,
    i_disp_valid    => disp_valid,
    i_disp_op       => disp_op,
    i_disp_f3       => disp_f3,
    i_disp_tq       => rgu_tq,
    i_disp_va       => lsu_va,
    i_disp_ta       => lsu_ta,
    i_disp_ra       => lsu_ra,
    i_disp_vd       => lsu_vd,
    i_disp_td       => lsu_td,
    i_disp_rd       => lsu_rd,
    o_cdbw_vq       => cdbw_lsu.vq,
    o_cdbw_tq       => cdbw_lsu.tq,
    o_cdbw_req      => cdbw_lsu.req,
    o_cdbw_lh       => cdbw_lsu.lh,
    i_cdbw_ack      => cdbw_lsu.ack,
    i_cdbr_vq       => cdbr_vq,
    i_cdbr_tq       => cdbr_tq,
    i_cdbr_rq       => cdbr_rq,
    o_mem_wr_valid  => o_dmem_wvalid,
    i_mem_wr_rdy    => i_dmem_wrdy,
    o_mem_wr_addr   => o_dmem_waddr,
    o_mem_wr_data   => o_dmem_wdata,
    o_mem_wr_we     => o_dmem_we,
    o_mem_rd_re     => o_dmem_ravalid,
    i_mem_rd_rdy    => i_dmem_rrdy,
    o_mem_rd_addr   => o_dmem_raddr,
    o_mem_rd_ptr    => dmem_ptr,
    i_mem_rd_data   => i_dmem_rdata,
    i_mem_rd_ptr    => dmem_ptr,
    i_mem_rd_valid  => i_dmem_rdvalid
  );


  ---
  -- CDB
  ---
  --connect_cdbw_client(cdbw_exu, cdbw_initiators(0));
  --connect_cdbw_client(cdbw_lsu, cdbw_initiators(1));

  cdbw_initiators(0).vq  <= cdbw_exu.vq;
  cdbw_initiators(0).tq  <= cdbw_exu.tq;
  cdbw_initiators(0).req <= cdbw_exu.req;
  cdbw_initiators(0).lh  <= cdbw_exu.lh;
  cdbw_exu.ack <= cdbw_initiators(0).ack;

  cdbw_initiators(1).vq  <= cdbw_lsu.vq;
  cdbw_initiators(1).tq  <= cdbw_lsu.tq;
  cdbw_initiators(1).req <= cdbw_lsu.req;
  cdbw_initiators(1).lh  <= cdbw_lsu.lh;
  cdbw_lsu.ack <= cdbw_initiators(1).ack;

  g_cdbw_initiator_ctrl:
  for i in 0 to NB_CDB_INITIATOR-1 generate
    cdbw_req(i) <= cdbw_initiators(i).req;
    cdbw_initiators(i).ack <= cdbw_ack(i);
  end generate;

  u_cdb_rra:
  entity hw.arbiter(round_robin)
  generic map (
    RST_LEVEL => RST_LEVEL,
    N         => NB_CDB_INITIATOR
  )
  port map (
    i_clk     => i_clk,
    i_srst    => i_srst,
    i_arst    => i_arst,
    i_req     => cdbw_req,
    o_ack     => cdbw_ack
  );

  cdbr_vq <= cdbw_initiators(to_integer(unsigned(one_hot_decoder(cdbw_ack)))).vq;
  cdbr_tq <= cdbw_initiators(to_integer(unsigned(one_hot_decoder(cdbw_ack)))).tq;
  cdbr_rq <= or cdbw_ack;

  ---
  -- OUTPUT
  ---
  o_imem_avalid  <= not sys_stall;
  o_imem_addr   <= pc;

  -- TODO: Depending on what instruction is decoded we can setup
  --       the stall so instructions unrelated to that full can still be executed

  o_stall <= sys_stall;
  o_halt  <= sys_halt;
  o_debug <= sys_debug;

end architecture;
