library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

library work;

entity brickbreaker is 
	port ( clk_50 		 : in  std_logic;                      -- 50MHz Clock
			 resetN 		 : in  std_logic;                      -- Active-low
			 clrN   	 	 : in  std_logic;                      -- Active-low
			 left2 		 : in  std_logic;                      -- Active-low
			 right2	    : in  std_logic;                      -- Active-low
			 RX2_BT      : in  std_logic;                      -- Bluetooth input
			 TX2_BT 		 : out std_logic;                      -- Bluetooth output
			 TX3_MP3 	 : out std_logic;                      -- MP3 output
			 HORIZ_SYNC  : out std_logic;                      -- VGA sync
			 VERT_SYNC 	 : out std_logic;                      -- VGA sync
			 BLUE 		 : out std_logic_vector(3 downto 0);   -- VGA color blue
			 GREEN 		 : out std_logic_vector(3 downto 0);   -- VGA color green
			 RED 		    : out std_logic_vector(3 downto 0);   -- VGA color red
			 sel 		    : out std_logic_vector(1 downto 0)    -- "01" for 1p, "10" for 2p, "11" for end screen, "00" for menu and default
	);
end brickbreaker;

architecture bdf_type of brickbreaker is 

	component hexcon
		port( clk_25	   : in  std_logic;
			   resetN	   : in  std_logic;
			   rx 		   : in  std_logic;
			   clr_reg 	   : in  std_logic;
			   send_serial : in  std_logic;
			   din 		   : in  std_logic_vector(63 downto 0);
			   tx 		   : out std_logic;
			   new_hex 	   : out std_logic;
			   up_out 	   : out std_logic;
			   down_out 	: out std_logic;
			   left_out 	: out std_logic;
			   right_out   : out std_logic;
			   select_out  : out std_logic;
			   ready  	   : out std_logic;
			   dout 		   : out std_logic_vector(63 downto 0) );
	end component;
	
	component pulse_reg
		generic ( pulse_len : INTEGER;
				    width 	  : INTEGER );
		port( clk 	 : in  std_logic;
			   resetN : in  std_logic;
			   clr 	 : in  std_logic;
			   tin 	 : in  std_logic_vector(width-1 downto 0);
			   qout 	 : out std_logic_vector(width-1 downto 0) );
	end component;
	
	component freq_div
		port ( clkin  : in  std_logic;
             clkout : out std_logic );
    end component;
	
	component vgasync
		port(resetN    : in  std_logic;
			  clk       : in  std_logic;
			  sync_h    : out std_logic;
			  sync_v    : out std_logic;
			  frame_end : out std_logic;
			  frame_odd : out std_logic;
			  video 	   : out std_logic;
			  count_h   : out std_logic_vector(9 downto 0);
			  count_v   : out std_logic_vector(9 downto 0) );
	end component;
	
	component pipe
		generic ( depth : INTEGER );
		port( resetN : in  std_logic;
			   clk    : in  std_logic;
			   din	 : in  std_logic;
			   dout 	 : out std_logic );
	end component;
	
	component screen_menu
		port( clk_50 	  : in  std_logic;
			   clk_25 	  : in  std_logic;
			   resetN 	  : in  std_logic;
			   video  	  : in  std_logic;
			   up 	 	  : in  std_logic;
			   down	 	  : in  std_logic;
			   sel	 	  : in  std_logic;
			   clrN 		  : in  std_logic;
			   enable 	  : in  std_logic;
			   count_h	  : in  std_logic_vector(9 downto 0);
			   count_v	  : in  std_logic_vector(9 downto 0);
			   BLUE 	 	  : out std_logic_vector(3 downto 0);
			   GREEN   	  : out std_logic_vector(3 downto 0);
			   next_stage : out std_logic_vector(1 downto 0);
			   RED    	  : out std_logic_vector(3 downto 0) );
	end component;
	
	component breakout_single
		port( clk_50 	   		  : in  std_logic;
			   clk_25 	    	     : in  std_logic;
			   resetN 	    	     : in  std_logic;
			   clrN                : in  std_logic;
			   video  	     	     : in  std_logic;
			   count_v 	    	     : in  std_logic_vector(9 downto 0);
			   count_h 	    	     : in  std_logic_vector(9 downto 0);
			   left, right   	     : in  std_logic;
			   enable 	    	     : in  std_logic;
			   game_over 		     : out std_logic;
			   level_cleared 	     : out std_logic;
			   vga_r, vga_g, vga_b : out std_logic_vector(3 downto 0) );
	end component;
	
	component breakout_two_player
		port( clk_50 	   		  : in  std_logic;
			   clk_25 	    	     : in  std_logic;
			   resetN 	    	     : in  std_logic;
			   clrN                : in  std_logic;
			   video  	     	     : in  std_logic;
			   count_v 	    	     : in  std_logic_vector(9 downto 0);
			   count_h 	    	     : in  std_logic_vector(9 downto 0);
			   left1, right1       : in  std_logic;
			   left2, right2       : in  std_logic;
			   enable 	    	     : in  std_logic;
			   game_over 		     : out std_logic;
			   level_cleared 	     : out std_logic;
			   vga_r, vga_g, vga_b : out std_logic_vector(3 downto 0) );
	end component;

	component screens
		port( clk_50 	  : in  std_logic;
			   clk_25 	  : in  std_logic;
			   resetN 	  : in  std_logic;
			   video  	  : in  std_logic;
			   mode   	  : in  std_logic;
			   left 		  : in  std_logic;
			   right		  : in  std_logic;
			   sel 		  : in  std_logic;
			   clrN 		  : in  std_logic;
			   enable 	  : in  std_logic;
			   count_h 	  : in  std_logic_vector(9 downto 0);
			   count_v 	  : in  std_logic_vector(9 downto 0);
			   BLUE   	  : out std_logic_vector(3 downto 0);
			   GREEN 	  : out std_logic_vector(3 downto 0);
			   RED 		  : out std_logic_vector(3 downto 0);
			   next_stage : out std_logic_vector(1 downto 0)	);
	end component;
	
	component mp3_player
		port( resetN  : in  std_logic;
			   clk_25  : in  std_logic;
			   send    : in  std_logic;
			   din     : in  std_logic_vector(15 downto 0);
			   TX3_MP3 : out std_logic;
			   ready   : out std_logic );
	end component;

	-- clock signals
	signal clk_25 : std_logic;    -- 25 MHz Clock

	-- hexcon
	signal hexcon_dout : std_logic_vector(63 downto 0);
	signal t 		    : std_logic_vector(4 downto 0);
   signal send_serial : std_logic;
	
	-- pulse_reg
	signal btn : std_logic_vector(4 downto 0);
	
	-- vgasync
	signal count_h : std_logic_vector(9 downto 0);
	signal count_v : std_logic_vector(9 downto 0);
	signal sync_h  : std_logic;
	signal sync_v  : std_logic;
	signal video   : std_logic;
	
	-- screen menu
	signal ena_menu 			      : std_logic := '1';
	signal r_menu, g_menu, b_menu : std_logic_vector(3 downto 0);
	signal sel_menu 			      : std_logic_vector(1 downto 0);
	signal clrN_menu			      : std_logic;
	
	-- breaker_single
	signal ena_p1 			   : std_logic;
	signal level_cleared_p1 : std_logic;
	signal game_over_p1 	   : std_logic;
	signal r_p1, g_p1, b_p1 : std_logic_vector(3 downto 0);
	signal clrN_p1		      : std_logic;
	
	-- breakout_two_player
	signal ena_p2 			   : std_logic;
	signal level_cleared_p2 : std_logic;
	signal game_over_p2 	   : std_logic;
	signal r_p2, g_p2, b_p2 : std_logic_vector(3 downto 0);
	signal clrN_p2		      : std_logic;
	
	-- screens
	signal ena_screen 			  		   : std_logic;
	signal r_screen, g_screen, b_screen : std_logic_vector(3 downto 0);
	signal sel_screen 			  		   : std_logic_vector(1 downto 0);
	signal clrN_screen				      : std_logic;
	
	-- mp3_player
	signal mp3_send : std_logic;
	signal mp3_din  : std_logic_vector(15 downto 0);

	-- state machine
    type state is ( pre, menu, breaker_1p, breaker_2p, screen ) ;
    signal present_state , next_state : state ;
    
    signal last_game_mode, next_last_game_mode : std_logic_vector(1 downto 0) := "00";  -- "01" for 1p, "10" for 2p, "00" default

begin 
	u1: hexcon 
		port map( clk_25 	    => clk_25,
				    resetN 	    => resetN,
				    rx     	    => RX2_BT,
				    clr_reg 	 => not clrN,
				    send_serial => send_serial,
				    din	 	    => hexcon_dout,
				    tx 	       => TX2_BT,
				    up_out      => t(0),
				    down_out    => t(1),
				    left_out    => t(2),
				    right_out   => t(3),
				    select_out  => t(4),
				    dout        => hexcon_dout );
						 
	u2: pulse_reg
		generic map( pulse_len => 1250000, width => 5 )
		port map( clk	  => clk_50,
				    resetN => resetN,
				    clr 	  => not clrN,
				    tin 	  => t,
				    qout   => btn );
				  
	u3: freq_div 
		port map ( clkin  => clk_50, 
				     clkout => clk_25 ); 
				   
	u4: vgasync
		port map( resetN  => resetN,
				    clk 	   => clk_25,
				    sync_h  => sync_h,
				    sync_v  => sync_v,
				    video   => video,
				    count_h => count_h,
				    count_v => count_v );
				  
	u5: pipe
		generic map( depth => 3 )
		port map( resetN => resetN,
				    clk    => clk_25,
				    din    => sync_h,
				    dout   => HORIZ_SYNC );

	u6: pipe
		generic map( depth => 3 )
		port map( resetN => resetN,
				    clk    => clk_25,
				    din    => sync_v,
				    dout   => VERT_SYNC );
				  
	u7: screen_menu
		port map( clk_50 	   => clk_50,
				    clk_25 	   => clk_25,
				    resetN 	   => resetN,
				    video  	   => video,
				    up 	 	   => btn(0),
				    down   	   => btn(1),
				    sel 	 	   => btn(4),
				    clrN 		=> clrN and clrN_menu,
				    enable 	   => ena_menu,
				    count_h	   => count_h,
				    count_v	   => count_v,
				    BLUE 	 	=> b_menu,
				    GREEN  	   => g_menu,
				    next_stage => sel_menu,
				    RED 	  	   => r_menu );

	u8: breakout_single
	port map( clk_50  	   => clk_50,
			    clk_25  	   => clk_25,
			    resetN  	   => resetN,
			    clrN			   => clrN and clrN_p1,
			    video   	   => video,
			    left	         => btn(2),
			    right 	      => btn(3),
			    enable  	   => ena_p1,
			    count_h	      => count_h,
			    count_v 	   => count_v,
			    game_over 	   => game_over_p1,
			    level_cleared => level_cleared_p1,
			    vga_b 		   => b_p1,
			    vga_g 		   => g_p1,
			    vga_r 		   => r_p1 );
			  
	u9: breakout_two_player
	port map( clk_50  	   => clk_50,
			    clk_25  	   => clk_25,
			    resetN  	   => resetN,
			    clrN			   => clrN and clrN_p2,
			    video   	   => video,
			    left1	      => btn(2),
			    right1 	      => btn(3),
			    left2	      => left2,
			    right2 	      => right2,
			    enable  	   => ena_p2,
			    count_h	      => count_h,
			    count_v 	   => count_v,
			    game_over  	=> game_over_p2,
			    level_cleared => level_cleared_p2,
			    vga_b 		   => b_p2,
			    vga_g 		   => g_p2,
			    vga_r 		   => r_p2 );

	u10: screens 
	port map( clk_50	   => clk_50,
			    clk_25	   => clk_25,
			    resetN	   => resetN,
			    video 	   => video,
			    mode  	   => not (game_over_p1 or game_over_p2),
			    left   	   => btn(2),
			    right  	   => btn(3),
			    sel   	   => btn(4),
			    clrN 		=> clrN and clrN_screen,
			    enable	   => ena_screen,
			    count_h 	=> count_h,
			    count_v 	=> count_v,
			    BLUE 		=> b_screen,
			    GREEN 	   => g_screen,
			    next_stage => sel_screen,
			    RED 		   => r_screen );
			  
	u11: mp3_player
	port map( resetN	 => resetN,
			    clk_25	 => clk_25,
			    send 	 => mp3_send,
			    din  	 => mp3_din,
			    TX3_MP3	 => TX3_MP3 );
	
	-------------------
	-- state machine --
	-------------------
	-- sync process
	process( clk_50, resetN )
	begin
		if to_x01(resetN) = '0' then
			present_state  <= pre;
         last_game_mode <= "00";
		elsif rising_edge(clk_50) then
			present_state  <= next_state;
         last_game_mode <= next_last_game_mode;
		end if;
	end process;

	-- comb process
	process( present_state )
	begin
		next_state          <= present_state;
      next_last_game_mode <= last_game_mode;
		ena_menu    <= '0';
		ena_p1      <= '0';
		ena_p2      <= '0';
		ena_screen  <= '0';
		clrN_menu   <= '1';
		clrN_screen <= '1';
		clrN_p1		<= '1';
		clrN_p2		<= '1';
		sel 	      <= "00";
		RED		   <= "0000";
		GREEN	      <= "0000";
		BLUE	      <= "0000";
		mp3_send	   <= '0'; 
		  
		case present_state is
         when pre =>
            next_state <= menu;
            mp3_din	<= "0000000000000001";
				mp3_send <= '1';
      
			when menu =>
				RED      <= r_menu;
				GREEN    <= g_menu;
				BLUE     <= b_menu;
				ena_menu <= '1';
            sel      <= "00";
				if sel_menu = "01" then
				   next_state <= breaker_1p;
				   ena_p1 	  <= '1';

				   mp3_din	  <= "0000000000000010";
				   mp3_send	  <= '1';
				elsif sel_menu = "10" then
				   next_state <= breaker_2p;
				   ena_p2 	  <= '1';

				   mp3_din	  <= "0000000000000010";
				   mp3_send	  <= '1';
				end if;

			when breaker_1p =>
				RED    <= r_p1;
				GREEN  <= g_p1;
				BLUE   <= b_p1;
				ena_p1 <= '1';
				sel    <= "01";
				if game_over_p1 = '1' or level_cleared_p1 = '1' then
				   next_state  <= screen;
               next_last_game_mode  <= "01";
				   ena_screen  <= '1';
				   clrN_screen <= '0';
				end if;

			when breaker_2p =>
				RED    <= r_p2;
				GREEN  <= g_p2;
				BLUE   <= b_p2;
				ena_p2 <= '1';
				sel    <= "10";
				if game_over_p2 = '1' or level_cleared_p2 = '1' then
				   next_state  <= screen;
               next_last_game_mode  <= "10";
				   ena_screen  <= '1';
				   clrN_screen <= '0';
				end if;

			when screen =>
				RED        <= r_screen;
				GREEN      <= g_screen;
				BLUE       <= b_screen;
				ena_screen <= '1';
				sel        <= "11";
				if sel_screen = "01" then
					if last_game_mode = "01" then
						next_state <= breaker_1p;
                  ena_p1 	  <= '1';
						clrN_p1	  <= '0';
					elsif last_game_mode = "10" then
						next_state <= breaker_2p;
                  ena_p2 	  <= '1';
						clrN_p2	  <= '0';
					end if;
				elsif sel_screen = "00" then
				   next_state <= menu;
				   ena_menu   <= '1';
				   clrN_menu  <= '0';
               clrN_p1	  <= '0';
               clrN_p2	  <= '0';
				   mp3_din	  <= "0000000000000001";
				   mp3_send	  <= '1';
				end if;
		end case;
	end process;
end bdf_type;
