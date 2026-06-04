library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity tb_breakout_single is
  -- test bench for breakout_single
end tb_breakout_single;

architecture arc_tb_breakout_single of tb_breakout_single is
   component breakout_single
      port (
         clk_50        : in  std_logic;
         clk_25        : in  std_logic;
         resetn        : in  std_logic;
         clrn          : in  std_logic;
         video         : in  std_logic;
         count_v       : in  unsigned(9 downto 0);
         count_h       : in  unsigned(9 downto 0);
         left          : in  std_logic;
         right         : in  std_logic;
         enable        : in  std_logic;
         game_over     : out std_logic;
         level_cleared : out std_logic;
         vga_r         : out std_logic_vector(3 downto 0);
         vga_g         : out std_logic_vector(3 downto 0);
         vga_b         : out std_logic_vector(3 downto 0)
      );
   end component;

   -- signals
   signal clk_50        : std_logic := '0'; -- 50 mhz clock
   signal clk_25        : std_logic := '0'; -- 25 mhz clock
   signal resetn        : std_logic := '1'; -- active-low reset
   signal clrn          : std_logic := '1'; -- active-low clear
   signal video         : std_logic := '0'; -- video enable
   signal count_v       : unsigned(9 downto 0) := (others => '0'); -- vertical count
   signal count_h       : unsigned(9 downto 0) := (others => '0'); -- horizontal count
   signal left          : std_logic := '0'; -- left button
   signal right         : std_logic := '0'; -- right button
   signal enable        : std_logic := '0'; -- enable game
   signal game_over     : std_logic; -- game over signal
   signal level_cleared : std_logic; -- level cleared signal
   signal vga_r         : std_logic_vector(3 downto 0); -- red output
   signal vga_g         : std_logic_vector(3 downto 0); -- green output
   signal vga_b         : std_logic_vector(3 downto 0); -- blue output

   -- timing constants
   constant clk_50_period : time := 20 ns; -- 50 mhz clock
   constant clk_25_period : time := 40 ns; -- 25 mhz clock
   constant pixel_time : time := 40 ns; -- one pixel at 25 mhz
   constant h_visible : integer := 640; -- visible horizontal pixels
   constant v_visible : integer := 480; -- visible vertical pixels
   constant game_period : time := 16666667 ns; -- ~60 hz game clock (1/60 s)

begin
   -- breakout_single instantiation (named association)
   eut: breakout_single
      port map (
         clk_50        => clk_50,
         clk_25        => clk_25,
         resetn        => resetn,
         clrn          => clrn,
         video         => video,
         count_v       => count_v,
         count_h       => count_h,
         left          => left,
         right         => right,
         enable        => enable,
         game_over     => game_over,
         level_cleared => level_cleared,
         vga_r         => vga_r,
         vga_g         => vga_g,
         vga_b         => vga_b
      );

   -- 50 mhz clock process
   process
   begin
      clk_50 <= '0'; wait for clk_50_period/2;
      clk_50 <= '1'; wait for clk_50_period/2;
   end process;

   -- 25 mhz clock process
   process
   begin
      clk_25 <= '0'; wait for clk_25_period/2;
      clk_25 <= '1'; wait for clk_25_period/2;
   end process;

   -- active low reset pulse
   resetn <= '0', '1' after 40 ns;

   -- test vectors process
   process
      procedure sim_vga_line is
      begin
         -- simulate one horizontal line (640 visible pixels)
         video <= '1';
         for h in 0 to h_visible-1 loop
            count_h <= to_unsigned(h, 10);
            wait for pixel_time;
         end loop;
         video <= '0';
         count_h <= (others => '0');
         wait for pixel_time * 160; -- non-visible portion (approx)
      end procedure;

      procedure sim_vga_frame is
      begin
         -- simulate one frame (480 visible lines)
         for v in 0 to v_visible-1 loop
            count_v <= to_unsigned(v, 10);
            sim_vga_line;
         end loop;
         count_v <= (others => '0');
         wait for pixel_time * 160 * 45; -- non-visible vertical portion (approx)
      end procedure;
   begin
      -- initialize inputs
      enable <= '0'; left <= '0'; right <= '0'; clrn <= '1';
      count_h <= (others => '0'); count_v <= (others => '0');
      wait for 40 ns; -- wait for end of async reset

      ----------------------------------------- vector 1: enable game, check initial display
      report "enabling game and checking initial display";
      enable <= '1';
      sim_vga_frame;
      assert game_over = '0' report "game over set initially #1" severity error;
      assert level_cleared = '0' report "level cleared set initially #1" severity error;
      assert vga_r /= "0000" or vga_g /= "0000" or vga_b /= "0000" report "no vga output #1" severity error;
      wait for game_period; -- wait one game cycle (~60 hz)

      ----------------------------------------- vector 2: move paddle right
      report "moving paddle right";
      right <= '1';
      wait for game_period * 5; -- simulate paddle movement for 5 game cycles
      right <= '0';
      sim_vga_frame;
      assert vga_r /= "0000" or vga_g /= "0000" or vga_b /= "0000" report "no vga output after paddle move #2" severity error;
      wait for game_period;

      ----------------------------------------- vector 3: move paddle left and hit ball
      report "moving paddle left and simulating ball hit";
      left <= '1';
      wait for game_period * 5;
      left <= '0';
      sim_vga_frame;
      assert vga_r /= "0000" or vga_g /= "0000" or vga_b /= "0000" report "no vga output after paddle move #3" severity error;
      wait for game_period * 10; -- allow ball to move and potentially hit bricks
      wait for game_period;

      ----------------------------------------- vector 4: test clear
      report "testing clear functionality";
      clrn <= '0';
      wait for game_period;
      clrn <= '1';
      sim_vga_frame;
      assert game_over = '0' report "game over set after clear #4" severity error;
      assert level_cleared = '0' report "level cleared set after clear #4" severity error;
      wait for game_period;

      ----------------------------------------- end of test
      report "end of test vectors";
      wait;
   end process;

end arc_tb_breakout_single;