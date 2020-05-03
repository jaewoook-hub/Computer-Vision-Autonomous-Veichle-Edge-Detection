library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.canny_constants.all;
use work.hough_constants.all;

package aved_constants is

  constant IMG_WIDTH      : natural := 10;
  constant IMG_HEIGHT     : natural := 10;
  constant IMG_SIZE       : natural := IMG_WIDTH*IMG_HEIGHT;

  component aved_top is
    port (
      signal clock     : in std_logic;
      signal reset     : in std_logic;
      signal in_wr_en  : in std_logic;
      signal in_din    : in std_logic_vector (23 downto 0);
      signal out_rd_en : in std_logic;
      signal in_full   : out std_logic;
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
  end component aved_top;

  component Canny_Edge_top is
  generic
  (
      constant WIDTH   : integer:= IMG_WIDTH;
      constant HEIGHT  : integer:= IMG_HEIGHT
  );
  port
  (
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
end component Canny_Edge_top;

  component hough_top_ram is
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
  end component hough_top_ram;

  component sram is
  generic (
    mem_file : string
  );
  port (
    clk   : in  std_logic;
  	cs	  : in	std_logic;
  	oe	  :	in	std_logic;
  	we	  :	in	std_logic;
  	addr      :     in	std_logic_vector(19 downto 0);
  	din	  :	in	std_logic_vector(23 downto 0);
  	dout      :	out     std_logic_vector(23 downto 0)
  );
end component sram;


end package;
