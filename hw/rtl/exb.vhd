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
    clk_i : std_logic;
    rst_i : std_logic;

    -- Dispatch interface
    op_i : std_logic_vector(5 downto 0);
    f7_i : std_logic_vector(6 downto 0);
    f3_i : std_logic_vector(2 downto 0);
    imm_i : std_logic_vector(XLEN-1 downto 0);
    qr_i : std_logic_vector(ROB_LEN-1 downto 0);
    pc_i : std_logic_vector(XLEN-1 downto 0);
    wei_i : std_logic;

    -- Register interface
    reg_vj_i : std_logic_vector(XLEN-1 downto 0);
    reg_qj_i : std_logic_vector(ROB_LEN-1 downto 0);
    reg_rj_i : std_logic;

    reg_vk_i : std_logic_vector(XLEN-1 downto 0);
    reg_qk_i : std_logic_vector(ROB_LEN-1 downto 0);
    reg_rk_i : std_logic;

    -- Rob interface
    rob_vj_i : std_logic_vector(XLEN-1 downto 0);
    rob_rj_i : std_logic;

    rob_vk_i : std_logic_vector(XLEN-1 downto 0);
    rob_rk_i : std_logic;

    -- Issue interface
    exu_rdy_i : std_logic;
    issue_o   : std_logic;
    vj_o      : std_logic_vector(XLEN-1 downto 0);
    vk_o      : std_logic_vector(XLEN-1 downto 0);
    qr_o      : std_logic_vector(ROB_LEN-1 downto 0);

    rob_o : std_logic; -- Result goes to REORDER BUFFER
    bru_o : std_logic; -- Result goes to BRANCH UNIT
    stb_o : std_logic; -- Result goes to STORE BUFFER
    ldb_o : std_logic; -- Result goes to LOAD_BUFFER

    -- Control interface
    full_o : std_logic -- EXB is FULL
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

  type exb_t is array (natural range <>) of exb_data_t;

  signal exb : exb_t(0 to 2**EXB_LEN-1);

  signal exb_issue_ptr : unsigned(EXB_LEN-1 downto 0);

  signal exb_store_ptr : unsigned(EXB_LEN-1 downto 0);

  signal full : std_logic;

begin

  p_exu:
  process(clk_i, rst_i)
    variable f7 : std_logic_vector(6 downto 0);
    variable f3 : std_logic_vector(2 downto 0);
    variable vj, vk : std_logic_vector(XLEN-1 downto 0);
    variable qj, qk, qr : std_logic_vector(ROB_LEN-1 downto 0);
    variable rj, rk : std_logic;
    variable dest : exb_dest_t;
  begin
    if rising_edge(clk_i) then
      -- Create new entry in ROB
      if wei_i = '1' and full = '0' then

        --- F7 & F3 : Operation selection
        -- Default: ADD
        f7 := (others => '0');
        f3 := (others => '0');
        -- OP : Depends on the F3 & F7
        -- IMM: if SR/SL include F7, else F3 = OP
        -- BRANCH : generate instruction according to branch type
        -- LOAD/STORE, JALR, LUI, AUIPC, JAL: ADD
        case op_i is
          when OP_IMM =>
            f3 := f3_i;
            if f3_i = FUNCT3_SR or f3_i = FUNCT3_SL then
              f7 := f7_i;
            end if;

          when OP_OP =>
            f7 := f7_i;
            f3 := f3_i;

          when OP_BRANCH =>
            case f3_i is
              when FUNCT3_BEQ | FUNCT3_BNE =>
                f7 := FUNCT7_SUB;
                f3 := FUNCT3_ADDSUB;
              when FUNCT3_BLT | FUNCT3_BGE =>
                f3 := FUNCT3_SLT;
              when FUNCT3_BLTU | FUNCT3_BGEU =>
                f3 := FUNCT3_SLTU;
            end case;
          when others =>
        end case;

        --- J Operand src
        rj := reg_rj_i or rob_rj_i;
        qj := reg_qj_i;
        case op_i is
          when OP_AUIPC =>
            vj := pc_i;
            rj := '1';
          when others =>
            if rob_rj_i = '1' then
              vj := rob_vj_i;
            elsif reg_rj_i = '1' then
              vj := reg_vj_i;
            end if;
        end case;

        --- K Operand source
        rk := reg_rk_i or rob_rk_i;
        qk := reg_qk_i;
        -- When ITYPE, comes from IMM
        case op_i is
          when OP_IMM | OP_LOAD | OP_STORE | OP_AUIPC =>
            rk := '1';
            vk := imm_i;
          when others =>
            if rob_rk_i = '1' then
              vk := rob_vk_i;
            elsif reg_rk_i = '1' then
              vk := reg_vk_i;
            end if;
        end case;

        -- QR & DESTINATION
        -- Branch OP => BRU addr
        -- LSU => Load/Store buffer address
        -- ROB => Rob addr
        case op_i is
          when OP_BRANCH => dest := BRU;
          when OP_STORE  => dest := STB;
          when OP_LOAD   => dest := LDB;
          when others    => dest := ROB;
        end case;

        qr := qr_i;

        exb(to_integer(exb_issue_ptr)) <= (
          f7 => f7,
          f3 => f3,
          vj => vj,
          vk => vk,
          qj => qj,
          qk => qk,
          qr => qr,
          rj  => rj,
          rk  => rk,
          dest => dest,
          busy => '1'
        );

        rob.issue_ptr <= rob.issue_ptr + 1;
      end if;

      for i in 0 to 2**EXB_LEN-1 loop
      end loop;
    end if;
  end process;


end architecture;
