library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library riscv;
use riscv.RV32I.all;

library common;
use common.types.all;
use common.fnct.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
context vunit_lib.data_types_context;
context vunit_lib.vc_context;


entity rv_vip is
  generic(
    COM_RECEIVER_NAME   : string;
    RST_VAL             : std_logic;
    REG_LEN             : natural;
    DMEM_ADDR_WIDTH     : natural;
    IMEM_ADDR_WIDTH     : natural;
    XLEN                : natural
  );
  port(
    i_clk             : in std_logic;
    i_rst             : in std_logic;

    i_reg_we          : in std_logic;
    i_reg_addr        : in std_logic_vector(REG_LEN-1 downto 0);
    i_reg_data        : in std_logic_vector(XLEN-1 downto 0);

    i_mem_we          : in std_logic;
    i_mem_addr        : in std_logic_vector(XLEN-1 downto 0);
    i_mem_data        : in std_logic_vector(XLEN-1 downto 0);

    i_en              : in boolean;
    o_done            : out boolean
  );
end entity;

architecture vip of rv_vip is

  constant BYTE_WIDTH : natural := 8;
  constant NB_BYTES : natural := XLEN / BYTE_WIDTH;

  constant DMEM_SIZE : natural := 2 ** (DMEM_ADDR_WIDTH) * NB_BYTES;
  constant IMEM_SIZE : natural := 2 ** (IMEM_ADDR_WIDTH) * NB_BYTES;

  -- VUNIT
  constant receiver : actor_t := new_actor(COM_RECEIVER_NAME);

  constant logger : logger_t := get_logger("RV_VIP");
  constant checker : checker_t := new_checker(logger);
  constant reg : memory_t := new_memory;
  constant imem : memory_t := new_memory;
  constant dmem : memory_t := new_memory;
  constant reg_queue : queue_t := new_queue;
  constant store_queue : queue_t := new_queue;


  -- VIP
  type ITYPE_T is ( R_TYPE, I_TYPE, S_TYPE, B_TYPE, U_TYPE, J_TYPE, X_TYPE );

  type ALU_OPERATION_T is (
    OP_ADD,
    OP_SUB,
    OP_SLT,
    OP_SLTU,
    OP_XOR,
    OP_AND,
    OP_OR,
    OP_SLL,
    OP_SRL,
    OP_SRA
  );

  function alu_op(
    op : ALU_OPERATION_T;
    a : std_logic_vector(XLEN-1 downto 0);
    b : std_logic_vector(XLEN-1 downto 0))
    return std_logic_vector
    is

    constant ua : unsigned(XLEN-1 downto 0) := unsigned(a);
    constant ub : unsigned(XLEN-1 downto 0) := unsigned(b);

    constant sa : signed(XLEN-1 downto 0) := signed(a);
    constant sb : signed(XLEN-1 downto 0) := signed(b);

    variable output : std_logic_vector(XLEN-1 downto 0);
  begin

    case op is
      when OP_ADD =>
        output := std_logic_vector(sa + sb);
      when OP_SUB =>
        output := std_logic_vector(sa - sb);
      when OP_SLT =>
        output := (others => '0');
        output(0)  := '1'  when sa < sb else '0';
      when OP_SLTU =>
        output := (others => '0');
        output(0) := '1' when ua < ub else '0';
      when OP_XOR =>
        output := a xor b;
      when OP_AND =>
        output := a and b;
      when OP_OR =>
        output := a or b;
      when OP_SLL =>
        output := std_logic_vector(shift_left(ua, to_integer(ub)));
      when OP_SRL =>
        output := std_logic_vector(shift_right(ua, to_integer(ub)));
      when OP_SRA =>
        output := std_logic_vector(shift_right(sa, to_integer(ub)));
      when others =>
        output := (others => 'X');
    end case;

    return output;
  end function;


begin

  -- This is the main model for the RV VIP
  p_main:
  process
    variable run : boolean := true;

    -- INSTRUCTION
    variable itype : ITYPE_T;

    variable i: std_logic_vector(31 downto 0);
    alias opcode : std_logic_vector(4 downto 0) is i(6 downto 2);
    alias f3     : std_logic_vector(2 downto 0) is i(14 downto 12);
    alias f7     : std_logic_vector(6 downto 0) is i(31 downto 25);
    alias rs1    : std_logic_vector(4 downto 0) is i(19 downto 15);
    alias rs2    : std_logic_vector(4 downto 0) is i(24 downto 20);
    alias rd     : std_logic_vector(4 downto 0) is i(11 downto 7);

    -- DATA
    variable op : ALU_OPERATION_T;
    variable imm : std_logic_vector(XLEN-1 downto 0);
    variable addr : std_logic_vector(XLEN-1 downto 0);
    variable index : natural;
    variable a, b, c : std_logic_vector(XLEN-1 downto 0);

    variable byte_data : std_logic_matrix(0 to NB_BYTES)(BYTE_WIDTH-1 downto 0);

    -- CONTROL
    variable pc : unsigned(XLEN-1 downto 0);
    variable pc_src : signed(XLEN-1 downto 0);
    variable branch : boolean;

    -- VUNIT MSG
    variable msg : msg_t;
    variable imem_file_path : string_ptr_t;
    variable dmem_file_path  : string_ptr_t;

    variable imem_int_array : integer_array_t;
    variable dmem_int_array : integer_array_t;

    variable imem_buf : buffer_t;
    variable dmem_buf : buffer_t;
    variable reg_buf  : buffer_t;

  begin

    o_done <= false;
    ---
    -- SETUP
    ---
    receive(net, receiver, msg);

    if i_en = false then
      wait until i_en = true;
    end if;

    -- IMEM init
    imem_file_path := pop_string_ptr_ref(msg);
    clear(imem);
    imem_buf := allocate(imem, IMEM_SIZE, "imem");
    if to_string(imem_file_path) /= "" then
      info(logger, "Loading file " & to_string(imem_file_path) & " into instruction memory");
      imem_int_array := load_raw(to_string(imem_file_path));

      info(logger, "Loaded instructions:");
      for j in 0 to length(imem_int_array)-1 loop
        info(logger, "0x" & to_hstring(to_unsigned(get(imem_int_array,j), 32)));
      end loop;

      assert length(imem_int_array) <= IMEM_SIZE report "IMEM file has more instructions than allocated size" severity failure;
      write_integer_array(imem, 0, imem_int_array);
      deallocate(imem_int_array);
    else
      failure(logger, "No Instruction memory file specified");
    end if;

    -- DMEM init
    dmem_file_path := pop_string_ptr_ref(msg);
    clear(dmem);
    dmem_buf := allocate(dmem, DMEM_SIZE, "dmem");
    if to_string(dmem_file_path) /= "" then
      info(logger, "Loading file " & to_string(dmem_file_path) & " into data memory");

      dmem_int_array := load_raw(to_string(dmem_file_path));
      dmem_buf := write_integer_array(dmem, dmem_int_array);
      deallocate(dmem_int_array);
    else
      info(logger, "No Data memory file specified");
    end if;

    clear(reg);
    reg_buf := allocate(reg, NB_BYTES*32);
    write_word(reg, 0, x"00000000");

    pc := (others => '0');

    -- LOOP
    while run loop
      ---
      -- FETCH
      ---
      info("PC = " & integer'image(to_integer(pc)));
      i := read_word(imem, to_integer(pc), pc'length / BYTE_WIDTH);
      info("read instruction: " & to_hstring(i));

      ---
      -- DECODE
      ---

      with opcode select
        itype := R_TYPE when OP_OP,
                 I_TYPE when OP_IMM | OP_JALR | OP_LOAD,
                 S_TYPE when OP_STORE,
                 B_TYPE when OP_BRANCH,
                 U_TYPE when OP_LUI | OP_AUIPC,
                 J_TYPE when OP_JAL,
                 X_TYPE when others;

      case itype is
        when I_TYPE =>
          imm(11 downto 0) := i(31 downto 20);

          imm(31 downto 12) := (others => imm(11));
        when S_TYPE =>
          imm(11 downto 5) := i(31 downto 25);
          imm(4 downto 0) := i(11 downto 7);

          imm(31 downto 12) := (others => imm(11));
        when B_TYPE =>
          imm(12) := i(31);
          imm(11) := i(7);
          imm(10 downto 5) := i(30 downto 25);
          imm(4 downto 1) := i(11 downto 8);
          imm(0) := '0';

          imm(31 downto 13) := (others => imm(12));
        when U_TYPE =>
          imm(31 downto 12) := i(31 downto 12);
          imm(11 downto 0) := (others => '0');
        when J_TYPE =>
          imm(20) := i(31);
          imm(19 downto 12) := i(19 downto 12);
          imm(11) := i(20);
          imm(10 downto 1) := i(30 downto 21);

          imm(31 downto 21) := (others => imm(20));
        when others =>
          imm := (others => 'X');
      end case;

      ---
      -- EXEC
      ---
      case opcode is
        when OP_OP => -- REG[RD] <- a OP b
          a := read_word(reg, to_integer(unsigned(rs1)) * NB_BYTES, XLEN / BYTE_WIDTH);
          b := read_word(reg, to_integer(unsigned(rs2)) * NB_BYTES, XLEN / BYTE_WIDTH);

          op := OP_ADD when f3 = FUNCT3_ADDSUB and f7 = FUNCT7_ADD else
                OP_SUB when f3 = FUNCT3_ADDSUB and f7 = FUNCT7_SUB else
                OP_SLT when f3 = FUNCT3_SLT else
                OP_SLTU when f3 = FUNCT3_SLTU else
                OP_XOR when f3 = FUNCT3_XOR else
                OP_AND when f3 = FUNCT3_AND else
                OP_OR  when f3 = FUNCT3_OR else
                OP_SLL when f3 = FUNCT3_SL else
                OP_SRL when f3 = FUNCT3_SR and f3 = FUNCT7_SRL else
                OP_SRA when f3 = FUNCT3_SR and f7 = FUNCT7_SRA else
                OP_ADD;

          c := alu_op(op, a, b);
        when OP_IMM =>
          a := read_word(reg, to_integer(unsigned(rs1)) * NB_BYTES, XLEN / BYTE_WIDTH);
          b := imm;

          op := OP_ADD when f3 = FUNCT3_ADDSUB else
                OP_SLT when f3 = FUNCT3_SLT else
                OP_SLTU when f3 = FUNCT3_SLTU else
                OP_XOR when f3 = FUNCT3_XOR else
                OP_AND when f3 = FUNCT3_AND else
                OP_OR  when f3 = FUNCT3_OR else
                OP_SLL when f3 = FUNCT3_SL else
                OP_SRL when f3 = FUNCT3_SR and f3 = FUNCT7_SRL else
                OP_SRA when f3 = FUNCT3_SR and f7 = FUNCT7_SRA else
                OP_ADD;

          c := alu_op(op, a, b);

        when OP_LOAD => -- REG[RD] <- MEM[RS1 + IMM]
          info("Executing load");
          addr := std_logic_vector(signed(read_word(reg, to_integer(unsigned(rs1)) * NB_BYTES, XLEN / BYTE_WIDTH)) + signed(imm));
          c := read_word(dmem, to_integer(unsigned(addr(DMEM_ADDR_WIDTH-1 downto 0))), XLEN / BYTE_WIDTH);

          for j in 0 to NB_BYTES-1 loop
            byte_data(j) := c(8*(j+1)-1 downto BYTE_WIDTH*j);
          end loop;

          index := to_integer(unsigned(addr(1 downto 0)));
          case f3 is
            when FUNCT3_LB =>
              c(BYTE_WIDTH-1 downto 0) := byte_data(index);
              c(c'left downto BYTE_WIDTH) := (others => byte_data(index)(BYTE_WIDTH-1));
            when FUNCT3_LBU =>
              c(BYTE_WIDTH-1 downto 0) := byte_data(index);
              c(c'left downto BYTE_WIDTH) := (others => '0');
            when FUNCT3_LH =>
              c(BYTE_WIDTH-1 downto 0) := byte_data(index);
              c(2*BYTE_WIDTH-1 downto BYTE_WIDTH) := byte_data(index+1);
              c(c'left downto 2*BYTE_WIDTH) := (others => byte_data(index+1)(BYTE_WIDTH-1));
            when FUNCT3_LHU =>
              c(BYTE_WIDTH-1 downto 0) := byte_data(index);
              c(2*BYTE_WIDTH-1 downto BYTE_WIDTH) := byte_data(index+1);
              c(c'left downto 2*BYTE_WIDTH) := (others => '0');
            when FUNCT3_LW =>
            when others =>
          end case;

          --c := new value

        when OP_STORE => -- MEM[RS1 + IMM] <- RS2
          info("Executing store");
          addr := std_logic_vector(signed(read_word(reg, to_integer(unsigned(rs1)) * NB_BYTES, XLEN / BYTE_WIDTH)) + signed(imm));
          c := read_word(reg, to_integer(unsigned(rs2)) * NB_BYTES, XLEN / BYTE_WIDTH);

          for j in 0 to NB_BYTES-1 loop
            byte_data(j) := c(8*(j+1)-1 downto BYTE_WIDTH*j);
          end loop;

          index := to_integer(unsigned(addr(1 downto 0)));
          case f3 is
            when FUNCT3_SB =>
              write_word(dmem, to_integer(unsigned(addr(DMEM_ADDR_WIDTH-1 downto 0))), c(BYTE_WIDTH-1 downto 0));
            when FUNCT3_SH =>
              assert addr(0) = '0' report "Unaligned store" severity error;
              write_word(dmem, to_integer(unsigned(addr(DMEM_ADDR_WIDTH-1 downto 0))), c(2*BYTE_WIDTH-1 downto 0));
            when FUNCT3_SW =>
              assert addr(1 downto 0) = "00" report "Unaligned store" severity error;
              -- mod DMEM_SIZE
              write_word(dmem, to_integer(unsigned(addr(DMEM_ADDR_WIDTH-1 downto 0))) , c);
            when others =>
          end case;

        when OP_LUI => -- REG[RD] <- IMM
          c := std_logic_vector(imm);
        when OP_AUIPC => -- REG[RD] <- PC + IMM
          c := std_logic_vector(signed(pc) + signed(imm));
        when OP_JALR | OP_JAL => -- REG[RD] <- PC+4
          c := std_logic_vector(pc + 4);
        when OP_BRANCH =>
        when OP_SYSTEM => -- ECALL ->, EBREAK ->
          run := false;
        when OP_MISC_MEM => -- FENCE: LOAD > STORE
        when others =>
      end case;

      ---
      -- WB
      ---
      case opcode is
        when OP_OP | OP_IMM | OP_LOAD | OP_LUI | OP_AUIPC | OP_JALR | OP_JAL =>
          if unsigned(rd) /= 0 then
            write_word(reg, to_integer(unsigned(rd)) * NB_BYTES, c);
          end if;
          push(reg_queue, rd);
          push(reg_queue, c);
        when OP_STORE =>
          push(store_queue, addr);
          push(store_queue, c);
        when others =>
      end case;

      ---
      -- PC
      ---
      pc_src := signed(pc);
      case opcode is
        when OP_JAL => -- PC <- PC + IMM
          branch := true;
        when OP_BRANCH => -- PC <- PC + IMM if REG[RS1] OP REG[RS2] ELSE PC+4
          a := read_word(reg, to_integer(unsigned(rs1)) * NB_BYTES, XLEN / BYTE_WIDTH);
          b := read_word(reg, to_integer(unsigned(rs2)) * NB_BYTES, XLEN / BYTE_WIDTH);

          branch := false;
          case f3 is
            when FUNCT3_BEQ =>
              if a = b then
                branch := true;
              end if;
            when FUNCT3_BNE =>
              if a /= b then
                branch := true;
              end if;
            when FUNCT3_BLT =>
              if signed(a) < signed(b) then
                branch := true;
              end if;
            when FUNCT3_BLTU =>
              if unsigned(a) < unsigned(b) then
                branch := true;
              end if;
            when FUNCT3_BGE =>
              if signed(a) > signed(b) then
                branch := true;
              end if;
            when FUNCT3_BGEU =>
              if unsigned(a) > unsigned(b) then
                branch := true;
              end if;
            when others =>
          end case;
        when OP_JALR => -- PC <- RS1 + IMM
          pc_src := signed(a);
        when others =>
      end case;

      if branch then
        pc := unsigned(pc_src + signed(imm));
      else
        pc := pc + 4;
      end if;
    end loop;

    o_done <= true;

    while i_rst /= RST_VAL loop
      wait until rising_edge(i_clk);
    end loop;

    run := true;
  end process;

  p_verify_reg:
  process
    variable addr : std_logic_vector(REG_LEN-1 downto 0);
    variable result : std_logic_vector(XLEN-1 downto 0);
  begin
    wait until rising_edge(i_clk);
    if i_reg_we = '1' then
      assert not is_empty(reg_queue) report "Trying to access empty reg queue" severity failure;
      addr   := pop(reg_queue);
      result := pop(reg_queue);
      info("VERIFYING: REG[" & to_hstring(addr) & "] <- " & to_hstring(result));

      check_equal(checker, i_reg_addr, addr, "REGISTER_COMPARE_ADDR");
      check_equal(checker, i_reg_data, result, "REGISTER_COMPARE_DATA");
    end if;
  end process;

  p_verify_store:
  process
    variable addr, result : std_logic_vector(XLEN-1 downto 0);
  begin
    wait until rising_edge(i_clk);
    if i_mem_we = '1' then
      assert not is_empty(store_queue) report "Trying to access empty store queue" severity failure;
      addr := pop(store_queue);
      result := pop(store_queue);
      info("VERIFYING: MEM[" & to_hstring(addr) & "] <- " & to_hstring(result));

      check_equal(checker, i_mem_addr, addr, "STORE_COMPARE_ADDR");
      check_equal(checker, i_mem_data, result, "STORE_COMPARE_DATA");
    end if;
  end process;

end architecture;

