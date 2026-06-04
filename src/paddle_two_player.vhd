library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity paddle_two_player is
   generic (
      PAD_WIDTH    : integer := 80;
      SCREEN_WIDTH : integer := 640;
      PAD_HEIGHT   : integer := 8;
      PADDLE_Y     : integer := 464  -- Default for bottom paddle (480 - 8 - 8)
   );
   port (
      clk         : in  std_logic;  -- Game clock (~60 Hz)
      resetN      : in  std_logic;
      clrN        : in  std_logic;
      left, right : in  std_logic;  -- Active-high controls
      pos_x       : out unsigned(9 downto 0);
      pos_y       : out unsigned(9 downto 0)
   );
end paddle_two_player;

architecture arch of paddle_two_player is
   signal pos_x_int : integer := SCREEN_WIDTH / 2 - PAD_WIDTH / 2;
begin
   process(clk, resetN)
      variable pos_x_next : integer;
   begin
      if resetN = '0' or clrN = '0' then
         pos_x_int <= SCREEN_WIDTH / 2 - PAD_WIDTH / 2;  -- Center paddle
      elsif rising_edge(clk) then
         pos_x_next := pos_x_int;
         if left = '1' and right = '0' then
            pos_x_next := pos_x_int - 4;  -- Move left
         elsif right = '1' and left = '0' then
            pos_x_next := pos_x_int + 4;  -- Move right
         end if;

         -- Keep paddle within screen bounds
         if pos_x_next < 0 then
            pos_x_next := 0;
         elsif pos_x_next > SCREEN_WIDTH - PAD_WIDTH then
            pos_x_next := SCREEN_WIDTH - PAD_WIDTH;
         end if;

         pos_x_int <= pos_x_next;
      end if;
   end process;

   -- Outputs
   pos_x <= to_unsigned(pos_x_int, 10);
   pos_y <= to_unsigned(PADDLE_Y, 10);  -- Fixed y-position
end arch;