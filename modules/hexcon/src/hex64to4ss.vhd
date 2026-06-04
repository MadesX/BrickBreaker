--------------------------------------
-- 64 bit to 4 Seven-Segments with  --
-- 2 bit select input & DP decoding --
-- Copyright (C) Amos Zaslavsky     --
--------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
entity hex64to4ss is
   port ( din     : in  std_logic_vector(63 downto 0) ;
          sel     : in  std_logic_vector( 1 downto 0) ;          
          hex0s   : out std_logic_vector( 6 downto 0) ;
          hex0_dp : out std_logic                     ;
          hex1s   : out std_logic_vector( 6 downto 0) ;
          hex1_dp : out std_logic                     ;          
          hex2s   : out std_logic_vector( 6 downto 0) ;
          hex2_dp : out std_logic                     ;
          hex3s   : out std_logic_vector( 6 downto 0) ;
          hex3_dp : out std_logic                     ) ;
end hex64to4ss ;
architecture arc_hex64to4ss of hex64to4ss is
   signal dint : std_logic_vector(15 downto 0) ; -- display width
   procedure hexss ( signal din : in  std_logic_vector(3 downto 0) ;
                     signal ss  : out std_logic_vector(6 downto 0) ) is
   begin   
      case din is
         when "0000" => ss <= "0000001" ; -- 0 active low
         when "0001" => ss <= "1001111" ; -- 1
         when "0010" => ss <= "0010010" ; -- 2
         when "0011" => ss <= "0000110" ; -- 3
         when "0100" => ss <= "1001100" ; -- 4
         when "0101" => ss <= "0100100" ; -- 5
         when "0110" => ss <= "0100000" ; -- 6
         when "0111" => ss <= "0001111" ; -- 7
         when "1000" => ss <= "0000000" ; -- 8
         when "1001" => ss <= "0000100" ; -- 9
         when "1010" => ss <= "0001000" ; -- A
         when "1011" => ss <= "1100000" ; -- B
         when "1100" => ss <= "0110001" ; -- C
         when "1101" => ss <= "1000010" ; -- D
         when "1110" => ss <= "0110000" ; -- E
         when "1111" => ss <= "0111000" ; -- F 
         when others => ss <= "1111111" ; -- dark 
      end case ; 
   end hexss ; 
begin
   process(din,sel)
   begin
      dint <= (others => '0') ;
      hex0_dp <= '1' ; -- active low
      hex1_dp <= '1' ;
      hex2_dp <= '1' ;
      hex3_dp <= '1' ;
      case sel is
         when "00"   => 
            dint <= din(15 downto  0) ;
            hex0_dp <= '0' ;
         when "01"   => 
            dint <= din(31 downto 16) ;
            hex1_dp <= '0' ;
         when "10"   => 
            dint <= din(47 downto 32) ;
            hex2_dp <= '0' ;
         when others => 
            dint <= din(63 downto 48) ;
            hex3_dp <= '0' ;
      end case ;
   end process ;        
   hexss( dint(15 downto 12) , hex3s ) ; -- left  ss
   hexss( dint(11 downto  8) , hex2s ) ;
   hexss( dint( 7 downto  4) , hex1s ) ;
   hexss( dint( 3 downto  0) , hex0s ) ; -- right ss   
end arc_hex64to4ss ;