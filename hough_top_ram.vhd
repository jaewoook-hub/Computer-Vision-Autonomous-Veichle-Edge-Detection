library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.hough_constants.all;

entity hough_top_ram is
  generic (
    constant WIDTH   : integer:= IMG_WIDTH;
    constant HEIGHT  : integer:= IMG_HEIGHT
  );
  port (
    signal clock     : in std_logic;
    signal reset     : in std_logic;
    signal canny_out_empty  : in std_logic;
    signal in_din    : in std_logic_vector (7 downto 0);
    signal out_rd_en : in std_logic;
    signal in_fifo_empty : in std_logic;
  	signal in_fifo_rd_en : in std_logic;
  	signal in_fifo_dout  : in std_logic_vector (23 downto 0);
    signal in_rd_en  : out std_logic;
    signal out_empty : out std_logic;
    signal out_dout  : out std_logic_vector (7 downto 0);

    -- External RAM
    signal ram_cs           : out std_logic;
    signal ram_read_en      : out std_logic;
    signal ram_wr_en        : out std_logic;
    signal ram_addr         : out std_logic_vector(19 downto 0);
    signal ram_wr_data      : out std_logic_vector(23 downto 0);
    signal ram_rd_data      : in  std_logic_vector(23 downto 0)
  );
end entity hough_top_ram;

architecture behavior of hough_top_ram is

  -- Dataflow:
  -- in_fifo --> accumulator --> accumulator_fifo --> threshold --> threshold_fifo -->
  -- finite_lines --> finite_lines_fifo --> draw_lines --> out_fifo

  -- Accumulator signals
  signal accumulator_rd_en      : std_logic;
  signal accumulator_out_wr_en : std_logic;
  signal accumulator_out_din    : std_logic_vector (7 downto 0);

  signal accumulator_fifo_dout  : std_logic_vector (7 downto 0);
  signal accumulator_out_full   : std_logic;
  signal accumulator_fifo_empty : std_logic;

  -- Threshold signals
  signal threshold_fifo_dout  : std_logic_vector (17 downto 0);
  signal threshold_rho_theta  : std_logic_vector (17 downto 0);
  signal threshold_rho        : std_logic_vector (9 downto 0);
  signal threshold_theta      : std_logic_vector (7 downto 0);
  signal threshold_done       : std_logic;

  signal threshold_rd_en     : std_logic;
  signal threshold_wr_en     : std_logic;
  signal threshold_out_full  : std_logic;
  signal threshold_out_empty : std_logic;

  -- Finite line signals
  signal xy_rd_en : std_logic;
  signal xy_wr_en : std_logic;
  signal xy_done  : std_logic;
  signal x1       : std_logic_vector (9 downto 0);
  signal x2       : std_logic_vector (9 downto 0);
  signal y1       : std_logic_vector (9 downto 0);
  signal y2       : std_logic_vector (9 downto 0);
  signal xy_coord : std_logic_vector (39 downto 0);
  signal xy_fifo_dout : std_logic_vector (39 downto 0);
  signal xy_out_full  : std_logic;
  signal xy_out_empty : std_logic;

  -- Draw line signals
  signal drawlines_rd_en : std_logic;
  signal drawlines_wr_en : std_logic;
  signal drawlines_full  : std_logic;
  signal drawlines_dout_din : std_logic_vector (7 downto 0);

begin

  in_rd_en  <= accumulator_rd_en;

  accumulator_inst : component accumulator
  port map (
    clock       => clock,
    reset       => reset,
    in_dout     => in_din,
    in_rd_en    => accumulator_rd_en,
    in_empty    => canny_out_empty,
    out_din     => accumulator_out_din,
    out_full    => accumulator_out_full,
    out_wr_en   => accumulator_out_wr_en
  );

  accumulator_fifo_inst : component fifo
  generic map (
    FIFO_BUFFER_SIZE => FIFO_BUFF_SIZE,
    FIFO_DATA_WIDTH => FIFO_D_WIDTH
  )
  port map (
    rd_clk  => clock,
    wr_clk  => clock,
    reset   => reset,
    rd_en   => threshold_rd_en,
    wr_en   => accumulator_out_wr_en,
    din     => accumulator_out_din,
    dout    => accumulator_fifo_dout,
    full    => accumulator_out_full,  -- output to accumulator_inst
    empty   => accumulator_fifo_empty
  );


  threshold_inst : threshold
  port map  (
    clock        => clock,
    reset        => reset,
    in_rd_en     => threshold_rd_en,        -- output
    in_empty     => accumulator_fifo_empty,       -- input
    in_dout      => accumulator_fifo_dout,        -- input
    out_full     => threshold_out_full,     -- input
    out_wr_en    => threshold_wr_en     ,   -- output
    out_rho_done => threshold_done,
    out_rho      => threshold_rho,          -- output: 10 bits
    out_theta    => threshold_theta         -- output:  8 bits
  );

  threshold_rho_theta <= threshold_rho & threshold_theta;

  threshold_fifo_inst : component fifo
  generic map (
    FIFO_BUFFER_SIZE => FIFO_BUFF_SIZE,
    FIFO_DATA_WIDTH  => 18
  )
  port map (
    rd_clk  => clock,
    wr_clk  => clock,
    reset   => reset,
    rd_en   => xy_rd_en,
    wr_en   => threshold_wr_en,
    din     => threshold_rho_theta,
    dout    => threshold_fifo_dout,
    full    => threshold_out_full,  -- output
    empty   => threshold_out_empty
  );


  finite_lines_inst : finite_lines
  port map (
    clock         => clock,
    reset         => reset,
    in_empty      => threshold_out_empty,    -- input
    out_full      => xy_out_full,            -- input
    in_rho        => threshold_fifo_dout(17 downto 8),
    in_theta      => threshold_fifo_dout(7 downto 0),
    in_rho_done   => threshold_done,
    in_rd_en      => xy_rd_en,
    out_wr_en     => xy_wr_en,
    out_xy_done   => xy_done,
    x1            => x1,
    x2            => x2,
    y1            => y1,
    y2            => y2
  );

  xy_coord <= y2 & y1 & x2 & x1;

  xy_fifo_inst : component fifo
  generic map (
    FIFO_BUFFER_SIZE => FIFO_BUFF_SIZE,
    FIFO_DATA_WIDTH  => 40
  )
  port map (
    rd_clk  => clock,
    wr_clk  => clock,
    reset   => reset,
    rd_en   => drawlines_rd_en,
    wr_en   => xy_wr_en,
    din     => xy_coord,
    dout    => xy_fifo_dout,
    full    => xy_out_full,  -- output
    empty   => xy_out_empty
  );

  drawlines_inst : draw_lines_ram
  port map (
    clock	              => clock,
    reset	              => reset,
    x1                  => xy_fifo_dout(9 downto 0),
    x2                  => xy_fifo_dout(19 downto 10),
    y1                  => xy_fifo_dout(29 downto 20),
    y2                  => xy_fifo_dout(39 downto 30),
    xy_in_empty         => xy_out_empty,
    xy_done	            => xy_done,
    in_rd_en            => drawlines_rd_en,
    in_empty            => in_fifo_empty,  -- Original image, same input to Canny
    accumulator_rd_en   => in_fifo_rd_en,  -- store/read original image
    in_dout	            => in_fifo_dout,     -- Input data TO Canny [23:0]
    out_wr_en           => drawlines_wr_en,
    out_full            => drawlines_full,      -- input
    out_din	            => drawlines_dout_din,

    -- External RAM
    ram_cs      => ram_cs,
    ram_oe      => ram_read_en,
    ram_we      => ram_wr_en,
    ram_addr    => ram_addr,
    ram_wr_data => ram_wr_data,
    ram_rd_data    => ram_rd_data
  );

  out_fifo_inst : component fifo
  generic map (
    FIFO_BUFFER_SIZE => FIFO_BUFF_SIZE,
    FIFO_DATA_WIDTH  => FIFO_D_WIDTH
  )
  port map (
    rd_clk  => clock,
    wr_clk  => clock,
    reset   => reset,
    rd_en   => out_rd_en,
    wr_en   => drawlines_wr_en,
    din     => drawlines_dout_din,
    dout    => out_dout,
    full    => drawlines_full,  -- output
    empty   => out_empty
  );

end architecture behavior;
