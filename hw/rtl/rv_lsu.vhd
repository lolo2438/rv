library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.common_pkg.all;

library riscv;
use riscv.RV32I.all;

entity rv_lsu is
  generic (
    RST_LEVEL : std_logic := '0';   --! Reset level
    STB_LEN   : natural;            --! STB_SIZE = 2**STB_LEN
    LDB_LEN   : natural;            --! LDB_SIZE = 2**LDB_LEN
    TAG_LEN   : natural;            --! Tag length
    XLEN      : natural;            --! Operand size
    BYTE_LEN  : natural := clog2(XLEN/8)-1
  );
  port (
    -- Control interface
    i_clk         : in  std_logic;                                    --! LSU Clock
    i_arst        : in  std_logic;                                    --! Async Reset
    i_srst        : in  std_logic;                                    --! Sync Reset

    o_stb_full    : out std_logic;                               --! Store buffer is full when '1'
    o_ldb_full    : out std_logic;                               --! Load buffer is full when '1'
    o_grp_full    : out std_logic;                               --! Group tracking for Fence operation is full when '1'

    -- Dispatch Interface
    i_disp_valid  : in  std_logic;                             --! Dispatch data is valid
    i_disp_store  : in  std_logic;                             --! Store instruction
    i_disp_load   : in  std_logic;                             --! Load instruction
    i_disp_fence  : in  std_logic;                             --! Fence instruction
    i_disp_f3     : in  std_logic_vector(2 downto 0);          --! L/S F3

    i_disp_tq     : in  std_logic_vector(TAG_LEN-1 downto 0);  --! Address to store the load result

    i_disp_va     : in  std_logic_vector(XLEN-1 downto 0);     --! Address field value for Load/Store
    i_disp_ta     : in  std_logic_vector(TAG_LEN-1 downto 0);  --! Address tag to look for if it's not ready
    i_disp_ra     : in  std_logic;                             --! Address ready flag

    i_disp_vd     : in  std_logic_vector(XLEN-1 downto 0);     --! Data field value for Store
    i_disp_td     : in  std_logic_vector(TAG_LEN-1 downto 0);  --! Data tag to look for if it's not ready
    i_disp_rd     : in  std_logic;                             --! Data ready flag

    -- CDB Write Interface
    o_cdb_vq      : out std_logic_vector(XLEN-1 downto 0);    --! Data to write on the bus
    o_cdb_tq      : out std_logic_vector(TAG_LEN-1 downto 0); --! Tag to write on the CDB bus
    o_cdb_req     : out std_logic;                            --! Request to the CDB bus
    i_cdb_ack     : in  std_logic;                            --! Acknowledge from the CDB bus

    -- CDB Read Interface
    i_cdb_vq      : in  std_logic_vector(XLEN-1 downto 0);     --! Data from the CDB bus
    i_cdb_tq      : in  std_logic_vector(TAG_LEN-1 downto 0);  --! Tag from the CDB bus
    i_cdb_rq      : in  std_logic;                             --! CDB Ready flag

    -- Memory Interface
    o_mem_ls        : out std_logic;                              --! Load/Store selection
    o_mem_f3        : out std_logic_vector(2 downto 0);           --! Operation F3
    o_mem_addr      : out std_logic_vector(XLEN-1 downto 0);      --! Address of the operation
    o_mem_wr_data   : out std_logic_vector(XLEN-1 downto 0);      --! Write data from memory
    i_mem_rd_data   : in  std_logic_vector(XLEN-1 downto 0);       --! Read data from memory
    o_mem_req       : out std_logic;                              --! Request to memory
    i_mem_ack       : in  std_logic                               --! Acknoledge from memory
  );
end entity;

architecture rtl of rv_lsu is

  constant STB_SIZE : natural := 2**STB_LEN;
  constant LDB_SIZE : natural := 2**LDB_LEN;

  constant GRP_LEN  : natural := 4;

  ---
  -- DECODE
  ---
  signal fence : std_logic;
  signal store : std_logic;
  signal load  : std_logic;

  ---
  -- STORE BUFFER
  ---
  type stb_buf_field_t is record
    addr        : std_logic_vector(XLEN-1 downto 0);
    addr_src    : std_logic_vector(TAG_LEN-1 downto 0);
    addr_rdy    : std_logic;

    data        : std_logic_vector(XLEN-1 downto 0);
    data_src    : std_logic_vector(TAG_LEN-1 downto 0);
    data_rdy    : std_logic;

    grp         : std_logic_vector(GRP_LEN-1 downto 0);

    f3          : std_logic_vector(2 downto 0);
    busy        : std_logic;
    commited    : std_logic;
  end record;

  type stb_buf_t is array (0 to STB_SIZE-1) of stb_buf_field_t;

  type stb_fifo_t is record
    buf : stb_buf_t;
    wr_ptr : natural range 0 to STB_SIZE-1;
    rd_ptr : natural range 0 to STB_SIZE-1;
    full   : std_logic;
    commit : std_logic;
    wr_rdy : std_logic;
  end record;

  signal stb : stb_fifo_t;
  signal stb_entry : stb_buf_field_t;


  ---
  -- LOAD BUFFER
  ---
  type ldb_buf_field_t is record
    addr        : std_logic_vector(XLEN-1 downto 0);        -- Mem addr to load from
    addr_src    : std_logic_vector(TAG_LEN-1 downto 0);     -- TAG to snoop for addr if not ready
    addr_rdy    : std_logic;                                -- ADDR field is ready

    data        : std_logic_vector(XLEN-1 downto 0);        -- Data loaded from memory
    data_dst    : std_logic_vector(TAG_LEN-1 downto 0);     -- Destination of the loaded data in the ROB

    grp         : std_logic_vector(GRP_LEN-1 downto 0);
    f3          : std_logic_vector(2 downto 0);             -- Funct3
    busy        : std_logic;                                -- The ldb field is active
    commited    : std_logic;                                -- The ldb field operation has been commited to the memory
    done        : std_logic;                                -- The ldb field has been populated with the memory value

    st_spec     : std_logic;                                -- SPECULATIVE: A store address was not ready but the load operation is still executed
    st_dep      : std_logic_vector(STB_SIZE-1 downto 0);    -- The stb entries of which the load depends on (store addr not ready) are stored here. When updated, the load will verify
  end record;

  type ldb_buf_t is array (0 to LDB_SIZE-1) of ldb_buf_field_t;

  type ldb_t is record
     buf    : ldb_buf_t;
     wr_ptr : natural range 0 to LDB_SIZE-1;
     rd_ptr : natural range 0 to LDB_SIZE-1;
     full   : std_logic;
     commit : std_logic;
  end record;

  signal ldb : ldb_t;
  signal ldb_entry : ldb_buf_field_t;

  signal stb_dep : std_logic_vector(STB_SIZE-1 downto 0);

  ---
  -- GROUP TRACKER
  ---
  signal rd_grp : unsigned(GRP_LEN-1 downto 0);
  signal ldb_grp_cmp : std_logic_vector(LDB_LEN-1 downto 0);
  signal stb_grp_cmp : std_logic;
  signal chg_rd_grp : std_logic;

  signal wr_grp : unsigned(GRP_LEN-1 downto 0);
  signal next_wr_grp : unsigned(wr_grp'range);

  signal grp_full : std_logic;


  ---
  -- MEMORY SHEDULER
  ---

  type msch_queue_field is record
    ls    : std_logic;
    f3    : std_logic_vector(2 downto 0);
    addr  : std_logic_vector(XLEN-1 downto 0);
    data  : std_logic_vector(XLEN-1 downto 0);
  end record;



  signal msch_store : std_logic;
  signal msch_load : std_logic;

begin

  ---
  -- DECODE
  ---
  store <= i_disp_store and i_disp_valid;

  load <= i_disp_load and i_disp_valid;

  fence <= i_disp_fence and i_disp_valid;


  ---
  -- GROUPS (FENCE)
  ---
  p_rd_grp:
  process(i_clk, i_arst)
  begin
    if i_arst = RST_LEVEL then
      rd_grp <= (others => '0');
    elsif rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        rd_grp <= (others => '0');
      elsif chg_rd_grp = '1' then
        rd_grp <= rd_grp + 1;
      end if;
    end if;
  end process;

  g_ldb_grp_cmp:
  for i in 0 to LDB_SIZE-1 generate
    g_ldb_grp_cmp_bit:
    if ldb.buf(i).grp = std_logic_vector(rd_grp) generate
      ldb_grp_cmp(i) <= '1';
    else generate
      ldb_grp_cmp(i) <= '0';
    end generate;
  end generate;

  stb_grp_cmp <= '1' when stb.buf(stb.rd_ptr).grp = std_logic_vector(rd_grp) else '0';

  chg_rd_grp <= (nor ldb_grp_cmp) and stb_grp_cmp;


  p_wr_grp:
  process(i_clk, i_arst)
  begin
    if i_arst = RST_LEVEL then
      wr_grp <= (others => '0');
    elsif rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        wr_grp <= (others => '0');
      elsif fence = '1' and grp_full = '0' then
          wr_grp <= next_wr_grp;
      end if;
    end if;
  end process;

  next_wr_grp <= wr_grp + 1;

  grp_full <= '1' when rd_grp = next_wr_grp else '0';


  ---
  -- STORE BUFFER
  ---
  p_stb:
  process(i_clk, i_arst)
  begin
    if i_arst = '1' then
      for i in 0 to STB_SIZE-1 loop
        stb.buf(i).busy     <= '0';
        stb.buf(i).commited <= '0';
      end loop;
      stb.wr_ptr <= 0;
      stb.rd_ptr <= 0;

    elsif rising_edge(i_clk) then
      if i_srst = '1' then
        for i in 0 to STB_SIZE-1 loop
          stb.buf(i).busy     <= '0';
          stb.buf(i).commited <= '0';
        end loop;
        stb.wr_ptr <= 0;
        stb.rd_ptr <= 0;

      else
      -- NEW ENTRY
        if store = '1' and stb.full = '0' then
          stb.buf(stb.wr_ptr) <= stb_entry;
          stb.wr_ptr <= stb.wr_ptr + 1;
        end if;

      -- CDB WRITEBACK
        if i_cdb_rq = '1' then
          for i in 0 to STB_SIZE-1 loop
            if stb.buf(i).busy = '1' and stb.buf(i).commited = '0' then
              if stb.buf(i).addr_rdy = '0' and stb.buf(i).addr_src = i_cdb_tq then
                stb.buf(i).addr <= i_cdb_vq;
                stb.buf(i).addr_rdy <= '1';
              end if;

              if stb.buf(i).data_rdy = '0' and stb.buf(i).data_src = i_cdb_tq then
                stb.buf(i).data <= i_cdb_vq;
                stb.buf(i).data_rdy <= '1';
              end if;
            end if;
          end loop;
        end if;

      -- COMMIT STORE
        if stb.commit = '1' then -- TODO: MEM SHED: get data + addr + byte sel
          stb.buf(stb.rd_ptr).commited <= '1';
          stb.buf(stb.rd_ptr).busy <= '0';
          stb.rd_ptr <= stb.rd_ptr + 1;
        end if;
      end if;
    end if;
  end process;

  stb_entry <= (
    addr_rdy    => i_disp_ra,
    addr        => i_disp_va,
    addr_src    => i_disp_ta,
    data        => i_disp_vd,
    data_rdy    => i_disp_rd,
    data_src    => i_disp_td,
    f3          => i_disp_f3,
    grp         => std_logic_vector(wr_grp),
    busy        => '1',
    commited    => '0'
  );


  p_stb_full:
  process(all)
    variable full : std_logic := '1';
  begin
    for i in 0 to 2**STB_LEN-1 loop
      full := full and stb.buf(i).busy;
    end loop;

    stb.full <= full;
  end process;


  stb.wr_rdy <= stb.buf(stb.rd_ptr).data_rdy and stb.buf(stb.rd_ptr).addr_rdy and stb.buf(stb.rd_ptr).busy;

  stb.commit <= stb.wr_rdy and sched_store;

  g_stb_dep:
  for i in 0 to STB_SIZE-1 generate
    stb_dep(i) <= stb.buf(i).busy and not stb.buf(i).commited;
  end generate;


  ---
  -- LOAD
  ---
  p_ldb:
  process(i_clk, i_arst)
  begin
    if i_arst = RST_LEVEL then
    elsif rising_edge(i_clk) then
      if i_srst = RST_LEVEL then
        for i in 0 to LDB_SIZE-1 loop
          ldb.buf(i).busy     <= '0';
          ldb.buf(i).commited <= '0';
          ldb.buf(i).done     <= '0';
        end loop;

        ldb.wr_ptr <= 0;
        ldb.rd_ptr <= 0;
      else
        -- NEW ENTRY
        if load = '1' and ldb.full = '0' then
          ldb.buf(ldb.wr_ptr) <= ldb_entry;
        end if;

        -- CDB WRITE BACK
        if i_cdb_rq = '1' then
          for i in 0 to STB_SIZE-1 loop
            if (ldb.buf(i).busy      = '1' and
                ldb.buf(i).commited  = '0' and
                ldb.buf(i).addr_rdy  = '0' and
                ldb.buf(i).addr_src  = i_cdb_tq) then

                ldb.buf(i).addr     <= i_cdb_vq;
                ldb.buf(i).addr_rdy <= '1';
            end if;
          end loop;
        end if;

        -- DATA WRITE BACK


        -- ST DEPENDENCIES
        if stb.commit = '1' then
          for i in 0 to LDB_SIZE-1 loop
            if ldb.buf(i).st_dep(stb.rd_ptr) = '1' and ldb.buf(i).busy = '1' then
              -- check address
              if ldb.buf(i).addr_rdy = '1' and ldb.buf(i).addr = stb.buf(stb.rd_ptr).addr then
                ldb.buf(i).data <= stb.buf(stb.rd_ptr).data;
                ldb.buf(i).done <= '1';
              end if;

              ldb.buf(i).st_dep(stb.rd_ptr) <= '0';
            end if;
          end loop;
        end if;


        -- LOAD SHEDULE
        if ldb.commit = '1' then
          ldb.buf(ldb.rd_ptr).commited <= '1';
        end if;
      end if;
    end if;
  end process;

  ldb_entry <= (
    addr        => i_disp_va,
    addr_src    => i_disp_ta,
    addr_rdy    => i_disp_ra,
    data        => (others => '-'), -- FIXME: use current entry
    data_dst    => i_disp_tq,
    grp         => std_logic_vector(wr_grp),
    f3          => i_disp_f3,
    busy        => '1',
    commited    => '0',
    done        => '0',
    st_spec     => '0',
    st_dep      => stb_dep
  );

  p_ldb_wr_ptr:
  process(all)
  begin
    for i in 0 to LDB_SIZE-1 loop
      if ldb.buf(i).busy = '0' then
        ldb.wr_ptr <= i;
        exit;
      end if;
    end loop;
  end process;


  p_ldb_full:
  process(all)
    variable full : std_logic := '1';
  begin
    for i in 0 to LDB_SIZE-1 loop
      full := full and ldb.buf(i).busy;
    end loop;

    ldb.full <= full;
  end process;

  ldb.commit <= stb.buf(stb.rd_ptr).addr_rdy and sched_load;


  ---
  -- MEMORY SCHEDULER
  ---

  -- Load have priority over stores
  -- Stores must be checked on rd_ptr
  -- Load must be sent if rdy
  -- If multiple loads are rdy at the same time, randomly select between them
  -- Verify groups



  p_memshed:
  process(i_clk)
  begin
  end process;

  -- shed_load <=
  -- shed_store <=

  -- store I/O
  --sched_store    <= i_mem_wr_ready;

  --o_mem_wr_addr  <= stb.buf(stb.rd_ptr).addr;
  --o_mem_wr_data  <= stb.buf(stb.rd_ptr).data;
  --o_mem_wr_bsel  <= stb.buf(stb.rd_ptr).data_bmask;
  --o_mem_wr_valid <= stb.wr_rdy;

  ---
  -- INTERFACE
  ---

  o_stb_full <= stb.full;
  o_ldb_full <= ldb.full;
  o_grp_full <= grp_full;

end architecture;
