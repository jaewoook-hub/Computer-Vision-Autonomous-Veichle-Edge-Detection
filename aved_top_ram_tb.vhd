library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.aved_constants.all;

entity aved_top_ram_tb is
generic
(
    constant IMG_IN_NAME  : string (18 downto 1)  := "tracks_216_216.bmp";
    constant IMG_OUT_NAME : string (32 downto 1) := "tracks_216_aved_ram_out_vhdl.bmp";
    constant COMPARE_NAME : string (25 downto 1) := "tracks_216_aved_out_c.bmp";
    constant CLOCK_PERIOD : time := 10 ns
);
end entity aved_top_ram_tb;


architecture behavior of aved_top_ram_tb is

    function to_slv(c : character) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(character'pos(c),8));
    end function to_slv;

    function to_char(v : std_logic_vector) return character is
    begin
        return character'val(to_integer(unsigned(v)));
    end function to_char;

    type raw_file is file of character;

    signal clock : std_logic := '1';
    signal reset : std_logic := '0';
    signal start : std_logic := '0';
    signal done : std_logic := '0';

	signal in_full : std_logic;
	signal in_wr_en : std_logic;
	signal in_din: std_logic_vector (23 downto 0);
	signal out_rd_en : std_logic;
	signal out_empty : std_logic;
	signal out_dout: std_logic_vector (23 downto 0);

    signal hold_clock : std_logic := '0';
    signal in_write_done : std_logic := '0';
    signal out_read_done : std_logic := '0';
    signal out_errors : integer := 0;

    signal pixel_count : integer :=0;
    signal dout_count  : integer :=0;

    -- External RAM
  signal ram_addr           : std_logic_vector(19 downto 0);
  signal ram_wr_data        : std_logic_vector(23 downto 0);
  signal ram_rd_data        : std_logic_vector(23 downto 0);
  signal ram_cs             : std_logic;
  signal ram_wr_en          : std_logic;
  signal ram_read_en        : std_logic;

begin

  sram_inst : sram
  generic map (
    mem_file => "test.data"
  )
  port map (
    clk       => clock,
    cs        => ram_cs,
    oe        => ram_read_en,
    we        => ram_wr_en,
    addr      => ram_addr,
    din       => ram_wr_data,
    dout      => out_dout           -- ram output, ram_rd_data
  );


  aved_top_inst : component aved_top
  port map
  (
    clock       => clock,
    reset       => reset,
    in_wr_en    => in_wr_en,
    in_din      => in_din,
    out_rd_en   => out_rd_en,       -- input
    in_full     => in_full,         -- output
    out_empty   => out_empty,
    out_dout    => open,
    -- External RAM
    ram_cs      => ram_cs,
    ram_read_en => ram_read_en,
    ram_wr_en   => ram_wr_en,
    ram_addr    => ram_addr,
    ram_wr_data => ram_wr_data,
    ram_rd_data    => out_dout      -- input
  );

    clock_process : process
    begin
        clock <= '1';
        wait for  (CLOCK_PERIOD / 2);
        clock <= '0';
        wait for  (CLOCK_PERIOD / 2);
        if ( hold_clock = '1' ) then
            wait;
        end if;
    end process clock_process;


    reset_process : process
    begin
        reset <= '0';
        wait until  (clock = '0');
        wait until  (clock = '1');
        reset <= '1';
        wait until  (clock = '0');
        wait until  (clock = '1');
        reset <= '0';
        wait;
    end process reset_process;


    tb_process : process
        variable errors : integer := 0;
        variable warnings : integer := 0;
        variable start_time : time;
        variable end_time : time;
        variable ln1, ln2, ln3, ln4 : line;
    begin
        wait until  (reset = '1');
        wait until  (reset = '0');

        wait until  (clock = '0');
        wait until  (clock = '1');

        start_time := NOW;
        write( ln1, string'("@ ") );
        write( ln1, start_time );
        write( ln1, string'(": Beginning simulation...") );
        writeline( output, ln1 );

        start <= '1';
        wait until  (clock = '0');
        wait until  (clock = '1');
        start <= '0';
        wait until  (out_read_done = '1');

        end_time := NOW;
        write( ln2, string'("@ ") );
        write( ln2, end_time );
        write( ln2, string'(": Simulation completed.") );
        writeline( output, ln2 );

        errors := out_errors;

        write( ln3, string'("Total simulation cycle count: ") );
        write( ln3, (end_time - start_time) / CLOCK_PERIOD );
        writeline( output, ln3 );
        write( ln4, string'("Total error count: ") );
        write( ln4, errors );
        writeline( output, ln4 );

        hold_clock <= '1';
        wait;
    end process tb_process;


    img_read_process : process
        file in_file : raw_file;
        variable char1, char2, char3 : character;
        variable ln1, ln2 : line;
        variable i : integer := 0;
    begin
        wait until  (reset = '1');
        wait until  (reset = '0');

        write( ln1, string'("@ ") );
        write( ln1, NOW );
        write( ln1, string'(": Loading file ") );
        write( ln1, IMG_IN_NAME );
        write( ln1, string'("...") );
        writeline( output, ln1 );

        file_open( in_file, IMG_IN_NAME, read_mode );
		in_wr_en <= '0';

        -- read header
		while ( not ENDFILE( in_file) and i < 54 ) loop
            read( in_file, char1 );
            i := i + 1;
        end loop;

		while ( not ENDFILE( in_file) ) loop
			wait until (clock = '1');
			wait until (clock = '0');
			if ( in_full = '0' ) then
				read( in_file, char1 );
				read( in_file, char2 );
				read( in_file, char3 );
				in_din <= to_slv( char3 ) & to_slv( char2 ) & to_slv( char1 );
				in_wr_en <= '1';
        pixel_count <= pixel_count + 1;
        if ((pixel_count mod 5000) = 0) then
            write(ln2,string'(" ... reading image pixel_count =  ... "));
            write(ln2,pixel_count);
            writeline(output,ln2);  -- write to stdout
        end if;
			else
				in_wr_en <= '0';
			end if;
		end loop;

		wait until (clock = '1');
		wait until (clock = '0');
		in_wr_en <= '0';
        file_close( in_file );
        in_write_done <= '1';
        wait;
    end process img_read_process;



    img_write_process : process
        file cmp_file : raw_file;
        file out_file : raw_file;
        variable char : character;
        variable ln1, ln2, ln3 : line;
        variable ln4 : line;
        variable my_line		: line;
        variable i : integer := 0;
        variable out_data_read : std_logic_vector (7 downto 0);
        variable out_data_cmp : std_logic_vector (7 downto 0);
    begin
        wait until  (reset = '1');
        wait until  (reset = '0');

        wait until  (clock = '1');
        wait until  (clock = '0');

        write( ln1, string'("@ ") );
        write( ln1, NOW );
        write( ln1, string'(": Comparing file ") );
        write( ln1, IMG_OUT_NAME );
        write( ln1, string'("...") );
        writeline( output, ln1 );

        file_open( out_file, IMG_OUT_NAME, write_mode);
        file_open( cmp_file, COMPARE_NAME, read_mode );
		out_rd_en <= '0';

		while ( not ENDFILE(cmp_file) and i < 54 ) loop
            read( cmp_file, char );
            write( out_file, char);
            i := i + 1;
        end loop;

        i := 0;

		while ( not ENDFILE(cmp_file) ) loop
			wait until ( clock = '1');
			wait until ( clock = '0');
			-- if ( out_empty = '0' ) then
      if ( ram_read_en = '1' ) then
				out_rd_en <= '1';

        if (dout_count = IMG_SIZE-1) then
          dout_count      <= 0;
        else
          dout_count  <= dout_count + 1;
        end if;
        if ((dout_count mod 5000) = 0) then
           write(ln4,string'(" ... writing dout pixel count =  ... "));
           write(ln4,dout_count);
           writeline(output,ln4);  -- write to stdout
       end if;

				read( cmp_file, char );
				read( cmp_file, char );
				read( cmp_file, char );
				out_data_cmp := to_slv(char);
                write(out_file, to_char(out_dout));
                write(out_file, to_char(out_dout));
                write(out_file, to_char(out_dout));

                -- write( ln3, string'("@ ") );
                -- write( ln3, NOW );
                -- write( ln3, string'(": ") );
                -- write( ln3, i );
                -- write( ln3, string'(": ") );
                -- hwrite( ln3, out_dout );
                -- writeline( output, ln3 );

				if ( to_01(unsigned(out_dout)) /= to_01(unsigned(out_data_cmp)) ) then
					out_errors <= out_errors + 1;
					write( ln2, string'("@ ") );
					write( ln2, NOW );
					write( ln2, string'(": ") );
					write( ln2, IMG_OUT_NAME );
					write( ln2, string'("(") );
					write( ln2, i + 1 );
					write( ln2, string'("): ERROR: ") );
					hwrite( ln2, out_dout );
					write( ln2, string'(" != ") );
					hwrite( ln2, out_data_cmp );
					write( ln2, string'(" at address 0x") );
					hwrite( ln2, std_logic_vector(to_unsigned(i,32)) );
					write( ln2, string'(".") );
					writeline( output, ln2 );
                    exit;
				end if;
                i := i + 1;
			else
				out_rd_en <= '0';
			end if;
        end loop;

		wait until (clock = '1');
		wait until (clock = '0');
		out_rd_en <= '0';
        file_close( cmp_file );
        file_close( out_file );
        out_read_done <= '1';
        wait;
    end process img_write_process;


end architecture behavior;
--
-- library IEEE;
-- use IEEE.std_logic_1164.all;
-- use IEEE.numeric_std.all;
-- use IEEE.std_logic_textio.all;
-- use STD.textio.all;
-- use work.aved_constants.all;
--
-- entity aved_top_ram_tb is
-- generic
-- (
-- --    constant IMG_IN_NAME  : string (18 downto 1)  := "tracks_216_216.bmp";
-- constant IMG_IN_NAME  : string (18 downto 1)  := "tracks_216_216.bmp";
--     constant IMG_OUT_NAME : string (32 downto 1) := "tracks_216_aved_ram_out_vhdl.bmp";
--     constant COMPARE_NAME : string (25 downto 1) := "tracks_216_aved_out_c.bmp";   -- Need to get the header info
--     constant CLOCK_PERIOD : time := 10 ns
-- );
-- end entity aved_top_ram_tb;
--
--
-- architecture behavior of aved_top_ram_tb is
--
--
--     function to_slv(c : character) return std_logic_vector is
--     begin
--         return std_logic_vector(to_unsigned(character'pos(c),8));
--     end function to_slv;
--
--     function to_char(v : std_logic_vector) return character is
--     begin
--         return character'val(to_integer(unsigned(v)));
--     end function to_char;
--
--     type raw_file is file of character;
--
--     signal clock : std_logic := '1';
--     signal reset : std_logic := '0';
--     signal start : std_logic := '0';
--     signal done : std_logic := '0';
--
-- 	signal in_full : std_logic;
-- 	signal in_wr_en : std_logic;
-- 	signal in_din: std_logic_vector (23 downto 0);
-- 	signal out_rd_en : std_logic;
-- 	signal out_empty : std_logic;
-- 	signal out_dout: std_logic_vector (23 downto 0);
--
--     signal hold_clock : std_logic := '0';
--     signal in_write_done : std_logic := '0';
--     signal out_read_done : std_logic := '0';
--     signal out_errors : integer := 0;
--
--     signal pixel_count : integer :=0;
--     signal dout_count  : integer :=0;
--     signal frame_count : integer :=0;
--
--     signal bmp_header  : character;
--
--         -- External RAM
--         signal ram_addr           : std_logic_vector(19 downto 0);
--         signal ram_wr_data        : std_logic_vector(23 downto 0);
--         signal ram_rd_data        : std_logic_vector(23 downto 0);
--         signal ram_cs             : std_logic;
--         signal ram_wr_en          : std_logic;
--         signal ram_read_en        : std_logic;
--
-- begin
--
-- -------------------------------------------------------------------------------
-- -- RAM Instantiation --
-- -------------------------------------------------------------------------------
--    hyst_sram : sram1024kx24
--      generic map (
--         mem_file => "test.data"
--      )
--      port map (
--         clk       => clock,
--         cs        => ram_cs,
--         oe        => ram_read_en,
--         we        => ram_wr_en,
--         addr      => ram_addr,
--         din       => ram_wr_data,
--         dout      => out_dout           -- ram output, ram_rd_data
--   );
--
--
--     aved_top_ram_inst : component aved_top_ram
--     port map
--     (
--         clock       => clock,
--         reset       => reset,
--         in_wr_en    => in_wr_en,
-- 	in_din      => in_din,
--         out_rd_en   => out_rd_en,       -- input
--         in_full     => in_full,         -- output
-- 	out_empty   => out_empty,
--         out_dout    => open,
--         -- External RAM
--         ram_cs      => ram_cs,
--         ram_read_en => ram_read_en,
--         ram_wr_en   => ram_wr_en,
--         ram_addr    => ram_addr,
--         ram_wr_data => ram_wr_data,
--         ram_rd_data    => out_dout      -- input
--     );
--
--
--     clock_process : process
--     begin
--         clock <= '1';
--         wait for  (CLOCK_PERIOD / 2);
--         clock <= '0';
--         wait for  (CLOCK_PERIOD / 2);
--         if ( hold_clock = '1' ) then
--             wait;
--         end if;
--     end process clock_process;
--
--
--     reset_process : process
--     begin
--         reset <= '0';
--         wait until  (clock = '0');
--         wait until  (clock = '1');
--         reset <= '1';
--         wait until  (clock = '0');
--         wait until  (clock = '1');
--         reset <= '0';
--         wait;
--     end process reset_process;
--
--
--     tb_process : process
--         variable errors : integer := 0;
--         variable warnings : integer := 0;
--         variable start_time : time;
--         variable end_time : time;
--         variable ln1, ln2, ln3, ln4 : line;
--     begin
--         wait until  (reset = '1');
--         wait until  (reset = '0');
--
--         wait until  (clock = '0');
--         wait until  (clock = '1');
--
--         start_time := NOW;
--         write( ln1, string'("@ ") );
--         write( ln1, start_time );
--         write( ln1, string'(": Beginning simulation...") );
--         writeline( output, ln1 );
--
--         start <= '1';
--         wait until  (clock = '0');
--         wait until  (clock = '1');
--         start <= '0';
--         write( ln2, string'(": Wait for out_read_done.") );
--         writeline( output, ln2 );
--         wait until  (out_read_done = '1');
--
--         end_time := NOW;
--         write( ln2, string'("@ ") );
--         write( ln2, end_time );
--         write( ln2, string'(": Simulation completed.") );
--         writeline( output, ln2 );
--
--         errors := out_errors;
--
--         write( ln3, string'("Total simulation cycle count: ") );
--         write( ln3, (end_time - start_time) / CLOCK_PERIOD );
--         writeline( output, ln3 );
--         --write( ln4, string'("Total error count: ") );
--         --write( ln4, errors );
--         --writeline( output, ln4 );
--
--         hold_clock <= '1';
--         wait;
--     end process tb_process;
--
--
--     img_read_process : process
--         file in_file : raw_file;
--         variable char1, char2, char3 : character;
--         variable ln1 : line;
-- 	variable my_line		: line;
--         variable i : integer := 0;
--     begin
--         wait until  (reset = '1');
--         wait until  (reset = '0');
--
--         write( ln1, string'("@ ") );
--         write( ln1, NOW );
--         write( ln1, string'(": Loading file ") );
--         write( ln1, IMG_IN_NAME );
--         write( ln1, string'("...") );
--         writeline( output, ln1 );
--
--         file_open( in_file, IMG_IN_NAME, read_mode );
-- 		in_wr_en <= '0';
--
--         -- read header
-- 	while ( not ENDFILE( in_file) and i < 54 ) loop
--             read( in_file, char1 );
--             bmp_header <= char1;
--             i := i + 1;
--         end loop;
--
-- 		while ( not ENDFILE( in_file) ) loop
-- 			wait until (clock = '1');
-- 			wait until (clock = '0');
-- 			if ( in_full = '0' ) then
-- 				read( in_file, char1 );
-- 				read( in_file, char2 );
-- 				read( in_file, char3 );
-- 				in_din <= to_slv( char3 ) & to_slv( char2 ) & to_slv( char1 );
-- 				in_wr_en <= '1';
--                                 pixel_count <= pixel_count + 1;
--                                 if ((pixel_count mod 5000) = 0) then
--                                     write(my_line,string'(" ... reading pixel_count =  ... "));
--                                     write(my_line,pixel_count);
--                                     writeline(output,my_line);  -- write to stdout
--                                 end if;
-- 			else
-- 				in_wr_en <= '0';
-- 			end if;
-- 		end loop;
--
-- 		wait until (clock = '1');
-- 		wait until (clock = '0');
-- 		in_wr_en <= '0';
--         write(my_line,string'(" ... End of Input File ... "));
--  	writeline(output,my_line);  -- write to stdout
--         file_close( in_file );
--         in_write_done <= '1';
--         wait;
--     end process img_read_process;
--
--
--
--     img_write_process : process
--         file cmp_file : raw_file;
--         file out_file : raw_file;
--         file out_file1 : raw_file;
--         file out_file2 : raw_file;
--         file out_file3 : raw_file;
--         variable char : character;
--         variable ln1, ln2, ln3 : line;
-- 	variable my_line		: line;
--         variable i : integer := 0;
--         variable out_data_read : std_logic_vector (7 downto 0);
--         --variable out_data_cmp : std_logic_vector (7 downto 0);
--     begin
--         wait until  (reset = '1');
--         wait until  (reset = '0');
--
--         wait until  (clock = '1');
--         wait until  (clock = '0');
--
--         write( ln1, string'("@ ") );
--         write( ln1, NOW );
--         write( ln1, string'(": Writing file ") );
--         write( ln1, IMG_OUT_NAME );
--         write( ln1, string'("...") );
--         writeline( output, ln1 );
--
--         file_open( cmp_file, COMPARE_NAME, read_mode);
--         file_open( out_file, IMG_OUT_NAME, write_mode);
-- 	out_rd_en <= '0';
--
-- 	while (  i < 54 ) loop
--             read( cmp_file, char );     -- To get the header
--             write( out_file, char);
--             i := i + 1;
--         end loop;
--
--         i := 0;
--
-- --	while ( i < 183240 ) loop
-- --	while ( frame_count < 4 ) loop
--         -- Only one frame is needed for external RAM
-- 	while ( frame_count < 1 ) loop
-- 		    wait until ( clock = '1');
-- 		    wait until ( clock = '0');
--
-- --		if ( out_empty = '0' ) then
-- 		if ( ram_read_en = '1' ) then
-- 		    out_rd_en    <= '1';
--                     if (dout_count = IMG_SIZE-1) then
--                         frame_count <= frame_count + 1;
--                         dout_count      <= 0;
--                     else
--                         dout_count  <= dout_count + 1;
--                     end if;
--                     if ((dout_count mod 5000) = 0) then
--                          write(my_line,string'(" ... writing dout count =  ... "));
--                          write(my_line,dout_count);
--                          writeline(output,my_line);  -- write to stdout
--                      end if;
-- 				--read( cmp_file, char );
-- 				--read( cmp_file, char );
-- 				--read( cmp_file, char );
-- 				--out_data_cmp := to_slv(char);
--                    if (frame_count = 0) then
--                      write(out_file, to_char(out_dout(7 downto 0)));
--                      write(out_file, to_char(out_dout(15 downto 8)));
--                      write(out_file, to_char(out_dout(23 downto 16)));
--                    end if;
--                    if (frame_count = 1) then
--                      write(out_file1, to_char(out_dout(23 downto 16)));
--                      write(out_file1, to_char(out_dout(15 downto 8)));
--                      write(out_file1, to_char(out_dout(7 downto 0)));
--                    end if;
--                    if (frame_count = 2) then
--                      write(out_file2, to_char(out_dout(23 downto 16)));
--                      write(out_file2, to_char(out_dout(15 downto 8)));
--                      write(out_file2, to_char(out_dout(7 downto 0)));
--                    end if;
--                    if (frame_count = 3) then
--                      write(out_file3, to_char(out_dout(23 downto 16)));
--                      write(out_file3, to_char(out_dout(15 downto 8)));
--                      write(out_file3, to_char(out_dout(7 downto 0)));
--                    end if;
--
--                 -- write( ln3, string'("@ ") );
--                 -- write( ln3, NOW );
--                 -- write( ln3, string'(": ") );
--                 -- write( ln3, i );
--                 -- write( ln3, string'(": ") );
--                 -- hwrite( ln3, out_dout );
--                 -- writeline( output, ln3 );
--
-- 				--if ( to_01(unsigned(out_dout)) /= to_01(unsigned(out_data_cmp)) ) then
-- 					--out_errors <= out_errors + 1;
-- 					--write( ln2, string'("@ ") );
-- 					--write( ln2, NOW );
-- 					--write( ln2, string'(": ") );
-- 					--write( ln2, IMG_OUT_NAME );
-- 					--write( ln2, string'("(") );
-- 					--write( ln2, i + 1 );
-- 					--write( ln2, string'("): ERROR: ") );
-- 					--hwrite( ln2, out_dout );
-- 					--write( ln2, string'(" != ") );
-- 					--hwrite( ln2, out_data_cmp );
-- 					--write( ln2, string'(" at address 0x") );
-- 					--hwrite( ln2, std_logic_vector(to_unsigned(i,32)) );
-- 					--write( ln2, string'(".") );
-- 					--writeline( output, ln2 );
--                     --exit;
-- 				--end if;
--                    -- Need to output original image first, then the lines
-- --                   if (in_write_done = '1') then
-- --                        i := i + 1;
-- --                   end if;
-- --		   if (i = 183240) then
-- --		      exit;
-- --		   end if;
-- 		else
-- --		   wait until ( clock = '1');
-- --		   wait until ( clock = '0');
-- 		   out_rd_en <= '0';
--                 end if;                 -- ram_read_en
--         end loop;
--
-- 		wait until (clock = '1');
-- 		wait until (clock = '0');
-- 		out_rd_en <= '0';
--         --file_close( cmp_file );
--         file_close( out_file );
--         out_read_done <= '1';
--         wait;
--     end process img_write_process;
--
--
-- end architecture behavior;
