library ieee ;
use ieee.std_logic_1164.all ;
entity dffx is
    port ( resetN,clk,d : in  std_logic ;
           q            : out std_logic ) ;
end dffx ;
architecture arc_dffx of dffx is
begin
    process ( resetN , clk )
    begin
        if resetN = '0' then
            q <= '0' ;
        elsif clk'event and clk = '1' then
            q <= d ;
        end if ;
    end process ;
end arc_dffx ;