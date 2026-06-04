--------------------------------------
-- Send 8 Bytes to XY5300 MP Player --
--------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;

entity bytes_to_mp3 is
	generic ( timer_active  : integer := 0;
              timer_count   : natural := 2500000 ); 		-- 0.1 sec per byte 
	port ( resetN       : in  std_logic;					-- Active-low
           clk          : in  std_logic;
           din          : in  std_logic_vector(15 downto 0) ;
           send         : in  std_logic;                    -- send contents of din back to PC
           stop         : in  std_logic;                    -- stop sending because PC or tranmitter are busy
           to_write_din : out std_logic;                    -- write back now command to UART
           to_din       : out std_logic_vector(7 downto 0);	-- data to write back to UART
           ready        : out std_logic );                  -- stste machine is back to idle
end bytes_to_mp3 ;

architecture arc_bytes_to_mp3 of bytes_to_mp3 is
    -- input sampler
	signal dint     : std_logic_vector(15 downto 0) ;  -- sample inputs (PIPO register)
	signal ena_dint : std_logic                      ; -- enable sample of inputs only when in idle state
	-- byte counter (each count points on a byte of the 128 bit register - dint)
	signal ncount     : std_logic_vector(2 downto 0) ; -- byte (character) counter
	signal ena_ncount : std_logic                    ; -- enable byte counter
	signal clr_ncount : std_logic                    ; -- clear byte counter
	signal eoc        : std_logic                    ; -- detect end of count
	-- sync mux: selects the 8 bits that will pass
	signal ena_byte   : std_logic                    ; -- enable loading a single byte from dint vector
	signal byte       : std_logic_vector(7 downto 0) ; -- a single byte extracted from vector
	-- delay timer declarations
	constant td_max   : integer := timer_count ; 	  -- 0.1 sec
	--   constant td_max   : integer := 300 ; -- 1/baud
	signal td_count   : integer range 0 to td_max ; 	  -- timer count
	signal ted        : std_logic ;                    -- timer enable
	signal tod        : std_logic ;                    -- delay time out         
	-- state machine states
	type state is
	( idle                ,
	  wait_for_clearance  ,   -- wait until UART and PC not Busy
	  point_to_byte       ,   -- send current byte 
	  tell_output         ,   -- activate UART now
	  chk_delay_timer     ,   -- stay in this state if timer requested and timeout did not pass
	  chk_count           ,   -- check if on last charater
	  count_byte          ) ; -- increment byte counter by 1
	  
	signal present_state , next_state : state ;
	
begin
	-------------------
	-- state machine --
	-------------------
	-- sync process
	process(clk, resetN)
	begin
		if to_x01(resetN) = '0' then
			present_state <= idle;
		elsif rising_edge(clk) then
			present_state <= next_state;
		end if;
	end process;

	-- comb process
	process(present_state, send, stop, tod, eoc)
	begin
		-- default assignments
		next_state    <= present_state;
		ena_dint      <= '0';
		clr_ncount    <= '0';
		ena_ncount    <= '0';
		ena_byte      <= '0';
		ted           <= '0';
		to_write_din  <= '0';
		ready         <= '0';

		case present_state is
			when idle =>
				ready    <= '1';
				ena_dint <= '1';
				if send = '1' then
				   clr_ncount <= '1';
				   next_state <= wait_for_clearance;
				end if;

			when wait_for_clearance =>
				if stop = '0' then
				   next_state <= point_to_byte;
				end if;

			when point_to_byte =>
				ena_byte   <= '1';
				next_state <= tell_output;

			when tell_output =>
				to_write_din <= '1';
				next_state   <= chk_delay_timer;

			when chk_delay_timer =>
				if timer_active = 1 then
				   ted <= '1';
				   if tod = '1' then
					  next_state <= chk_count;
				   end if;
				else
				   next_state <= chk_count;
				end if;

			when chk_count =>
				if eoc = '1' then
				   next_state <= idle;
				else
				   next_state <= count_byte;
				end if;

			when count_byte =>
				ena_ncount <= '1';
				next_state <= wait_for_clearance;

			when others =>
				next_state <= idle;
		end case;
	end process;

	---------------------------
	-- Input sample register --
	---------------------------
	process (resetN,clk)
	begin
		if resetN = '0' then
			dint <= (others => '0') ;
		elsif rising_edge(clk) then
			if send = '1' and ena_dint = '1' then
				dint <= din ;
			end if ; 
		end if ;
	end process ;

	--------------------------------------------------------------
	-- byte counter that points to the 8 bit section to be sent --
	--------------------------------------------------------------
	process ( resetN , clk )
	begin
		if resetN = '0' then
			ncount <= (others => '0') ;
		elsif rising_edge(clk) then
			if clr_ncount = '1' then
				ncount <= (others => '0') ;
			elsif ena_ncount = '1' and eoc /= '1' then
				ncount <= ncount + 1 ;
			end if ;
		end if ;
	end process ;
	
	-- limit number of characters that can be sent back to 31
	eoc <= '1' when ncount = "111" else '0' ;

	--------------------------
	-- Optional delay timer --
	-- used only for debug  --
	--------------------------
	process ( clk , resetN )
	begin
		if resetN = '0' then
			td_count <= 0 ;
		elsif rising_edge(clk) then
			if ted = '0'  then
				td_count <= 0 ;
			elsif (td_count < td_max)  then
				td_count <= td_count + 1 ;
			end if ;
		end if ;
	end process;
	
	tod <= '1' when td_count = td_max else '0' ;

	-------------------------------------------------
	-- Select sections of 8 bits pointed by ncount --
	-------------------------------------------------
	process ( resetN , clk )
	begin
		if resetN = '0' then
			byte <= (others => '0') ;
		elsif rising_edge(clk) then
			if ena_byte = '1' then
				case conv_integer(ncount) is
					when 0 =>      byte <= x"7E" ;              -- start byte                   
					when 1 =>      byte <= x"FF" ;              -- Version Byte                 
					when 2 =>      byte <= x"06" ;              -- Bytes count                  
					when 3 =>      byte <= x"03" ;              -- command byte: play_with_index
					when 4 =>      byte <= x"00" ;              -- Feedback: No                   
					when 5 =>      byte <= dint(15 downto  8) ; -- Data (High song index) 
					when 6 =>      byte <= dint( 7 downto  0) ; -- Data (Low song index)
					when 7 =>      byte <= x"EF" ;              -- Ending Byte
					when others => byte <= x"00" ;            
				end case ;
			end if ;
		end if ;
	end process ;

	-- you can put one more sync stage and enable it 
	-- with signal generated from state machine and you can 
	-- make a filter that will change output string
	to_din <= byte ;
   
end arc_bytes_to_mp3 ;