-------------------------------------------------------
-- UART transmitter  --
-------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
entity transmitter is
	generic ( clockfreq : integer := 25000000 ;
              baud      : integer := 9600 ) ;
	port ( resetN    : in  std_logic;					-- Active-low
           clk       : in  std_logic;	
           write_din : in  std_logic;
           din       : in  std_logic_vector(7 downto 0);
           tx        : out std_logic;
           tx_ready  : out std_logic ) ;
end transmitter ;

architecture arc_transmitter of transmitter is
	constant t1_count   : integer := clockfreq / baud ; -- 217
	constant t2_count   : integer := t1_count / 2     ; -- 108
   
	-- timer            floor(log2(t1_count)) downto 0
	signal tcount : integer range 0 to (t1_count - 1) ;
	signal te     : std_logic ; -- Timer_Enable/!reset
	signal t1     : std_logic ; -- end of one time slot

	-- data counter
	signal dcount     : std_logic_vector(2 downto 0) ; -- data counter
	signal ena_dcount : std_logic                    ; -- enable this counter
	signal clr_dcount : std_logic                    ; -- clear this counter
	signal eoc        : std_logic                    ; -- end of count (7)

	-- shift register
	signal dint      : std_logic_vector(7 downto 0) ;
	signal ena_shift : std_logic                    ; -- enable shift register
	signal ena_load  : std_logic                    ; -- enable parallel load

	-- output flip-flop --
	signal clr_tx : std_logic ; -- clear  tx during start bit
	signal set_tx : std_logic ; -- set    tx during stop  bit
	signal ena_tx : std_logic ; -- enable tx from shift register during data transfer

	-- state machine
	type state is
	( idle        ,
      send_start  ,
      clear_timer ,
      send_data   ,
      test_eoc    ,
      shift_count ,
      send_stop   ) ;

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
	process(present_state, write_din, t1, eoc)
	begin
		next_state <= present_state;
		ena_load   <= '0';
		clr_dcount <= '0';
		tx_ready   <= '0';
		te         <= '0';
		clr_tx     <= '0';
		ena_tx     <= '0';
		ena_shift  <= '0';
		ena_dcount <= '0';
		set_tx     <= '0';
      
		case present_state is 
			when idle => 
				tx_ready <= '1';
				if to_x01(write_din) = '1' then 
				   next_state <= send_start;
				end if;
            
			when send_start =>
				clr_tx     <= '1';
				ena_load   <= '1';
				te         <= '1';
				clr_dcount <= '1';
				if to_x01(t1) = '1' then
					next_state <= clear_timer;
				end if;
         
			when clear_timer => 
				next_state <= send_data;
         
			when send_data =>
				ena_tx     <= '1';
				te         <= '1';
				if to_x01(t1) = '1' then
					next_state <= test_eoc;
				end if;
         
			when test_eoc => 
				ena_dcount <= '1';
				if to_x01(eoc) = '1' then
				   next_state <= send_stop;
				else
				   next_state <= shift_count;
				end if;
            
			when shift_count =>
				ena_shift <= '1';
				next_state <= send_data;
			 
			when send_stop =>
				set_tx <= '1';
				te     <= '1';
				if to_x01(t1) = '1' then
					next_state <= idle;
				end if;
		end case;
	end process;
   
	-----------
	-- timer --
	-----------
	process(clk, resetN)
	begin
		if to_x01(resetN) = '0' then
			tcount <= 0;
		elsif rising_edge(clk) then
			if to_x01(te) = '0' then
				tcount <= 0;
			elsif not (tcount = t1_count - 1) then
				tcount <= tcount + 1;
			else 
				tcount <= 0;
			end if;
		end if;
	end process;
   
    t1 <= '0' when (not (tcount = t1_count - 1)) else '1';
   
	------------------
	-- data counter --
	------------------
	process(clk, resetN)
	begin
		if to_x01(resetN) = '0' or to_x01(clr_dcount) = '1' then
			dcount <= (others => '0');
		elsif rising_edge(clk) then
			if to_x01(ena_dcount) = '1' then
				dcount <= dcount + 1;
			end if;
		end if;
	end process;
   
	eoc <= '1' when dcount = "111" else '0';
   
	--------------------
	-- shift register --
	--------------------
	process(clk, resetN)
	begin 
		if to_x01(resetN) = '0' then
			dint <= (others => '1');
		elsif rising_edge(clk) then
			if to_x01(ena_load) = '1' then
				dint <= din;
			elsif to_x01(ena_shift) = '1' then
				dint <= '1' & dint(7 downto 1);
			end if;
		end if;
	end process;

	----------------------
	-- output flip-flop --
	----------------------
	process(clk, resetN)
	begin
		if to_x01(resetN) = '0' then
			tx <= '1';
		elsif rising_edge(clk) then
			if to_x01(clr_tx) = '1' then
				tx <= '0';
			elsif to_x01(ena_tx) = '1' then
				tx <= dint(0);
			elsif to_x01(set_tx) = '1' then
				tx <= '1';
			end if;
		end if;
	end process;  

end arc_transmitter ;