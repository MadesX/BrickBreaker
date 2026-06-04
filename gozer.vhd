---------------------------------------------
-- Sync fall(0)/rise(1)/change(2) detector --
-- Amoz Zaslavsky (C) Copyright            --
--------------------------------------------- 
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
entity gozer is
   port ( resetN, clk, din   : in  std_logic ;
          rise, fall, change : out std_logic ) ;
end gozer ;
architecture arc_gozer of gozer is
   signal sampled1 , sampled2 : std_logic ;
begin
   process ( clk , resetN )
   begin
      if resetN = '0' then
         sampled1 <= '0' ;
         sampled2 <= '0' ;
      elsif rising_edge(clk) then
         sampled1 <= din      ;
         sampled2 <= sampled1 ;
      end if ;
   end process ;
   rise <= sampled1 and not sampled2 ;
   fall <= not sampled1 and sampled2 ;   
   change <= sampled1 xor sampled2 ;
end arc_gozer ;
