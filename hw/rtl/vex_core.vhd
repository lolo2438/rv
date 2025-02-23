library ieee;
use ieee.std_logic_1164.all;

library vex;

entity vex_core is
  generic(
    -- EXTENSIONS
    RST_LEVEL : std_logic := '0';
    XLEN : natural
  );
  port(
    -- CONTROL I/F
    i_clk         : in  std_logic;                            --! Core clock
    i_arst        : in  std_logic;                            --! Asynchronous reset
    i_srst        : in  std_logic;                            --! Synchronous reset
    o_halt        : out std_logic;

    -- IMEM I/F
    o_imem_addr   : out std_logic_vector(31 downto 0);        --! Address to read instruction from
    o_imem_valid  : out std_logic;                            --! Address read is valid
    i_imem_rdy    : in  std_logic;                            --! Instruction is ready to be read
    i_imem_data   : in  std_logic_vector(31 downto 0);        --! Instruction

    -- DMEM I/F
    i_dmem_rdata  : in  std_logic_vector(XLEN-1 downto 0);    --! Data read from memory
    i_dmem_re     : in  std_logic;                            --! Data read from memory is valid
    i_dmem_wrdy   : in  std_logic;                            --! Write operation to memory is ready
    i_dmem_rrdy   : in  std_logic;                            --! Read operation to memory is ready
    o_dmem_addr   : out std_logic_vector(XLEN-1 downto 0);    --! Memory address to read/write from
    o_dmem_we     : out std_logic;                            --! Write enable: '1' for a write request, '0' for a read request
    o_dmem_wdata  : out std_logic_vector(XLEN-1 downto 0);    --! Data to write to memory
    o_dmem_valid  : out std_logic                             --! Memory operation is valid
  );
end entity;

architecture rtl of vex_core is

  constant REG_LEN : natural := 5;
  constant ROB_LEN : natural := 5;
  constant EXB_LEN : natural := 5;
  constant TAG_LEN : natural := 7;

  signal sel_rob : std_logic;
  signal sel_lsu : std_logic;
  signal sel_sys : std_logic;
  signal sel_bru : std_logic;


  type disp_data is record
    v : std_logic_vector(XLEN-1 downto 0);
    t : std_logic_vector(TAG_LEN-1 downto 0);
    r : std_logic;
  end record;

  signal pc : std_logic_vector(XLEN-1 downto 0);
  signal pc_stall : std_logic;

  signal inst                 : std_logic_vector(31 downto 0);
  signal inst_valid           : std_logic;

  signal disp_op              : std_logic_vector(4 downto 0);
  signal disp_f12             : std_logic_vector(11 downto 0);
  signal disp_f7              : std_logic_vector(6 downto 0);
  signal disp_f3              : std_logic_vector(2 downto 0);
  signal disp_rs1             : std_logic_VECTOR(REG_LEN-1 downto 0);
  signal disp_rs2             : std_logic_VECTOR(REG_LEN-1 downto 0);
  signal disp_rd              : std_logic_VECTOR(REG_LEN-1 downto 0);
  signal disp_imm             : std_logic_vector(XLEN-1 downto 0);

  signal reg_rs1              : disp_data;
  signal reg_rs2              : disp_data;
  signal reg_wb               : std_logic;
  signal reg_wb_data          : std_logic_vector(XLEN-1 downto 0);
  signal reg_wb_rd            : std_logic_vector(REG_LEN-1 downto 0);

  signal rob_rs1              : disp_data;
  signal rob_rs2              : disp_data;
  signal rob_wb_valid         : std_logic;
  signal rob_wb_addr          : std_logic_vector(ROB_LEN-1 downto 0);
  signal rob_wb_data          : std_logic_vector(XLEN-1 downto 0);
  signal rob_full             : std_logic;

  signal disp_j               : disp_data;
  signal disp_k               : disp_data;
  signal disp_tq              : std_logic_vector(TAG_LEN-1 downto 0);
  signal disp_valid           : std_logic;

  signal exb_full             : std_logic;
  signal issue_f3             : std_logic_vector(2 downto 0);
  signal issue_f7             : std_logic_vector(2 downto 0);
  signal issue_vj             : std_logic_vector(XLEN-1 downto 0);
  signal issue_vk             : std_logic_vector(XLEN-1 downto 0);
  signal issue_tq             : std_logic_vector(TAG_LEN-1 downto 0);
  signal issue_valid          : std_logic;

  signal exec_rdy             : std_logic;
  signal exec_result          : std_logic_vector(XLEN-1 downto 0);
  signal exec_tq              : std_logic_vector(TAG_LEN-1 downto 0);
  signal exec_done            : std_logic;

  signal cdb : disp_data;

begin

  ---
  -- Configurations
  ---

  ---
  -- INPUT
  ---

  inst        <= i_imem_data;
  inst_valid  <= i_imem_rdy and not pc_stall;

  --<= i_dmem_rdata
  --<= i_dmem_re
  --<= i_dmem_wrdy
  --<= i_dmem_rrdy
  ---
  -- FRONT END
  ---
  u_dec:
  entity vex.dec
  generic map(
    XLEN => XLEN
  )
  port map (
    i_wed     => inst_valid,
    i_inst    => inst,
    o_op      => disp_op,
    o_f12     => disp_f12,
    o_f7      => disp_f7,
    o_f3      => disp_f3,
    o_imm     => disp_imm,
    o_rs1     => disp_rs1,
    o_rs2     => disp_rs2,
    o_rd      => disp_rd,
    o_rob     => sel_rob,
    o_bru     => sel_bru,
    o_lsu     => sel_lsu,
    o_sys     => sel_sys,
    o_inst_v  => disp_valid
  );


  u_reg:
  entity vex.reg
  generic map(
    RST_LEVEL => RST_LEVEL,
    REG_LEN   => REG_LEN,
    ROB_LEN   => ROB_LEN,
    XLEN      => XLEN
  )
  port map(
    i_clk  => i_clk,
    i_arst => i_arst,
    i_srst => i_srst,
    i_rs1  => disp_rs1,
    o_vj   => reg_rs1.v,
    o_qj   => reg_rs1.t(ROB_LEN-1 downto 0),
    o_rj   => reg_rs1.r,
    i_rs2  => disp_rs2,
    o_vk   => reg_rs2.v,
    o_qk   => reg_rs2.t(ROB_LEN-1 downto 0),
    o_rk   => reg_rs2.r,
    i_wed  => disp_valid,
    i_rd   => disp_rd,
    i_qr   => rob_wb_addr,
    i_wer  => reg_wb,
    i_wr   => reg_wb_rd,
    i_res  => reg_wb_data
  );



  ---
  -- BACK END
  ---

  --rob_wb_addr extracted cdb
  --rob_wb_data cdb data
  --rob_wb_valid <= cdb valid + rob selected

  u_rob:
  entity vex.rob
  generic map(
    RST_LEVEL => RST_LEVEL,
    REG_LEN   => REG_LEN,
    ROB_LEN   => ROB_LEN,
    XLEN      => XLEN
  )
  port map(
    i_clk           => i_clk,
    i_arst          => i_arst,
    i_srst          => i_srst,
    i_flush         => '0',
    o_full          => rob_full,
    i_disp_valid    => disp_valid,
    i_disp_rob      => sel_rob,
    i_disp_rd       => disp_rd,
    o_disp_wb_addr  => rob_wb_addr,
    i_disp_rs1      => disp_rs1,
    o_disp_rs1_rdy  => rob_rs1.r,
    o_disp_rs1_data => rob_rs1.v,
    o_disp_rs1_addr => rob_rs1.t(ROB_LEN-1 downto 0),
    i_disp_rs2      => disp_rs2,
    o_disp_rs2_rdy  => rob_rs2.r,
    o_disp_rs2_data => rob_rs2.v,
    o_disp_rs2_addr => rob_rs2.t(ROB_LEN-1 downto 0),
    o_reg_commit    => reg_wb,
    o_reg_rd        => reg_wb_rd,
    o_reg_result    => reg_wb_data,
    i_wb_addr       => rob_wb_addr,
    i_wb_result     => rob_wb_data,
    i_wb_valid      => rob_wb_valid
  );


  -- tq <=
  -- rob_wb_addr
  -- j <=
  -- k <=

  -- exec_rdy <=
  u_exb:
  entity vex.exb
  generic map(
    RST_LEVEL => RST_LEVEL,
    EXB_LEN   => EXB_LEN,
    TAG_LEN   => TAG_LEN,
    XLEN      => XLEN
  )
  port map(
    i_clk       => i_clk,
    i_arst      => i_arst,
    i_srst      => i_srst,
    o_full      => exb_full,
    o_empty     => open,
    i_disp_we   => disp_valid,
    i_disp_f3   => disp_f3,
    i_disp_f7   => disp_f7,
    i_disp_vj   => disp_j.v,
    i_disp_tj   => disp_j.t,
    i_disp_rj   => disp_j.r,
    i_disp_vk   => disp_k.v,
    i_disp_tk   => disp_k.t,
    i_disp_rk   => disp_k.r,
    i_disp_tq   => disp_tq,
    i_issue_rdy => exec_rdy,
    o_issue_vj  => issue_vj,
    o_issue_vk  => issue_vk,
    o_issue_f3  => issue_f3,
    o_issue_f7  => issue_f7,
    o_issue_tq  => issue_tq,
    o_issue_we  => issue_valid,
    i_cdb_we    => cdb.r,
    i_cdb_tq    => cdb.t,
    i_cdb_vq    => cdb.v
  );


  -- EXU:
  exec_rdy <= '1';

  u_alu:
  entity vex.alu
  generic map(
    XLEN => XLEN
  )
  port map(
    i_clk   => i_clk,
    i_valid => issue_valid,
    i_tq    => issue_tq,
    i_a     => issue_vj,
    i_b     => issue_vk,
    i_f3    => issue_f3,
    i_f7    => issue_f7,
    o_c     => exec_result,
    o_tq    => exec_tq,
    o_done  => exec_done
  );

  cdb.r <= exec_done;
  cdb.v <= exec_result;
  cdb.t <= exec_tq;


  ---
  -- OUTPUT
  ---
  o_imem_valid  <= not pc_stall;
  o_imem_addr   <= pc;

  --o_dmem_addr   <=
  --o_dmem_we     <=
  --o_dmem_wdata  <=
  --o_dmem_valid  <=

end architecture;
