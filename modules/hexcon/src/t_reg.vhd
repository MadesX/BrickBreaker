--------------------------------------
-- t_register (C) Amos Zaslavsky    --
-- detect singel clock width pulses -- 
--------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;

entity t_reg is
	generic ( width : natural := 3 ) ;
	port ( resetN : in  std_logic                          ;
           clk    : in  std_logic                          ;
           clr    : in  std_logic                          ;
           tin    : in  std_logic_vector(width-1 downto 0) ;
           qout   : out std_logic_vector(width-1 downto 0) ) ;
end t_reg ;

architecture arc_t_reg of t_reg is
	procedure tffx ( signal resetN, clk , clr , t  : in    std_logic ;
                     signal q                      : inout std_logic ) is
	begin
		if resetN = '0' then
			q <= '0' ;
		elsif rising_edge(clk) then
			if clr = '1' then
				q <= '0' ;
			elsif t = '1' then
				q <= not q ;
			end if ;   
		end if ;
	end tffx ;
	
	signal q : std_logic_vector(width-1 downto 0) ;
	begin
		loop_label : for i in 0 to width-1 generate
			tffx ( resetN , clk , clr , tin(i) , q(i) ) ;
	end generate ;
	
	qout <= q ;
end arc_t_reg ;