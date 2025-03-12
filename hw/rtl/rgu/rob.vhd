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

    -- Dispatch I/F
    i_disp_valid    : in std_logic;
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

  signal rob : rob_buf_t;

  signal wr_ptr : natural range 0 to ROB_SIZE-1;
  signal rd_ptr : natural range 0 to ROB_SIZE-1;
  signal full   : std_logic;

  signal commit : std_logic;

  signal disp : std_logic;

begin

  disp <= i_disp_rob and i_disp_valid;
  ---
  -- DATAPATH
  ---

  p_rob_buf:
  process(i_clk)
    variable wb_addr : natural;
  begin
    if i_arst = RST_LEVEL then
      for i in 0 to ROB_SIZE-1 loop
        rob(i).busy <= '0';
      end loop;
      wr_ptr <= 0;
      rd_ptr <= 0;

    elsif rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        for i in 0 to ROB_SIZE-1 loop
          rob(i).busy <= '0';
        end loop;
        wr_ptr <= 0;
        rd_ptr <= 0;
      else
        if i_flush = '1' then
          for i in 0 to ROB_SIZE-1 loop
            rob(i).busy <= '0';
          end loop;
          wr_ptr <= 0;
          rd_ptr <= 0;
        else
          -- Dispatch
          if disp = '1' and full = '0' then
            rob(wr_ptr).rd <= i_disp_rd;
            rob(wr_ptr).busy <= '1';
            rob(wr_ptr).valid <= '0';
            wr_ptr <= wr_ptr + 1;
          end if;

          -- WB
          if i_wb_valid = '1' then
            wb_addr := to_integer(unsigned(i_wb_addr));
            rob(wb_addr).result <= i_wb_result;
            rob(wb_addr).valid <= '1';
          end if;

          -- Commit
          if commit = '1' then
            rob(rd_ptr).busy <= '0';
            rd_ptr <= rd_ptr + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  commit <= rob(rd_ptr).valid;

  -- Check if RD = RS
  -- If 1 hit -> foward
  -- If multiple hits -> foward latest
  -- in any case: if hit but not valid, do not foward

  -- Strategy: create a bit vector of hits, and with it's respective "valid" and "busy" bit
  --           Send bit vector through a shifted priority encoder depending on rd and select the latest
  disp_rs(1).reg_addr <= i_disp_rs1;
  disp_rs(2).reg_addr <= i_disp_rs2;

  g_rob_foward:
  for i in 1 to 2 generate
    b_rob_foward_rs:
    block
      signal rs : std_logic_vector(REG_LEN-1 downto 0);   -- register source addr
      signal hit : std_logic_vector(ROB_LEN-1 downto 0);  -- hit vector
      signal rhit : std_logic_vector(ROB_LEN-1 downto 0); -- rotated hit vector
      signal rob_fwd_addr : natural range 0 to ROB_SIZE-1;
    begin
      rs <= disp_rs(i).reg_addr;

      p_rob_hit:
      process(all)
      begin
        for i in 0 to ROB_SIZE-1 loop
          if rob(i).busy = '1' and rob(i).valid = '1' and rob(i).rd = rs then
            hit(i) <= '1';
          else
            hit(i) <= '0';
          end if;
        end loop;
      end process;

      rhit <= hit ror rd_ptr;

      p_prio_enc:
      process(all)
      begin
        rob_fwd_addr <= 0;
        for i in 0 to ROB_SIZE-1 loop
          if rhit(i) = '1' then
            rob_fwd_addr <= i + rd_ptr;
          end if;
        end loop;
      end process;

      disp_rs(i).rob_rdy  <= or hit;
      disp_rs(i).rob_data <= rob(rob_fwd_addr).result;
      disp_rs(i).rob_addr <= std_logic_vector(to_unsigned(rob_fwd_addr,ROB_LEN));
    end block;
  end generate;

  ---
  -- CONTROL
  ---

  p_rob_full:
  process(all)
    variable vfull : std_logic := '1';
  begin
    for i in 0 to ROB_SIZE-1 loop
      vfull := vfull and rob(i).busy;
    end loop;
    full <= full;
  end process;

  ---
  -- OUTPUT
  ---
  o_disp_qr <= std_logic_vector(to_unsigned(wr_ptr, o_disp_qr'length));

  o_full <= full;

  o_reg_commit <= commit;
  o_reg_rd     <= rob(rd_ptr).rd;
  o_reg_result <= rob(rd_ptr).result;

  o_disp_rj <= disp_rs(1).rob_rdy;
  o_disp_vj <= disp_rs(1).rob_data;
  o_disp_qj <= disp_rs(1).rob_addr;

  o_disp_rk <= disp_rs(2).rob_rdy;
  o_disp_vk <= disp_rs(2).rob_data;
  o_disp_qk <= disp_rs(2).rob_addr;

end architecture;
