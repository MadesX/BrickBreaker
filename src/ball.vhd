library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all ;
use ieee.numeric_std.all;

entity ball is
   generic ( SCREEN_W  : integer := 640;
             SCREEN_H  : integer := 480;
             PADDLE_W  : integer := 80;
             BALL_SIZE : integer := 8 );
   port ( clk          : in  std_logic;  -- Game clock (~60 Hz)
          resetN       : in  std_logic;
          clrN         : in  std_logic;
          stop         : in  std_logic;
          paddle_x     : in  unsigned(9 downto 0);
          paddle_y     : in  unsigned(9 downto 0);
          brick_hit    : in  std_logic;
          pos_x, pos_y : out unsigned(9 downto 0);
          score        : out std_logic_vector(5 downto 0);
          lives        : out unsigned(2 downto 0)  ) ;
end ball;

architecture arc_ball of ball is
	signal pos_x_int, pos_y_int : integer := SCREEN_W / 2;
	signal vx       	  : integer := 1;  -- px/frame
	signal vy       	  : integer := 2;  -- px/frame
	signal score_reg    : std_logic_vector(5 downto 0) := "000000";
	signal lives_reg    : integer :=  3;

	begin
      process(clk, resetN)
         variable pos_x_next, pos_y_next   : integer;
         variable vx_next, vy_next : integer;
         variable hit_off  : integer;
      begin
         if resetN = '0' or clrN = '0' then
            pos_x_int  <= SCREEN_W / 2;
            pos_y_int  <= SCREEN_H / 2;
            vx         <= 1;
            vy         <= 2;
            score_reg  <= "000000";
            lives_reg  <= 3;
         elsif rising_edge(clk) and stop = '0' then
            -- default
            pos_x_next := pos_x_int + vx;
            pos_y_next := pos_y_int + vy;
            vx_next    := vx;
            vy_next    := vy;

            -- Left / Right Wall collision
            if pos_x_next < 0 then
               pos_x_next := 0;
               vx_next    := -vx_next;
            elsif pos_x_next > SCREEN_W - BALL_SIZE then
               pos_x_next := SCREEN_W - BALL_SIZE;
               vx_next    := -vx_next;
            end if;

            -- Ceiling collision
            if (pos_y_next < 0) and (vy < 0) then
               pos_y_next := 0;
               vy_next    := -vy;
            end if;

            -- Floor collision: lose life / reset
            if pos_y_next > SCREEN_H - BALL_SIZE then
               -- lose a life and reset ball
               if lives_reg > 0 then
                  lives_reg <= lives_reg - 1;
               end if;
               
               -- reset ball to centre with initial velocity
               pos_x_next := SCREEN_W / 2;
               pos_y_next := SCREEN_H / 2;
               vx_next    := 1;
               vy_next    := 2;
            end if;

            -- PADDLE collision: only when ball is moving down (vy > 0)
            -- check overlap using the *next* position (pos_x_next, pos_y_next) to avoid tunneling in simple cases
            if (vy > 0) and (pos_y_next + BALL_SIZE >= to_integer(paddle_y)) and (pos_y_int + BALL_SIZE <= to_integer(paddle_y) + 4) and
               (pos_x_next + BALL_SIZE >= to_integer(paddle_x)) and (pos_x_next <= to_integer(paddle_x) + PADDLE_W) then
               
               vy_next := -vy_next;

               -- horizontal deflection proportional to hit offset from paddle center
               hit_off := (vx / 1) * abs((pos_x_next + BALL_SIZE/2) - (to_integer(paddle_x) + PADDLE_W/2));
               vx_next := hit_off / 10;  -- tune this divisor to control angle
               
               if (vx_next < -4) then
                  vx_next := -4;
               elsif (vx_next > 4) then
                  vx_next := 4;
               elsif vx_next = 0 then                 -- avoid zero horizontal velocity
                  if hit_off >= 0 then
                     vx_next := 1;
                  else
                     vx_next := -1;
                  end if;
               end if;

               pos_y_next := to_integer(paddle_y) - BALL_SIZE - 1;   -- place ball on top of paddle to avoid sinking
            end if;

            -- Brick hit
            if brick_hit = '1' then
               vy_next := -vy_next;
               score_reg <= score_reg + 1;
            end if;

            -- commit next state to signals
            pos_x_int <= pos_x_next;
            pos_y_int <= pos_y_next;
            vx        <= vx_next;
            vy        <= vy_next;
         end if;
      end process;

	-- outputs
	pos_x <= to_unsigned(pos_x_int, 10);
	pos_y <= to_unsigned(pos_y_int, 10);
	score <= score_reg;
	lives <= to_unsigned(lives_reg, 3);
   
end arc_ball;
