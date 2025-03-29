library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library riscv;
use riscv.RV32I.all;

entity exb is
  generic (
    EXB_LEN : natural;
    ROB_LEN : natural;
    XLEN : natural
  );
  port (
    clk_i : in std_logic;
    rst_i : in std_logic;

    -- Dispatch interface
    op_i  : in std_logic_vector(5 downto 0);
    f7_i  : in std_logic_vector(6 downto 0);
    f3_i  : in std_logic_vector(2 downto 0);
    imm_i : in  std_logic_vector(XLEN-1 downto 0);
    qr_i  : in std_logic_vector(ROB_LEN-1 downto 0);
    pc_i  : in std_logic_vector(XLEN-1 downto 0);
    wei_i : in  std_logic;

    -- Register interface
    reg_vj_i : in std_logic_vector(XLEN-1 downto 0);
    reg_qj_i : in std_logic_vector(ROB_LEN-1 downto 0);
    reg_rj_i : in std_logic;

    reg_vk_i : in std_logic_vector(XLEN-1 downto 0);
    reg_qk_i : in std_logic_vector(ROB_LEN-1 downto 0);
    reg_rk_i : in std_logic;

    -- CDB Interface

    -- Rob interface
    rob_vj_i : in std_logic_vector(XLEN-1 downto 0);
    rob_rj_i : in std_logic;

    rob_vk_i : in std_logic_vector(XLEN-1 downto 0);
    rob_rk_i : in std_logic;

    -- Issue interface
    exu_rdy_i : in std_logic;
    issue_o   : out std_logic;
    vj_o      : out std_logic_vector(XLEN-1 downto 0);
    vk_o      : out std_logic_vector(XLEN-1 downto 0);
    qr_o      : out std_logic_vector(ROB_LEN-1 downto 0);

    rob_o : out std_logic; -- Result goes to REORDER BUFFER
    bru_o : out std_logic; -- Result goes to BRANCH UNIT
    stb_o : out std_logic; -- Result goes to STORE BUFFER
    ldb_o : out std_logic; -- Result goes to LOAD_BUFFER

    -- Control interface
    full_o : out std_logic -- EXB is FULL
  );
end entity;

architecture rtl of exb is

  type exb_dest_t is (ROB, BRU, STB, LDB); -- Reorder Buffer, Branch Unit, Store Buffer, Load Buffer

  type exb_data_t is record
    f7 : std_logic_vector(6 downto 0);
    f3 : std_logic_vector(2 downto 0);                 -- Combined F7 & F3
    vj, vk : std_logic_vector(XLEN-1 downto 0);         -- Operands J and K
    qj, qk, qr : std_logic_vector(ROB_LEN-1 downto 0);  -- Src of J, K, and destination R
    rj, rk : std_logic;                                 -- Ready flags for J & K
    dest : exb_dest_t;
    busy : std_logic;                                   -- Entry busy
  end record;

  signal exb_entry : exb_data_t;

  type exb_t is array (natural range <>) of exb_data_t;

  signal exb : exb_t(0 to 2**EXB_LEN-1);

  signal exb_wp : unsigned(EXB_LEN-1 downto 0);
  signal exb_rp : unsigned(EXB_LEN-1 downto 0);

  signal exb_we : std_logic;
  signal exb_re : std_logic;

  signal exb_hit : std_logic;

  signal full : std_logic;


begin

  exb_we <= wei_i and not full;

  -- EXB Write pointer
  p_exb_wp:
  process(clk_i, rst_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '0' then
        exb_wp <= (others => '0');
      else
        if exb_we = '1' then
          exb_wp <= exb_wp + 1;
        end if;

        if exb_re = '1' then
          exb_wp <= exb_wp - 1;
        end if;
      end if;
    end if;
  end process;

  -- EXB Entry creation

  --when OP_IMM =>
  --  f3 := f3_i;
  --  if f3_i = FUNCT3_SR or f3_i = FUNCT3_SL then
  --    f7 := f7_i;
  --  end if;

  --when OP_OP =>
  --  f7 := f7_i;
  --  f3 := f3_i;

  --when OP_BRANCH =>
  --    case f3_i is
  --      when FUNCT3_BEQ | FUNCT3_BNE =>
  --        f7 := FUNCT7_SUB;
  --        f3 := FUNCT3_ADDSUB;
  --      when FUNCT3_BLT | FUNCT3_BGE =>
  --        f3 := FUNCT3_SLT;
  --      when FUNCT3_BLTU | FUNCT3_BGEU =>
  --        f3 := FUNCT3_SLTU;
  --    end case;
  --  when others =>
  --end case;

  ----- J Operand src
  --case op_i is
  --  when OP_AUIPC =>
  --    vj := pc_i;
  --    rj := '1';
  --  when others =>
  --    if rob_rj_i = '1' then
  --      vj := rob_vj_i;
  --    elsif reg_rj_i = '1' then
  --      vj := reg_vj_i;
  --    end if;
  --end case;

  ---- When ITYPE, comes from IMM
  --case op_i is
  --  when OP_IMM | OP_LOAD | OP_STORE | OP_AUIPC =>
  --    rk := '1';
  --    vk := imm_i;
  --  when others =>
  --    if rob_rk_i = '1' then
  --      vk := rob_vk_i;
  --    elsif reg_rk_i = '1' then
  --      vk := reg_vk_i;
  --    end if;
  --end case;

  -- FIXME: Nouvelle entrée:
  -- F3 & F7: Vient de l'instruction, où est généré si : LOAD/STORE, BRANCH, AUIPC, LUI, (reste a dererminer)
  -- Vj, Vk:
  -- Qj, Qk : Provenance de la donnée, peut venir de : ROB ou LOAD, mais comme load -> ROB seulement ROB
  -- Qr: Destination de la donnée : peut aller dans ROB, BRU, STB ou LDB en fonction de DEST
  -- dest: Détermine QR fait reference à quelle unité

  --exb_entry.f3 <=
  --exb_entry.f7 <=

  --exb_entry.qj <= reg_qj_i;
  --exb_entry.vj <=
  --exb_entry.rj <= reg_rj_i or rob_rj_i;

  --exb_entry.qk <= reg_qk_i;
  --exb_entry.vk <=
  --exb_entry.rk <= reg_rk_i or rob_rk_i;

  --exb_entry.qr <= qr_i;

  --with op_i select
  --  exb_entry.dest <= BRU when OP_BRANCH,
  --                    STB when OP_STORE,
  --                    LDB when OP_LOAD,
  --                    ROB when others;

  --exb_entry.busy <= '1';


  -- EXB Memory/Shift register
  -- TODO: Write back values from rob, value bypass in the shift reg if QJ/QK match and shifting
  p_exb_mem:
  process(clk_i, rst_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '0' then
        for i in 0 to 2**EXB_LEN-1 loop
          exb(i).busy <= '0';
        end loop;
      else
        if exb_we = '1' then
          exb(to_integer(exb_wp)) <= exb_entry;
        end if;

        if exb_re = '1' then
          for i in 0 to 2**EXB_LEN-2 loop
            exb(i) <= exb(i+1);
          end loop;
          exb(2**EXB_LEN-1).busy <= '0';
        end if;
      end if;
    end if;
  end process;

  -- EXB Read pointer
  p_exb_rp:
  process(all)
  begin
    exb_hit <= '0';
    exb_rp <= (others => '0');
    for i in 2**EXB_LEN-1 to 0 loop
      if exb(i).busy = '1' and exb(i).rj = '1' and exb(i).rk = '1' then
        exb_rp <= to_unsigned(i, exb_rp'length);
        exb_hit <= '1';
      end if;
    end loop;
  end process;

  exb_re <= exb_hit and exu_rdy_i;

  -- Outputs


  -- NOTE: Maybe will need a register at output...
  vj_o <= exb(to_integer(exb_rp)).vj;
  vk_o <= exb(to_integer(exb_rp)).vk;
  qr_o <= exb(to_integer(exb_rp)).qr;

  issue_o <= exb_re;

  -- full
  p_full:
  process(all)
    variable full : std_logic;
  begin
    full := '1';
    for i in 0 to 2**EXB_LEN-1 loop
      full := full and exb(i).busy;
    end loop;
    full_o <= full;
  end process;

  rob_o <= '1' when exb(to_integer(exb_rp)).dest = ROB else '0';
  bru_o <= '1' when exb(to_integer(exb_rp)).dest = BRU else '0';
  stb_o <= '1' when exb(to_integer(exb_rp)).dest = STB else '0';
  ldb_o <= '1' when exb(to_integer(exb_rp)).dest = LDB else '0';

end architecture;
