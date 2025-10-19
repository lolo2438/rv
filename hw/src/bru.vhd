---
--
--
--
--
--
--
-- ROLE:
-- Hold speculative branch table
-- Return address stack
-- Detect speculative error
--
--
-- JAL:
-- IF OP = JAL & RD = X1/X5
--  RAS.PUSH PC+4
--  BRANCH = '1', Speculative = '0'
--
-- JALR:
-- 1. if OP = JALR:
--    RS1=X1/X5 -> POP
--    RD =X1/X5 -> PUSH
--    RS1 & RD = X1/X5 & rd!=rs1 -> pop -> push
--    RS1 & RD = X1/X5 & rd=rs1 -> push
-- 2. Place target PC in BRU and mark as speculative.
-- 3. When RS1 + OFFSET comes back, verify if it was speculative or nah
--
-- BRANCH:
-- 1. Depending on the F3, select the expected result
-- 2. Use branch detector predictor to select specify that we are in a speculative state
-- 3.
library ieee;
use ieee.std_logic_1164.all;

library riscv;
use riscv.RV32I.all;

library hw;

entity bru is
  generic(
    RAS_SIZE  : natural;
    TAG_LEN   : natural;
    REG_LEN   : natural;
    XLEN      : natural
  );
  port(
    -- CTRL I/F
    i_clk           : in std_logic;
    i_srst          : in std_logic;
    i_arst          : in std_logic;

    o_ras_empty     : out std_logic;
    o_ras_full      : out std_logic;

    o_bru_full      : out std_logic;
    o_bru_empty     : out std_logic;

    -- DISPATCH I/F
    i_disp_valid    : in std_logic;
    i_disp_op       : in std_logic_vector(4 downto 0);
    i_disp_f3       : in std_logic_vector(2 downto 0);
    i_disp_rs1      : in std_logic_vector(REG_LEN-1 downto 0);
    i_disp_rd       : in std_logic_vector(REG_LEN-1 downto 0);

    i_disp_rj       : in std_logic;
    i_disp_vj       : in std_logic_vector(XLEN-1 downto 0);
    i_disp_tj       : in std_logic_vector(TAG_LEN-1 downto 0);

    i_disp_rk       : in std_logic;
    i_disp_vk       : in std_logic_vector(XLEN-1 downto 0);
    i_disp_tk       : in std_logic_vector(TAG_LEN-1 downto 0);

    o_disp_tq       : out std_logic_vector(TAG_LEN-1 downto 0);

    --
    i_next_pc       : in std_logic;
    o_branch        : out std_logic;
    o_spec          : out std_logic;
    o_pc            : out std_logic_vector(XLEN-1 downto 0);

    -- CDBR I/F
    i_cdbr_rq       : in std_logic;
    i_cdbr_vq       : in std_logic_vector(XLEN-1 downto 0);
    i_cdbr_tq       : in std_logic_vector(TAG_LEN-1 downto 0)
  );
end entity;

architecture rtl of bru is

  type BRU_T is record
    fallback_pc : std_logic;
    exp_result  : std_logic;
  end record;

  signal bru_buf : BRU_T;

  -- PREDICTORS
  --signal 2bit_pred : std_logic_vector(1 downto 0);
  --signal loop_pred : std_logic;

  type RAS_T is record
    din   : std_logic_vector(XLEN-1 downto 0);
    dout  : std_logic_vector(XLEN-1 downto 0);
    push  : std_logic;
    pop   : std_logic;
    full  : std_logic;
    empty : std_logic;
  end record;

  signal ras : RAS_T;

begin

  -- Inputs
  -- CDB:     TAG + Result, will be able to tell if branch successful
  -- DISPATCH:
  --  BRANCH,
  --  JALR

  -- LOGIC

  -- BRU_BUF
  p_bru_buf:
  process(i_clk)
  begin
    if rising_edge(i_clk) then
    end if;
  end process;

  -- PREDICTORS
  ras.pop <= '1' when i_disp_op = OP_JALR and (i_disp_rs1 = REG_X01 or i_disp_rs1 = REG_X05) and (i_disp_rs1 /= i_disp_rd) else
             '0';

  ras.push <= '1' when i_disp_op = OP_JALR and (i_disp_rd = REG_X01 or i_disp_rd = REG_X05) and (i_disp_rs1 = i_disp_rd) else
              '1' when i_disp_op = OP_JAL else
              '0';

  -- RETURN ADDRESS STACK
  -- TODO: ras.din, ras.dout
  u_ras:
  entity hw.stack
  generic map(
    DATA_WIDTH => XLEN,
    STACK_SIZE => RAS_SIZE
  )
  port map(
    i_clk   => i_clk,
    i_srst  => i_srst,
    i_data  => ras.din,
    i_push  => ras.push,
    i_pop   => ras.pop,
    o_full  => ras.full,
    o_empty => ras.empty,
    o_data  => ras.dout
  );

  -- Outputs
  --
  -- SYSTEM
  -- PC to jump to
  -- stall if can't do anything
  -- speculative flag: information if the operation is speculative
  -- Rollback

  o_ras_full <= ras.full;
  o_ras_empty <= ras.empty;

end architecture;
