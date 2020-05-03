library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.hough_constants.all;
use IEEE.MATH_REAL.ALL;

entity accumulator is
	port (
		signal clock         : in  std_logic;
		signal reset         : in  std_logic;
		signal in_rd_en      : out std_logic;
		signal in_empty      : in  std_logic;
		signal in_dout       : in  std_logic_vector(7 downto 0);
		signal out_wr_en     : out std_logic;
		signal out_full      : in  std_logic;
		signal out_din       : out std_logic_vector(7 downto 0)
	);
end entity accumulator;

architecture behavior of accumulator is

	type accu is array (natural range <> ) of std_logic_vector(7 downto 0);
	signal center_x        : integer := IMG_WIDTH/2;
	signal center_y        : integer := IMG_HEIGHT/2;
	signal x, x_c       		: integer;
	signal y, y_c       		: integer;

	TYPE state_types is (s0,s1,s1a,s2,s3);
	signal state        : state_types;
	signal next_state   : state_types;
	signal accu_array, accu_array_c  : accu(0 to (ACCU_HEIGHT*ACCU_WIDTH)-1);

	signal theta,theta_c : integer:= 0;
	signal cos_theta : std_logic_vector (15 downto 0);
	signal sin_theta : std_logic_vector (15 downto 0);

	signal theta_in     : std_logic_vector (7 downto 0);
	signal cos_theta_neg : std_logic_vector (15 downto 0);
	signal cos_theta_int : integer;

	--sqrt2= 1.41421356
	--PI=3.14159265

begin

	cos_table_inst : cos_table
	port map (
		theta      => theta_in,
		cos_theta  => cos_theta
	);

	sin_table_inst : sin_table
	port map (
		theta      => theta_in,
		sin_theta  => sin_theta
	);

	cos_theta_neg  <= std_logic_vector(to_signed(cos_theta_int,16));

	accumulate_process : process( state, in_dout, x, y, in_empty, out_full, theta,cos_theta,sin_theta,cos_theta_neg ) is
		variable r, temp : signed (31 downto 0);
		variable x_position, y_position : signed (15 downto 0);
		variable accu_index     		: integer;
	begin
		next_state <= state;
		x_c <= x;
		y_c <= y;
		accu_array_c <= accu_array;
		in_rd_en <= '0';
		out_wr_en <= '0';
		out_din   <= (others => '0');


		if (theta >= 90) then
			theta_in   <= std_logic_vector(to_unsigned((180 - theta),8));
		else
			theta_in   <= std_logic_vector(to_unsigned(theta,8));
		end if;

		if (theta > 90) then
			cos_theta_int <=  -(to_integer(unsigned(cos_theta)));
		else
			cos_theta_int <=  to_integer(unsigned(cos_theta));
		end if;

		case ( state ) is
			when s0 =>
				x_c <= 0;
				y_c <= 0;
				theta_c   <= 0;
				accu_array_c <= (others => (others => '0'));
				next_state <= s1;
			when s1 =>
				if ( in_empty = '0' ) then
					in_rd_en <= '1';
					-- pixel <= in_dout;
					x_c <= x + 1;
					if (to_integer(unsigned(in_dout)) > IMG_THRESHOLD) then
						next_state <= s2;
					end if;

					if ( x = IMG_WIDTH - 1 ) then
						x_c <= 0;
						y_c <= y + 1;
					end if;
					if ( (x = (IMG_WIDTH -1)) AND (y = (IMG_HEIGHT -1)) )then
						x_c <= 0;
						y_c <= 0;
						next_state <= s3;
					end if;
				end if;
			when s2 =>
				in_rd_en <= '0';
				x_position :=  to_signed((x - W_div2),  16);
				y_position :=  to_signed((y - H_div2), 16);
				r := x_position*signed(cos_theta_neg) + y_position*signed(sin_theta);  -- cordic is quantized to 2^14

				temp:= (HOUGH_H + r) srl 14;  -- dequantized
				-- accu_array_c(to_integer(temp)*ACCU_WIDTH + theta) <= accu_array(to_integer(temp)*ACCU_WIDTH + theta) + 1;

				accu_index := to_integer(temp)*ACCU_WIDTH + theta;
				if (accu_index > ACCU_HEIGHT*ACCU_WIDTH-1) then
					 accu_index := ACCU_HEIGHT*ACCU_WIDTH-1;
				end if;
				accu_array_c(accu_index) <= std_logic_vector(to_unsigned(to_integer(unsigned(accu_array(accu_index)) + 1),8));
				theta_c <= theta + 1;

				if (theta = 180) then
					theta_c <= 0;
					next_state <= s1;
				end if;
			when s3 =>
				--output the accumulator
				out_wr_en <= '1';
				-- out_din <=  std_logic_vector(to_unsigned(accu_array(x + y*ACCU_WIDTH), 8));
				out_din <=  accu_array(x + y*ACCU_WIDTH);
				x_c <= x + 1;
				if ( x = (ACCU_WIDTH -1)) then
					x_c <= 0;
					y_c <= y + 1;
				end if;
				if ( (x = (ACCU_WIDTH -1)) AND (y = (ACCU_HEIGHT -1))) then
					x_c <= 0;
					y_c <= 0;
					next_state <= s0;
				end if;
			when others =>
				x_c <= 0;
				y_c <= 0;
				next_state <= s0;
		end case;
	end process;

	clock_process : process( clock, reset ) is
	begin
		if ( reset = '1' ) then
			state <= s0;
			x <= 0;
			y <= 0;
			theta<= 0;
			accu_array <= (others => (others => '0'));
		elsif ( rising_edge(clock) ) then
			state <= next_state after 1 ps;
			x <= x_c after 1 ps;
			y <= y_c after 1 ps;
			theta <= theta_c after 1 ps;
			accu_array <= accu_array_c;
		end if;
	end process;

end architecture;
