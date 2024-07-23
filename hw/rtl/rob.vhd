library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity rob is
  generic (
    REG_LEN : natural;
    ROB_LEN : natural;
    XLEN    : natural
  );
  port (
    clk_i : in std_logic;
    rst_i : in std_logic;

    -- ISSUE
    wei_i : in  std_logic;                             -- Write Enable Issue
    rd_i  : in  std_logic_vector(REG_LEN-1 downto 0);  -- Reg Destination Address
    qr_o  : out std_logic_vector(ROB_LEN-1 downto 0);  -- Rob Entry of issued instruction

    -- CDB
    wres_i : in std_logic;                            -- Write enable for result
    qr_i   : in std_logic_vector(ROB_LEN-1 downto 0); -- Rob address of result
    res_i  : in std_logic_vector(XLEN-1 downto 0);    -- Result from execution units

    -- FOWARD
    qj_i : in std_logic_vector;                       -- Rob address looking to foward
    vj_o : out std_logic_vector(XLEN-1 downto 0);     -- Value stored at that address
    rj_o : out std_logic;                             -- Flag indicating value is ready

    qk_i : in std_logic_vector;                       -- Rob address looking to foward
    vk_o : out std_logic_vector(XLEN-1 downto 0);     -- Value stored at that address
    rk_o : out std_logic;                             -- Flag indicating value is ready

    -- REG
    wer_o  : out std_logic;                            -- Write Enable Register
    wr_o   : out std_logic_vector(REG_LEN-1 downto 0); -- Write Register address
    res_o  : out std_logic_vector(XLEN-1 downto 0);    -- Result to write in registers

    -- Status
    --flush_i : std_logic; -- Flush speculative instructions
    full_o : out std_logic  -- Rob is full
  );
end entity;

architecture rtl of rob is

  -- Types

  type rob_data_t is record
    res  : std_logic_vector(XLEN-1 downto 0);    -- DATA to be stored in reg
    rd   : std_logic_vector(REG_LEN-1 downto 0); -- Reg address
    done : std_logic;                            -- Done flag
  end record;

  type rob_t is array (0 to 2**ROB_LEN-1) of rob_data_t;

  -- Constants

  -- Signals
  signal rob : rob_t;

  signal commit_ptr : unsigned(ROB_LEN-1 downto 0);

  signal wer : std_logic;

  signal issue_ptr  : unsigned(ROB_LEN-1 downto 0);
  signal next_issue_ptr : unsigned(issue_ptr'range);

  signal full : std_logic;

begin

  next_issue_ptr <= issue_ptr + 1;
  wer <= rob(to_integer(commit_ptr)).done;

  p_rob:
  process(clk_i, rst_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '0' then
        commit_ptr <= (others => '0');
        issue_ptr <= (others => '0');

        full <= '0';
        for i in 0 to 2**ROB_LEN-1 loop
          rob(i).done <= '0';
        end loop;

      else

        -- Issue
        if wei_i = '1' and full = '0' then
          rob(to_integer(issue_ptr)).rd <= rd_i;
          issue_ptr <= next_issue_ptr;

          if (next_issue_ptr = commit_ptr) then
            full <= '1';
          end if;
        end if;

        -- CDB
        if wres_i = '1' then
          rob(to_integer(unsigned(qr_i))).res <= res_i;
          rob(to_integer(unsigned(qr_i))).done <= '1';
        end if;

        -- REG
        if wer = '1' then
          commit_ptr <= commit_ptr + 1;
          full <= '0';
        end if;
      end if;
    end if;
  end process;

  -- TODO
  --p_j_foward:
  --process(qj_i)
  --begin
  --  for i in 0 to 2**ROBLEN-1 loop
  --  end loop;
  --end process;


  qr_o <= std_logic_vector(issue_ptr);

  wer_o <= wer;
  wr_o <= rob(to_integer(commit_ptr)).rd;
  res_o <= rob(to_integer(commit_ptr)).res;

  full_o <= full;

end architecture;
