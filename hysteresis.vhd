library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.canny_constants.all;

entity hysteresis is
port
(
	signal clock        : in  std_logic;
    signal reset        : in  std_logic;
	signal in_rd_en     : out std_logic;
	signal in_empty     : in  std_logic;
	signal in_dout      : in  std_logic_vector(MAG_WIDTH - 1 downto 0);
	signal out_wr_en	: out std_logic;
	signal out_full     : in  std_logic;
	signal out_din      : out std_logic_vector(MAG_WIDTH - 1 downto 0)
);
end entity hysteresis;

architecture behavior of hysteresis is

	constant REG_SIZE   : integer := (IMG_WIDTH * 2) + 3;

	type ARRAY_INT is array (natural range <> ) of integer;
	type ARRAY_SLV is array (natural range <> ) of std_logic_vector(MAG_WIDTH-1 downto 0);
	signal shift_reg    : ARRAY_SLV (0 to REG_SIZE-1);
	signal shift_reg_c  : ARRAY_SLV (0 to REG_SIZE-1);

	TYPE state_types is (s0,s1,s2,s3,s4);
	signal state        : state_types;
	signal next_state   : state_types;

	signal x, x_c       : integer; -- x-coordinate
	signal y, y_c       : integer; -- y-coordinate

	function hysteresis_op(data : ARRAY_SLV(0 to 8))
	return std_logic_vector is
		variable img_current_mag	: std_logic_vector (MAG_WIDTH - 1 downto 0);
		variable img_top_mag			: std_logic_vector (MAG_WIDTH - 1 downto 0);
		variable img_bot_mag			: std_logic_vector (MAG_WIDTH - 1 downto 0);
		variable img_left_mag		: std_logic_vector (MAG_WIDTH - 1 downto 0);
		variable img_right_mag		: std_logic_vector (MAG_WIDTH - 1 downto 0);
		variable img_ne_mag			: std_logic_vector (MAG_WIDTH - 1 downto 0);
		variable img_nw_mag			: std_logic_vector (MAG_WIDTH - 1 downto 0);
		variable img_se_mag			: std_logic_vector (MAG_WIDTH - 1 downto 0);
		variable img_sw_mag			: std_logic_vector (MAG_WIDTH - 1 downto 0);
		variable all_zeros			: std_logic_vector (MAG_WIDTH - 1 downto 0) := (others => '0');
		constant HIGH_THRESHOLD 	: integer:= 48;
		constant LOW_THRESHOLD 		: integer:= 12;
	begin
		-- in_data[y*width + x] = img_current_mag
		-- in_data[y*width + x - 1] = img_left_mag
		-- in_data[y*IMG_WIDTH + x + 1] = img_right_mag
		-- in_data[(y-1)*IMG_WIDTH + x] = img_top_mag
		-- in_data[(y+1)*IMG_WIDTH + x] = img_bot_mag
		-- in_data[(y-1)*IMG_WIDTH + x + 1] = img_ne_mag
		-- in_data[(y+1)*IMG_WIDTH + x - 1] = img_sw_mag
		-- in_data[(y-1)*IMG_WIDTH + x - 1] = img_nw_mag
		-- in_data[(y+1)*IMG_WIDTH + x + 1] = img_se_mag

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

		if (to_integer(unsigned(img_current_mag)) > HIGH_THRESHOLD or
			(to_integer(unsigned(img_current_mag)) > LOW_THRESHOLD and
			(to_integer(unsigned(img_nw_mag)) > HIGH_THRESHOLD or
			to_integer(unsigned(img_top_mag)) > HIGH_THRESHOLD or
			to_integer(unsigned(img_ne_mag)) > HIGH_THRESHOLD or
			to_integer(unsigned(img_left_mag)) > HIGH_THRESHOLD or
			to_integer(unsigned(img_right_mag)) > HIGH_THRESHOLD or
			to_integer(unsigned(img_sw_mag)) > HIGH_THRESHOLD or
			to_integer(unsigned(img_bot_mag)) > HIGH_THRESHOLD or
			to_integer(unsigned(img_se_mag)) > HIGH_THRESHOLD))) then
				return img_current_mag;
			else
				return all_zeros;
		end if;
	end hysteresis_op;

begin

	hysteresis_process : process( state, in_empty, in_dout, out_full, x, y, shift_reg ) is

		variable result : std_logic_vector(MAG_WIDTH-1 downto 0);
		variable data   : ARRAY_SLV(0 to 8);

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
				data(i*3+j) := shift_reg(i*IMG_WIDTH + j);
			end loop;
		end loop;

		result := (others => '0');
		if ( (x /= 0) AND (x /= IMG_WIDTH-1) AND (y /= 0) AND (y /= IMG_HEIGHT-1) ) then
			result := hysteresis_op(data);
		end if;

		case ( state ) is
			when s0 =>
				x_c <= 0;
				y_c <= 0;
				shift_reg_c <= (others => (others => '0'));
				next_state <= s1;

			when s1 =>
				if ( in_empty = '0' ) then
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

						  out_din <= result;
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
							  out_din <= result;
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
		 end process hysteresis_process;

    clock_process : process( clock, reset ) is
    begin
        if ( reset = '1' ) then
            state <= s0;
            x <= 0;
            y <= 0;
            shift_reg <= (others => (others => '0'));
        elsif ( rising_edge(clock) ) then
            state <= next_state;
            x <= x_c;
            y <= y_c;
            shift_reg <= shift_reg_c;
        end if;
    end process clock_process;

end architecture behavior;
