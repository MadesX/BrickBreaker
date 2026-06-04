library ieee ;
use ieee.std_logic_1164.all ;

entity rise is
	port ( din,clk,resetN : in  std_logic ;
           dout           : out std_logic ) ;
end rise ;

architecture arc_rise of rise is
	signal sampled1 , sampled2 : std_logic ;
begin
    process ( clk , resetN )
    begin
		if resetN = '0' then
			sampled1 <= '0' ;
			sampled2 <= '0' ;
		elsif clk'event and clk = '1' then
			sampled1 <= din      ;
			sampled2 <= sampled1 ;
		end if ;
    end process ;
	
    dout <= sampled1 and not sampled2 ;
end arc_rise ;

