library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library riscv;
use riscv.RV32I.all;

entity exec_shed is
  generic (
    ULEN : natural; -- log2(NUM_ALU) : Addressable alus
    TLEN : natural; -- log2(TAG_SIZE): Addressable elements in the Execution BUFFER
    XLEN : natural
  );
  port (
    -- CTRL
    clk_i : in std_logic;
    rst_i : in std_logic;

    -- INPUTS
    inst_i      : in  std_logic_vector(31 downto 0);      -- Instruction, TODO change to µop
    vj_i        : in  std_logic_vector(XLEN-1 downto 0);  --
    tj_i        : in  std_logic_vector(TLEN-1 downto 0);  --
    tk_i        : in  std_logic_vector(TLEN-1 downto 0);  --
    vk_i        : in  std_logic_vector(XLEN-1 downto 0);  --
    rb_data_i   : in  std_logic_vector(XLEN-1 downto 0);  --
    rb_tag_i    : in  std_logic_vector(TLEN-1 downto 0);  --
    rb_we_i     : in  std_logic;                          --

    -- OUTPUTS
    valid_o     : out std_logic;                          -- []
    vj_o, vk_o  : out std_logic_vector(XLEN-1 downto 0);  -- []
    op_o        : out std_logic_vector(5 downto 0);       -- []
    f3_o        : out std_logic_vector(2 downto 0);       -- []
    f7_o        : out std_logic_vector(6 downto 0);       -- []
    tag_o       : out std_logic_vector(TLEN-1 downto 0);  -- []
    eu_sel_o    : out std_logic_vector(ULEN-1 downto 0);  -- []
    full_o      : out std_logic                           -- [x] '1' indicates that the exec buffer is full
  );
end entity;

architecture rtl of exec_shed is

  -- Execution buffer
  -- op, f3, f7: controls signals for operation type
  -- uj, uk : Rename registers src, 0 = data is READY, else waiting on an instruction
  -- vj, vk : value for operand j and k. vk can be a value from sign immediate or register.
  -- ui     : Renamed register for this instruction
  -- ut     : Flag to indicate to wich unit is this instruction destined
  -- busy   : Flag to indicate if the instruction is waiting for exec (1) or can be overwritten (0)
  type execution_buffer_reg_t is record
    -- TODO:
    -- Macro-op decoding -> micro-op, permet de faire des macro op fusions et augmenter throughput
    -- Pour le moment on garde ça en macro op decoding pour implémenter OOO, apres optimisations
    op      : std_logic_vector(6 downto 2);      -- OPCODE
    f3      : std_logic_vector(2 downto 0);      -- F3
    f7      : std_logic_vector(6 downto 0);      -- F7
    ti      : std_logic_vector(TLEN-1 downto 0); -- Tag of the operation, 0 = invalid
    tj, tk  : std_logic_vector(TLEN-1 downto 0); -- Tags of the operands, 0 = READY, else wait for tag from the result bus
    vj, vk  : std_logic_vector(XLEN-1 downto 0); -- Value of the operands
    b       : std_logic;                         -- Busy: 1 indicates that the instruction is reserved until completion.
  end record;

  type execution_buffer_t is array (0 to 2**TLEN-1) of execution_buffer_reg_t;

  signal eb : execution_buffer_t;

  signal eb_we : std_logic;
  signal eb_shed : std_logic_vector(TLEN-1 downto 0);
  signal eb_wptr : unsigned(TLEN-1 downto 0);
  signal eb_rptr : unsigned(TLEN-1 downto 0);

  signal inst_rdy : std_logic_vector(TLEN-1 downto 0);

begin

  -- Execution Buffer
  -- Stores instructions as
  p_exec_buf:
  process(clk_i)
    variable wptr : natural;
  begin
    if rising_edge(clk_i) then
      if rst_i = '0' then
        for i in 0 to 2**TLEN-1 loop
          eb(i).b <= '0';
        end loop;

      elsif eb_we = '1' then
        wptr := to_integer(eb_wptr);

        -- TODO: Add condition if rb writes back for performance
        if (eb(wptr).b = '0') then
          eb(wptr) <= (
            op => inst_i(INST32_OPCODE'range),
            f3 => inst_i(INST32_FUNCT3'range),
            f7 => inst_i(INST32_FUNCT7'range),
            ti => (others => '0'), -- FIXME: Value comes from sheduler
            tj => tj_i,
            tk => tk_i,
            vj => vj_i,
            vk => vk_i,
            b  => '1'
          );
        end if;
      --elsif check for RB for tj/tj and store vj/vk
      end if;
    end if;
  end process;

  g_inst_rdy:
  for i in 0 to 2**TLEN-1 generate
    inst_rdy(i) <= '1' when eb(i).b = '1' and unsigned(eb(i).tj) = 0 and unsigned(eb(i).tk) = 0 else '0';
  end generate;

  -- Execution sheduler: Shedules which instruction should be executed next cycle
  -- According to paper, does not matter what shed algorithme to choose.
  -- NOTE:
  -- use a LINEAR FEEDBACK SHIFT REGISTER for ALU selection

  p_exec_shed:
  process(clk_i)
  begin
    if rising_edge(clk_i) then
    end if;
  end process;


  p_full:
  process(eb)
    variable full : std_logic;
  begin
    full := '1';

    for i in 0 to 2**TLEN-1 loop
      full := full and eb(i).b;
    end loop;

    full_o <= full;
  end process;


end architecture;
