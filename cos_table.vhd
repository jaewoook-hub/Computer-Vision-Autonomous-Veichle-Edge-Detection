library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.hough_constants.all;

entity cos_table is
	port (
		signal theta       : in std_logic_vector (7 downto 0);
		signal cos_theta   : out std_logic_vector (15 downto 0)
	);
end entity cos_table;

architecture behavioral of cos_table is

	signal theta_int              : integer;

begin

	theta_int <= to_integer(unsigned(theta));

	cos_t: process (theta_int)
	begin
		case theta_int is
			when 0  =>    cos_theta <= std_logic_vector(to_unsigned(16384,16));
			when 1  =>    cos_theta <= std_logic_vector(to_unsigned(16381,16));
			when 2  =>    cos_theta <= std_logic_vector(to_unsigned(16374,16));
			when 3  =>    cos_theta <= std_logic_vector(to_unsigned(16361,16));
			when 4  =>    cos_theta <= std_logic_vector(to_unsigned(16344,16));
			when 5  =>    cos_theta <= std_logic_vector(to_unsigned(16321,16));
			when 6  =>    cos_theta <= std_logic_vector(to_unsigned(16294,16));
			when 7  =>    cos_theta <= std_logic_vector(to_unsigned(16261,16));
			when 8  =>    cos_theta <= std_logic_vector(to_unsigned(16224,16));
			when 9  =>    cos_theta <= std_logic_vector(to_unsigned(16182,16));
			when 10  =>    cos_theta <= std_logic_vector(to_unsigned(16135,16));
			when 11  =>    cos_theta <= std_logic_vector(to_unsigned(16082,16));
			when 12  =>    cos_theta <= std_logic_vector(to_unsigned(16025,16));
			when 13  =>    cos_theta <= std_logic_vector(to_unsigned(15964,16));
			when 14  =>    cos_theta <= std_logic_vector(to_unsigned(15897,16));
			when 15  =>    cos_theta <= std_logic_vector(to_unsigned(15825,16));
			when 16  =>    cos_theta <= std_logic_vector(to_unsigned(15749,16));
			when 17  =>    cos_theta <= std_logic_vector(to_unsigned(15668,16));
			when 18  =>    cos_theta <= std_logic_vector(to_unsigned(15582,16));
			when 19  =>    cos_theta <= std_logic_vector(to_unsigned(15491,16));
			when 20  =>    cos_theta <= std_logic_vector(to_unsigned(15395,16));
			when 21  =>    cos_theta <= std_logic_vector(to_unsigned(15295,16));
			when 22  =>    cos_theta <= std_logic_vector(to_unsigned(15190,16));
			when 23  =>    cos_theta <= std_logic_vector(to_unsigned(15081,16));
			when 24  =>    cos_theta <= std_logic_vector(to_unsigned(14967,16));
			when 25  =>    cos_theta <= std_logic_vector(to_unsigned(14848,16));
			when 26  =>    cos_theta <= std_logic_vector(to_unsigned(14725,16));
			when 27  =>    cos_theta <= std_logic_vector(to_unsigned(14598,16));
			when 28  =>    cos_theta <= std_logic_vector(to_unsigned(14466,16));
			when 29  =>    cos_theta <= std_logic_vector(to_unsigned(14329,16));
			when 30  =>    cos_theta <= std_logic_vector(to_unsigned(14188,16));
			when 31  =>    cos_theta <= std_logic_vector(to_unsigned(14043,16));
			when 32  =>    cos_theta <= std_logic_vector(to_unsigned(13894,16));
			when 33  =>    cos_theta <= std_logic_vector(to_unsigned(13740,16));
			when 34  =>    cos_theta <= std_logic_vector(to_unsigned(13582,16));
			when 35  =>    cos_theta <= std_logic_vector(to_unsigned(13420,16));
			when 36  =>    cos_theta <= std_logic_vector(to_unsigned(13254,16));
			when 37  =>    cos_theta <= std_logic_vector(to_unsigned(13084,16));
			when 38  =>    cos_theta <= std_logic_vector(to_unsigned(12910,16));
			when 39  =>    cos_theta <= std_logic_vector(to_unsigned(12732,16));
			when 40  =>    cos_theta <= std_logic_vector(to_unsigned(12550,16));
			when 41  =>    cos_theta <= std_logic_vector(to_unsigned(12365,16));
			when 42  =>    cos_theta <= std_logic_vector(to_unsigned(12175,16));
			when 43  =>    cos_theta <= std_logic_vector(to_unsigned(11982,16));
			when 44  =>    cos_theta <= std_logic_vector(to_unsigned(11785,16));
			when 45  =>    cos_theta <= std_logic_vector(to_unsigned(11585,16));
			when 46  =>    cos_theta <= std_logic_vector(to_unsigned(11381,16));
			when 47  =>    cos_theta <= std_logic_vector(to_unsigned(11173,16));
			when 48  =>    cos_theta <= std_logic_vector(to_unsigned(10963,16));
			when 49  =>    cos_theta <= std_logic_vector(to_unsigned(10748,16));
			when 50  =>    cos_theta <= std_logic_vector(to_unsigned(10531,16));
			when 51  =>    cos_theta <= std_logic_vector(to_unsigned(10310,16));
			when 52  =>    cos_theta <= std_logic_vector(to_unsigned(10086,16));
			when 53  =>    cos_theta <= std_logic_vector(to_unsigned(9860,16));
			when 54  =>    cos_theta <= std_logic_vector(to_unsigned(9630,16));
			when 55  =>    cos_theta <= std_logic_vector(to_unsigned(9397,16));
			when 56  =>    cos_theta <= std_logic_vector(to_unsigned(9161,16));
			when 57  =>    cos_theta <= std_logic_vector(to_unsigned(8923,16));
			when 58  =>    cos_theta <= std_logic_vector(to_unsigned(8682,16));
			when 59  =>    cos_theta <= std_logic_vector(to_unsigned(8438,16));
			when 60  =>    cos_theta <= std_logic_vector(to_unsigned(8191,16));
			when 61  =>    cos_theta <= std_logic_vector(to_unsigned(7943,16));
			when 62  =>    cos_theta <= std_logic_vector(to_unsigned(7691,16));
			when 63  =>    cos_theta <= std_logic_vector(to_unsigned(7438,16));
			when 64  =>    cos_theta <= std_logic_vector(to_unsigned(7182,16));
			when 65  =>    cos_theta <= std_logic_vector(to_unsigned(6924,16));
			when 66  =>    cos_theta <= std_logic_vector(to_unsigned(6663,16));
			when 67  =>    cos_theta <= std_logic_vector(to_unsigned(6401,16));
			when 68  =>    cos_theta <= std_logic_vector(to_unsigned(6137,16));
			when 69  =>    cos_theta <= std_logic_vector(to_unsigned(5871,16));
			when 70  =>    cos_theta <= std_logic_vector(to_unsigned(5603,16));
			when 71  =>    cos_theta <= std_logic_vector(to_unsigned(5334,16));
			when 72  =>    cos_theta <= std_logic_vector(to_unsigned(5062,16));
			when 73  =>    cos_theta <= std_logic_vector(to_unsigned(4790,16));
			when 74  =>    cos_theta <= std_logic_vector(to_unsigned(4516,16));
			when 75  =>    cos_theta <= std_logic_vector(to_unsigned(4240,16));
			when 76  =>    cos_theta <= std_logic_vector(to_unsigned(3963,16));
			when 77  =>    cos_theta <= std_logic_vector(to_unsigned(3685,16));
			when 78  =>    cos_theta <= std_logic_vector(to_unsigned(3406,16));
			when 79  =>    cos_theta <= std_logic_vector(to_unsigned(3126,16));
			when 80  =>    cos_theta <= std_logic_vector(to_unsigned(2845,16));
			when 81  =>    cos_theta <= std_logic_vector(to_unsigned(2563,16));
			when 82  =>    cos_theta <= std_logic_vector(to_unsigned(2280,16));
			when 83  =>    cos_theta <= std_logic_vector(to_unsigned(1996,16));
			when 84  =>    cos_theta <= std_logic_vector(to_unsigned(1712,16));
			when 85  =>    cos_theta <= std_logic_vector(to_unsigned(1427,16));
			when 86  =>    cos_theta <= std_logic_vector(to_unsigned(1142,16));
			when 87  =>    cos_theta <= std_logic_vector(to_unsigned(857,16));
			when 88  =>    cos_theta <= std_logic_vector(to_unsigned(571,16));
			when 89  =>    cos_theta <= std_logic_vector(to_unsigned(285,16));
			when others =>  cos_theta <= std_logic_vector(to_unsigned(285,16));
		end case;
	end process;

end architecture;
