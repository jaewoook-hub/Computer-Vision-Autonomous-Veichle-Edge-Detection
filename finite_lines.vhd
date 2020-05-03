library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.hough_constants.all;
use IEEE.MATH_REAL.ALL;

entity finite_lines is
  port (
    signal clock         : in  std_logic;
    signal reset         : in  std_logic;
    signal in_empty      : in  std_logic;
    signal out_full      : in  std_logic;
    signal in_rho        : in  std_logic_vector(RHO_WIDTH-1  downto 0);
    signal in_theta      : in  std_logic_vector(7 downto 0);
    signal in_rho_done   : in  std_logic;
    signal in_rd_en      : out std_logic;
    signal out_wr_en     : out std_logic;
    signal out_xy_done   : out std_logic;
    signal x1            : out std_logic_vector(RHO_WIDTH-1 downto 0);
    signal x2            : out std_logic_vector(RHO_WIDTH-1  downto 0);
    signal y1            : out std_logic_vector(RHO_WIDTH-1  downto 0);
    signal y2            : out std_logic_vector(RHO_WIDTH-1  downto 0)
  );
end entity finite_lines;

architecture behavior of finite_lines is

  TYPE state_types is (s0,s1,s2,s3);
  signal state        : state_types;
  signal next_state   : state_types;

  signal cos_theta : std_logic_vector (15 downto 0);
  signal sin_theta : std_logic_vector (15 downto 0);

  signal fifo_rd_en : std_logic;
  signal xy_done_c       : std_logic;
  signal xy_done         : std_logic;
  signal xy_coord_c      : std_logic_vector(39 downto 0);

  signal rho             : std_logic_vector (9 downto 0);
  signal theta           : std_logic_vector (7 downto 0);
  signal theta_deg       : std_logic_vector (7 downto 0);
  signal rho_xy          : signed(31 downto 0);
  signal rho_int         : integer := 0;
  signal theta_int       : integer := 0;
  signal out_wr_en_c     : std_logic;

  signal cos_theta_neg : std_logic_vector (15 downto 0);
  signal cos_theta_int : integer;

  function get_xy (
    rho       : std_logic_vector(9 downto 0);
    theta     : std_logic_vector(7 downto 0);
    cos_theta : std_logic_vector(15 downto 0);
    sin_theta : std_logic_vector(15 downto 0))
  return std_logic_vector is
    variable x1    : std_logic_vector(31 downto 0);
    variable x2    : std_logic_vector(31 downto 0);
    variable y1    : std_logic_vector(31 downto 0);
    variable y2    : std_logic_vector(31 downto 0);
    variable xy_coord  : std_logic_vector(39 downto 0);

    variable int_in_theta : integer;
    variable quant_theta : integer;
    variable int_in_rho : integer;
    variable quant_rho : integer;

  begin

    int_in_theta := to_integer(unsigned(theta));
    -- int rho_quant = QUANTIZE_I(r - accu_h_div2);
    int_in_rho   := to_integer(unsigned(rho));
    quant_rho    := (int_in_rho - ACCU_h_div2)*(2**14);

    if (int_in_theta >= 45 and int_in_theta <= 135) then
      x1 := (others => '0');
      y1 := std_logic_vector(resize(((to_signed(quant_rho, 32) - to_signed((0 - W_div2), 32) * signed(cos_theta)) / signed(sin_theta)) + to_signed(H_div2, 32), 32));
      x2 := std_logic_vector(to_signed(IMG_WIDTH, 32));
      y2 := std_logic_vector(resize(((to_signed(quant_rho, 32) - to_signed((IMG_WIDTH - W_div2), 32) * signed(cos_theta)) / signed(sin_theta)) + to_signed(H_div2, 32), 32));
    else
      y1 := (others => '0');
      x1 := std_logic_vector(resize(((to_signed(quant_rho, 32) - to_signed((0 - H_div2), 32) * signed(sin_theta)) / signed(cos_theta)) + to_signed(W_div2, 32), 32));
      y2 := std_logic_vector(to_signed(IMG_HEIGHT, 32));
      x2 := std_logic_vector(resize(((to_signed(quant_rho, 32) - to_signed((IMG_HEIGHT - H_div2), 32) * signed(sin_theta)) / signed(cos_theta)) + to_signed(W_div2, 32), 32));
    end if;
    xy_coord := y2(9 downto 0) & y1(9 downto 0) & x2(9 downto 0) & x1(9 downto 0);
    return xy_coord;
  end get_xy;

begin

  out_xy_done <= xy_done;

  cos_table_inst : cos_table
  port map (
    theta      => theta_deg,
    cos_theta  => cos_theta
  );

  sin_table_inst : sin_table
  port map (
    theta      => theta_deg,
    sin_theta  => sin_theta
  );

  cos_theta_neg  <= std_logic_vector(to_signed(cos_theta_int,16));

  XY_process : process( state, in_empty, out_full, rho,theta,in_rho_done,xy_done,cos_theta,cos_theta_neg,sin_theta,theta_int ) is
  begin
    next_state   <= state;
    fifo_rd_en   <= '0';
    in_rd_en     <= '0';
    xy_done_c    <= xy_done;
    xy_coord_c   <= (others => '0');
    rho_int       <= to_integer(unsigned(rho));
    theta_int     <= to_integer(unsigned(theta));
    -- t*PI/180
    rho_xy    <= to_signed((rho_int - ACCU_h_div2),32) sll 14;

    out_wr_en_c <= '0';

    if (theta_int >= 90) then
      theta_deg   <= std_logic_vector(to_unsigned((180 - theta_int),8));
    else
      theta_deg   <= std_logic_vector(to_unsigned(theta_int,8));
    end if;

    if (theta_int > 90) then
      cos_theta_int <=  -(to_integer(unsigned(cos_theta)));
    else
      cos_theta_int <=  to_integer(unsigned(cos_theta));
    end if;

    case ( state ) is
      when s0 =>
        if (in_empty = '0') then -- Wait until data is written to FIFO
          next_state <= s1;
          xy_done_c  <= '0';
        end if;

      when s1 =>
        fifo_rd_en   <= '1';
        in_rd_en     <= '1';
        next_state   <= s2;

      when s2 =>
        xy_coord_c <= get_xy(rho, theta, cos_theta_neg, sin_theta);
        next_state <= s3;
        out_wr_en_c <= '1';

      when s3 =>
        if (in_empty = '0') then
          next_state <= s1;
        elsif (in_rho_done = '1') then
          next_state <= s0;
          xy_done_c  <= '1';
        end if;

      when others =>
        next_state <= s0;
    end case;
  end process XY_process;


  clock_process : process( clock, reset ) is
  begin
    if ( reset = '1' ) then
      state    <= s0;
      x1       <= (others => '0');
      x2       <= (others => '0');
      y1       <= (others => '0');
      y2       <= (others => '0');
      out_wr_en <= '0';
      xy_done   <= '0';
      rho       <= (others => '0');
      theta     <= (others => '0');
    elsif ( rising_edge(clock) ) then
      state     <= next_state;
      xy_done   <= xy_done_c;
      out_wr_en <= out_wr_en_c;
      if (fifo_rd_en = '1') then
        rho     <= in_rho;
        theta   <= in_theta;
      end if;
      if (out_wr_en_c = '1') then
        x1 <= xy_coord_c(RHO_WIDTH-1 downto 0);
        x2 <= xy_coord_c(RHO_WIDTH*2-1 downto RHO_WIDTH);
        y1 <= xy_coord_c(RHO_WIDTH*3-1 downto RHO_WIDTH*2);
        y2 <= xy_coord_c(RHO_WIDTH*4-1 downto RHO_WIDTH*3);
      end if;
    end if;
  end process clock_process;

end architecture behavior;
