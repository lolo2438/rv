library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library common;
use common.fnct.all;
use common.types.all;

entity dispatcher is
  generic(
    RST_LEVEL: std_logic := '0';
    ADDR_LEN : natural
  );
  port(
    i_clk       : in  std_logic;                                  --! Clock
    i_arst      : in  std_logic;                                  --! Asynchronous Reset
    i_srst      : in  std_logic;                                  --! Synchronous Reset
    o_empty     : out std_logic;                                  --! dispatcher storage is empty
    o_full      : out std_logic;                                  --! dispatcher storage is full
    i_we        : in  std_logic;                                  --! Write Enable
    i_re        : in  std_logic;                                  --! Read Enable
    i_wr_addr   : in  std_logic_vector(ADDR_LEN-1 downto 0);      --! Write address
    i_rd_mask   : in  std_logic_vector(2**ADDR_LEN-1 downto 0);   --! Read mask
    o_rd_addr   : out std_logic_vector(ADDR_LEN-1 downto 0)       --! Oldest Read address
  );
end entity;

-- TODO: do a age_fifo_rtl and compare results in vivado synthesis
architecture age_fifo of dispatcher is

  constant ADDR_SIZE : natural := 2**ADDR_LEN;

  signal age_fifo : std_logic_matrix(0 to ADDR_SIZE-1)(ADDR_LEN-1 downto 0);

  signal wr_sel_d : std_logic_vector(ADDR_SIZE downto 0);
  signal wr_sel_q : std_logic_vector(ADDR_SIZE downto 0);
  signal rd_sel : std_logic_vector(ADDR_SIZE-1 downto 0);
  signal shift_en : std_logic_vector(ADDR_SIZE-2 downto 0);

  signal rd_ptr  : std_logic_vector(ADDR_LEN-1 downto 0);

  signal empty : std_logic;
  signal full : std_logic;

  signal we : std_logic;
  signal re : std_logic;

begin

  ---
  -- INPUT
  ---
  we <= i_we and not full;
  re <= i_re and not empty;

  --FIXME: The issue with the age_fifo is that the data must be compared, which
  -- Resolve at building a matrix of "equal" to match the correct index to the correct data
  -- In a sense, it's better to just go with a matrix before as it will reduce the datapath
  -- Compared here to adding multiple logic levels
  --
  -- Note: fix the downto/to and priority enc LSB/MSB, it should in theory work but not tested
  p_rd_ptr:
  process(i_rd_mask, age_fifo)
    variable cmp_matrix : std_logic_matrix(ADDR_SIZE-1 downto 0)(ADDR_SIZE-1 downto 0);
    variable cmp_matrix_col : std_logic_vector(ADDR_SIZE-1 downto 0);
  begin
    for i in 0 to ADDR_SIZE-1 loop
      for j in 0 to ADDR_SIZE-1 loop
        if i_rd_mask(j) = '1' then
          if unsigned(age_fifo(i)) = j then
            cmp_matrix_col(i) := '1';
            cmp_matrix(i)(j) := '1';
          end if;
        end if;
      end loop;
    end loop;

    rd_ptr <= priority_encoder(cmp_matrix(to_integer(unsigned(priority_encoder(cmp_matrix_col)))));
  end process;

  rd_ptr <= priority_encoder(i_rd_mask, LSB);

  ---
  -- LOGIC
  ---
  with std_logic_vector'(we & re) select
     wr_sel_d  <= wr_sel_q srl 1 when "01", -- Read
                  wr_sel_q sll 1 when "10", -- Write
                  wr_sel_q when others;

  p_wr_sel_q:
  process(i_clk, i_arst)
  begin
    if i_arst = RST_LEVEL then
      wr_sel_q <= (others => '0');
      wr_sel_q(0) <= '1';
    elsif rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        wr_sel_q <= (others => '0');
        wr_sel_q(0) <= '1';
      else
        wr_sel_q <= wr_sel_d;
      end if;
    end if;
  end process;

  rd_sel <= one_hot_encoder(rd_ptr);

  shift_en(0) <= rd_sel(0);
  g_shift_en:
  for i in 1 to ADDR_SIZE-2 generate
    shift_en(i) <= rd_sel(i) or shift_en(i-1);
  end generate;

  p_age_fifo:
  process(i_clk)
  begin
    if rising_edge(i_clk) then
      case std_logic_vector'(we & re) is

        -- Read only
        when "01" =>
          for i in 0 to ADDR_SIZE-2 loop
            if shift_en(i) = '1' then
              age_fifo(i) <= age_fifo(i+1);
            end if;
          end loop;

        -- Write only
        when "10" =>
          for i in 0 to 2**ADDR_LEN-1 loop
            if wr_sel_q(i) = '1' then
              age_fifo(i) <= i_wr_addr;
            end if;
          end loop;

        -- Read and Write
        when "11" =>
          for i in 0 to 2**ADDR_LEN-2 loop
            if shift_en(i) = '1' then
              if wr_sel_q(i+1) = '1' then
                age_fifo(i) <= i_wr_addr;
              else
                age_fifo(i) <= age_fifo(i+1);
              end if;
            end if;
          end loop;

        when others =>
          -- Keep value

      end case;
    end if;
  end process;

  empty <= wr_sel_q(0);
  full <= wr_sel_q(ADDR_SIZE);

  ---
  -- OUTPUT
  ---
  o_empty <= empty;
  o_full <= full;

  o_rd_addr <= age_fifo(to_integer(unsigned(rd_ptr)));

end architecture;


architecture age_matrix of dispatcher is

    constant MATRIX_SIZE : natural := 2**ADDR_LEN;

    type matrix_t is array (natural range <>) of std_logic_vector;

    signal age_matrix : matrix_t(MATRIX_SIZE-1 downto 0)(MATRIX_SIZE downto 0);
    signal next_age_matrix : matrix_t(MATRIX_SIZE-1 downto 0)(MATRIX_SIZE-1 downto 0);

    signal wr_col       : std_logic_vector(MATRIX_SIZE downto 0);
    signal wr_row       : std_logic_vector(MATRIX_SIZE-1 downto 0);
    signal rd_row       : std_logic_vector(MATRIX_SIZE-1 downto 0);
    signal rd_mask      : std_logic_vector(MATRIX_SIZE-1 downto 0);

    signal shift_en     : std_logic_vector(MATRIX_SIZE-1 downto 0);

    signal col_mask     : std_logic_vector(MATRIX_SIZE-1 downto 0);

    signal col_addr     : std_logic_vector(ADDR_LEN-1 downto 0);
    signal wr_addr      : std_logic_vector(ADDR_LEN-1 downto 0);
    signal rd_addr      : std_logic_vector(ADDR_LEN-1 downto 0);

    signal we, re       : std_logic;
    signal empty, full  : std_logic;

begin

    ---
    -- INPUT
    ---
    we <= i_we and not full;
    re <= i_re and not empty;

    rd_mask <= i_rd_mask;
    wr_addr <= i_wr_addr;

    ---
    -- LOGIC
    ---
    empty <= wr_col(wr_col'right);
    full <= wr_col(wr_col'left);

    wr_row <= one_hot_encoder(wr_addr);

    --! Write column: A one hot encoded vector that indcates the position to write the
    --! next "address" in. Encoded in a (0 to N) fashion:
    --! [4][ 3 2 1 0 ]
    --! [0][ 1 0 0 0 ]
    --! Bit [0] is connected to "Empty" while bit [N] is connected to "full"
    --! When a write is executed the wr_col bit shifts right ->
    --! When a read is executed the wr_col bit shifts left <-
    p_wr_col:
    process(i_clk, i_arst)
    begin
      if i_arst = RST_LEVEL then
        wr_col <= (0 => '1', others => '0');
      elsif rising_edge(i_clk) then
        if i_srst = RST_LEVEL then
          wr_col <= (0 => '1', others => '0');
        else
          case std_logic_vector'(we & re) is
            when "01" => wr_col <= wr_col srl 1;
            when "10" => wr_col <= wr_col sll 1;
            when others =>
          end case;
        end if;
      end if;
    end process;


    --! The matrix's cells have three options for it's next state:
    --! 1. If a write is initiated and the column is not reading nor the next column
    --! 2. If there is an older index that has been read, shift to re-adjust the order tracking
    --! 3. Keep the current cell value
    p_next_age_matrix:
    process(all)
      variable col_we  : std_logic;
      variable row_we  : std_logic;
      variable cell_we : std_logic;
    begin
      for i in 0 to MATRIX_SIZE-1 loop
        for j in 0 to MATRIX_SIZE-1 loop
          row_we := we and wr_row(i);
          -- Use the current write column to select the column to write.
          -- In the case of read+write, we won't write to the next col,
          -- it will be fowarded to the col before
          col_we := (wr_col(j) and not re) or (wr_col(j+1) and re);
          cell_we := row_we and col_we;

          if cell_we = '1' then
            next_age_matrix(i)(j) <= '1';
          elsif shift_en(j) = '1' then
            next_age_matrix(i)(j) <= age_matrix(i)(j+1);
          else
            next_age_matrix(i)(j) <= age_matrix(i)(j);
          end if;
        end loop;
      end loop;
    end process;


    --! Next state for the matrix register
    --! The leftmost bit is always 0 for the shift register
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
            for j in 0 to MATRIX_SIZE-1 loop
              age_matrix(i)(j) <= next_age_matrix(i)(j);
            end loop;
            age_matrix(i)(MATRIX_SIZE) <= '0';
          end loop;
        end if;
      end if;
    end process;


    -- Mask and OR reduce the matrix
    p_col_mask:
    process(all)
      variable col_or_reduce : std_logic_vector(MATRIX_SIZE-1 downto 0) := (others => '0');
    begin
      for i in 0 to MATRIX_SIZE-1 loop
        col_or_reduce(i) := '0';
        for j in 0 to MATRIX_SIZE-1 loop
          col_or_reduce(i) := col_or_reduce(i) or (age_matrix(j)(i) and rd_mask(j));
        end loop;
      end loop;

      -- FIXME: it looks like there is an issue here when converting from mask -> age priority
      col_mask <= col_or_reduce;
    end process;

    col_addr <= priority_encoder(col_mask, LSB);

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
      variable shift_encoder : std_logic_vector(MATRIX_SIZE-1 downto 0) := (others => '0');
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

    rd_addr <= one_hot_decoder(rd_row);

    ---
    -- OUTPUT
    ---
    o_rd_addr   <= rd_addr;
    o_full      <= full;
    o_empty     <= empty;

end architecture;

