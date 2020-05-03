library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.hough_constants.all;

entity sin_table is
	port (
		signal theta        : in std_logic_vector (7 downto 0);
		signal sin_theta    : out std_logic_vector (15 downto 0)
	);
end entity sin_table;

architecture behavioral of sin_table is

	signal theta_int              : integer;

begin

	theta_int <= to_integer(unsigned(theta));

	cos_t: process (theta_int)
	begin
		case theta_int is
			when 0  =>    sin_theta <= std_logic_vector(to_unsigned(0,16));
			when 1  =>    sin_theta <= std_logic_vector(to_unsigned(285,16));
			when 2  =>    sin_theta <= std_logic_vector(to_unsigned(571,16));
			when 3  =>    sin_theta <= std_logic_vector(to_unsigned(857,16));
			when 4  =>    sin_theta <= std_logic_vector(to_unsigned(1142,16));
			when 5  =>    sin_theta <= std_logic_vector(to_unsigned(1427,16));
			when 6  =>    sin_theta <= std_logic_vector(to_unsigned(1712,16));
			when 7  =>    sin_theta <= std_logic_vector(to_unsigned(1996,16));
			when 8  =>    sin_theta <= std_logic_vector(to_unsigned(2280,16));
			when 9  =>    sin_theta <= std_logic_vector(to_unsigned(2563,16));
			when 10  =>    sin_theta <= std_logic_vector(to_unsigned(2845,16));
			when 11  =>    sin_theta <= std_logic_vector(to_unsigned(3126,16));
			when 12  =>    sin_theta <= std_logic_vector(to_unsigned(3406,16));
			when 13  =>    sin_theta <= std_logic_vector(to_unsigned(3685,16));
			when 14  =>    sin_theta <= std_logic_vector(to_unsigned(3963,16));
			when 15  =>    sin_theta <= std_logic_vector(to_unsigned(4240,16));
			when 16  =>    sin_theta <= std_logic_vector(to_unsigned(4516,16));
			when 17  =>    sin_theta <= std_logic_vector(to_unsigned(4790,16));
			when 18  =>    sin_theta <= std_logic_vector(to_unsigned(5062,16));
			when 19  =>    sin_theta <= std_logic_vector(to_unsigned(5334,16));
			when 20  =>    sin_theta <= std_logic_vector(to_unsigned(5603,16));
			when 21  =>    sin_theta <= std_logic_vector(to_unsigned(5871,16));
			when 22  =>    sin_theta <= std_logic_vector(to_unsigned(6137,16));
			when 23  =>    sin_theta <= std_logic_vector(to_unsigned(6401,16));
			when 24  =>    sin_theta <= std_logic_vector(to_unsigned(6663,16));
			when 25  =>    sin_theta <= std_logic_vector(to_unsigned(6924,16));
			when 26  =>    sin_theta <= std_logic_vector(to_unsigned(7182,16));
			when 27  =>    sin_theta <= std_logic_vector(to_unsigned(7438,16));
			when 28  =>    sin_theta <= std_logic_vector(to_unsigned(7691,16));
			when 29  =>    sin_theta <= std_logic_vector(to_unsigned(7943,16));
			when 30  =>    sin_theta <= std_logic_vector(to_unsigned(8191,16));
			when 31  =>    sin_theta <= std_logic_vector(to_unsigned(8438,16));
			when 32  =>    sin_theta <= std_logic_vector(to_unsigned(8682,16));
			when 33  =>    sin_theta <= std_logic_vector(to_unsigned(8923,16));
			when 34  =>    sin_theta <= std_logic_vector(to_unsigned(9161,16));
			when 35  =>    sin_theta <= std_logic_vector(to_unsigned(9397,16));
			when 36  =>    sin_theta <= std_logic_vector(to_unsigned(9630,16));
			when 37  =>    sin_theta <= std_logic_vector(to_unsigned(9860,16));
			when 38  =>    sin_theta <= std_logic_vector(to_unsigned(10086,16));
			when 39  =>    sin_theta <= std_logic_vector(to_unsigned(10310,16));
			when 40  =>    sin_theta <= std_logic_vector(to_unsigned(10531,16));
			when 41  =>    sin_theta <= std_logic_vector(to_unsigned(10748,16));
			when 42  =>    sin_theta <= std_logic_vector(to_unsigned(10963,16));
			when 43  =>    sin_theta <= std_logic_vector(to_unsigned(11173,16));
			when 44  =>    sin_theta <= std_logic_vector(to_unsigned(11381,16));
			when 45  =>    sin_theta <= std_logic_vector(to_unsigned(11585,16));
			when 46  =>    sin_theta <= std_logic_vector(to_unsigned(11785,16));
			when 47  =>    sin_theta <= std_logic_vector(to_unsigned(11982,16));
			when 48  =>    sin_theta <= std_logic_vector(to_unsigned(12175,16));
			when 49  =>    sin_theta <= std_logic_vector(to_unsigned(12365,16));
			when 50  =>    sin_theta <= std_logic_vector(to_unsigned(12550,16));
			when 51  =>    sin_theta <= std_logic_vector(to_unsigned(12732,16));
			when 52  =>    sin_theta <= std_logic_vector(to_unsigned(12910,16));
			when 53  =>    sin_theta <= std_logic_vector(to_unsigned(13084,16));
			when 54  =>    sin_theta <= std_logic_vector(to_unsigned(13254,16));
			when 55  =>    sin_theta <= std_logic_vector(to_unsigned(13420,16));
			when 56  =>    sin_theta <= std_logic_vector(to_unsigned(13582,16));
			when 57  =>    sin_theta <= std_logic_vector(to_unsigned(13740,16));
			when 58  =>    sin_theta <= std_logic_vector(to_unsigned(13894,16));
			when 59  =>    sin_theta <= std_logic_vector(to_unsigned(14043,16));
			when 60  =>    sin_theta <= std_logic_vector(to_unsigned(14188,16));
			when 61  =>    sin_theta <= std_logic_vector(to_unsigned(14329,16));
			when 62  =>    sin_theta <= std_logic_vector(to_unsigned(14466,16));
			when 63  =>    sin_theta <= std_logic_vector(to_unsigned(14598,16));
			when 64  =>    sin_theta <= std_logic_vector(to_unsigned(14725,16));
			when 65  =>    sin_theta <= std_logic_vector(to_unsigned(14848,16));
			when 66  =>    sin_theta <= std_logic_vector(to_unsigned(14967,16));
			when 67  =>    sin_theta <= std_logic_vector(to_unsigned(15081,16));
			when 68  =>    sin_theta <= std_logic_vector(to_unsigned(15190,16));
			when 69  =>    sin_theta <= std_logic_vector(to_unsigned(15295,16));
			when 70  =>    sin_theta <= std_logic_vector(to_unsigned(15395,16));
			when 71  =>    sin_theta <= std_logic_vector(to_unsigned(15491,16));
			when 72  =>    sin_theta <= std_logic_vector(to_unsigned(15582,16));
			when 73  =>    sin_theta <= std_logic_vector(to_unsigned(15668,16));
			when 74  =>    sin_theta <= std_logic_vector(to_unsigned(15749,16));
			when 75  =>    sin_theta <= std_logic_vector(to_unsigned(15825,16));
			when 76  =>    sin_theta <= std_logic_vector(to_unsigned(15897,16));
			when 77  =>    sin_theta <= std_logic_vector(to_unsigned(15964,16));
			when 78  =>    sin_theta <= std_logic_vector(to_unsigned(16025,16));
			when 79  =>    sin_theta <= std_logic_vector(to_unsigned(16082,16));
			when 80  =>    sin_theta <= std_logic_vector(to_unsigned(16135,16));
			when 81  =>    sin_theta <= std_logic_vector(to_unsigned(16182,16));
			when 82  =>    sin_theta <= std_logic_vector(to_unsigned(16224,16));
			when 83  =>    sin_theta <= std_logic_vector(to_unsigned(16261,16));
			when 84  =>    sin_theta <= std_logic_vector(to_unsigned(16294,16));
			when 85  =>    sin_theta <= std_logic_vector(to_unsigned(16321,16));
			when 86  =>    sin_theta <= std_logic_vector(to_unsigned(16344,16));
			when 87  =>    sin_theta <= std_logic_vector(to_unsigned(16361,16));
			when 88  =>    sin_theta <= std_logic_vector(to_unsigned(16374,16));
			when 89  =>    sin_theta <= std_logic_vector(to_unsigned(16381,16));
			when others =>  sin_theta <= std_logic_vector(to_unsigned(16381,16));
		end case;
	end process;

end architecture;
