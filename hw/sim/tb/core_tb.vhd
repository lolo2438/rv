library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

library common;
use common.cnst.BYTE;

library hw;

library sim;
use sim.tb_pkg.clk_gen;

library std;
use std.textio.all;

entity core_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of core_tb is

  constant XLEN : natural := 32;
  constant REG_LEN : natural := 5;
  constant RST_LEVEL : std_logic := '0';

  constant IMEM_DATA_WIDTH : natural := XLEN;
  constant IMEM_ADDR_WIDTH : natural := 12;

  constant DMEM_DATA_WIDTH : natural := XLEN;
  constant DMEM_ADDR_WIDTH : natural := 12;


  -- CTRL
  signal core_clk           : std_logic;
  signal core_arst          : std_logic := not RST_LEVEL;
  signal core_srst          : std_logic := not RST_LEVEL;
  signal core_en            : std_logic;
  signal core_restart       : std_logic;
  signal core_step          : std_logic;

  signal core_stalled       : std_logic;
  signal core_halted        : std_logic;
  signal core_debug         : std_logic;

  -- IMEM
  signal imem_en            : std_logic;
  signal imem_addr          : std_logic_vector(IMEM_ADDR_WIDTH-1 downto 0);
  signal imem_we            : std_logic_vector(IMEM_DATA_WIDTH/BYTE-1 downto 0);
  signal imem_wdata         : std_logic_vector(IMEM_DATA_WIDTH-1 downto 0);
  signal imem_rdata         : std_logic_vector(IMEM_DATA_WIDTH-1 downto 0);

  signal tb_imem_sel        : std_logic;
  signal tb_imem_we         : std_logic_vector(IMEM_DATA_WIDTH/BYTE-1 downto 0);
  signal tb_imem_wdata      : std_logic_vector(IMEM_DATA_WIDTH-1 downto 0);
  signal tb_imem_addr       : std_logic_vector(IMEM_ADDR_WIDTH-1 downto 0);

  signal core_imem_rdy      : std_logic;
  signal core_imem_avalid   : std_logic;
  signal core_imem_dvalid   : std_logic;
  signal core_imem_addr     : std_logic_vector(XLEN-1 downto 0);
  signal core_imem_rdata    : std_logic_vector(XLEN-1 downto 0);


  -- DMEM
  signal tb_dmem_sel        : std_logic;
  signal tb_dmem_we         : std_logic_vector(DMEM_DATA_WIDTH/BYTE-1 downto 0);
  signal tb_dmem_waddr      : std_logic_vector(DMEM_ADDR_WIDTH-1 downto 0);
  signal tb_dmem_wdata      : std_logic_vector(DMEM_DATA_WIDTH-1 downto 0);

  signal tb_dmem_raddr      : std_logic_vector(DMEM_ADDR_WIDTH-1 downto 0);

  signal core_dmem_rrdy     : std_logic;
  signal core_dmem_rdvalid  : std_logic;
  signal core_dmem_ravalid  : std_logic;
  signal core_dmem_raddr    : std_logic_vector(XLEN-1 downto 0);
  signal core_dmem_rdata    : std_logic_vector(XLEN-1 downto 0);

  signal core_dmem_we       : std_logic_vector(DMEM_DATA_WIDTH/BYTE-1 downto 0);
  signal core_dmem_wvalid   : std_logic;
  signal core_dmem_wrdy     : std_logic;
  signal core_dmem_waddr    : std_logic_vector(XLEN-1 downto 0);
  signal core_dmem_wdata    : std_logic_vector(XLEN-1 downto 0);

  signal dmem_en            : std_logic;
  signal dmem_we            : std_logic_vector(DMEM_DATA_WIDTH/BYTE-1 downto 0);
  signal dmem_raddr         : std_logic_vector(DMEM_ADDR_WIDTH-1 downto 0);
  signal dmem_rdata         : std_logic_vector(DMEM_DATA_WIDTH-1 downto 0);
  signal dmem_waddr         : std_logic_vector(DMEM_ADDR_WIDTH-1 downto 0);
  signal dmem_wdata         : std_logic_vector(DMEM_DATA_WIDTH-1 downto 0);




  --procedure dmem_write_byte(addr : in std_logic_vector(DMEM_ADDRWIDTH-1 downto 0);
  --                          data : in std_logic_vector(7 downto 0);
  --                          byte_en: in std_logic_vector(1 downto 0)) is
  --begin
  --  dmem_en_i <= '1';

  --  dmem_addr_i <= addr;
  --  dmem_data_i <= (others => '0');

  --  case byte_en is
  --    when "00" =>
  --      dmem_data_i(7 downto 0) <= data;
  --      dmem_we_i <= "0001";
  --    when "01" =>
  --      dmem_data_i(15 downto 8) <= data;
  --      dmem_we_i <= "0010";
  --    when "10" =>
  --      dmem_data_i(23 downto 16) <= data;
  --      dmem_we_i <= "0100";
  --    when "11" =>
  --      dmem_data_i(31 downto 24) <= data;
  --      dmem_we_i <= "1000";
  --    when others =>
  --  end case;

  --  wait until rising_edge(clk_i);

  --  dmem_en_i <= '0';
  --  dmem_we_i <= (others => '0');
  --end procedure;


  --procedure dmem_write_word(addr : in std_logic_vector(DMEM_ADDRWIDTH-1 downto 0);
  --                          data : in std_logic_vector(31 downto 0)) is
  --begin
  --  dmem_en_i <= '1';
  --  dmem_addr_i <= addr;
  --  dmem_data_i <= data;

  --  dmem_we_i <= "1111";

  --  wait until rising_edge(clk_i);

  --  dmem_en_i <= '0';
  --  dmem_we_i <= (others => '0');

  --end procedure;


  --procedure dmem_import_from_file;
  --procedure dmem_export_to_file;



begin

  ---
  -- CONFIGURATION
  ---

  clk_gen(core_clk, 100.0e6);

  test_runner_watchdog(runner, 100 us);

  ---
  -- MAIN PROCESS
  ---

  main:
  process

    --! \param[in] file_name The name of the file to load into the instruction memory
    --! \brief Loads a program into the instruction memory
    --!        The file format is one instruction per line, each instruction being a
    --!        4 bytes word encoded in ascii characters
    --!        Example: $ cat instruction.mem
    --!                 1A2B3C4D
    --!                 AABBCCDD
    --!                 DEADBEEF
    --!                 ...
    --!        The instructions are loaded each clock cycles in the instruction memory
    --!
    --! \note The program is loaded starting at address 0 in the instruction memory
    --! \note This procedure will assert a failure if the number of instructions is greater
    --!       than the memory allocated
    procedure imem_load_program(file_name : in string)
    is
      file ifile      : text;
      variable iline  : line;
      variable inst   : std_logic_vector(31 downto 0);
      variable addr   : natural;
    begin
      file_open(ifile, file_name, READ_MODE);

      core_en     <= '0';
      tb_imem_sel <= '1';

      wait until rising_edge(core_clk);

      addr := 0;
      while not endfile(ifile) loop
        assert addr < 2**IMEM_ADDR_WIDTH
        report "Specified instruction file is too big, can only " & to_string(2**IMEM_ADDR_WIDTH) & " instructions"
        severity failure;

        readline(ifile, iline);
        hread (iline, inst);
        tb_imem_addr <= std_logic_vector(to_unsigned(addr, tb_imem_addr'length));
        tb_imem_wdata <= inst;
        tb_imem_we <= (others => '1');
        wait until rising_edge(core_clk);

        addr := addr + 1;
      end loop;

      tb_imem_we <= (others => '0');
      tb_imem_sel <= '0';

      file_close(ifile);
    end procedure;

    procedure run_program is
    begin
      core_srst <= RST_LEVEL;
      wait until rising_edge(core_clk);
      core_srst <= not RST_LEVEL;

      core_en <= '1';
      wait until (core_halted = '1');
      core_en <= '0';
    end procedure;

  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("basic_program") then
        imem_load_program("code/basic_program.hex");
        run_program;
      elsif run("test2") then
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

  ---
  -- DUT
  ---

  imem_en   <= (not core_stalled and core_en and core_imem_avalid) or tb_imem_sel;
  imem_we   <= tb_imem_we   when tb_imem_sel = '1' else (others => '0');
  imem_addr <= tb_imem_addr when tb_imem_sel = '1' else core_imem_addr(IMEM_ADDR_WIDTH-1+2 downto 2);
  imem_wdata <= tb_imem_wdata;

  u_imem:
  entity hw.spmem
  generic map(
    DATA_WIDTH => IMEM_DATA_WIDTH,
    ADDR_WIDTH => IMEM_ADDR_WIDTH
  )
  port map(
    i_clk   => core_clk,
    i_en    => imem_en,
    i_we    => imem_we,
    i_addr  => imem_addr,
    i_data  => imem_wdata,
    o_data  => imem_rdata
  );

  core_imem_rdy    <= not tb_imem_sel;
  core_imem_dvalid <= imem_en;

  dmem_en    <= (not core_stalled and core_en and (core_dmem_wvalid or core_dmem_ravalid)) or tb_dmem_sel;
  dmem_we    <= tb_dmem_we    when tb_dmem_sel = '1' else core_dmem_we;
  dmem_waddr <= tb_dmem_waddr when tb_dmem_sel = '1' else core_dmem_waddr(DMEM_ADDR_WIDTH-1+2 downto 2);
  dmem_wdata <= tb_dmem_wdata when tb_dmem_sel = '1' else core_dmem_wdata;
  dmem_raddr <= tb_dmem_raddr when tb_dmem_sel = '1' else core_dmem_raddr(DMEM_ADDR_WIDTH-1+2 downto 2);

  u_dmem:
  entity hw.dpmem
  generic map(
    DATA_WIDTH => DMEM_DATA_WIDTH,
    ADDR_WIDTH => DMEM_ADDR_WIDTH
  )
  port map(
    i_clk    => core_clk,
    i_en     => dmem_en,
    i_we     => dmem_we,
    i_waddr  => dmem_waddr,
    i_wdata  => dmem_wdata,
    i_raddr  => dmem_raddr,
    o_rdata  => dmem_rdata
  );

  core_dmem_rrdy <= not tb_dmem_sel;
  core_dmem_wrdy <= not tb_dmem_sel;
  core_dmem_rdvalid <= dmem_en when rising_edge(core_clk);
  core_dmem_rdata <= dmem_rdata;

  core_imem_rdata <= imem_rdata;

  u_dut:
  entity hw.core
  generic map (
    -- EXTENSIONS
    REG_LEN   => REG_LEN,
    RST_LEVEL => RST_LEVEL,
    XLEN      => XLEN
  )
  port map(
    i_clk           => core_clk,
    i_arst          => core_arst,
    i_srst          => core_srst,
    i_en            => core_en,
    i_step          => core_step,
    i_restart       => core_restart,
    o_stall         => core_stalled,
    o_halt          => core_halted,
    o_debug         => core_debug,
    o_imem_addr     => core_imem_addr,
    o_imem_avalid   => core_imem_avalid,
    i_imem_rdy      => core_imem_rdy,
    i_imem_data     => core_imem_rdata,
    i_imem_dvalid   => core_imem_dvalid,
    i_dmem_rrdy     => core_dmem_rrdy,
    o_dmem_raddr    => core_dmem_raddr,
    o_dmem_ravalid  => core_dmem_ravalid,
    i_dmem_rdata    => core_dmem_rdata,
    i_dmem_rdvalid  => core_dmem_rdvalid,
    o_dmem_wvalid   => core_dmem_wvalid,
    i_dmem_wrdy     => core_dmem_wrdy,
    o_dmem_we       => core_dmem_we,
    o_dmem_waddr    => core_dmem_waddr,
    o_dmem_wdata    => core_dmem_wdata
  );

end architecture;
