library ieee;
use ieee.std_logic_1164.all;

library hw;

entity exu is
  generic(
    RST_LEVEL   : std_logic := '0';
    EXB_LEN     : natural;
    TAG_LEN     : natural;
    XLEN        : natural
  );
  port(
    -- CONTROL I/F
    i_clk         : in  std_logic;
    i_srst        : in  std_logic;
    i_arst        : in  std_logic;
    o_exu_full    : out std_logic;
    o_exu_empty   : out std_logic;

    -- DISPATCH I/F
    i_disp_valid  : in  std_logic;
    i_disp_op     : in  std_logic_vector(4 downto 0);
    i_disp_f3     : in  std_logic_vector(2 downto 0);
    i_disp_f7     : in  std_logic_vector(6 downto 0);
    i_disp_vj     : in  std_logic_vector(XLEN-1 downto 0);
    i_disp_tj     : in  std_logic_vector(TAG_LEN-1 downto 0);
    i_disp_rj     : in  std_logic;
    i_disp_vk     : in  std_logic_vector(XLEN-1 downto 0);
    i_disp_tk     : in  std_logic_vector(TAG_LEN-1 downto 0);
    i_disp_rk     : in  std_logic;
    i_disp_tq     : in  std_logic_vector(TAG_LEN-1 downto 0);

    -- CDB WR I/F
    o_cdbw_vq     : out std_logic_vector(XLEN-1 downto 0);      --! Data to write on the bus
    o_cdbw_tq     : out std_logic_vector(TAG_LEN-1 downto 0);   --! Tag to write on the CDB bus
    o_cdbw_req    : out std_logic;                              --! Request to the CDB bus
    o_cdbw_lh     : out std_logic;                              --! Look Ahead flag indicates that there are at least 2 values that are ready
    i_cdbw_ack    : in  std_logic;                              --! Acknowledge from the CDB bus

    -- CDB WB I/F
    i_cdbr_vq     : in  std_logic_vector(XLEN-1 downto 0);
    i_cdbr_tq     : in  std_logic_vector(TAG_LEN-1 downto 0);
    i_cdbr_rq     : in  std_logic
  );
end entity;


architecture rtl of exu is

  -- CTRL
  signal exb_full  : std_logic;
  signal exb_empty : std_logic;
  signal exec_rdy  : std_logic;

  -- ISSUE
  signal issue_vj     : std_logic_vector(XLEN-1 downto 0);
  signal issue_vk     : std_logic_vector(XLEN-1 downto 0);
  signal issue_f3     : std_logic_vector(2 downto 0);
  signal issue_f7     : std_logic_vector(6 downto 0);
  signal issue_tq     : std_logic_vector(TAG_LEN-1 downto 0);
  signal issue_valid  : std_logic;

  signal exec_result  : std_logic_vector(XLEN-1 downto 0);
  signal exec_tq      : std_logic_vector(TAG_LEN-1 downto 0);
  signal exec_done    : std_logic;

  signal cdbw_req   : std_logic;
  signal cdbw_tq    : std_logic_vector(TAG_LEN-1 downto 0);
  signal cdbw_vq    : std_logic_vector(XLEN-1 downto 0);
  signal cdbw_lh    : std_logic;

begin

  ---
  -- INPUT
  ---
  -- FIXME: because exec_rdy = '0', exec_done can't be pipelined since issue_valid = 0
  exec_rdy <= not (cdbw_req and i_cdbw_ack and exec_done);

  --rad|e
  --000|1
  --001|1
  --010|1
  --011|1
  --100|1
  --101|0
  --110|1
  --111|1

  ---
  -- LOGIC
  ---
  u_exb:
  entity hw.exb
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
    o_empty     => exb_empty,
    i_disp_we   => i_disp_valid,
    i_disp_op   => i_disp_op,
    i_disp_f3   => i_disp_f3,
    i_disp_f7   => i_disp_f7,
    i_disp_vj   => i_disp_vj,
    i_disp_tj   => i_disp_tj,
    i_disp_rj   => i_disp_rj,
    i_disp_vk   => i_disp_vk,
    i_disp_tk   => i_disp_tk,
    i_disp_rk   => i_disp_rk,
    i_disp_tq   => i_disp_tq,
    i_issue_rdy => exec_rdy,
    o_issue_vj  => issue_vj,
    o_issue_vk  => issue_vk,
    o_issue_f3  => issue_f3,
    o_issue_f7  => issue_f7,
    o_issue_tq  => issue_tq,
    o_issue_we  => issue_valid,
    i_cdbr_rq    => i_cdbr_rq,
    i_cdbr_tq    => i_cdbr_tq,
    i_cdbr_vq    => i_cdbr_vq
  );


  u_alu:
  entity hw.alu
  generic map(
    TAG_LEN => TAG_LEN,
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


  p_cdbw_handler:
  process(i_clk)
  begin
    if rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        cdbw_req <= '0';
      else
        if cdbw_req = '0' then
          if exec_done = '1' then
            cdbw_req <= '1';
          end if;

        elsif cdbw_req = '1' then
          if i_cdbw_ack = '1' then
            cdbw_vq <= exec_result;
            cdbw_tq <= exec_tq;

            if exec_done = '0' then
              cdbw_req <= '0';
            end if;
          end if;

        end if;
      end if;
    end if;
  end process;

  cdbw_lh <= exec_done and cdbw_req;

  ---
  -- OUTPUT
  ---
  o_exu_full  <= exb_full;
  o_exu_empty <= exb_empty;

  o_cdbw_vq   <= cdbw_vq;
  o_cdbw_tq   <= cdbw_tq;
  o_cdbw_req  <= cdbw_req;
  o_cdbw_lh   <= cdbw_lh;

end architecture;
