library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

use std.textio.all;

use work.tb_pkg.all;

entity cpu_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of cpu_tb is

    constant XLEN : natural := 32;
    constant IMEM_ADDRWIDTH : natural := 8;
    constant DMEM_ADDRWIDTH : natural := 8;

    signal clk_i   : std_logic := '0';
    signal rst_i   : std_logic := '0';
    signal en_i    : std_logic := '0';
    signal halt_o  : std_logic;

    signal ls_op_o  : std_logic;
    signal ls_o     : std_logic;
    signal addr_o   : std_logic_vector(XLEN-1 downto 0);
    signal data_o   : std_logic_vector(XLEN-1 downto 0);
    signal data_i   : std_logic_vector(XLEN-1 downto 0) := (others => '0');
    signal dvalid_i : std_logic := '0';

    signal imem_en_i   : std_logic := '0';
    signal imem_we_i   : std_logic_vector(XLEN/8-1 downto 0) := (others => '0');
    signal imem_addr_i : std_logic_vector(IMEM_ADDRWIDTH-1 downto 0) := (others => '0');
    signal imem_data_i : std_logic_vector(XLEN-1 downto 0) := (others => '0');
    signal imem_data_o : std_logic_vector(XLEN-1 downto 0);

    signal dmem_en_i      : std_logic := '0';
    signal dmem_we_i      : std_logic_vector(XLEN/8-1 downto 0) := (others => '0');
    signal dmem_addr_i    : std_logic_vector(DMEM_ADDRWIDTH-1 downto 0) := (others => '0');
    signal dmem_data_i    : std_logic_vector(XLEN-1 downto 0) := (others => '0');
    signal dmem_data_o    : std_logic_vector(XLEN-1 downto 0);

begin

  clk_gen(clk_i, 100.0e6);

  --------------------------------------------------
  -- Main process
  --------------------------------------------------
  test_runner_watchdog(runner, 100 us);
  main : process

    procedure load_program(file_name : in string) is
      file inst_f : text;
      variable line_i : line;
      variable inst : std_logic_vector(31 downto 0);
      variable addr : unsigned(imem_addr_i'range) := (others => '0');
    begin
      file_open(inst_f, file_name, READ_MODE);

      en_i      <= '0';
      imem_en_i <= '1';

      wait until rising_edge(clk_i);
      while not endfile(inst_f) loop
        readline(inst_f, line_i);

        if line_i'length = 8 then
          hread (line_i, inst);
          imem_addr_i <= std_logic_vector(addr);
          imem_data_i <= inst;
          imem_we_i <= "1111";

          wait until rising_edge(clk_i);
          addr := addr + 1;

        elsif line_i'length = 4 then
          hread (line_i, inst(15 downto 0));

          imem_addr_i <= std_logic_vector(addr);
          imem_data_i <= inst;

          if addr(1) = '0' then
            imem_we_i <= "0011";
          else
            imem_we_i <= "1100";
          end if;

          wait until rising_edge(clk_i);
          -- FIXME: unaligned addresses!
          addr := addr + 2;

        end if;
      end loop;

      imem_en_i <= '0';
      imem_we_i <= (others => '0');

      file_close(inst_f);
    end procedure;


    procedure run_program is
    begin
      rst_i <= '1';
      wait until rising_edge(clk_i);
      rst_i <= '0';

      en_i <= '1';
      wait until halt_o = '1';

      en_i <= '0';
    end procedure;


    procedure dmem_write_byte(addr : in std_logic_vector(DMEM_ADDRWIDTH-1 downto 0);
                              data : in std_logic_vector(7 downto 0);
                              byte_en: in std_logic_vector(1 downto 0)) is
    begin
      dmem_en_i <= '1';

      dmem_addr_i <= addr;
      dmem_data_i <= (others => '0');

      case byte_en is
        when "00" =>
          dmem_data_i(7 downto 0) <= data;
          dmem_we_i <= "0001";
        when "01" =>
          dmem_data_i(15 downto 8) <= data;
          dmem_we_i <= "0010";
        when "10" =>
          dmem_data_i(23 downto 16) <= data;
          dmem_we_i <= "0100";
        when "11" =>
          dmem_data_i(31 downto 24) <= data;
          dmem_we_i <= "1000";
        when others =>
      end case;

      wait until rising_edge(clk_i);

      dmem_en_i <= '0';
      dmem_we_i <= (others => '0');
    end procedure;


    procedure dmem_write_word(addr : in std_logic_vector(DMEM_ADDRWIDTH-1 downto 0);
                              data : in std_logic_vector(31 downto 0)) is
    begin
      dmem_en_i <= '1';
      dmem_addr_i <= addr;
      dmem_data_i <= data;

      dmem_we_i <= "1111";

      wait until rising_edge(clk_i);

      dmem_en_i <= '0';
      dmem_we_i <= (others => '0');

    end procedure;





    -- Fixme: mask the bytes cuz reading in 32 bit mode
    --procedure dmem_read_byte(addr : in std_logic_vector(DMEM_ADDRWIDTH-1 downto 0);
    --                         data : out std_logic_vector(7 downto 0)) is
    --begin
    --  dmem_en_i <= '1';
    --  dmem_we_i <= (others => '0');

    --  dmem_addr_i <= addr;
    --  wait until rising_edge(clk_i);
    --  data := dmem_data_o;

    --  dmem_en_i <= '0';
    --end procedure;

  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("strlen") then
        load_program("test_code/strlen.txt");
        --dmem_write_byte(x"00",x"41","00"); -- 'A'
        --dmem_write_byte(x"01",x"42","01"); -- 'B'
        --dmem_write_byte(x"02",x"43","10"); -- 'C'
        --dmem_write_byte(x"03",x"44","11"); -- 'D'
        --dmem_write_byte(x"04",x"45","00"); -- 'E'
        --dmem_write_byte(x"05",x"46","01"); -- 'F'
        --dmem_write_byte(x"06",x"47","10"); -- 'G'
        --dmem_write_byte(x"07",x"48","11"); -- 'H'
        --dmem_write_byte(x"08",x"49","00"); -- 'I'
        --dmem_write_byte(x"09",x"00","01"); -- '\0'
        dmem_write_word(x"00", x"44434241");
        dmem_write_word(x"01", x"48474645");
        dmem_write_word(x"02", x"00000049");
        run_program;

      elsif run("hexstr") then
        load_program("hexstr.txt");

        dmem_write_byte(x"00", x"78", "00");
        dmem_write_byte(x"01", x"56", "01");
        dmem_write_byte(x"02", x"34", "10");
        dmem_write_byte(x"03", x"12", "11");

        dmem_write_byte(x"04", x"EF", "00");
        dmem_write_byte(x"05", x"CD", "01");
        dmem_write_byte(x"06", x"AB", "10");
        dmem_write_byte(x"07", x"90", "11");

        dmem_write_byte(x"08", x"00", "00");
        dmem_write_byte(x"09", x"04", "01");
        dmem_write_byte(x"0A", x"00", "10");
        dmem_write_byte(x"0B", x"00", "11");

        dmem_write_byte(x"0C", x"10", "00");
        dmem_write_byte(x"0D", x"04", "01");
        dmem_write_byte(x"0E", x"00", "10");
        dmem_write_byte(x"0F", x"00", "11");

        run_program;

      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;


  --------------------------------------------------
  -- DUT instanciation
  --------------------------------------------------
  DUT : entity work.cpu(rtl)
  generic map(
    XLEN => XLEN,
    IMEM_ADDRWIDTH => IMEM_ADDRWIDTH,
    DMEM_ADDRWIDTH => DMEM_ADDRWIDTH
  )
  port map(
    -- CTRL
    clk_i   => clk_i,
    rst_i   => rst_i,
    en_i    => en_i,
    halt_o  => halt_o,

    -- LOAD/STORE
    ls_op_o  => ls_op_o,
    ls_o     => ls_o,
    addr_o   => addr_o,
    data_o   => data_o,
    data_i   => data_i,
    dvalid_i => dvalid_i,

    -- IMEM
    imem_en_i   => imem_en_i,
    imem_we_i   => imem_we_i,
    imem_addr_i => imem_addr_i,
    imem_data_i => imem_data_i,
    imem_data_o => imem_data_o,

    -- DMEM
    dmem_en_i      => dmem_en_i,
    dmem_we_i      => dmem_we_i,
    dmem_addr_i    => dmem_addr_i,
    dmem_data_i    => dmem_data_i,
    dmem_data_o    => dmem_data_o
  );

end architecture;
