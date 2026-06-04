library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;

entity ball_two_player is
   generic ( SCREEN_W   : integer := 640;
             SCREEN_H   : integer := 480;
             PADDLE_W   : integer := 80;
             BALL_SIZE  : integer := 8;
             PAD_HEIGHT : integer := 8;
             BRICK_START_Y : integer := 180;
             BRICK_HEIGHT  : integer := 20 );
   port ( clk          : in  std_logic;  -- Game clock (~60 Hz)
          resetN       : in  std_logic;
          clrN         : in  std_logic;
          stop         : in  std_logic;
          paddle1_x    : in  unsigned(9 downto 0);  -- Bottom paddle (Player 1)
          paddle1_y    : in  unsigned(9 downto 0);
          paddle2_x    : in  unsigned(9 downto 0);  -- Top paddle (Player 2)
          paddle2_y    : in  unsigned(9 downto 0);
          brick_hit    : in  std_logic;
          pos_x, pos_y : out unsigned(9 downto 0);
          score        : out std_logic_vector(5 downto 0);
          lives        : out unsigned(2 downto 0);
          debug_hit_p1 : out std_logic;  -- Debug: Bottom paddle hit
          debug_hit_p2 : out std_logic   -- Debug: Top paddle hit
   );
end ball_two_player;

architecture arc_ball_two_player of ball_two_player is
   signal pos_x_int, pos_y_int : integer := SCREEN_W / 2;
   signal vx                   : integer := 1;  -- px/frame
   signal vy                   : integer := 2;  -- px/frame
   signal score_reg            : std_logic_vector(5 downto 0) := "000000";
   signal lives_reg            : integer := 3;
   signal hit_p1, hit_p2       : std_logic := '0';

begin
   process(clk, resetN)
      variable pos_x_next, pos_y_next : integer;
      variable vx_next, vy_next       : integer;
      variable hit_off                : integer;
      constant INITIAL_Y : integer := BRICK_START_Y + 4 * (BRICK_HEIGHT + 10) + 10;  -- y = 290
   begin
      if resetN = '0' or clrN = '0' then
         pos_x_int  <= SCREEN_W / 2;
         pos_y_int  <= INITIAL_Y;
         vx         <= 1;
         vy         <= 2;
         score_reg  <= "000000";
         lives_reg  <= 3;
         hit_p1     <= '0';
         hit_p2     <= '0';
      elsif rising_edge(clk) and stop = '0' then
         -- Default movement
         pos_x_next := pos_x_int + vx;
         pos_y_next := pos_y_int + vy;
         vx_next    := vx;
         vy_next    := vy;
         hit_p1     <= '0';
         hit_p2     <= '0';

         -- Left / Right Wall collision
         if pos_x_next < 0 then
            pos_x_next := 0;
            vx_next    := -vx;
         elsif pos_x_next > SCREEN_W - BALL_SIZE then
            pos_x_next := SCREEN_W - BALL_SIZE;
            vx_next    := -vx;
         end if;

         -- Ceiling collision: lose life / reset
         if pos_y_next < 0 then
            if lives_reg > 0 then
               lives_reg <= lives_reg - 1;
            end if;
            pos_x_next := SCREEN_W / 2;
            pos_y_next := INITIAL_Y;
            vx_next    := 1;
            vy_next    := 2;
         end if;

         -- Floor collision: lose life / reset
         if pos_y_next > SCREEN_H - BALL_SIZE then
            if lives_reg > 0 then
               lives_reg <= lives_reg - 1;
            end if;
            pos_x_next := SCREEN_W / 2;
            pos_y_next := INITIAL_Y;
            vx_next    := 1;
            vy_next    := 2;
         end if;

         -- Bottom paddle collision (Player 1): when ball is moving down (vy > 0)
         if (vy > 0) and (pos_y_next + BALL_SIZE >= to_integer(paddle1_y)) and 
            (pos_y_next <= to_integer(paddle1_y) + PAD_HEIGHT) and
            (pos_x_next + BALL_SIZE >= to_integer(paddle1_x)) and 
            (pos_x_next <= to_integer(paddle1_x) + PADDLE_W) then
            
            vy_next := -vy;
            hit_off := (vx / 1) * abs((pos_x_next + BALL_SIZE/2) - (to_integer(paddle1_x) + PADDLE_W/2));
            vx_next := hit_off / 10;
            
            if vx_next < -4 then
               vx_next := -4;
            elsif vx_next > 4 then
               vx_next := 4;
            elsif vx_next = 0 then
               if hit_off >= 0 then
                  vx_next := 1;
               else
                  vx_next := -1;
               end if;
            end if;

            pos_y_next := to_integer(paddle1_y) - BALL_SIZE - 1;
            hit_p1 <= '1';
         end if;

         -- Top paddle collision (Player 2): when ball is moving up (vy < 0)
         if (vy < 0) and (pos_y_next <= to_integer(paddle2_y) + PAD_HEIGHT) and 
            (pos_y_next + BALL_SIZE >= to_integer(paddle2_y)) and
            (pos_x_next + BALL_SIZE >= to_integer(paddle2_x)) and 
            (pos_x_next <= to_integer(paddle2_x) + PADDLE_W) then
            
            vy_next := -vy;
            hit_off := (vx / 1) * abs((pos_x_next + BALL_SIZE/2) - (to_integer(paddle2_x) + PADDLE_W/2));
            vx_next := hit_off / 10;
            
            if vx_next < -4 then
               vx_next := -4;
            elsif vx_next > 4 then
               vx_next := 4;
            elsif vx_next = 0 then
               if hit_off >= 0 then
                  vx_next := 1;
               else
                  vx_next := -1;
               end if;
            end if;

            pos_y_next := to_integer(paddle2_y) + PAD_HEIGHT + 1;
            hit_p2 <= '1';
         end if;

         -- Brick hit
         if brick_hit = '1' then
            vy_next := -vy;
            score_reg <= score_reg + 1;
         end if;

         -- Commit next state
         pos_x_int <= pos_x_next;
         pos_y_int <= pos_y_next;
         vx        <= vx_next;
         vy        <= vy_next;
      end if;
   end process;

   -- Outputs
   pos_x <= to_unsigned(pos_x_int, 10);
   pos_y <= to_unsigned(pos_y_int, 10);
   score <= score_reg;
   lives <= to_unsigned(lives_reg, 3);
   debug_hit_p1 <= hit_p1;
   debug_hit_p2 <= hit_p2;
   
end arc_ball_two_player;