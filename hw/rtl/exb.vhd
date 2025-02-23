library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vex;
use vex.common_pkg.all;

entity exb is
  generic(
    RST_LEVEL : std_logic := '0'; -- Reset level
    EXB_LEN   : natural;          -- Length of the address of the exb, the size of the EXP = 2**EXB_LEN
    TAG_LEN   : natural;          -- Length of the tag
    XLEN      : natural           -- Bit width of the operands
  );
  port(
    -- Control ports
    i_clk     : in  std_logic;
    i_arst    : in  std_logic;
    i_srst    : in  std_logic;
    o_full    : out std_logic;
    o_empty   : out std_logic;

    -- Dispatch bus interface
    i_disp_we    : in std_logic;                              --! Dispatch write enable
    i_disp_f3    : in std_logic_vector(2 downto 0);           --! Dispatch F3
    i_disp_f7    : in std_logic_vector(6 downto 0);           --! Dispatch F7

    i_disp_vj    : in std_logic_vector(XLEN-1 downto 0);      --! Dispatch J operand value
    i_disp_tj    : in std_logic_vector(TAG_LEN-1 downto 0);   --! Dispatch J operand tag
    i_disp_rj    : in std_logic;                              --! Dispatch J operand readyness

    i_disp_vk    : in std_logic_vector(XLEN-1 downto 0);      --! Disparch k operand value
    i_disp_tk    : in std_logic_vector(TAG_LEN-1 downto 0);   --! Dispatch k operand tag
    i_disp_rk    : in std_logic;                              --! Dispatch k operand readyness

    i_disp_tq    : in std_logic_vector(TAG_LEN-1 downto 0);   --! Dispatch destination tag

    -- Issue bus interface
    i_issue_rdy  : in  std_logic;
    o_issue_vj   : out std_logic_vector(XLEN-1 downto 0);
    o_issue_vk   : out std_logic_vector(XLEN-1 downto 0);
    o_issue_f3   : out std_logic_vector(2 downto 0);
    o_issue_f7   : out std_logic_vector(6 downto 0);
    o_issue_tq   : out std_logic_vector(TAG_LEN-1 downto 0);
    o_issue_we   : out std_logic;

    -- CDB Foward interface
    i_cdb_we : in std_logic;
    i_cdb_tq : in std_logic_vector(TAG_LEN-1 downto 0);
    i_cdb_vq : in std_logic_vector(XLEN-1 downto 0)
  );
end entity;

architecture rtl of exb is

  constant EXB_SIZE : natural := 2**EXB_LEN;

  type exb_entry_t is record
    f7      : std_logic_vector(6 downto 0);          -- Operation f7 to execute
    f3      : std_logic_vector(2 downto 0);          --
    vj, vk  : std_logic_vector(XLEN-1 downto 0);     -- Operands J and K
    tj, tk  : std_logic_vector(TAG_LEN-1 downto 0);  -- Source tags
    tq      : std_logic_vector(TAG_LEN-1 downto 0);  -- Destination tag
    rj, rk  : std_logic;                             -- Ready flags for op J & K
    busy    : std_logic;                             -- Rob entry is busy
  end record;

  type exb_buf_t is array (0 to EXB_SIZE-1) of exb_entry_t;

  signal exb : exb_buf_t;
  signal exb_entry : exb_entry_t;

  signal wr_ptr : natural range 0 to EXB_SIZE-1;
  signal disp_ptr : std_logic_vector(EXB_LEN-1 downto 0);

  signal rd_ptr : natural range 0 to EXB_SIZE-1;
  signal issue_ptr : std_logic_vector(EXB_LEN-1 downto 0);

  signal op_rdy : std_logic_vector(EXB_LEN-1 downto 0);

  signal busy : std_logic_vector(EXB_SIZE-1 downto 0);

  signal disp_we : std_logic;
  signal issue_re : std_logic;
  signal full : std_logic;
  signal empty : std_logic;

  signal otm_re : std_logic;


begin

  u_otm : entity work.otm(rtl)
  generic map(
    RST_LEVEL => RST_LEVEL,
    ADDR_LEN => EXB_LEN
  )
  port map(
    i_clk       => i_clk,
    i_arst      => i_arst,
    i_srst      => i_srst,
    o_empty     => open,
    o_full      => open,
    i_we        => disp_we,
    i_re        => otm_re,
    i_wr_addr   => disp_ptr,
    i_rd_mask   => op_rdy,
    o_rd_addr   => issue_ptr,
    o_rd_valid  => issue_re
  );

  exb_entry.f7 <= i_disp_f7;
  exb_entry.f3 <= i_disp_f3;

  exb_entry.vj <= i_disp_vj;
  exb_entry.tj <= i_disp_tj;
  exb_entry.rj <= i_disp_rj;

  exb_entry.vk <= i_disp_vk;
  exb_entry.tk <= i_disp_tk;
  exb_entry.rk <= i_disp_rk;

  exb_entry.tq   <= i_disp_tq;
  exb_entry.busy <= '1';

  -- EXB

  disp_we <= not full and i_disp_we;
  disp_ptr <= priority_encoder(bit_reverse(busy));

  wr_ptr <= to_integer(unsigned(disp_ptr));

  p_exb:
  process(i_clk, i_arst)
  begin
    if i_arst = RST_LEVEL then
      for i in 0 to EXB_SIZE-1 loop
        exb(i).busy <= '0';
      end loop;
    elsif rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        for i in 0 to EXB_SIZE-1 loop
          exb(i).busy <= '0';
        end loop;
      else
        if issue_re = '1' then
          exb(rd_ptr).busy <= '0';
        end if;

        if disp_we = '1' then
          exb(wr_ptr) <= exb_entry;
        end if;

        if i_cdb_we = '1' then
          for i in 0 to EXB_SIZE-1 loop
            if exb(i).busy = '1' then
              if exb(i).rj = '0' and exb(i).tj = i_cdb_tq then
                exb(i).rj <= '1';
                exb(i).vj <= i_cdb_vq;
              end if;

              if exb(i).rk = '0' and exb(i).tk = i_cdb_tq then
                exb(i).rk <= '1';
                exb(i).vk <= i_cdb_vq;
              end if;
            end if;
          end loop;
        end if;

      end if;
    end if;
  end process;


  otm_re <= (not empty) and i_issue_rdy and (or op_rdy);

  rd_ptr <= to_integer(unsigned(issue_ptr));

  p_op_rdy:
  process(all)
  begin
    for i in 0 to EXB_SIZE-1 loop
      op_rdy(i) <= exb(i).rj and exb(i).rk and exb(i).busy;
    end loop;
  end process;

  p_busy:
  process(all)
  begin
    for i in 0 to EXB_SIZE-1 loop
      busy(i) <= exb(i).busy;
    end loop;
  end process;

  full <= and busy;

  empty <= nor busy;

  ---
  -- OUTPUTS
  ---
  o_empty <= empty;
  o_full <= full;

  o_issue_we <= issue_re;
  o_issue_vj <= exb(rd_ptr).vj;
  o_issue_vk <= exb(rd_ptr).vk;
  o_issue_f3 <= exb(rd_ptr).f3;
  o_issue_f7 <= exb(rd_ptr).f7;
  o_issue_tq <= exb(rd_ptr).tq;

end architecture;

