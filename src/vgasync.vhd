-----------------------------------------
-- VGA vgasync generator / Amos Zaslavsky --
-- Version 2.0 - (C) Copyright         --
-----------------------------------------

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
entity vgasync is
   port ( resetN    : in  std_logic                    ;
          clk       : in  std_logic                    ;
          sync_h    : out std_logic                    ;   -- horizontal sync
          sync_v    : out std_logic                    ;   -- vertical sync
          count_h   : out std_logic_vector(9 downto 0) ;   -- horizontal count
          count_v   : out std_logic_vector(9 downto 0) ;   -- vertical count
          frame_end : out std_logic                    ;   -- last pixle count
          frame_odd : out std_logic                    ;   -- odd frame count
          video     : out std_logic                    ) ;
end vgasync ;
architecture arc_vgasync of vgasync is
   -- h_sync ----------------------____________------------
   -- video  ------------________________________________--
   -- satae      D      ,   E     ,     B      ,    C

   -- v_sync ------------------------______________-------------
   -- video  -------------____________________________________--
   -- state       R      ,     S    ,      P      ,    Q

   constant a     : integer   := 800 ; -- scanline pixels
   constant b     : integer   :=  95 ; -- horizontal sync
   constant c     : integer   :=  45 ; -- back porch
   constant d     : integer   := 640 ; -- video
   constant e     : integer   :=  20 ; -- front porch
   -- 640 x 480 @ 60Hz default Windows VGA graphics mode
   constant o     : integer   := 525 ; -- frame lines
   constant p     : integer   :=   2 ; -- vertical sync
   constant q     : integer   :=  32 ; -- back porch
   constant r     : integer   := 480 ; -- video
   constant s     : integer   :=  11 ; -- front porch
   -- polarity is: '0'=negative, '1'=positive
   constant pol_h : std_logic := '0' ; ---__---
   constant pol_v : std_logic := '0' ; ---__---

--   -- 640 x 400 @ 70Hz default MS-DOS text mode
--   constant o     : integer   := 449 ; -- frame lines
--   constant p     : integer   :=   2 ; -- vertical sync
--   constant q     : integer   :=  35 ; -- back porch
--   constant r     : integer   := 400 ; -- video
--   constant s     : integer   :=  12 ; -- front porch
--   -- polarity: '0'=negative, '1'=positive
--   constant pol_h : std_logic := '0' ; ---__---
--   constant pol_v : std_logic := '1' ; ___--___

--   -- 640 x 350 @ 70Hz EGA mode on a VGA display
--   constant o     : integer   := 449 ; -- frame lines
--   constant p     : integer   :=   2 ; -- vertical sync
--   constant q     : integer   :=  60 ; -- back porch
--   constant r     : integer   := 350 ; -- video
--   constant s     : integer   :=  37 ; -- front porch
--   -- polarity: '0'=negative, '1'=positive
--   constant pol_h : std_logic := '1' ; ___--___
--   constant pol_v : std_logic := '0' ; ---__---

-----------------------------------------------------------------

--   -- 800 x 600 @ 56Hz Super VGA I display mode
--   -- clock      frequency = 36.0 MHz
--   -- horizontal frequency = 35.15625 KHz
--   -- vertical   frequency = 56.25 Hz
--   constant a     : integer     := 1024 ; -- scanline pixels
--   constant b     : integer     :=   72 ; -- horizontal sync
--   constant c     : integer     :=  128 ; -- back porch
--   constant d     : integer     :=  800 ; -- video
--   constant e     : integer     :=   24 ; -- front porch
--   constant o     : integer     :=  625 ; -- frame lines
--   constant p     : integer     :=    1 ; -- verical sync
--   constant q     : integer     :=   23 ; -- back porch
--   constant r     : integer     :=  600 ; -- video
--   constant s     : integer     :=    1 ; -- front porch
--   -- polarity: '0'=negative, '1'=positive
--   constant pol_h : std_logic   :=  '0' ; ---__---
--   constant pol_v : std_logic   :=  '0' ; ---__---


--   -- 800 x 600 @ 60Hz Super VGA II display mode   ****
--   -- clock      frequency = 40.0 MHz
--   -- horizontal frequency = 37.87878787879 KHz
--   -- vertical   frequency = 60.31654120826 Hz
--   constant a     : integer     := 1056 ; -- scanline pixels
--   constant b     : integer     :=  128 ; -- horizontal sync
--   constant c     : integer     :=   88 ; -- back porch
--   constant d     : integer     :=  800 ; -- video
--   constant e     : integer     :=   40 ; -- front porch
--   constant o     : integer     :=  628 ; -- frame lines
--   constant p     : integer     :=    4 ; -- verical sync
--   constant q     : integer     :=   23 ; -- back porch
--   constant r     : integer     :=  600 ; -- video
--   constant s     : integer     :=    1 ; -- front porch
--   -- polarity: '0'=negative, '1'=positive
--   constant pol_h : std_logic   :=  '1' ; ___--___
--   constant pol_v : std_logic   :=  '1' ; ___--___

--   -- 800 x 600 @ 72 Hz Super VGA III display mode
--   -- clock      frequency = 50.0 MHz
--   -- horizontal frequency = 48.07692307692 KHz
--   -- vertical   frequency = 72.18757218757 Hz
--   constant a     : integer     := 1040 ; -- scanline pixels
--   constant b     : integer     :=  120 ; -- horizontal sync
--   constant c     : integer     :=   64 ; -- back porch
--   constant d     : integer     :=  800 ; -- video
--   constant e     : integer     :=   56 ; -- front porch
--   constant o     : integer     :=  666 ; -- frame lines
--   constant p     : integer     :=    6 ; -- verical sync
--   constant q     : integer     :=   23 ; -- back porch
--   constant r     : integer     :=  600 ; -- video
--   constant s     : integer     :=   37 ; -- front porch
--   -- polarity: '0'=negative, '1'=positive
--   constant pol_h : std_logic   :=  '1' ; ___--___
--   constant pol_v : std_logic   :=  '1' ; ___--___


   signal count_h_int   : integer range 0 to 1023 ;  -- internal hor counter
   signal count_v_int   : integer range 0 to 1023 ;  -- internal ver counter
   signal tc_h , tc_v   : std_logic               ;  -- terminal counts
   signal ce_v          : std_logic               ;  -- count enable vertical
   signal sync_h_int    : std_logic               ;  -- internal hor sync
   signal sync_v_int    : std_logic               ;  -- internal ver sync
   signal frame_end_int : std_logic               ;  -- internal last pixle detector
   signal frame_odd_int : std_logic               ;  -- internal odd frame counter
   signal video_int     : std_logic               ;  -- internal video

begin

   -- horizontal counter
   process ( resetN , clk )
   begin
      if resetN = '0' then
         count_h_int <= 0 ;
      elsif clk'event and clk = '1' then
         if tc_h = '1' then   -- mod 800 counter
            count_h_int <= 0 ;
         else
            count_h_int <= count_h_int + 1 ;
         end if ;
      end if ;
   end process ;
   -- counter loop creator
   tc_h <=  '1'  when count_h_int = a - 1 else '0' ;

   -- horizontal synchronization
   sync_h_int <= '1' when     ( d + e <= count_h_int)
                          and (count_h_int < d + e + b )
                     else '0' ;

   -- interconnect between hor & vert counters
   ce_v <=  '1' when (count_h_int = d + e + b/2)
                else '0' ;

   -- vertical counter
   process ( resetN , clk )
   begin
      if resetN = '0' then
         count_v_int <= 0 ;
      elsif clk'event and clk = '1' then
         if ce_v = '1' then
            if tc_v = '1' then   -- mod 525
               count_v_int <= 0 ;
            else
               count_v_int <= count_v_int + 1 ;
            end if ;
         end if ;
      end if ;
   end process ;
   tc_v <= '1' when count_v_int = o - 1 else '0' ;

   -- vertical synchronization
   sync_v_int <= '1' when     ( r + s <= count_v_int )
                          and (count_v_int < r + s + p )
                     else '0' ;

   -- video enable
   video_int <= '1' when     ( count_h_int < d )
                         and ( count_v_int < r )
                else '0' ;

   -- last pixle count
   frame_end_int <= '1' when     ( count_h_int = d - 1 )
                             and ( count_v_int = r - 1 )
                    else '0' ;

   -- internal frame_odd Toggle flip-flip
   process ( clk , resetN )
   begin
      if    resetN = '0' then
         frame_odd_int <= '0' ;
      elsif clk'event and clk = '1' then
         frame_odd_int <= frame_end_int xor frame_odd_int ;
      end if ;
   end process ;

   -- output synchronization
   -- latency level = 2
   process ( clk , resetN )
   begin
      if resetN = '0' then
         sync_h    <=   not pol_h       ;
         sync_v    <=   not pol_v       ;
         count_h   <= ( others => '0' ) ;
         count_v   <= ( others => '0' ) ;
         frame_end <=   '0'             ;
         frame_odd <=   '0'             ;
         video     <=   '0'             ;
      elsif clk'event and clk = '1' then
         sync_h    <= sync_h_int xor not pol_h   ;
         sync_v    <= sync_v_int xor not pol_v   ;
         count_h   <= count_h_int + "0000000000" ; -- convert to vector
         count_v   <= count_v_int + "0000000000" ; -- convert to vector
         frame_end <= frame_end_int              ;
         frame_odd <= frame_odd_int              ;
         video     <= video_int                  ;
      end if ;
   end process ;

end arc_vgasync ;
