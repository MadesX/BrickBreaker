----------------------------------------------------------------------
-- Amos Zaslavsky (C) Copyright (part of serial2reg or hexcon       --
-- This is a General Inteface prototype whic gets (collects) bytes  --
-- from UART receiver and converts them to a big register (64)      --
-- Can be used to interface PC (or smart phone) to FPGA on card     --
-- You are invited to change it to suite your project needs ...     --
----------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
entity bytes2reg is
    port ( resetN     : in  std_logic;						   -- Active-low
           clk        : in  std_logic;
           din        : in  std_logic_vector(7 downto 0);      -- comes from dout of UART
           enable     : in  std_logic;                         -- comes from dout_new of UART
           clr_reg    : in  std_logic;                         -- clear register an pointer
           hexout     : out std_logic_vector( 7 downto 0);     -- hex number output for debug only          
           cout       : out std_logic_vector( 4 downto 0);     -- pointer position for debug only          
           dout       : out std_logic_vector(63 downto 0);     -- 64 bit register  
           new_hex    : out std_logic;                         -- a new nibble has arrived
           g_out      : out std_logic;                         -- a get command signal (used with reg2bytes/hexcon)
           stop       : out std_logic;                         -- a stop signal caused by Xon/Xoff (used with regreader)
		   
		   up_out     : out std_logic;
           down_out   : out std_logic;
           left_out   : out std_logic;
		   right_out  : out std_logic;
		   select_out : out std_logic  ) ;
end bytes2reg ;

architecture arc_bytes2reg of bytes2reg is
	signal dint     : std_logic_vector(7 downto 0) ; -- filtered low level hex value
	signal hex_ena  : std_Logic ;                    -- character is a HEX character
	signal bs_int   : std_logic ;                    -- Back Space move the pointer backwards
	signal tab_int  : std_logic ;                    -- move counter to the right but not writting    
	signal g_int    : std_logic ;                    -- get data back to PC
	signal count    : std_logic_vector(4 downto 0) ; -- coutner that points to register (stuck at 16)
	
    signal up_int, down_int, left_int, right_int     : std_logic;
	signal stop_int, start_int, back_int, select_int : std_logic;
begin
   --------------------------------------
   -- Hex combinatorial filter section --
   --------------------------------------
   process (enable,din)
   begin
		dint       <= "00000000" ;
		hex_ena    <= '0' ;
		bs_int     <= '0' ;
		tab_int    <= '0' ;      
		g_int      <= '0' ;
		up_int     <= '0' ;
		down_int   <= '0' ; 
		left_int   <= '0' ;
		right_int  <= '0' ;
		select_int <= '0' ;
        if enable = '1' then
			if (48 <= din) and (din <= 57 ) then 	-- 0 to 9
				dint <= din - 48 ;
				hex_ena <= '1' ;
			elsif din = 32 then 					-- added section to make space chr function as 0   
				dint <= "00000000" ; 
				hex_ena <= '1' ;            
			elsif (65 <= din) and (din <= 70 ) then -- A to F
				dint <= din - 55 ;
				hex_ena <= '1' ;
			elsif (97 <= din) and (din <= 102) then -- a to f
				dint <= din - 87 ;
				hex_ena <= '1' ;
			elsif din = 8  then                     -- BS
				bs_int <= '1' ;
			elsif din = 9  then                     -- TAB
				tab_int <= '1' ;                        
			elsif din = character'pos('g') or din = character'pos('G') then  -- din = 103 or din = 71  -- g or G
				g_int <= '1' ;
			elsif din = character'pos('u') or din = character'pos('U') then
			   up_int <= '1';
			elsif din = character'pos('n') or din = character'pos('N') then
			   down_int <= '1';
			elsif din = character'pos('l') or din = character'pos('L') then
			   left_int <= '1';
			elsif din = character'pos('r') or din = character'pos('R') then
			   right_int <= '1';
			elsif din = character'pos('v') or din = character'pos('V') then
			   select_int <= '1';
			end if ;
       end if ;
    end process ;
	
    ----------------------------------------------------------
    -- counter that points to the 4 bit section of register --
    ----------------------------------------------------------
    process ( resetN , clk )
    begin
        if resetN = '0' then
			count <= (others => '0') ;
        elsif rising_edge(clk) then
			if clr_reg = '1' then 
				count <= (others => '0') ;
			elsif hex_ena = '1' then
				if count < 16 then
					count <= count + 1 ;
				end if ;
			elsif bs_int = '1' then
				if 0 < count then
					count <= count - 1 ;
				end if ;            
			elsif tab_int = '1' then
				if count < 16 then
					count <= count + 1 ;
				end if ;                        
			end if ;
        end if ;
    end process ;
    cout <= count + "00000" ; -- debug vector output

    -------------------------------------------------
    -- register divided into 16 sections of 4 bits --
    -------------------------------------------------
    process ( resetN , clk )
    begin
		if resetN = '0' then
			dout <= (others => '0') ;
		elsif rising_edge(clk) then
			if clr_reg = '1' then 
				dout <= (others => '0') ;
			elsif hex_ena = '1' then         
				for i in 0 to 15 loop
				    if count = i then
						-- Coose only one entry type !
						dout(63 - 4 * i downto 63 - 4 * i - 3) <= dint(3 downto 0) ; -- MSB First
	                    -- dout( 4 * i + 3 downto 4 * i)       <= dint(3 downto 0) ; -- LSB First
				    end if ;
				end loop ;           
			end if ;
		end if ;
    end process ;
   
    ----------------------------------------
    -- Synchronization of output commands --
    ----------------------------------------
    process ( resetN , clk )
    begin
        if resetN = '0' then
			hexout     <= (others => '0') ;      
			new_hex    <= '0' ;
			g_out      <= '0' ;
			down_out   <= '0' ;
			left_out   <= '0' ;
			right_out  <= '0' ;
			select_out <= '0' ;
		elsif rising_edge(clk) then
			hexout     <= dint ;      
			new_hex    <= hex_ena;
			g_out      <= g_int;
			up_out     <= up_int;
			down_out   <= down_int;
			left_out   <= left_int;
			right_out  <= right_int;
			select_out <= select_int;
		end if ;
    end process ;

    --------------------------
    -- Xon/Xoff Recognition --
    -- Behaves as an SR-FF  --
    --------------------------
    process ( clk , resetN )
		constant xon : std_logic_vector(7 downto 0) := "00010001" ; --11h
		constant xoff: std_logic_vector(7 downto 0) := "00010011" ; --13h
    begin
		if resetN = '0' then
			stop <= '0';
		elsif rising_edge(clk) then
			if enable = '1' then
				if din = xoff  then
					stop <= '1';
				elsif din = xon then
					stop <= '0';
				end if;
			end if;
		end if ;
	end process ;

end arc_bytes2reg ;