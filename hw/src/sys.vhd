library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library riscv;
use riscv.RV32I.all;

entity sys is
  generic(
    RST_LEVEL : std_logic := '0';
    XLEN      : natural
  );
  port (
    i_clk         : in  std_logic;                        --! System clock
    i_srst        : in  std_logic;                        --! Synchronous reset
    i_arst        : in  std_logic;                        --! Asynchronous reset

    i_disp_valid  : in  std_logic;                        --! Valid dispatch
    i_disp_op     : in  std_logic_vector(4 downto 0);     --! Dispatched OPCODE
    i_disp_f12    : in  std_logic_vector(11 downto 0);    --! Dispacthec FUNCT12

    i_en          : in  std_logic;                        --! Enable program counter
    i_restart     : in  std_logic;                        --! Restart a halted system in debug mode
    i_full        : in  std_logic;                        --! Full information about the different unit
    i_empty       : in  std_logic;                        --! Empty information about the different units

    o_stall       : out std_logic;                        --! PC is stalled
    o_halt        : out std_logic;                        --! System is halted
    o_debug       : out std_logic;                        --! System is in debug mode
    o_pc          : out std_logic_vector(XLEN-1 downto 0) --! Current program counter address
  );
end entity;

architecture rtl of sys is

  signal pc       : unsigned(o_pc'range);
  signal pc_stall : std_logic;

  signal ebreak   : std_logic;
  signal ecall    : std_logic;

  signal debug    : std_logic;
  signal service  : std_logic;

  signal halt     : std_logic;

begin

  ---
  -- INPUT
  ---
  halt <= i_empty and not i_en;

  ebreak <= '1' when i_disp_valid = '1' and i_disp_op = OP_SYSTEM and i_disp_f12 = FUNCT12_EBREAK else '0';

  ecall <= '1' when i_disp_valid = '1' and i_disp_op = OP_SYSTEM and i_disp_f12 = FUNCT12_ECALL else '0';

  ---
  -- EBREAK
  --
  -- Needs the ZiCSR to have more use
  -- In this implementation, it stalls the pipeline until it's done and
  -- halts the CPU with the debug flag. The CPU can be restarted by toggling the i_restart
  ---
  p_debug:
  process(i_clk, i_arst)
  begin
    if i_arst = RST_LEVEL then
      debug <= '0';
    elsif rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        debug <= '0';
      else
        if ebreak = '1' then
          debug <= '1';
        end if;

        if i_restart = '1' then
          debug <= '0';
        end if;
      end if;
    end if;
  end process;



  ---
  -- ECALL
  --
  -- Needs the extension ZiCSR to be of any use
  -- In this implementation, it simply halts the CPU in non-debug mode when the pipeline is off
  -- To restart the CPU a hard reset is needed
  ---
  p_ecall:
  process(i_clk, i_arst)
  begin
    if i_arst = RST_LEVEL then
      service <= '0';
    elsif rising_edge(i_clk) then
      if i_srst = '1' then
        service <= '0';
      elsif ecall = '1' then
        service <= '1';
      end if;
    end if;
  end process;


  ---
  -- PC Logic
  ---
  pc_stall <= debug or service or i_full or (not i_en);

  p_pc:
  process(i_clk, i_arst)
  begin
    if i_arst = RST_LEVEL then
      pc <= (others => '0');
    elsif rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        pc <= (others => '0');
      elsif pc_stall = '0' then
        pc <= pc + 4;
      end if;
    end if;
  end process;

  ---
  -- OUTPUT
  ---
  o_pc <= std_logic_vector(pc);

  o_stall <= pc_stall;
  o_debug <= debug and halt;
  o_halt  <= halt;


end architecture;
