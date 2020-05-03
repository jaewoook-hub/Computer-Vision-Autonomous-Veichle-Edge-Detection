library IEEE;
use IEEE.std_logic_1164.all;
-- use ieee.std_logic_arith.all;
use IEEE.numeric_std.all;
-- use IEEE.numeric_std_unsigned;
use work.hough_constants.all;

entity threshold is
  port (
    signal clock		: in std_logic;
    signal reset		: in std_logic;
    signal in_rd_en		: out std_logic;
    signal in_empty		: in std_logic;
    signal out_full		: in std_logic;
    signal in_dout		: in std_logic_vector (MAG_WIDTH - 1 downto 0); -- accumulator input
    signal out_wr_en	: out std_logic;  -- '1' when out_rho and out_theta are valid
    signal out_rho_done	: out std_logic;  -- RHO/THETA calculation done
    signal out_rho	        : out std_logic_vector (RHO_WIDTH - 1 downto 0);
    signal out_theta	: out std_logic_vector (THETA_WIDTH - 1 downto 0)
  );
end entity threshold;

architecture behavioral of threshold is

  constant REG_SIZE   : integer := (ACCU_WIDTH * 6) + 7; -- size of shift register,7x7 window

  type ARRAY_SLV is array (natural range <> ) of std_logic_vector (MAG_WIDTH - 1 downto 0);
  signal shift_reg    : ARRAY_SLV (0 to REG_SIZE - 1);
  signal shift_reg_c  : ARRAY_SLV (0 to REG_SIZE - 1);

  type state_types is (s0,s1,s2,s3,s4);
  signal state        : state_types;
  signal next_state   : state_types;

  signal x, x_c       : integer; -- x-coordinate
  signal y, y_c       : integer; -- y-coordinate
  signal rho          : integer;
  signal theta        : integer;


  signal data_valid    : std_logic;
  signal rho_done_c    : std_logic;
  signal rho_done      : std_logic;
  signal accu_data      : integer;

  -- Use 7x7 window to do noise filtering, coordinate is only valid if it's local maximum
  function h_threshold_op (data : ARRAY_SLV(0 to 48)) return std_logic is
    variable accu_00		: integer;
    variable accu_01		: integer;
    variable accu_02		: integer;
    variable accu_03		: integer;
    variable accu_04		: integer;
    variable accu_05		: integer;
    variable accu_06		: integer;
    variable accu_07		: integer;
    variable accu_08		: integer;
    variable accu_09		: integer;
    variable accu_10		: integer;
    variable accu_11		: integer;
    variable accu_12		: integer;
    variable accu_13		: integer;
    variable accu_14		: integer;
    variable accu_15		: integer;
    variable accu_16		: integer;
    variable accu_17		: integer;
    variable accu_18		: integer;
    variable accu_19		: integer;
    variable accu_20		: integer;
    variable accu_21		: integer;
    variable accu_22		: integer;
    variable accu_23		: integer;
    variable current_accu           : integer;  -- pixel 24 is the current
    -- variable accu_24		: integer;
    -- 7x7
    variable accu_25		: integer;
    variable accu_26		: integer;
    variable accu_27		: integer;
    variable accu_28		: integer;
    variable accu_29		: integer;
    variable accu_30		: integer;
    variable accu_31		: integer;
    variable accu_32		: integer;
    variable accu_33		: integer;
    variable accu_34		: integer;
    variable accu_35		: integer;
    variable accu_36		: integer;
    variable accu_37		: integer;
    variable accu_38		: integer;
    variable accu_39		: integer;
    variable accu_40		: integer;
    variable accu_41		: integer;
    variable accu_42		: integer;
    variable accu_43		: integer;
    variable accu_44		: integer;
    variable accu_45		: integer;
    variable accu_46		: integer;
    variable accu_47		: integer;
    variable accu_48		: integer;
    --
    variable local_max_1		: std_logic;
    variable local_max_2		: std_logic;
    variable zero		        : std_logic := '0';
    variable one		        : std_logic := '1';

  begin
    -- previous rows
    accu_00  := to_integer(unsigned(data(0)));
    accu_01  := to_integer(unsigned(data(1)));
    accu_02  := to_integer(unsigned(data(2)));
    accu_03  := to_integer(unsigned(data(3)));
    accu_04  := to_integer(unsigned(data(4)));
    accu_05  := to_integer(unsigned(data(5)));
    accu_06  := to_integer(unsigned(data(6)));
    accu_07  := to_integer(unsigned(data(7)));
    accu_08  := to_integer(unsigned(data(8)));
    accu_09  := to_integer(unsigned(data(9)));
    accu_10  := to_integer(unsigned(data(10)));
    accu_11  := to_integer(unsigned(data(11)));
    accu_12  := to_integer(unsigned(data(12)));
    accu_13  := to_integer(unsigned(data(13)));
    accu_14  := to_integer(unsigned(data(14)));
    accu_15  := to_integer(unsigned(data(15)));
    accu_16  := to_integer(unsigned(data(16)));
    accu_17  := to_integer(unsigned(data(17)));
    accu_18  := to_integer(unsigned(data(18)));
    accu_19  := to_integer(unsigned(data(19)));
    accu_20  := to_integer(unsigned(data(20)));
    accu_21  := to_integer(unsigned(data(21)));
    accu_22  := to_integer(unsigned(data(22)));
    accu_23  := to_integer(unsigned(data(23)));
    --
    current_accu := to_integer(unsigned(data(24)));
    -- next rows
    accu_25  := to_integer(unsigned(data(25)));
    accu_26  := to_integer(unsigned(data(26)));
    accu_27  := to_integer(unsigned(data(27)));
    accu_28  := to_integer(unsigned(data(28)));
    accu_29  := to_integer(unsigned(data(29)));
    accu_30  := to_integer(unsigned(data(30)));
    accu_31  := to_integer(unsigned(data(31)));
    accu_32  := to_integer(unsigned(data(32)));
    accu_33  := to_integer(unsigned(data(33)));
    accu_34  := to_integer(unsigned(data(34)));
    accu_35  := to_integer(unsigned(data(35)));
    accu_36  := to_integer(unsigned(data(36)));
    accu_37  := to_integer(unsigned(data(37)));
    accu_38  := to_integer(unsigned(data(38)));
    accu_39  := to_integer(unsigned(data(39)));
    accu_40  := to_integer(unsigned(data(40)));
    accu_41  := to_integer(unsigned(data(41)));
    accu_42  := to_integer(unsigned(data(42)));
    accu_43  := to_integer(unsigned(data(43)));
    accu_44  := to_integer(unsigned(data(44)));
    accu_45  := to_integer(unsigned(data(45)));
    accu_46  := to_integer(unsigned(data(46)));
    accu_47  := to_integer(unsigned(data(47)));
    accu_48  := to_integer(unsigned(data(48)));

    -- Only return valid coordinate (r,Theta) if current_acc > THRESHOLD and is local maximum.
    -- The valid coordinate (r,Theta) will be converted back to two points (X1,Y1) and (X2,Y2) in image space.
    -- 7x7 neighbor window, check 49 values
    -- Check the first 24
    if ((accu_00 > current_accu) or (accu_01  > current_accu) or (accu_02  > current_accu)  or (accu_03  > current_accu) or (accu_04  > current_accu)
    or (accu_05  > current_accu) or (accu_06  > current_accu) or (accu_07  > current_accu) or (accu_08  > current_accu) or (accu_09  > current_accu)
    or (accu_10  > current_accu) or (accu_11  > current_accu) or (accu_12  > current_accu) or (accu_13  > current_accu) or (accu_14  > current_accu)
    or (accu_15  > current_accu) or (accu_16  > current_accu) or (accu_17  > current_accu) or (accu_18  > current_accu) or (accu_19  > current_accu)
    or (accu_20  > current_accu) or (accu_21  > current_accu) or (accu_22  > current_accu) or (accu_23  > current_accu)) then
      local_max_1 := '0';
    else
      local_max_1 := '1';
    end if;
    -- Check the second set of 24
    if ((accu_25 > current_accu) or (accu_26  > current_accu) or (accu_27  > current_accu)  or (accu_28  > current_accu) or (accu_29  > current_accu)
    or (accu_30  > current_accu) or (accu_31  > current_accu) or (accu_32  > current_accu) or (accu_33  > current_accu) or (accu_34  > current_accu)
    or (accu_35  > current_accu) or (accu_36  > current_accu) or (accu_37  > current_accu) or (accu_38  > current_accu) or (accu_39  > current_accu)
    or (accu_40  > current_accu) or (accu_41  > current_accu) or (accu_42  > current_accu) or (accu_43  > current_accu) or (accu_44  > current_accu)
    or (accu_45  > current_accu) or (accu_46  > current_accu) or (accu_47  > current_accu) or (accu_48  > current_accu)) then
      local_max_2 := '0';
    else
      local_max_2 := '1';
    end if;


    if ((current_accu > ACCU_THRESHOLD) and (local_max_1 = '1') and (local_max_2 = '1')) then
      return one;
    else
      return zero;
    end if;

  end h_threshold_op;

begin

  out_rho_done <= rho_done;

  h_thresh_process : process(state, in_empty, in_dout, out_full, x, y, shift_reg) is
    variable data		: ARRAY_SLV (0 to 48);
    variable coord_valid    : std_logic;
  begin
    next_state <= state;
    x_c <= x;
    y_c <= y;
    shift_reg_c <= shift_reg;
    in_rd_en    <= '0';
    rho_done_c  <= rho_done;

    -- 7x7 window
    for i in 0 to 6 loop                 -- row
      for j in 0 to 6 loop         -- column
        data(i*7+j) := shift_reg (i*ACCU_WIDTH + j);
      end loop;
    end loop;

    coord_valid := '0';
    accu_data   <= to_integer(unsigned(data(24)));  -- current_pixel, debug purpose
    if ( (x /= 0) AND (x /= ACCU_WIDTH-1) AND (y /= 0) AND (y /= ACCU_HEIGHT-1) ) then
      coord_valid := h_threshold_op (data);
      if (coord_valid = '1')  then
        rho     <= y-3;   -- 3 rows and column offset due to 7x7 window
        theta   <= x-3;
      else
        rho     <= 0;
        theta   <= 0;
      end if;
    end if;

    data_valid <= coord_valid;
    case (state) is
      when s0 =>
        x_c <= 0;
        y_c <= 0;
        shift_reg_c <= (others => (others => '0'));
        next_state <= s1;

      when s1 =>      -- 1st row
        if (in_empty = '0') then
          rho_done_c  <= '0';
          in_rd_en <= '1';
          shift_reg_c(0 to REG_SIZE-2) <= shift_reg(1 to REG_SIZE-1);
          shift_reg_c(REG_SIZE-1) <= in_dout;
          next_state <= s2;
        end if;

      when s2 =>
        if ( in_empty = '0' AND out_full = '0' ) then
          shift_reg_c(0 to REG_SIZE-2) <= shift_reg(1 to REG_SIZE-1);
          shift_reg_c(REG_SIZE-1) <= in_dout;
          x_c <= x + 1;
          if ( x = ACCU_WIDTH - 1 ) then
            x_c <= 0;
            y_c <= y + 1;
          end if;

          in_rd_en <= '1';

          if ( y = ACCU_HEIGHT-2 AND x = ACCU_WIDTH-3 ) then
            next_state <= s3;
          else
            next_state <= s2;
          end if;
        end if;

      when s3 =>     -- last row
        if ( out_full = '0' ) then
          x_c <= x + 1;
          if ( x = ACCU_WIDTH - 1 ) then
            x_c <= 0;
            y_c <= y + 1;
          end if;

          if ( (x = ACCU_WIDTH-1) AND (y = ACCU_HEIGHT-1) ) then
            next_state  <= s0;
            rho_done_c  <= '1';
          end if;
        end if;

      when others =>
        x_c <= 0;
        y_c <= 0;
        shift_reg_c <= (others => (others => 'X'));
        next_state <= s0;
    end case;
  end process h_thresh_process;

  clock_process : process (clock, reset) is
  begin
    if (reset = '1') then
      state <= s0;
      x <= 0;
      y <= 0;
      shift_reg <= (others => (others => '0'));
      out_rho   <= (others => '0');
      out_theta <= (others => '0');
      rho_done  <= '0';
      out_wr_en <= '0';
    elsif (rising_edge(clock)) then
      state         <= next_state;
      rho_done      <= rho_done_c;
      x <= x_c;
      y <= y_c;
      shift_reg <= shift_reg_c;
      out_wr_en <= data_valid;
      if (data_valid = '1') then
        out_rho   <= std_logic_vector(to_unsigned(rho,RHO_WIDTH));
        out_theta <= std_logic_vector(to_unsigned(theta,THETA_WIDTH));
      end if;
    end if;
  end process clock_process;

end architecture behavioral;
