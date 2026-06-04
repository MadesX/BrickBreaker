----------------------------------------------------
-- Duplicate input signal X 4 for simple DAC --
----------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
entity dup4 is
    port ( din_r  : in  std_logic ;
           din_g  : in  std_logic ;
           din_b  : in  std_logic ;
           ena    : in  std_logic ;
           dout_r : out std_logic_vector(3 downto 0) ;
           dout_g : out std_logic_vector(3 downto 0) ;
           dout_b : out std_logic_vector(3 downto 0) ) ;
end dup4 ;

architecture arc_dup4 of dup4 is
begin
    process ( din_r, din_g, din_b, ena )
    begin
        dout_r <= (others => '0') ;
        dout_g <= (others => '0') ;
        dout_b <= (others => '0') ;
        if ena = '1' then
            dout_r <= ( others => din_r ) ;
            dout_g <= ( others => din_g ) ;
            dout_b <= ( others => din_b ) ;
        end if ;
    end process ;
end arc_dup4 ;
