------------------------------
-- Reg Reader               --
-- Read from register to PC --
------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;

entity reg2bytes is
	generic ( timer_active  : integer := 1;
			  timer_count   : natural := 2500000 ); 		 -- 0.1 sec
	port ( resetN       : in  std_logic;					 -- Active-low
          clk          : in  std_logic;
          din          : in  std_logic_vector(63 downto 0);
          send         : in  std_logic;                      -- send contents of din back to PC
          stop         : in  std_logic;                      -- stop sending because PC or tranmitter are busy
          to_write_din : out std_logic;                      -- write back command
          to_din       : out std_logic_vector(7 downto 0);
          ready        : out std_logic ) ;
end reg2bytes ;

architecture arc_reg2bytes of reg2bytes is
	-- input sampler
	signal dint     : std_logic_vector(63 downto 0); -- sample inputs
	signal ena_dint : std_logic ;                    -- enable sample of inputs when in idle state
	-- nibble counter (each count points on a nibbl of the 64 bit register)
	signal ncount     : std_logic_vector(3 downto 0);
	signal ena_ncount : std_logic ; 				 -- enable nibble counter
	signal clr_ncount : std_logic ; 				 -- clear nibble counter
	signal eoc        : std_logic ; 				 -- end of count
	-- sync mux: selects the 4 bit that will pass
	signal ena_4      : std_logic ;
	signal nibble     : std_logic_vector(3 downto 0) ;
	-- sync filter: converts the nibble HEX value to it's ASCII code
	signal ena_8      : std_logic ;

	-- delay timer declarations
	constant td_max   : integer := timer_count ; 	 -- 0.1 sec

	signal td_count   : integer range 0 to td_max ;  -- timer count
	signal ted        : std_logic ;                  -- timer enable
	signal tod        : std_logic ;                  -- delay time out


	-- state machine
	type state is
	( idle        ,
	  wait_for_clerence     ,
	  point_to_nibble       ,
	  filter_assci_out      ,
	  tell_output           ,
	  chk_delay_timer       ,   -- stay in this state if timer requested and timeout did not pass
	  chk_count             ,
	  count_nibble          ) ;
	  
	signal present_state , next_state : state ;
	
begin
	-------------------
	-- state machine --
	-------------------
	-- sync process
	process ( resetN , clk )
	begin
		if resetN = '0' then
			present_state <= idle ;
		elsif clk'event and clk = '1' then
			present_state <= next_state ;
		end if ;
	end process ;
	
	-- comb process
	process ( present_state , send , stop , eoc, tod )
	begin
		ena_dint     <= '0' ;
		ena_ncount   <= '0' ;
		clr_ncount   <= '0' ;
		ena_4        <= '0' ;
		ena_8        <= '0' ;
		to_write_din <= '0' ;
		ready        <= '0' ;
		ted          <= '0' ;
		case present_state is
		 -------------------------------------
			when idle =>
				clr_ncount   <= '1' ;
				ena_dint     <= '1' ;
				ready        <= '1' ;
				if send = '1' then
				   next_state <= wait_for_clerence ;
				else
				   next_state <= idle ;
				end if ;
		 -------------------------------------
			when wait_for_clerence =>
				if stop = '1' then
				   next_state <= wait_for_clerence ;
				else
				   next_state <= point_to_nibble ;
				end if ;
		 -------------------------------------
			when point_to_nibble =>
				ena_4      <= '1' ;
				next_state <= filter_assci_out ;
		 -------------------------------------
			when filter_assci_out =>
				ena_8      <= '1' ;
				next_state <= tell_output ;
		 -------------------------------------
			when tell_output =>
				to_write_din <= '1' ;
				next_state   <= chk_delay_timer ;
		 -------------------------------------
			when chk_delay_timer =>
				ted <= '1' ;
				if tod /= '1' and timer_active = 1 then
				   next_state <= chk_delay_timer ;
				else
				   next_state <= chk_count ;
				end if ;  
		 -------------------------------------
			when chk_count =>
				if eoc = '1' then
				   next_state <= idle ;
				else
				   next_state <= count_nibble ;
				end if ;
		 -------------------------------------
			when count_nibble =>
				ena_ncount <= '1' ;
				next_state <= wait_for_clerence ;
		 -------------------------------------
			when others => next_state <= idle ;
		 -------------------------------------
		end case;
	end process ;

	---------------------------
	-- Input sample register --
	---------------------------
	process (resetN,clk)
	begin
		if resetN = '0' then
			dint <= (others => '0') ;
		elsif clk'event and clk = '1' then
			if send = '1' and ena_dint = '1' then
				dint <= din ;
			end if ;
		end if ;
	end process ;

	-----------------------------------------------------------------
	-- nibble counter that points to the 4 bit section of register --
	-----------------------------------------------------------------
	process ( resetN , clk )
	begin
		if resetN = '0' then
			ncount <= (others => '0') ;
		elsif clk'event and clk = '1' then
			if clr_ncount = '1' then
				ncount <= (others => '0') ;
			elsif ena_ncount = '1' and eoc /= '1' then
				ncount <= ncount + 1 ;
			end if ;
		end if ;
	end process ;
	eoc <= '1' when ncount = "1111" else '0' ;

	------------------------------------------------
	-- store sections of 4 bits pointed by ncount --
	------------------------------------------------
	process ( resetN , clk )
	begin
		if resetN = '0' then
			nibble <= (others => '0') ;
		elsif clk'event and clk = '1' then
			if ena_4 = '1' then
				case conv_integer(ncount) is
					when  0 => nibble <= dint(63 downto 60) ;
					when  1 => nibble <= dint(59 downto 56) ;
					when  2 => nibble <= dint(55 downto 52) ;
					when  3 => nibble <= dint(51 downto 48) ;
					when  4 => nibble <= dint(47 downto 44) ;
					when  5 => nibble <= dint(43 downto 40) ;
					when  6 => nibble <= dint(39 downto 36) ;
					when  7 => nibble <= dint(35 downto 32) ;
					when  8 => nibble <= dint(31 downto 28) ;
					when  9 => nibble <= dint(27 downto 24) ;
					when 10 => nibble <= dint(23 downto 20) ;
					when 11 => nibble <= dint(19 downto 16) ;
					when 12 => nibble <= dint(15 downto 12) ;
					when 13 => nibble <= dint(11 downto  8) ;
					when 14 => nibble <= dint( 7 downto  4) ;
					when 15 => nibble <= dint( 3 downto  0) ;
					when others => nibble <= "0000" ;
				end case ;
			end if ;
		end if ;
	end process ;

	-----------------------------------------------------
	-- filter out nibble value as ASCII character code --
	-----------------------------------------------------
	process ( resetN , clk )
	begin
		if resetN = '0' then
			to_din <= (others => '0') ;
		elsif clk'event and clk = '1' then
			if ena_8 = '1' then
				if  nibble < 10 then                    -- 0 to 9
					to_din <= ("0000" & nibble) + 48 ;
				else
					to_din <= ("0000" & nibble) + 55 ;  -- A to F (genrated as UPPERCASE to PC)
				end if ;
			end if ;
		end if ;
	end process ;

	-----------------
	-- delay timer --
	-----------------
	process ( clk , resetN )
	begin
		if resetN = '0' then
			td_count <= 0 ;
		elsif clk'event and clk = '1' then
			if ted = '0'  then
				td_count <= 0 ;
			elsif (td_count < td_max)  then
				td_count <= td_count + 1 ;
			end if ;
		end if ;
	end process;
	
	tod <= '1' when td_count = td_max else '0' ;
end arc_reg2bytes ;