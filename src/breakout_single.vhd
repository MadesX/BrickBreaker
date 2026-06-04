library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity breakout_single is
   port ( clk_50              : in  std_logic;     -- 50 MHz clock
		    clk_25   			   : in  std_logic;     -- 25 MHz for VGA
          resetN              : in  std_logic; 
          clrN                : in  std_logic; 
		    video         	   : in  std_logic;
		    count_v             : in  unsigned(9 downto 0);
		    count_h             : in  unsigned(9 downto 0);
          left, right         : in  std_logic;     -- Active-high
		    enable			      : in  std_logic;
          game_over           : out std_logic := '0';
          level_cleared       : out std_logic := '0';
          vga_r, vga_g, vga_b : out std_logic_vector(3 downto 0)   );
end breakout_single;

architecture arch of breakout_single is
   -- Game Clock signal
   signal clk_game : std_logic;    -- ~60 Hz for game logic

   -- Game objects
   signal paddle_x, paddle_y : unsigned(9 downto 0);
   signal ball_x, ball_y     : unsigned(9 downto 0);
   signal stop               : std_logic := '1';
   signal brick_matrix       : std_logic_vector(0 to 63);  -- 8x8 grid
   signal brick_hit          : std_logic;
   signal brick_count        : std_logic_vector(5 downto 0);
   signal score              : std_logic_vector(5 downto 0);
   signal lives              : unsigned(2 downto 0);

   -- Constants
   constant PAD_WIDTH     : integer := 80;
   constant PAD_HEIGHT    : integer := 8;
   constant BALL_SIZE     : integer := 8;
   constant BRICK_WIDTH   : integer := 60;
   constant BRICK_HEIGHT  : integer := 20;
   constant SCREEN_WIDTH  : integer := 640;
   constant SCREEN_HEIGHT : integer := 480;

   component freq_div_game
      port ( clk    : in std_logic;
             clkout : out std_logic  );
   end component;

   component paddle
      generic ( PAD_WIDTH    : integer := PAD_WIDTH;
                SCREEN_WIDTH : integer := SCREEN_WIDTH  );
      port ( clk         : in std_logic;
             resetN      : in std_logic;
             clrN        : in std_logic;
             left, right : in std_logic;
             pos_x       : out unsigned(9 downto 0);
             pos_y       : out unsigned(9 downto 0)  );
   end component;

   component bricks
      generic ( BRICK_WIDTH  : integer := BRICK_WIDTH;
                BRICK_HEIGHT : integer := BRICK_HEIGHT;
                BALL_SIZE    : integer := BALL_SIZE );
      port ( clk             : in std_logic;
             resetN          : in std_logic;
             clrN            : in std_logic;
             ball_x, ball_y  : in unsigned(9 downto 0);
             brick_hit       : out std_logic;
             brick_matrix    : out std_logic_vector(0 to 63);
             brick_count_out : out std_logic_vector(5 downto 0)  );
   end component;

   component ball
      generic ( SCREEN_W  : integer := SCREEN_WIDTH;
                SCREEN_H  : integer := SCREEN_HEIGHT;
                PADDLE_W  : integer := PAD_WIDTH;
                BALL_SIZE : integer := BALL_SIZE );
      port ( clk           : in  std_logic;
             resetN        : in  std_logic;
			    clrN          : in  std_logic;
             stop          : in  std_logic;
             paddle_x      : in  unsigned(9 downto 0);
             paddle_y      : in  unsigned(9 downto 0);
             brick_hit     : in  std_logic;
             pos_x, pos_y  : out unsigned(9 downto 0);
             score         : out std_logic_vector(5 downto 0);
             lives         : out unsigned(2 downto 0) );
   end component;

begin
   u1: freq_div_game port map (
      clk    => clk_50, 
      clkout => clk_game
   );
   u2: paddle port map (
      clk    => clk_game,
      resetN => resetN,
	   clrN   => clrN,
      left   => left,
      right  => right,
      pos_x  => paddle_x,
      pos_y  => paddle_y
   );
   u3: bricks port map (
      clk             => clk_game,
      resetN          => resetN,
	   clrN            => clrN,
      ball_x          => ball_x,
      ball_y          => ball_y,
      brick_hit       => brick_hit,
      brick_matrix    => brick_matrix,
      brick_count_out => brick_count
   );
   u4: ball port map (
      clk           => clk_game,
      resetN        => resetN,
	   clrN          => clrN,
      stop          => stop,
      paddle_x      => paddle_x,
      paddle_y      => paddle_y,
      brick_hit     => brick_hit,
      pos_x         => ball_x,
      pos_y         => ball_y,
      score         => score,
      lives         => lives
   );

   pixel_gen: process (count_h, count_v, video, paddle_x, paddle_y, ball_x, ball_y, brick_matrix, score, lives, enable)
   begin
		vga_r <= "0000";
		vga_g <= "0000";
		vga_b <= "0000";
		if video = '1' and enable = '1' then
			if count_v >= paddle_y and count_v < paddle_y + PAD_HEIGHT and count_h >= paddle_x and count_h < paddle_x + PAD_WIDTH then
				vga_r <= "1111";  -- White paddle
				vga_g <= "1111";
				vga_b <= "1111";
			elsif count_h >= ball_x and count_h < ball_x + BALL_SIZE and count_v >= ball_y and count_v < ball_y + BALL_SIZE then
				vga_r <= "1111";  -- Yellow ball
				vga_g <= "1111";
				vga_b <= "0000";
			else
				for i in 0 to 31 loop
				   if brick_matrix(i) = '1' and
					  count_h >= (i mod 8) * (BRICK_WIDTH + 10) + 60 and count_h < (i mod 8) * (BRICK_WIDTH + 10) + 120 and
					  count_v >= (i/8) * (BRICK_HEIGHT + 10) + 40 and count_v < (i/8) * (BRICK_HEIGHT + 10) + 60 then
						 case i/8 is
							when 0 => vga_r <= "1111"; 					   -- Red
							when 1 => vga_r <= "1100"; vga_g <= "0100";  -- Orange
							when 2 => vga_g <= "1111";  				      -- Green
							when 3 => vga_b <= "1111"; 					   -- Blue
							when others => null;
						 end case;
				   end if;
				end loop;
			end if;
			if count_h < 48 and count_v < 25 then
				vga_r <= "1000";  -- Red placeholder for lives
				
				if count_v >= 10 and count_v < 18 then
					-- First heart (lives >= 1)
					if lives >= 1 and count_h >= 10 and count_h < 18 then
						if (count_v = 10 and (count_h = 11 or count_h = 12 or count_h = 14 or count_h = 15)) or
						   (count_v = 11 and (count_h = 10 or count_h = 11 or count_h = 12 or count_h = 14 or count_h = 15 or count_h = 16)) or
						   (count_v = 12 and (count_h = 10 or count_h = 11 or count_h = 12 or count_h = 14 or count_h = 15 or count_h = 16)) or
						   (count_v = 13 and (count_h = 10 or count_h = 11 or count_h = 12 or count_h = 13 or count_h = 14 or count_h = 15 or count_h = 16)) or
						   (count_v = 14 and (count_h = 11 or count_h = 12 or count_h = 13 or count_h = 14 or count_h = 15)) or
						   (count_v = 15 and (count_h = 12 or count_h = 13 or count_h = 14)) or
						   (count_v = 16 and (count_h = 13)) then
							vga_r <= "1111";  -- White heart
							vga_g <= "1111";
							vga_b <= "1111";
						end if;
					-- Second heart (lives >= 2)
					elsif lives >= 2 and count_h >= 20 and count_h < 28 then
						if (count_v = 10 and (count_h = 21 or count_h = 22 or count_h = 24 or count_h = 25)) or
						   (count_v = 11 and (count_h = 20 or count_h = 21 or count_h = 22 or count_h = 24 or count_h = 25 or count_h = 26)) or
						   (count_v = 12 and (count_h = 20 or count_h = 21 or count_h = 22 or count_h = 24 or count_h = 25 or count_h = 26)) or
						   (count_v = 13 and (count_h = 20 or count_h = 21 or count_h = 22 or count_h = 23 or count_h = 24 or count_h = 25 or count_h = 26)) or
						   (count_v = 14 and (count_h = 21 or count_h = 22 or count_h = 23 or count_h = 24 or count_h = 25)) or
						   (count_v = 15 and (count_h = 22 or count_h = 23 or count_h = 24)) or
						   (count_v = 16 and (count_h = 23)) then
							vga_r <= "1111";  -- White heart
							vga_g <= "1111";
							vga_b <= "1111";
						end if;
					-- Third heart (lives >= 3)
					elsif lives >= 3 and count_h >= 30 and count_h < 38 then
						if (count_v = 10 and (count_h = 31 or count_h = 32 or count_h = 34 or count_h = 35)) or
						   (count_v = 11 and (count_h = 30 or count_h = 31 or count_h = 32 or count_h = 34 or count_h = 35 or count_h = 36)) or
						   (count_v = 12 and (count_h = 30 or count_h = 31 or count_h = 32 or count_h = 34 or count_h = 35 or count_h = 36)) or
						   (count_v = 13 and (count_h = 30 or count_h = 31 or count_h = 32 or count_h = 33 or count_h = 34 or count_h = 35 or count_h = 36)) or
						   (count_v = 14 and (count_h = 31 or count_h = 32 or count_h = 33 or count_h = 34 or count_h = 35)) or
						   (count_v = 15 and (count_h = 32 or count_h = 33 or count_h = 34)) or
						   (count_v = 16 and (count_h = 33)) then
							vga_r <= "1111";  -- White heart
							vga_g <= "1111";
							vga_b <= "1111";
						end if;
					end if;
				end if;
				
			end if;
		end if;
	end process;
   
	game_over     <= '1'  when  lives = 0 else '0';
	level_cleared <= '1'  when  score = brick_count else '0';
	stop          <= '1'  when (lives = 0 or score = brick_count or enable = '0') else '0';
end arch;