library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.common_pkg.all;

library riscv;
use riscv.RV32I.all;

entity lsu is
  generic (
    RST_LEVEL : std_logic := '0';   --! Reset level
    STB_LEN   : natural;            --! STB_SIZE = 2**STB_LEN
    LDB_LEN   : natural;            --! LDB_SIZE = 2**LDB_LEN
    TAG_LEN   : natural;            --! Tag length
    XLEN      : natural             --! Operand size
  );
  port (
    -- CTRL I/F
    i_clk           : in  std_logic;                              --! LSU Clock
    i_arst          : in  std_logic;                              --! Async Reset
    i_srst          : in  std_logic;                              --! Sync Reset

    o_stb_full      : out std_logic;                              --! Store buffer is full when '1'
    o_ldb_full      : out std_logic;                              --! Load buffer is full when '1'
    o_grp_full      : out std_logic;                              --! Group tracking for Fence operation is full when '1'

    -- DISP I/F
    i_disp_valid    : in  std_logic;                              --! Dispatch data is valid
    i_disp_op       : in  std_logic_vector(4 downto 0);           --! Opcode
    i_disp_f3       : in  std_logic_vector(2 downto 0);           --! L/S F3
    i_disp_tq       : in  std_logic_vector(TAG_LEN-1 downto 0);   --! Address to store the load result
    i_disp_va       : in  std_logic_vector(XLEN-1 downto 0);      --! Address field value for Load/Store
    i_disp_ta       : in  std_logic_vector(TAG_LEN-1 downto 0);   --! Address tag to look for if it's not ready
    i_disp_ra       : in  std_logic;                              --! Address ready flag
    i_disp_vd       : in  std_logic_vector(XLEN-1 downto 0);      --! Data field value for Store
    i_disp_td       : in  std_logic_vector(TAG_LEN-1 downto 0);   --! Data tag to look for if it's not ready
    i_disp_rd       : in  std_logic;                              --! Data ready flag
    o_disp_stu_qr   : out std_logic_vector(STB_LEN-1 downto 0);   --! STB Entry that the address should be fowarded
    o_disp_ldu_qr   : out std_logic_vector(LDB_LEN-1 downto 0);   --! LDB Entry that the address should be fowarded

    -- CDB WR I/F
    o_cdbw_vq       : out std_logic_vector(XLEN-1 downto 0);      --! Data to write on the bus
    o_cdbw_tq       : out std_logic_vector(TAG_LEN-1 downto 0);   --! Tag to write on the CDB bus
    o_cdbw_req      : out std_logic;                              --! Request to the CDB bus
    o_cdbw_lh       : out std_logic;                              --! Look Ahead flag indicates that there are at least 2 values that are ready
    i_cdbw_ack      : in  std_logic;                              --! Acknowledge from the CDB bus

    -- CDB RD I/F
    i_cdbr_vq       : in  std_logic_vector(XLEN-1 downto 0);      --! Data from the CDB bus
    i_cdbr_tq       : in  std_logic_vector(TAG_LEN-1 downto 0);   --! Tag from the CDB bus
    i_cdbr_rq       : in  std_logic;                              --! CDB Ready flag

    -- MEM WR I/F
    o_mem_wr_we     : out std_logic;                              --! Write Enable to memory
    i_mem_wr_rdy    : in  std_logic;                              --! Memory is ready to issue a write
    o_mem_wr_addr   : out std_logic_vector(XLEN-1 downto 0);      --! Address of the operation
    o_mem_wr_data   : out std_logic_vector(XLEN-1 downto 0);      --! Write data from memory
    o_mem_wr_byten  : out std_logic_vector(XLEN/8-1 downto 0);    --! Byte enable vector for write data

    -- MEM RD I/F
    o_mem_rd_re     : out std_logic;                              --! Read enable to memory
    i_mem_rd_rdy    : in  std_logic;                              --! Memory is ready to issue a read
    o_mem_rd_addr   : out std_logic_vector(XLEN-1 downto 0);      --! Memory read address
    o_mem_rd_ptr    : out std_logic_vector(LDB_LEN-1 downto 0);   --! LDB address that the load should be stored at
    i_mem_rd_data   : in  std_logic_vector(XLEN-1 downto 0);      --! Read data from memory
    i_mem_rd_ptr    : in  std_logic_vector(LDB_LEN-1 downto 0);   --! LDB address that the read data will be store at
    i_mem_rd_valid  : in  std_logic                               --! Read data is valid
  );
end entity;

architecture rtl of lsu is

  constant GRP_LEN  : natural := 4;

  ---
  -- GRP
  ---
  signal grp_disp_fence   : std_logic;
  signal grp_full         : std_logic;
  signal wr_grp           : std_logic_vector(GRP_LEN-1 downto 0);
  signal rd_grp           : std_logic_vector(GRP_LEN-1 downto 0);

  ---
  -- STB
  ---
  signal stb_full         : std_logic;
  signal stb_disp_store   : std_logic;
  signal stb_rd_grp_match : std_logic;
  signal stb_deps         : std_logic_vector(2**STB_LEN-1 downto 0);
  signal stb_raddr        : std_logic_vector(STB_LEN-1 downto 0);
  signal stb_issue_rdy    : std_logic;
  signal stb_issue_valid  : std_logic;
  signal stb_issue_f3     : std_logic_vector(2 downto 0);
  signal stb_issue_addr   : std_logic_vector(XLEN-1 downto 0);
  signal stb_issue_data   : std_logic_vector(XLEN-1 downto 0);
  signal stb_issue        : std_logic;


  ---
  -- LDB
  ---
  signal ldb_disp_load    : std_logic;
  signal ldb_issue_rdy    : std_logic;
  signal ldb_issue_valid  : std_logic;
  signal ldb_issue_addr   : std_logic_vector(XLEN-1 downto 0);
  signal ldb_issue_ptr    : std_logic_vector(LDB_LEN-1 downto 0);
  signal ldb_wb_valid     : std_logic;
  signal ldb_wb_ptr       : std_logic_vector(LDB_LEN-1 downto 0);
  signal ldb_wb_data      : std_logic_vector(XLEN-1 downto 0);
  signal ldb_rd_grp_match : std_logic;
  signal ldb_full         : std_logic;

  ---
  -- MEM
  ---
  signal store_byten : std_logic_vector(XLEN/8-1 downto 0);

begin

  ---
  -- INPUT
  ---
  ldb_issue_rdy <= i_mem_rd_rdy;
  ldb_wb_data   <= i_mem_rd_data;
  ldb_wb_valid  <= i_mem_rd_valid;
  ldb_wb_ptr    <= i_mem_rd_ptr;

  grp_disp_fence <= '1' when i_disp_op = OP_MISC_MEM and i_disp_f3 = FUNCT3_FENCE else '0';
  ldb_disp_load <= '1' when i_disp_op = OP_LOAD else '0';
  stb_disp_store <= '1' when i_disp_op = OP_STORE else '0';


  ---
  -- LOGIC
  ---
  u_grp:
  entity work.grp
  generic map(
    RST_LEVEL => RST_LEVEL,
    GRP_LEN => GRP_LEN
  )
  port map(
    i_clk               => i_clk,
    i_arst              => i_arst,
    i_srst              => i_srst,
    o_full              => grp_full,
    i_disp_valid        => i_disp_valid,
    i_disp_fence        => grp_disp_fence,
    i_stb_rd_grp_match  => stb_rd_grp_match,
    i_ldb_rd_grp_match  => ldb_rd_grp_match,
    o_wr_grp            => wr_grp,
    o_rd_grp            => rd_grp
  );


  u_stb:
  entity work.stb
  generic map(
    RST_LEVEL => RST_LEVEL,
    STB_LEN   => STB_LEN,
    GRP_LEN   => GRP_LEN,
    TAG_LEN   => TAG_LEN,
    XLEN      => XLEN
  )
  port map (
    i_clk           => i_clk,
    i_arst          => i_arst,
    i_srst          => i_srst,
    o_full          => stb_full,
    i_disp_valid    => i_disp_valid,
    i_disp_store    => stb_disp_store,
    i_disp_f3       => i_disp_f3,
    i_disp_va       => i_disp_va,
    i_disp_ta       => i_disp_ta,
    i_disp_ra       => i_disp_ra,
    i_disp_vd       => i_disp_vd,
    i_disp_td       => i_disp_td,
    i_disp_rd       => i_disp_rd,
    o_disp_qr       => o_disp_stu_qr,
    i_wr_grp        => wr_grp,
    i_rd_grp        => rd_grp,
    o_rd_grp_match  => stb_rd_grp_match,
    i_cdbr_vq       => i_cdbr_vq,
    i_cdbr_tq       => i_cdbr_tq,
    i_cdbr_rq       => i_cdbr_rq,
    o_stb_dep       => stb_deps,
    o_stb_addr      => stb_raddr,
    i_issue_rdy     => stb_issue_rdy,
    o_issue_valid   => stb_issue_valid,
    o_issue_f3      => stb_issue_f3,
    o_issue_addr    => stb_issue_addr,
    o_issue_data    => stb_issue_data
  );

  stb_issue <= (stb_issue_rdy and stb_issue_valid);

  u_ldb:
  entity work.ldb
  generic map(
    RST_LEVEL => RST_LEVEL,
    LDB_LEN   => LDB_LEN,
    GRP_LEN   => GRP_LEN,
    STB_LEN   => STB_LEN,
    TAG_LEN   => TAG_LEN,
    XLEN      => XLEN
  )
  port map(
    i_clk           => i_clk,
    i_arst          => i_arst,
    i_srst          => i_srst,
    o_full          => ldb_full,
    i_disp_valid    => i_disp_valid,
    i_disp_load     => ldb_disp_load,
    i_disp_f3       => i_disp_f3,
    i_disp_tq       => i_disp_tq,
    i_disp_va       => i_disp_va,
    i_disp_ta       => i_disp_ta,
    i_disp_ra       => i_disp_ra,
    o_disp_qr       => o_disp_ldu_qr,
    i_cdbr_vq       => i_cdbr_vq,
    i_cdbr_tq       => i_cdbr_tq,
    i_cdbr_rq       => i_cdbr_rq,
    i_wr_grp        => wr_grp,
    i_rd_grp        => rd_grp,
    o_rd_grp_match  => ldb_rd_grp_match,
    i_stb_issue     => stb_issue,
    i_stb_addr      => stb_issue_addr,
    i_stb_data      => stb_issue_data,
    i_stb_dep       => stb_deps,
    i_issue_rdy     => ldb_issue_rdy,
    o_issue_valid   => ldb_issue_valid,
    o_issue_addr    => ldb_issue_addr,
    o_issue_ldb_ptr => ldb_issue_ptr,
    i_wb_valid      => ldb_wb_valid,
    i_wb_ldb_ptr    => ldb_wb_ptr,
    i_wb_data       => ldb_wb_data,
    o_cdbw_vq       => o_cdbw_vq,
    o_cdbw_tq       => o_cdbw_tq,
    o_cdbw_req      => o_cdbw_req,
    o_cdbw_lh       => o_cdbw_lh,
    i_cdbw_ack      => i_cdbw_ack
  );

  ---
  -- Memory
  ---

  -- TODO
  --F3 value:
  --store_byten <=


  -- OUTPUT
  ---
  o_mem_wr_we    <= stb_issue_valid;
  stb_issue_rdy  <= i_mem_wr_rdy;
  o_mem_wr_addr  <= stb_issue_addr;
  o_mem_wr_data  <= stb_issue_data;
  o_mem_wr_byten <= store_byten;

  o_mem_rd_re   <= ldb_issue_valid;
  o_mem_rd_addr <= ldb_issue_addr;
  o_mem_rd_ptr  <= ldb_issue_ptr;

  o_stb_full <= stb_full;
  o_ldb_full <= ldb_full;
  o_grp_full <= grp_full;


end architecture;
