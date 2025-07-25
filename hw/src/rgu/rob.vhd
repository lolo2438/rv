--! \file rv_rob.vhd
--! \version 1.0
--! \author Laurent Tremblay
--! \date 2024-11-03
--! \license
--
--! \brief Re-Order Buffer (ROB) module for the RV OoO processor

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library common;
use common.fnct.all;

entity rob is
  generic(
    RST_LEVEL : std_logic := '0';   --! Reset level, default = '0'
    REG_LEN   : natural;            --! REG_SIZE = 2**REG_LEN
    ROB_LEN   : natural;            --! ROB_SIZE = 2**ROB_LEN
    XLEN      : natural             --! RV XLEN
  );
  port(
    -- Control I/F
    i_clk           : in  std_logic;                            --! Clock domain
    i_arst          : in  std_logic;                            --! asynchronous reset
    i_srst          : in  std_logic;                            --! Synchronous reset
    i_flush         : in  std_logic;                            --! Flush the content of the ROB
    o_full          : out std_logic;                            --! Rob is full
    o_empty         : out std_logic;                            --! Rob is empty

    -- Dispatch I/F
    i_disp_rob      : in std_logic;                             --! Create an entry in the ROB
    i_disp_rd       : in std_logic_vector(REG_LEN-1 downto 0);  --! Destination register of the result
    o_disp_qr       : out std_logic_vector(ROB_LEN-1 downto 0); --! Rob address to write back the result

    i_disp_rs1      : in std_logic_vector(REG_LEN-1 downto 0);  --! Source register for operand 1
    o_disp_vj       : out std_logic_vector(XLEN-1 downto 0);    --! Data fowarded from ROB for operand 1
    o_disp_qj       : out std_logic_vector(ROB_LEN-1 downto 0); --! Rob address of the fowarded opreand 1
    o_disp_rj       : out std_logic;                            --! Value found in the ROB for operand 1

    i_disp_rs2      : in std_logic_vector(REG_LEN-1 downto 0);  --! Source register for operant 2
    o_disp_vk       : out std_logic_vector(XLEN-1 downto 0);    --! Data fowarded from ROB for operand 2
    o_disp_qk       : out std_logic_vector(ROB_LEN-1 downto 0); --! Rob address of the fowarded opreand 2
    o_disp_rk       : out std_logic;                            --! Value found in the ROB for operand 2

    -- REG I/F
    o_reg_commit    : out std_logic;                            --! Rob is commiting a value that is ready and clearing it's entry
    o_reg_rd        : out std_logic_vector(REG_LEN-1 downto 0); --! Register Destination address
    o_reg_qr        : out std_logic_vector(ROB_LEN-1 downto 0); --! The rob address that contained the result
    o_reg_result    : out std_logic_vector(XLEN-1 downto 0);    --! Result to write to register

    -- WB I/F
    i_wb_addr       : in std_logic_vector(ROB_LEN-1 downto 0);  --! Write back rob address
    i_wb_result     : in std_logic_vector(XLEN-1 downto 0);     --! Write back result
    i_wb_valid      : in std_logic                              --! Write back result is valid
  );
end entity;

architecture rtl of rob is

  constant ROB_SIZE : natural := 2**ROB_LEN;

  type disp_rs_t is record
    reg_addr : std_logic_vector(REG_LEN-1 downto 0);  --! Source register for operand 1
    rob_rdy  : std_logic;                             --! Value found in the ROB for operand 1
    rob_data : std_logic_vector(XLEN-1 downto 0);     --! Data fowarded from ROB for operand 1
    rob_addr : std_logic_vector(ROB_LEN-1 downto 0);  --! Rob address of the fowarded opreand 1
  end record;

  type disp_rs_array_t is array (1 to 2) of disp_rs_t;
  signal disp_rs : disp_rs_array_t;

  type rob_entry_t is record
    rd      : std_logic_vector(REG_LEN-1 downto 0); -- Destination register
    result  : std_logic_vector(XLEN-1 downto 0);    -- Result value
    valid   : std_logic;                            -- Result field is valid
    busy    : std_logic;                            -- Rob entry is busy
  end record;

  type rob_buf_t is array (0 to ROB_SIZE-1) of rob_entry_t;

  signal rob_buf : rob_buf_t;

  signal busy_flag : std_logic_vector(ROB_SIZE-1 downto 0);

  signal wr_ptr : unsigned(ROB_LEN-1 downto 0);
  signal rd_ptr : unsigned(ROB_LEN-1 downto 0);
  signal full   : std_logic;
  signal empty  : std_logic;

  signal commit : std_logic;

  signal disp : std_logic;

begin

  disp <= i_disp_rob;

  ---
  -- DATAPATH
  ---

  p_rob_buf:
  process(i_clk, i_arst)
    variable wb_addr : natural;
  begin
    if i_arst = RST_LEVEL then
      for i in 0 to ROB_SIZE-1 loop
        rob_buf(i).busy <= '0';
      end loop;
      wr_ptr <= (others => '0');
      rd_ptr <= (others => '0');

    elsif rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        for i in 0 to ROB_SIZE-1 loop
          rob_buf(i).busy <= '0';
        end loop;
        wr_ptr <= (others => '0');
        rd_ptr <= (others => '0');
      else
        if i_flush = '1' then
          for i in 0 to ROB_SIZE-1 loop
            rob_buf(i).busy <= '0';
          end loop;
          wr_ptr <= (others => '0');
          rd_ptr <= (others => '0');
        else
          -- Dispatch
          if disp = '1' and full = '0' then
            rob_buf(to_integer(wr_ptr)).rd    <= i_disp_rd;
            rob_buf(to_integer(wr_ptr)).busy  <= '1';
            rob_buf(to_integer(wr_ptr)).valid <= '0';

            wr_ptr <= wr_ptr + 1;
          end if;

          -- WB
          if i_wb_valid = '1' then
            wb_addr := to_integer(unsigned(i_wb_addr));
            rob_buf(wb_addr).result <= i_wb_result;
            rob_buf(wb_addr).valid <= '1';
          end if;

          -- Commit
          if commit = '1' then
            rob_buf(to_integer(rd_ptr)).busy <= '0';
            rd_ptr <= rd_ptr + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  commit <= rob_buf(to_integer(rd_ptr)).valid and rob_buf(to_integer(rd_ptr)).busy;

  -- Check if RD = RS
  -- If 1 hit -> foward
  -- If multiple hits -> foward latest
  -- in any case: if hit but not valid, do not foward

  -- Strategy: create a bit vector of hits, and with it's respective "valid" and "busy" bit
  --           Send bit vector through a shifted priority encoder depending on rd_ptr to select the latest
  disp_rs(1).reg_addr <= i_disp_rs1;
  disp_rs(2).reg_addr <= i_disp_rs2;

  g_rob_buf_foward:
  for k in 1 to 2 generate
    b_rob_buf_foward_rs:
    block
      signal rs               : std_logic_vector(REG_LEN-1 downto 0);  -- register source addr
      signal hit              : std_logic_vector(ROB_SIZE-1 downto 0); -- hit vector
      signal rhit             : std_logic_vector(ROB_SIZE-1 downto 0); -- rotated hit vector
      signal rhit_masked      : std_logic_vector(ROB_SIZE-1 downto 0); -- rotated hit vector
      signal rob_buf_fwd_addr : unsigned(ROB_LEN-1 downto 0); -- Latest entry in the rob
    begin
      rs <= disp_rs(k).reg_addr;

      g_rob_buf_hit:
      for i in 0 to ROB_SIZE-1 generate
        hit(i) <= rob_buf(i).busy when rob_buf(i).rd = rs else '0';
      end generate;

      rhit <= hit ror to_integer(rd_ptr);
      rhit_masked <= rhit and one_hot_encoder(priority_encoder(rhit));
      rob_buf_fwd_addr <= unsigned(one_hot_decoder(rhit_masked)) rol to_integer(rd_ptr);

      disp_rs(k).rob_rdy  <= rob_buf(to_integer(rob_buf_fwd_addr)).valid and (or hit);
      disp_rs(k).rob_data <= rob_buf(to_integer(rob_buf_fwd_addr)).result;
      disp_rs(k).rob_addr <= std_logic_vector(rob_buf_fwd_addr);
    end block;
  end generate;

  ---
  -- CONTROL
  ---
  g_rob_flags:
  for i in 0 to ROB_SIZE-1 generate
    busy_flag(i) <= rob_buf(i).busy;
  end generate;

  full <= and busy_flag;
  empty <= nor busy_flag;

  ---
  -- OUTPUT
  ---
  o_disp_qr <= std_logic_vector(wr_ptr);

  o_full <= full;
  o_empty <= empty;

  o_reg_commit <= commit;
  o_reg_qr     <= std_logic_vector(rd_ptr);
  o_reg_rd     <= rob_buf(to_integer(rd_ptr)).rd;
  o_reg_result <= rob_buf(to_integer(rd_ptr)).result;

  o_disp_rj <= disp_rs(1).rob_rdy;
  o_disp_vj <= disp_rs(1).rob_data;
  o_disp_qj <= disp_rs(1).rob_addr;

  o_disp_rk <= disp_rs(2).rob_rdy;
  o_disp_vk <= disp_rs(2).rob_data;
  o_disp_qk <= disp_rs(2).rob_addr;

end architecture;
