library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library rtl;
use rtl.common_pkg.all;

entity rv_otm is
  generic( RST_LEVEL: std_logic := '0';
           ADDR_LEN : natural);
  port(
    i_clk   : in std_logic;                                   --! Clock
    i_arst  : in std_logic;                                   --! Asynchronous Reset
    i_srst  : in std_logic;                                   --! Synchronous Reset
    o_empty : out std_logic;                                  --! Matrix is empty
    o_full  : out std_logic;                                  --! Matrix is full
    i_we    : in std_logic;                                   --! Write Enable
    i_re    : in std_logic;                                   --! Read Enable
    i_wr_addr : in std_logic_vector(ADDR_LEN-1 downto 0);     --! Write address
    i_rd_mask : in std_logic_vector(2**ADDR_LEN-1 downto 0);  --! Read mask
    o_rd_addr : out std_logic_vector(ADDR_LEN-1 downto 0);    --! Oldest Read address
    o_rd_valid : out std_logic                                --! Read is valid
  );
end entity;


architecture rtl of rv_otm is

    constant MATRIX_SIZE : natural := 2**ADDR_LEN;

    signal age_matrix : std_logic_matrix(0 to MATRIX_SIZE-1)(0 to MATRIX_SIZE);
    signal next_age_matrix : std_logic_matrix(0 to MATRIX_SIZE-1)(0 to MATRIX_SIZE-1);

    signal wr_col       : std_logic_vector(0 to MATRIX_SIZE);
    signal wr_row       : std_logic_vector(0 to MATRIX_SIZE-1);
    signal rd_row       : std_logic_vector(0 to MATRIX_SIZE-1);
    signal rd_mask      : std_logic_vector(0 to MATRIX_SIZE-1);

    signal shift_en     : std_logic_vector(0 to MATRIX_SIZE-1);

    signal col_mask     : std_logic_vector(0 to MATRIX_SIZE-1);

    signal col_addr     : std_logic_vector(ADDR_LEN-1 downto 0);
    signal wr_addr      : std_logic_vector(ADDR_LEN-1 downto 0);
    signal rd_addr      : std_logic_vector(ADDR_LEN-1 downto 0);

    signal we, re, rd_valid : std_logic;
    signal empty, full : std_logic;

begin
    ---
    -- INPUT
    ---
    we <= i_we and not full;
    re <= i_re and not empty;

    rd_mask <= bit_reverse(i_rd_mask);
    wr_addr <= i_wr_addr;


    ---
    -- LOGIC
    ---
    empty <= wr_col(wr_col'left);
    full <= wr_col(wr_col'right);

    wr_row <= bit_reverse(one_hot_encoder(wr_addr));

    p_wr_col:
    process(i_clk, i_arst)
    begin
      if i_arst = RST_LEVEL then
        wr_col <= (0 => '1', others => '0');
      elsif rising_edge(i_clk) then
        if re = '1' and empty = '0' then
          wr_col <= wr_col sll 1;
        end if;

        if we = '1' and full = '0' then
          wr_col <= wr_col srl 1;
        end if;
      end if;
    end process;


    p_next_age_matrix:
    process(all)
      variable cell_we : std_logic;
    begin
      for i in 0 to MATRIX_SIZE-1 loop
        for j in 0 to MATRIX_SIZE-1 loop
          cell_we := (we and wr_row(i)) and ((wr_col(j) and not re) or (wr_col(j+1) and re));
          if cell_we = '1' then
            next_age_matrix(i)(j) <= '1';
          else
            if shift_en(j) = '1' then
              next_age_matrix(i)(j) <= age_matrix(i)(j+1);
            else
              next_age_matrix(i)(j) <= age_matrix(i)(j);
            end if;
          end if;
        end loop;
      end loop;
    end process;


    p_age_matrix:
    process(i_clk, i_arst)
    begin
      if i_arst = RST_LEVEL then
        age_matrix <= (others => (others => '0'));
      elsif rising_edge(i_clk) then
        if i_srst = RST_LEVEL then
          age_matrix <= (others => (others => '0'));
        else
          for i in 0 to MATRIX_SIZE-1 loop
            age_matrix(i)(0 to MATRIX_SIZE-1) <= next_age_matrix(i);
            age_matrix(i)(age_matrix(i)'right) <= '0';
          end loop;
        end if;
      end if;
    end process;


    -- Mask and OR reduce the matrix
    p_col_mask:
    process(all)
      variable col_or_reduce : std_logic_vector(0 to MATRIX_SIZE-1) := (others => '0');
    begin
      for i in 0 to MATRIX_SIZE-1 loop
        col_or_reduce(i) := '0';
        for j in 0 to MATRIX_SIZE-1 loop
          col_or_reduce(i) := col_or_reduce(i) or (age_matrix(j)(i) and rd_mask(j));
        end loop;
      end loop;

      col_mask <= col_or_reduce;
    end process;

    col_addr <= priority_encoder(col_mask);

    p_rd_row:
    process(all)
    begin
      for j in 0 to MATRIX_SIZE-1 loop
        rd_row(j) <= age_matrix(j)(to_integer(unsigned(col_addr)));
      end loop;
    end process;

    -- Shift encoder, C# = Column #
    -- If does not synth: R0 = C0, R1 = C0 + C1, R2 = C0 + C1 + C2...
    p_shift_encoder:
    process(all)
      variable shift_encoder : std_logic_vector(0 to MATRIX_SIZE-1) := (others => '0');
    begin
      if re = '1' then
        shift_encoder(0) := col_mask(0);
        for i in 1 to MATRIX_SIZE-1 loop
          shift_encoder(i) := shift_encoder(i-1) or col_mask(i);
        end loop;
      else
        shift_encoder := (others => '0');
      end if;

      shift_en <= shift_encoder;
    end process;

    rd_addr <= priority_encoder(rd_row);

    rd_valid <= re and (or rd_row);


    ---
    -- OUTPUT
    ---
    o_rd_valid  <= rd_valid;
    o_rd_addr   <= rd_addr;
    o_full      <= full;
    o_empty     <= empty;


end architecture;

