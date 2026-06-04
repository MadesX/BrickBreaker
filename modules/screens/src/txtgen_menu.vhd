library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;

entity txtgen_menu is
    port (
        clk       : in     std_logic ;
        count_v   : in     std_logic_vector(9 downto 0) ;
        count_h   : in     std_logic_vector(9 downto 0) ;
        size      : in     std_logic ;						-- '0' for button text | '1' for title
        char_code : buffer std_logic_vector(5 downto 0) ;
        pospix_v  : buffer std_logic_vector(2 downto 0) ;
        pospix_h  : buffer std_logic_vector(2 downto 0)
    );
end txtgen_menu ;

architecture arc_txtgen_menu of txtgen_menu is
    -- Internal outputs (to be synchronized)
    signal int_char_code : std_logic_vector(5 downto 0) ;
    signal int_pospix_h  : std_logic_vector(2 downto 0) ; -- 3 bit/8 pix
    signal int_pospix_v  : std_logic_vector(2 downto 0) ; -- 3 bit/8 pix
    signal int_poschr_h  : std_logic_vector(6 downto 0) ; -- 7 bit/max 80
    signal int_poschr_v  : std_logic_vector(6 downto 0) ; -- 7 bit/max 60
   
	signal cnt_h : std_logic_vector(9 downto 0); -- virtual h-counter
	signal cnt_v : std_logic_vector(9 downto 0); -- virtual v-counter
   
begin
	process (count_h, count_v, cnt_h, cnt_v, size)
	begin
		if (size = '0') then
			-- Constant text block placer
			cnt_h <= count_h - 273;
			cnt_v <= count_v - 266;
			
			-- Low bits are column of pixel in char box
			int_pospix_h <= cnt_h(2 downto 0) ;
			-- High bits are column of text on screen
			int_poschr_h <= cnt_h(9 downto 3) ;
			
			-- Low bits are row of pixel in char box
			int_pospix_v <= cnt_v(2 downto 0) ;
			-- High bits are row of text on screen
		    int_poschr_v <= cnt_v(9 downto 3) ;
		else
			cnt_h <= count_h - 124;
			cnt_v <= count_v - 150;
			
			int_pospix_h <= cnt_h(4 downto 2) ;
			int_poschr_h <= "00" & cnt_h(9 downto 5) ;

			int_pospix_v <= cnt_v(4 downto 2) ;
			int_poschr_v <= "00" & cnt_v(9 downto 5) ;
		end if;
	end process;

    -- Text generation process
    process (int_poschr_h, int_poschr_v, size)
    begin
		if size = '0' then
			case conv_integer(int_poschr_v) is
				when 2 => -- line 2
					case conv_integer(int_poschr_h) is
						when 0  => int_char_code <= "000001" ; -- 1
						when 1  => int_char_code <= "110000" ; -- space
						when 2  => int_char_code <= "011001" ; -- P
						when 3  => int_char_code <= "010101" ; -- L
						when 4  => int_char_code <= "001010" ; -- A
						when 5  => int_char_code <= "100010" ; -- Y
						when 6  => int_char_code <= "001110" ; -- E
						when 7  => int_char_code <= "011011" ; -- R
						when 8  => int_char_code <= "110000" ; -- space
						when 9  => int_char_code <= "010110" ; -- M
						when 10 => int_char_code <= "011000" ; -- O
						when 11 => int_char_code <= "001101" ; -- D
						when 12 => int_char_code <= "001110" ; -- E
						when others => int_char_code <= "110000" ; -- space
					end case ;
				when 10 => -- line 10
					case conv_integer(int_poschr_h) is
						when 0  => int_char_code <= "000010" ; -- 2
						when 1  => int_char_code <= "110000" ; -- space
						when 2  => int_char_code <= "011001" ; -- P
						when 3  => int_char_code <= "010101" ; -- L
						when 4  => int_char_code <= "001010" ; -- A
						when 5  => int_char_code <= "100010" ; -- Y
						when 6  => int_char_code <= "001110" ; -- E
						when 7  => int_char_code <= "011011" ; -- R
						when 8  => int_char_code <= "110000" ; -- space
						when 9  => int_char_code <= "010110" ; -- M
						when 10 => int_char_code <= "011000" ; -- O
						when 11 => int_char_code <= "001101" ; -- D
						when 12 => int_char_code <= "001110" ; -- E
						when others => int_char_code <= "110000" ; -- space
					end case ;
				when others => int_char_code <= "110000" ; -- space
			end case ;
		else
			case conv_integer(int_poschr_v) is
				when 0 => -- line 0
					case conv_integer(int_poschr_h) is
						when 0  => int_char_code <= "001011" ; -- B
						when 1  => int_char_code <= "011011" ; -- R
						when 2  => int_char_code <= "010010" ; -- I
						when 3  => int_char_code <= "001100" ; -- C
						when 4  => int_char_code <= "010100" ; -- K
						when 5  => int_char_code <= "110000" ; -- space
						when 6  => int_char_code <= "001011" ; -- B
						when 7  => int_char_code <= "011011" ; -- R
						when 8  => int_char_code <= "001110" ; -- E
						when 9  => int_char_code <= "001010" ; -- A
						when 10 => int_char_code <= "010100" ; -- K
						when 11 => int_char_code <= "001110" ; -- E
						when 12 => int_char_code <= "011011" ; -- R
						when others => int_char_code <= "110000" ; -- space
					end case ;
				when others => int_char_code <= "110000" ; -- space
			end case ;
		end if;
    end process ;

    -- Pipeline (synchronization) stage
    process (clk)
    begin
        if clk'event and clk = '1' then
            char_code <= int_char_code ;
            pospix_v  <= int_pospix_v ;
            pospix_h  <= int_pospix_h ;
        end if ;
    end process ;

end arc_txtgen_menu ;
