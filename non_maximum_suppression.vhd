library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.canny_constants.all; 

entity non_maximum_suppression is
	port (
		signal clock		: in std_logic;
		signal reset		: in std_logic;
		signal in_rd_en		: out std_logic;
		signal in_empty		: in std_logic;
		signal in_dout		: in std_logic_vector (MAG_WIDTH - 1 downto 0);
		signal out_wr_en	: out std_logic;
		signal out_full		: in std_logic;
		signal out_din		: out std_logic_vector (MAG_WIDTH - 1 downto 0)
		);
end entity non_maximum_suppression;

architecture behavioral of non_maximum_suppression is

	constant REG_SIZE   : integer := (IMG_WIDTH * 2) + 3; -- size of shift register

	type ARRAY_SLV is array (natural range <> ) of std_logic_vector (MAG_WIDTH - 1 downto 0);
	signal shift_reg    : ARRAY_SLV (0 to REG_SIZE - 1);
	signal shift_reg_c  : ARRAY_SLV (0 to REG_SIZE - 1);

	type state_types is (s0,s1,s2,s3,s4);
	signal state        : state_types;
	signal next_state   : state_types;

	signal x, x_c       : integer; -- x-coordinate
	signal y, y_c       : integer; -- y-coordinate

	function nms_op (data : ARRAY_SLV(0 to 8)) return std_logic_vector is
		variable img_current_mag	: std_logic_vector (MAG_WIDTH - 1 downto 0);
		variable img_top_mag		: std_logic_vector (MAG_WIDTH - 1 downto 0);
		variable img_bot_mag		: std_logic_vector (MAG_WIDTH - 1 downto 0);
		variable img_left_mag		: std_logic_vector (MAG_WIDTH - 1 downto 0);
		variable img_right_mag		: std_logic_vector (MAG_WIDTH - 1 downto 0);
		variable img_ne_mag		: std_logic_vector (MAG_WIDTH - 1 downto 0);
		variable img_nw_mag		: std_logic_vector (MAG_WIDTH - 1 downto 0);
		variable img_se_mag		: std_logic_vector (MAG_WIDTH - 1 downto 0);
		variable img_sw_mag		: std_logic_vector (MAG_WIDTH - 1 downto 0);
		variable north_south		: integer range 0 to 2**(MAG_WIDTH + 1) - 1;  -- 2^MAG_WIDTH - 1
		variable east_west		: integer range 0 to 2**(MAG_WIDTH + 1) - 1;
		variable north_west		: integer range 0 to 2**(MAG_WIDTH + 1) - 1;
		variable north_east		: integer range 0 to 2**(MAG_WIDTH + 1) - 1;
		variable all_zeros		: std_logic_vector (MAG_WIDTH - 1 downto 0) := (others => '0');
	begin
		-- previous row
		img_nw_mag := data(0);
		img_top_mag := data(1);
		img_ne_mag := data(2);
		-- middle row
		img_left_mag := data(3);
		img_current_mag := data(4);
		img_right_mag := data(5);
		-- next row
		img_sw_mag := data(6);
		img_bot_mag := data(7);
		img_se_mag := data(8);

		north_south := to_integer(unsigned(img_top_mag)) + to_integer(unsigned(img_bot_mag)); -- North + South
		east_west   := to_integer(unsigned(img_right_mag)) + to_integer(unsigned(img_left_mag)); -- East + West
		north_west  := to_integer(unsigned(img_nw_mag)) + to_integer(unsigned(img_se_mag)); -- Northwest + SouthEast
		north_east  := to_integer(unsigned(img_sw_mag)) + to_integer(unsigned(img_ne_mag)); -- Northeast + SouthWest

		if (north_south >= east_west) and (north_south >= north_west) and (north_south >= north_east) then
			if (img_current_mag > img_left_mag) and (img_current_mag >= img_right_mag) then      -- compare current with west and east
				return img_current_mag;
			else
				return all_zeros;
			end if;  -- left and right neighbors

		elsif (east_west >= north_west) and (east_west >= north_east) then
			if (img_current_mag > img_top_mag) and (img_current_mag >= img_bot_mag) then  -- compare current with north and north
				return img_current_mag;
			else
				return all_zeros;
			end if; -- top and bottom neighbors

		elsif (north_west >= north_east) then
			if (img_current_mag > img_ne_mag) and (img_current_mag >= img_sw_mag) then -- compare current with north_east and south_west
				return img_current_mag;
			else
				return all_zeros;
			end if; -- southeast and northwest neighbors

		else
			if (img_current_mag > img_nw_mag) and (img_current_mag >= img_se_mag) then --
				-- compare current with north_west and south_east
				return img_current_mag;
			else
				return all_zeros;
			end if; -- southwest and northeast neighbors
		end if;
    	end nms_op;

begin

	nms_process : process(state, in_empty, in_dout, out_full, x, y, shift_reg) is
		variable nmax_supp_out	: std_logic_vector (MAG_WIDTH - 1 downto 0) := (others => '0');
		variable data		: ARRAY_SLV (0 to 8);
	begin
		next_state <= state;
		x_c <= x;
		y_c <= y;
		shift_reg_c <= shift_reg;
		in_rd_en <= '0';
		out_wr_en <= '0';
		out_din <= (others => '0');

		for i in 0 to 2 loop
			for j in 0 to 2 loop
				data(i*3+j) := shift_reg (i*IMG_WIDTH + j);
			end loop;
		end loop;

		nmax_supp_out := (others => '0');
		if ( (x /= 0) AND (x /= IMG_WIDTH-1) AND (y /= 0) AND (y /= IMG_HEIGHT-1) ) then
			nmax_supp_out := nms_op (data);
		end if;

		case (state) is
			when s0 =>
				x_c <= 0;
				y_c <= 0;
				shift_reg_c <= (others => (others => '0'));
				next_state <= s1;

			when s1 =>
				if (in_empty = '0') then
					in_rd_en <= '1';
					shift_reg_c(0 to REG_SIZE-2) <= shift_reg(1 to REG_SIZE-1);
					shift_reg_c(REG_SIZE-1) <= in_dout;
					x_c <= x + 1;
					if ( x = IMG_WIDTH - 1 ) then
						x_c <= 0;
						y_c <= y + 1;
					end if;
					if ( (y * IMG_WIDTH + x) = (IMG_WIDTH + 1) ) then
						x_c <= x - 1;
						y_c <= y - 1;
						next_state <= s2;
					end if;
				end if;

			when s2 =>
				if ( in_empty = '0' AND out_full = '0' ) then
					shift_reg_c(0 to REG_SIZE-2) <= shift_reg(1 to REG_SIZE-1);
					shift_reg_c(REG_SIZE-1) <= in_dout;
					x_c <= x + 1;
					if ( x = IMG_WIDTH - 1 ) then
						x_c <= 0;
						y_c <= y + 1;
					end if;

					out_din <= nmax_supp_out;
					in_rd_en <= '1';
					out_wr_en <= '1';
					if ( y = IMG_HEIGHT-2 AND x = IMG_WIDTH-3 ) then
						next_state <= s3;
					else
						next_state <= s2;
					end if;
				end if;

			when s3 =>
				if ( out_full = '0' ) then
					x_c <= x + 1;
					if ( x = IMG_WIDTH - 1 ) then
						x_c <= 0;
						y_c <= y + 1;
					end if;
					out_din <= nmax_supp_out;
					out_wr_en <= '1';
					if ( (x = IMG_WIDTH-1) AND (y = IMG_HEIGHT-1) ) then
						next_state <= s0;
					end if;
				end if;

			when others =>
				x_c <= 0;
				y_c <= 0;
				shift_reg_c <= (others => (others => 'X'));
				next_state <= s0;
		end case;
	end process nms_process;


	clock_process : process (clock, reset) is
	begin
		if (reset = '1') then
			state <= s0;
			x <= 0;
			y <= 0;
			shift_reg <= (others => (others => '0'));
		elsif (rising_edge(clock)) then
			state <= next_state;
			x <= x_c;
			y <= y_c;
			shift_reg <= shift_reg_c;
		end if;
	end process clock_process;

end architecture behavioral;
