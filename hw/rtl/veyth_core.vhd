library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library riscv;
use riscv.RV32I.all;

library veyth;
use veyth.tag_pkg.all;

entity veyth_core is
  generic(
    -- EXTENSIONS
    RST_LEVEL : std_logic := '0';
    XLEN : natural
  );
  port(
    -- CONTROL I/F
    i_clk           : in  std_logic;                            --! Core clock
    i_arst          : in  std_logic;                            --! Asynchronous reset
    i_srst          : in  std_logic;                            --! Synchronous reset
    --o_halt          : out std_logic;
    --i_debug         : in  std_logic;
    o_stall         : out std_logic;

    -- IMEM I/F
    o_imem_addr     : out std_logic_vector(31 downto 0);        --! Address to read instruction from
    o_imem_valid    : out std_logic;                            --! Address read is valid
    i_imem_rdy      : in  std_logic;                            --! Instruction is ready to be read
    i_imem_data     : in  std_logic_vector(31 downto 0);        --! Instruction

    -- DMEM RD I/F
    i_dmem_rrdy     : in  std_logic;                            --! Memory is ready for read operation
    o_dmem_raddr    : out std_logic_vector(XLEN-1 downto 0);    --! Address to read from memory
    o_dmem_ravalid  : out std_logic;                            --! Processor Read operation is valid
    i_dmem_rdata    : in  std_logic_vector(XLEN-1 downto 0);    --! Data read from memory
    i_dmem_rdvalid  : in  std_logic;                            --! Data from memory is valid

    -- DMEM WR I/F
    o_dmem_wvalid   : out std_logic;                            --! Processor write operation is valid
    i_dmem_wrdy     : in  std_logic;                            --! Memory is ready for write operation
    o_dmem_wbyten   : out std_logic_vector(XLEN/8-1 downto 0);  --! Byte enable for store operation
    o_dmem_waddr    : out std_logic_vector(XLEN-1 downto 0);    --! Memory address to read/write from
    o_dmem_wdata    : out std_logic_vector(XLEN-1 downto 0)     --! Data to write to memory
  );
end entity;

architecture rtl of veyth_core is

  constant ZERO : std_logic_vector(XLEN-1 downto 0) := (others => '0');

  signal pc : std_logic_vector(XLEN-1 downto 0);
  signal pcu : unsigned(pc'range);
  signal pc_stall : std_logic;

  signal inst                 : std_logic_vector(31 downto 0);
  signal inst_valid           : std_logic;

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

  signal exu_vj_src           : std_logic;
  signal exu_vk_src           : std_logic;
  signal exu_vj               : std_logic_vector(XLEN-1 downto 0);
  signal exu_tj               : std_logic_vector(TAG_LEN-1 downto 0);
  signal exu_rj               : std_logic;
  signal exu_vk               : std_logic_vector(XLEN-1 downto 0);
  signal exu_tk               : std_logic_vector(TAG_LEN-1 downto 0);
  signal exu_rk               : std_logic;
  signal exu_tq               : std_logic_vector(TAG_LEN-1 downto 0);

  signal lsu_va               : std_logic_vector(XLEN-1 downto 0);
  signal lsu_ta               : std_logic_vector(TAG_LEN-1 downto 0);
  signal lsu_ra               : std_logic;
  signal lsu_vd               : std_logic_vector(XLEN-1 downto 0);
  signal lsu_td               : std_logic_vector(TAG_LEN-1 downto 0);
  signal lsu_rd               : std_logic;

  signal ldu_qr               : std_logic_vector(LDB_LEN-1 downto 0);
  signal stu_qr               : std_logic_vector(STB_LEN-1 downto 0);

  signal rgu_tq               : std_logic_vector(TAG_LEN-1 downto 0);
  signal rgu_vj               : std_logic_vector(XLEN-1 downto 0);
  signal rgu_tj               : std_logic_vector(TAG_LEN-1 downto 0);
  signal rgu_rj               : std_logic;
  signal rgu_vk               : std_logic_vector(XLEN-1 downto 0);
  signal rgu_tk               : std_logic_vector(TAG_LEN-1 downto 0);
  signal rgu_rk               : std_logic;

  signal cdbr_vq              : std_logic_vector(XLEN-1 downto 0);
  signal cdbr_tq              : std_logic_vector(TAG_LEN-1 downto 0);
  signal cdbr_rq              : std_logic;

  signal rgu_rob_full         : std_logic;
  signal exu_exb_full         : std_logic;
  signal lsu_ldb_full         : std_logic;
  signal lsu_stb_full         : std_logic;
  signal lsu_grp_full         : std_logic;

  -- TODO: this pointer is a q address to write back to the data from the read
  --       for now it is looped back on the lsu cuz single read tests, but in
  --       the future it is expected to be associated to out of order multi issue reads
  signal dmem_ptr             : std_logic_vector(LDB_LEN-1 downto 0);


  type cdbw_sig is record
    vq  : std_logic_vector(XLEN-1 downto 0);
    tq  : std_logic_vector(TAG_LEN-1 downto 0);
    req : std_logic;
    lh  : std_logic;
    ack : std_logic;
  end record;

  signal cdbw_exu : cdbw_sig;
  signal cdbw_lsu : cdbw_sig;

begin

  ---
  -- Configurations
  ---

  ---
  -- INPUT
  ---
  inst        <= i_imem_data;
  inst_valid  <= i_imem_rdy and not pc_stall;

  ---
  -- LOGIC
  ---

  -- TODO place in system component
  p_pc:
  process(i_clk, i_arst)
  begin
    if i_arst = RST_LEVEL then
      pcu <= (others => '0');
    elsif rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        pcu <= (others => '0');
      else
        pcu <= pcu + 4;
      end if;
    end if;
  end process;

  pc <= std_logic_vector(pcu);


  u_dec:
  entity veyth.dec
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


  u_rgu:
  entity veyth.rgu
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
    o_rob_full    => rgu_rob_full,
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
  process(disp_op, rgu_tq, ldu_qr, stu_qr)
  begin
    exu_tq <= (others => 'X');
    case disp_op is
      when OP_OP | OP_IMM | OP_AUIPC | OP_LUI | OP_JAL | OP_JALR =>
        exu_tq <= rgu_tq;
      when OP_LOAD =>
        exu_tq <= format_tag(UNIT_LDU, ldu_qr);
      when OP_STORE =>
        exu_tq <= format_tag(UNIT_STU, stu_qr);
      when OP_BRANCH =>
        --exu_tq <= format_tag(UNIT_BRU, bru_qr);
      when others => -- Exentions here
    end case;
  end process;

  exu_vj_src <= '0' when disp_op = OP_OP or disp_op = OP_BRANCH else '1';

  exu_vj <= disp_imm         when exu_vj_src = '1' else rgu_vj;
  exu_tj <= (others => 'X')  when exu_vj_src = '1' else rgu_tj;
  exu_rj <= '1'              when exu_vj_src = '1' else rgu_rj;

  exu_vk_src <= '1' when disp_op = OP_AUIPC else '0';

  exu_vk <= pc               when exu_vk_src = '1' else rgu_vk;
  exu_tk <= (others => 'X')  when exu_vk_src = '1' else rgu_tk;
  exu_rk <= '1'              when exu_vk_src = '1' else rgu_rk;

  u_exu:
  entity veyth.exu
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
    o_exb_full    => exu_exb_full,
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



  -- LSU
  lsu_ra <= '1' when disp_rs1 = ZERO(disp_rs1'range) else '0';
  lsu_va <= disp_imm when lsu_ra = '1' else (others => 'X');
  lsu_ta <= exu_tq;

  lsu_rd <= '1' when disp_rs2 = ZERO(disp_rs2'range) else '0';
  lsu_vd <= (others => '0') when lsu_rd = '1' else (others => 'X');
  lsu_td <= rgu_tk;


  u_lsu:
  entity veyth.lsu
  generic map (
    RST_LEVEL => RST_LEVEL,
    STB_LEN   => STB_LEN,
    LDB_LEN   => LDB_LEN,
    TAG_LEN   => TAG_LEN,
    XLEN      => XLEN
  )
  port map (
    i_clk           => i_clk,
    i_arst          => i_arst,
    i_srst          => i_srst,
    o_stb_full      => lsu_stb_full,
    o_ldb_full      => lsu_ldb_full,
    o_grp_full      => lsu_grp_full,
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
    o_disp_stu_qr   => stu_qr,
    o_disp_ldu_qr   => ldu_qr,
    o_cdbw_vq       => cdbw_lsu.vq,
    o_cdbw_tq       => cdbw_lsu.tq,
    o_cdbw_req      => cdbw_lsu.req,
    o_cdbw_lh       => cdbw_lsu.lh,
    i_cdbw_ack      => cdbw_lsu.ack,
    i_cdbr_vq       => cdbr_vq,
    i_cdbr_tq       => cdbr_tq,
    i_cdbr_rq       => cdbr_rq,
    o_mem_wr_we     => o_dmem_wvalid,
    i_mem_wr_rdy    => i_dmem_wrdy,
    o_mem_wr_addr   => o_dmem_waddr,
    o_mem_wr_data   => o_dmem_wdata,
    o_mem_wr_byten  => o_dmem_wbyten,
    o_mem_rd_re     => o_dmem_ravalid,
    i_mem_rd_rdy    => i_dmem_rrdy,
    o_mem_rd_addr   => o_dmem_raddr,
    o_mem_rd_ptr    => dmem_ptr,
    i_mem_rd_data   => i_dmem_rdata,
    i_mem_rd_ptr    => dmem_ptr,
    i_mem_rd_valid  => i_dmem_rdvalid
  );


  -- TODO: CDBW arbiter logic
  -- cdbw_exu, cdbw_lsu, cdbr_*


  ---
  -- OUTPUT
  ---
  o_imem_valid  <= not pc_stall;
  o_imem_addr   <= pc;

  -- TODO: Depending on what instruction is decoded we can setup
  --       the stall so instructions unrelated to that full can still be executed
  o_stall <= lsu_ldb_full or lsu_stb_full or lsu_grp_full or exu_exb_full or rgu_rob_full;

end architecture;
