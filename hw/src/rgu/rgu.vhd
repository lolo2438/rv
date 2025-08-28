library ieee;
use ieee.std_logic_1164.all;

library riscv;
use riscv.RV32I.all;

library hw;
use hw.tag_pkg.all;

entity rgu is
  generic (
    RST_LEVEL : std_logic := '0';
    ROB_LEN   : natural;
    REG_LEN   : natural;
    TAG_LEN   : natural;
    XLEN      : natural
  );
  port (
    i_clk         : in  std_logic;
    i_srst        : in  std_logic;
    i_arst        : in  std_logic;
    o_rob_full    : out std_logic;
    o_rob_empty   : out std_logic;

    -- DISPATCH I/F
    i_disp_valid  : in  std_logic;
    i_disp_op     : in  std_logic_vector(4 downto 0);
    i_disp_rs1    : in  std_logic_vector(4 downto 0);
    i_disp_rs2    : in  std_logic_vector(4 downto 0);
    i_disp_rd     : in  std_logic_vector(4 downto 0);
    o_disp_tq     : out std_logic_vector(TAG_LEN-1 downto 0);

    -- DATA I/F
    o_data_vj     : out std_logic_vector(XLEN-1 downto 0);
    o_data_tj     : out std_logic_vector(TAG_LEN-1 downto 0);
    o_data_rj     : out std_logic;

    o_data_vk     : out std_logic_vector(XLEN-1 downto 0);
    o_data_tk     : out std_logic_vector(TAG_LEN-1 downto 0);
    o_data_rk     : out std_logic;

    -- CDB RD I/F
    i_cdbr_vq     : in  std_logic_vector(XLEN-1 downto 0);
    i_cdbr_tq     : in  std_logic_vector(TAG_LEN-1 downto 0);
    i_cdbr_rq     : in  std_logic
  );
end entity;

architecture rtl of rgu is

  signal disp_we      : std_logic;

  signal reg_wb       : std_logic;
  signal rob_disp_qr  : std_logic_vector(ROB_LEN-1 downto 0);
  signal rob_wb_qr    : std_logic_vector(ROB_LEN-1 downto 0);

  signal reg_vj       : std_logic_vector(XLEN-1 downto 0);
  signal reg_qj       : std_logic_vector(ROB_LEN-1 downto 0);
  signal reg_rj       : std_logic;

  signal reg_vk       : std_logic_vector(XLEN-1 downto 0);
  signal reg_qk       : std_logic_vector(ROB_LEN-1 downto 0);
  signal reg_rk       : std_logic;

  signal rob_vk       : std_logic_vector(XLEN-1 downto 0);
  signal rob_qk       : std_logic_vector(ROB_LEN-1 downto 0);
  signal rob_rk       : std_logic;

  signal rob_vj       : std_logic_vector(XLEN-1 downto 0);
  signal rob_qj       : std_logic_vector(ROB_LEN-1 downto 0);
  signal rob_rj       : std_logic;


  signal rob_commit   : std_logic;
  signal rob_rd       : std_logic_vector(REG_LEN-1 downto 0);
  signal rob_result   : std_logic_vector(XLEN-1 downto 0);

  signal rob_full     : std_logic;
  signal rob_empty    : std_logic;

  signal vj, vk       : std_logic_vector(XLEN-1 downto 0);
  signal tj, tk       : std_logic_vector(TAG_LEN-1 downto 0);
  signal rj, rk       : std_logic;

begin


  -- TODO: no need to wb when rd=0
  p_reg_wb:
  process(i_disp_op)
  begin
    reg_wb <= '0';
      case i_disp_op is
        -- EXLCUDED: OP_SYSTEM
        when OP_OP | OP_IMM | OP_LUI | OP_AUIPC | OP_JAL | OP_JALR | OP_LOAD  =>
          reg_wb <= '1';
        when others => -- Add extensions
      end case;
  end process;

  disp_we <= reg_wb and i_disp_valid;

  u_reg:
  entity hw.reg
  generic map(
    RST_LEVEL => RST_LEVEL,
    REG_LEN   => REG_LEN,
    ROB_LEN   => ROB_LEN,
    XLEN      => XLEN
  )
  port map(
    i_clk        => i_clk,
    i_arst       => i_arst,
    i_srst       => i_srst,
    i_disp_rs1   => i_disp_rs1,
    o_reg_vj     => reg_vj,
    o_reg_qj     => reg_qj,
    o_reg_rj     => reg_rj,
    i_disp_rs2   => i_disp_rs2,
    o_reg_vk     => reg_vk,
    o_reg_qk     => reg_qk,
    o_reg_rk     => reg_rk,
    i_disp_wb    => disp_we,
    i_disp_rd    => i_disp_rd,
    i_disp_qr    => rob_disp_qr,
    i_wb_we      => rob_commit,
    i_wb_rd      => rob_rd,
    i_wb_qr      => rob_wb_qr,
    i_wb_data    => rob_result
  );


  u_rob:
  entity hw.rob
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
    o_empty         => rob_empty,
    i_disp_rob      => disp_we,
    i_disp_rd       => i_disp_rd,
    o_disp_qr       => rob_disp_qr,
    i_disp_rs1      => i_disp_rs1,
    o_disp_vj       => rob_vj,
    o_disp_qj       => rob_qj,
    o_disp_rj       => rob_rj,
    i_disp_rs2      => i_disp_rs2,
    o_disp_vk       => rob_vk,
    o_disp_qk       => rob_qk,
    o_disp_rk       => rob_rk,
    o_reg_commit    => rob_commit,
    o_reg_rd        => rob_rd,
    o_reg_qr        => rob_wb_qr,
    o_reg_result    => rob_result,
    i_wb_addr       => i_cdbr_tq(ROB_LEN-1 downto 0),
    i_wb_result     => i_cdbr_vq,
    i_wb_valid      => i_cdbr_rq
  );

  vj <= reg_vj when reg_rj = '1' else
        rob_vj when rob_rj = '1' else
        (others => 'X');
  tj <= tag_format(UNIT_RGU_ROB, reg_qj);
  rj <= reg_rj or rob_rj;

  vk <= reg_vk when reg_rk = '1' else
        rob_vk when rob_rk = '1' else
        (others => 'X');
  tk <= tag_format(UNIT_RGU_ROB, reg_qk);
  rk <= reg_rk or rob_rk;

  ---
  -- OUTPUT
  ---
  o_rob_full <= rob_full;
  o_rob_empty <= rob_empty;

  o_disp_tq <= tag_format(UNIT_RGU_ROB, rob_disp_qr);

  o_data_vj <= vj;
  o_data_tj <= tj;
  o_data_rj <= rj;

  o_data_vk <= vk;
  o_data_tk <= tk;
  o_data_rk <= rk;

end architecture;
