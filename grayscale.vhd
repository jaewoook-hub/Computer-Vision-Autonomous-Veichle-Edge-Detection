library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.canny_constants.all; 

entity grayscale is
port
(
	signal clock        : in  std_logic;
    signal reset        : in  std_logic;
	signal in_rd_en     : out std_logic;
	signal in_empty     : in  std_logic;
	signal in_dout      : in  std_logic_vector(23 downto 0);
	signal out_wr_en	: out std_logic;
	signal out_full     : in  std_logic;
	signal out_din      : out std_logic_vector(7 downto 0)
);
end entity grayscale;

architecture behavior of grayscale is
    type state_types is (s0, s1);
    signal state        : state_types;
    signal next_state   : state_types;
    signal gray_val     : std_logic_vector(7 downto 0);
    signal gray_val_c   : std_logic_vector(7 downto 0);
begin

    gs_process : process( state, in_empty, in_dout, out_full, gray_val ) is
        variable gs : std_logic_vector(15 downto 0);
    begin
        next_state <= state;
        gray_val_c <= gray_val;
        in_rd_en <= '0';
        out_wr_en <= '0';
        out_din <= (others => '0');

        case ( state ) is
            when s0 =>
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    gs := std_logic_vector((resize(unsigned(in_dout(23 downto 16)),16) + resize(unsigned(in_dout(15 downto 8)),16) + resize(unsigned(in_dout(7 downto 0)),16)) / to_unsigned(3, 16));
                    gray_val_c <= gs(7 downto 0);
                    next_state <= s1;
                end if;

            when s1 =>
                out_din <= gray_val;
                if ( out_full = '0' ) then
                    out_wr_en <= '1';
                    next_state <= s0;
                end if;

            when others =>
                gray_val_c <= (others => 'X');
                next_state <= s0;
        end case;
    end process gs_process;

    clock_process : process( clock, reset ) is
    begin
        if ( reset = '1' ) then
            state <= s0;
            gray_val <= (others => '0');
        elsif ( rising_edge(clock) ) then
            state <= next_state;
            gray_val <= gray_val_c;
        end if;
    end process clock_process;

end architecture behavior;


architecture combinational of grayscale is
begin
    gs_process : process( in_empty, in_dout, out_full ) is
        variable gs : std_logic_vector(15 downto 0);
    begin
        in_rd_en <= '0';
        out_wr_en <= '0';
        out_din <= (others => '0');

        if ( in_empty = '0' and out_full = '0' ) then
            in_rd_en <= '1';
            gs := std_logic_vector((resize(unsigned(in_dout(23 downto 16)),16) + resize(unsigned(in_dout(15 downto 8)),16) + resize(unsigned(in_dout(7 downto 0)),16)) / to_unsigned(3, 16));
            out_din <= gs(7 downto 0);
            out_wr_en <= '1';
        end if;
    end process gs_process;

end architecture combinational;
