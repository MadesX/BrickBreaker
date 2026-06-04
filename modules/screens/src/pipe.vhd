----------------------------------------------------
-- Pipeline includes zero too --
-- Copyright (C) Amos Zaslavsky --
----------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
entity pipe is
    generic ( depth : natural := 1 ) ;
    port ( resetN : in  std_logic ;
           clk    : in  std_logic ;
           din    : in  std_logic ;
           dout   : out std_logic ) ;
end pipe ;

architecture arc_pipe of pipe is
    component dffx
        port ( resetN,clk,d : in  std_logic ;
               q            : out std_logic ) ;
    end component ;
    signal d : std_logic_vector(1 to depth+1) ;
begin
    u0: if depth = 0 generate
        dout <= din ;
    end generate ;

    ubig: if 0 < depth generate
        d(1) <= din ;
        loop_label: for i in 1 to depth generate
            ui : dffx port map ( resetN => resetN ,
                                 clk    => clk ,
                                 d      => d(i) ,
                                 q      => d(i+1) ) ;
        end generate ;
        dout <= d(depth + 1) ;
    end generate ;
end arc_pipe ;
