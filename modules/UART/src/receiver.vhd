--------------------------------------
-- UART Receiver --
--------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
entity receiver is
	generic ( clockfreq : integer := 25000000 ;
              baud      : integer := 9600 ) ;
	port ( resetN     : in  std_logic;					-- Active-low
           clk        : in  std_logic;
           rx         : in  std_logic;
           read_dout  : in  std_logic;
           rx_ready   : out std_logic;
           dout       : out std_logic_vector(7 downto 0);
           dout_new   : out std_logic;
           dout_ready : out std_logic ) ;
end receiver ;

architecture arc_receiver of receiver is
	constant t1_count   : integer :=  clockfreq / baud      - 2 ; -- 215
	constant t2_count   : integer := (clockfreq / baud) / 2 - 2 ; -- 106

	-- timer            floor(log2(t1_count)) downto 0
	signal tcount : integer range 0 to (t1_count - 1);  -- reach even baud 9600 with 50 MHz clock
	signal te     : std_logic ;                         -- Timer_Enable/!reset
	signal t1     : std_logic ;                         -- end of one  time slot
	signal t2     : std_logic ;                         -- end of half time slot

	-- data counter
	signal dcount     : std_logic_vector(2 downto 0);   -- data counter
	signal ena_dcount : std_logic;                      -- enable this counter
	signal clr_dcount : std_logic;                      -- clear this counter
	signal eoc        : std_logic;                      -- end of count (7)

	-- internal shift register
	signal dint      : std_logic_vector(7 downto 0);
	signal shift_ena : std_logic;                       -- enable shift register

	-- output register
	signal dout_ena  : std_logic;                       -- enable shift register

	-- input flip-flop --
	signal rxs : std_logic ;                            -- synchronize the rx input

	-- state machine
	type state is
	( idle        ,   -- default state no low received yet
	  start_wait  ,   -- wait for mid of start bit sample
	  start_chk   ,   -- decide if it's realy a start bit
	  data_wait   ,   -- wait for mid of a data bit sample
	  data_chk    ,   -- decide if it's the last data bit
	  data_count  ,   -- shift new serial data in and count it ?????
	  stop_wait   ,   -- wait for mid of stop bit sample
	  stop_chk    ,   -- check that stop bit is high
	  break_wait  ,   -- wait until fucked-up low finishes
	  update_out  ,   -- update output data register
	  tell_out    ) ; -- tell external world

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
	process(present_state, rxs, t1, t2, eoc)
	begin
		next_state <= present_state;
		rx_ready   <= '0';
		te         <= '0';
		ena_dcount <= '0';
		clr_dcount <= '0';
		shift_ena  <= '0';
		dout_ena   <= '0';
		dout_new   <= '0';
      
		case present_state is
			when idle =>
				rx_ready <= '1';
				clr_dcount <= '1';
				if rxs = '0' then
				   next_state <= start_wait;
				end if;

			when start_wait =>
				te <= '1';
				if t2 = '1' then
				   next_state <= start_chk;
				end if;

			when start_chk =>
				if rxs = '0' then
				   next_state <= data_wait;
				else
				   next_state <= idle;
				end if;

			when data_wait =>
				te <= '1';
				if t1 = '1' then
				   next_state <= data_chk;
				end if;
            
			when data_chk =>
				shift_ena <= '1';
				if eoc = '1' then
				   next_state <= stop_wait;
				else
				   next_state <= data_count;
				end if;

			when data_count =>
				ena_dcount <= '1';
				next_state <= data_wait;

			when stop_wait =>
				te <= '1';
				if t1 = '1' then
				   next_state <= stop_chk;
				end if;

			when stop_chk =>
				if rxs = '1' then
				   next_state <= update_out;
				else
				   next_state <= break_wait;
				end if;

			when break_wait =>
				if rxs = '1' then
				   next_state <= idle;
				end if;

			when update_out =>
				dout_ena <= '1';
				next_state <= tell_out;

			when tell_out =>
				dout_new   <= '1';
				next_state <= idle;
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

	t1 <= '1' when (tcount = t1_count - 1) else '0';
	t2 <= '1' when (tcount = ((t1_count - 1) / 2)) else '0';

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

	-----------------------------
	-- internal shift register --
	-----------------------------
	process(clk, resetN)
	begin
		if to_x01(resetN) = '0' then
			dint <= (others => '0');
		elsif rising_edge(clk) then
			if to_x01(shift_ena) = '1' then
				dint <= rxs & dint(7 downto 1);
			end if;
		end if;
	end process;

	---------------------
	-- output register --
	---------------------
	process(clk, resetN)
	begin
		if to_x01(resetN) = '0' then
			dout <= (others => '0');
		elsif rising_edge(clk) then
			if to_x01(dout_ena) = '1' then
				dout <= dint;
			end if;
		end if;
	end process;

	-----------------------------
	-- dout_ready SR flip-flop --
	-----------------------------
	process(clk, resetN)
	begin
		if to_x01(resetN) = '0' then
			dout_ready <= '0';
		elsif rising_edge(clk) then
			if to_x01(read_dout) = '1' then
				dout_ready <= '0';
			elsif to_x01(dout_ena) = '1' then
				dout_ready <= '1';
			end if;
		end if;
	end process;

	---------------------
	-- input flip-flop --
	---------------------
	process (clk, resetN)
	begin
		if rising_edge(clk) then
			rxs <= rx ;
		end if ;
	end process ;

end arc_receiver ;