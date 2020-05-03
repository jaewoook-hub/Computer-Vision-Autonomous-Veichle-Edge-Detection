library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.canny_constants.all;

entity Canny_Edge_top is
generic (
    constant WIDTH   : integer:= IMG_WIDTH;
    constant HEIGHT  : integer:= IMG_HEIGHT
);
port (
	signal clock     : in std_logic;
	signal reset     : in std_logic;
	signal in_full   : out std_logic;
	signal in_wr_en  : in std_logic;
	signal in_din    : in std_logic_vector (23 downto 0);
  signal in_fifo_empty : out std_logic;
  signal in_fifo_rd_en : out std_logic;
	signal in_fifo_dout     : out std_logic_vector (23 downto 0);
	signal out_rd_en : in std_logic;
	signal out_empty : out std_logic;
	signal out_dout  : out std_logic_vector (7 downto 0)
);
end entity Canny_Edge_top;


architecture behavior of Canny_Edge_top is

    -- configure the grayscale architecture
    for all : grayscale use entity work.grayscale(combinational);
    -- for all : grayscale use entity work.grayscale(behavior);

	-- DATAPATH : in_inst -> gs	-> gs_inst -> gaussian_filter -> gaussain_inst -> sobel -> sobel_inst -> threshold -> threshold_inst -> hysteresis -> hysteresis_inst -> out_inst

	--------------------

	signal in_dout      : std_logic_vector (23 downto 0);
	signal in_empty     : std_logic;
	signal in_rd_en     : std_logic;
    	signal out_din      : std_logic_vector (7 downto 0);
	signal out_full     : std_logic;
	signal out_wr_en    : std_logic;

	signal gs_dout      : std_logic_vector (7 downto 0);
	signal gs_empty     : std_logic;
	signal gs_rd_en     : std_logic;
	signal gs_din       : std_logic_vector (7 downto 0);
	signal gs_full      : std_logic;
	signal gs_wr_en     : std_logic;

	signal gauss_dout   : std_logic_vector (7 downto 0);
	signal gauss_empty  : std_logic;
	signal gauss_rd_en  : std_logic;
	signal gauss_din    : std_logic_vector (7 downto 0);
	signal gauss_full   : std_logic;
	signal gauss_wr_en  : std_logic;

	signal sobel_dout   : std_logic_vector (7 downto 0);
	signal sobel_empty  : std_logic;
	signal sobel_rd_en  : std_logic;
	signal sobel_din    : std_logic_vector (7 downto 0);
	signal sobel_full   : std_logic;
	signal sobel_wr_en  : std_logic;

	signal thresh_dout   : std_logic_vector (MAG_WIDTH - 1 downto 0);
	signal thresh_empty  : std_logic;
	signal thresh_rd_en  : std_logic;
	signal thresh_din    : std_logic_vector (7 downto 0);
	signal thresh_full   : std_logic;
	signal thresh_wr_en  : std_logic;

	signal hyst_dout   : std_logic_vector (7 downto 0);
	signal hyst_empty  : std_logic;
	signal hyst_rd_en  : std_logic;
	signal hyst_din    : std_logic_vector (7 downto 0);
	signal hyst_full   : std_logic;
	signal hyst_wr_en  : std_logic;

begin

  in_fifo_empty   <= in_empty;
  in_fifo_dout    <= in_dout;
  in_fifo_rd_en   <= in_rd_en;

	in_inst : component fifo
	generic map
	(
		FIFO_BUFFER_SIZE => FIFO_BUFF_SIZE,
		FIFO_DATA_WIDTH => FIFO_D_WIDTH*3
	)
	port map
	(
		rd_clk  => clock,
		wr_clk  => clock,
		reset   => reset,
		rd_en   => in_rd_en,
		wr_en   => in_wr_en,
		din     => in_din,
		dout    => in_dout,
		full    => in_full,
		empty   => in_empty
	);

    	grayscale_inst : component grayscale
	port map
	(
		clock       => clock,
		reset       => reset,
		in_dout     => in_dout,
		in_rd_en    => in_rd_en,
		in_empty    => in_empty,
		out_din     => gs_din,
		out_full    => gs_full,
		out_wr_en   => gs_wr_en
	);

	gs_inst : component fifo
	generic map
	(
		FIFO_BUFFER_SIZE => FIFO_BUFF_SIZE,
		FIFO_DATA_WIDTH => FIFO_D_WIDTH
	)
	port map
	(
		rd_clk  => clock,
		wr_clk  => clock,
		reset   => reset,
		rd_en   => gs_rd_en,
		wr_en   => gs_wr_en,
		din     => gs_din,
		dout    => gs_dout,
		full    => gs_full,
		empty   => gs_empty
	);

	gauss_inst : component gaussian
	port map
	(
		clock       => clock,
		reset       => reset,
		in_dout     => gs_dout,
		in_rd_en    => gs_rd_en,
		in_empty    => gs_empty,
		out_din     => gauss_din,
		out_full    => gauss_full,
		out_wr_en   => gauss_wr_en
	);

	gauss_fifo : component fifo
	generic map
	(
		FIFO_BUFFER_SIZE => FIFO_BUFF_SIZE,
		FIFO_DATA_WIDTH  => FIFO_D_WIDTH
	)
	port map
	(
		rd_clk       => clock,
		wr_clk       => clock,
		reset        => reset,
		rd_en        => gauss_rd_en,
		wr_en        => gauss_wr_en,
		din          => gauss_din,
		dout         => gauss_dout,
		full         => gauss_full,
		empty        => gauss_empty
	);

	sobel_inst : component sobel
	port map
	(
		clock       => clock,
		reset       => reset,
		in_dout     => gauss_dout,
		in_rd_en    => gauss_rd_en,
		in_empty    => gauss_empty,
		out_din     => sobel_din,
		out_full    => sobel_full,
		out_wr_en   => sobel_wr_en
	);

	sobel_fifo : component fifo
	generic map
	(
		FIFO_BUFFER_SIZE => FIFO_BUFF_SIZE,
		FIFO_DATA_WIDTH => FIFO_D_WIDTH
	)
	port map
	(
		rd_clk  => clock,
		wr_clk  => clock,
		reset   => reset,
		rd_en   => sobel_rd_en,
		wr_en   => sobel_wr_en,
		din     => sobel_din,
		dout    => sobel_dout,
		full    => sobel_full,
		empty   => sobel_empty
	);

	threshold_inst : component non_maximum_suppression
	port map
	(
		clock       => clock,
		reset       => reset,
		in_dout     => sobel_dout,
		in_rd_en    => sobel_rd_en,
		in_empty    => sobel_empty,
		out_din     => thresh_din,
		out_full    => thresh_full,
		out_wr_en   => thresh_wr_en
	);

	threshold_fifo : component fifo
	generic map
	(
		FIFO_BUFFER_SIZE => FIFO_BUFF_SIZE,
		FIFO_DATA_WIDTH => FIFO_D_WIDTH
	)
	port map
	(
		rd_clk  => clock,
		wr_clk  => clock,
		reset   => reset,
		rd_en   => thresh_rd_en,
		wr_en   => thresh_wr_en,
		din     => thresh_din,
		dout    => thresh_dout,
		full    => thresh_full,
		empty   => thresh_empty
	);

	hysteresis_inst : component hysteresis
	port map
	(
		clock       => clock,
		reset       => reset,
		in_dout     => thresh_dout,
		in_rd_en    => thresh_rd_en,
		in_empty    => thresh_empty,
		out_din     => out_din,
		out_full    => out_full,
		out_wr_en   => out_wr_en
	);

	out_inst : component fifo
	generic map
	(
		FIFO_BUFFER_SIZE => FIFO_BUFF_SIZE,
		FIFO_DATA_WIDTH => FIFO_D_WIDTH
	)
	port map
	(
		rd_clk  => clock,
		wr_clk  => clock,
		reset   => reset,
		rd_en   => out_rd_en,
		wr_en   => out_wr_en,
		din     => out_din,
		dout    => out_dout,
		full    => out_full,
		empty   => out_empty
	);

end architecture behavior;
