library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity tb_screen_menu is
  -- test bench for screen_menu
end tb_screen_menu;

architecture arc_tb_screen_menu of tb_screen_menu is
   component screen_menu
      port (
         video      : in  std_logic;
         resetn     : in  std_logic;
         clk_25     : in  std_logic;
         clk_50     : in  std_logic;
         enable     : in  std_logic;
         up         : in  std_logic;
         down       : in  std_logic;
         sel        : in  std_logic;
         clrn       : in  std_logic;
         count_h    : in  std_logic_vector(9 downto 0);
         count_v    : in  std_logic_vector(9 downto 0);
         blue       : out std_logic_vector(3 downto 0);
         green      : out std_logic_vector(3 downto 0);
         next_stage : out std_logic_vector(1 downto 0);
         red        : out std_logic_vector(3 downto 0)
      );
   end component;

   -- signals
   signal video      : std_logic := '0'; -- video enable
   signal resetn     : std_logic := '1'; -- active-low reset
   signal clk_25     : std_logic := '0'; -- 25 mhz clock
   signal clk_50     : std_logic := '0'; -- 50 mhz clock
   signal enable     : std_logic := '0'; -- enable menu
   signal up         : std_logic := '0'; -- up button
   signal down       : std_logic := '0'; -- down button
   signal sel        : std_logic := '0'; -- select button
   signal clrn       : std_logic := '1'; -- active-low clear
   signal count_h    : std_logic_vector(9 downto 0) := (others => '0'); -- horizontal count
   signal count_v    : std_logic_vector(9 downto 0) := (others => '0'); -- vertical count
   signal blue       : std_logic_vector(3 downto 0); -- blue output
   signal green      : std_logic_vector(3 downto 0); -- green output
   signal next_stage : std_logic_vector(1 downto 0); -- stage output
   signal red        : std_logic_vector(3 downto 0); -- red output

   -- timing constants
   constant clk_25_period : time := 40 ns; -- 25 mhz clock
   constant clk_50_period : time := 20 ns; -- 50 mhz clock
   constant pixel_time : time := 40 ns; -- one pixel at 25 mhz
   constant h_visible : integer := 640; -- visible horizontal pixels
   constant v_visible : integer := 480; -- visible vertical pixels

begin
   -- screen_menu instantiation (named association)
   eut: screen_menu
      port map (
         video      => video,
         resetn     => resetn,
         clk_25     => clk_25,
         clk_50     => clk_50,
         enable     => enable,
         up         => up,
         down       => down,
         sel        => sel,
         clrn       => clrn,
         count_h    => count_h,
         count_v    => count_v,
         blue       => blue,
         green      => green,
         next_stage => next_stage,
         red        => red
      );

   -- 25 mhz clock process
   process
   begin
      clk_25 <= '0'; wait for clk_25_period/2;
      clk_25 <= '1'; wait for clk_25_period/2;
   end process;

   -- 50 mhz clock process
   process
   begin
      clk_50 <= '0'; wait for clk_50_period/2;
      clk_50 <= '1'; wait for clk_50_period/2;
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
            count_h <= std_logic_vector(to_unsigned(h, 10));
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
            count_v <= std_logic_vector(to_unsigned(v, 10));
            sim_vga_line;
         end loop;
         count_v <= (others => '0');
         wait for pixel_time * 160 * 45; -- non-visible vertical portion (approx)
      end procedure;
   begin
      -- initialize inputs
      enable <= '0'; up <= '0'; down <= '0'; sel <= '0'; clrn <= '1';
      count_h <= (others => '0'); count_v <= (others => '0');
      wait for 40 ns; -- wait for end of async reset

      ----------------------------------------- vector 1: enable menu, check initial stage
      report "enabling menu and checking initial stage";
      enable <= '1';
      sim_vga_frame;
      assert next_stage = "00" report "initial stage not 00 #1" severity error;
      assert red /= "0000" or green /= "0000" or blue /= "0000" report "no vga output #1" severity error;
      wait for clk_25_period * 10;

      ----------------------------------------- vector 2: press up button
      report "pressing up button";
      up <= '1';
      wait for clk_50_period * 10;
      up <= '0';
      sim_vga_frame;
      assert next_stage /= "00" report "stage did not change after up #2" severity error;
      wait for clk_25_period * 10;

      ----------------------------------------- vector 3: press down and select
      report "pressing down and select buttons";
      down <= '1';
      wait for clk_50_period * 10;
      down <= '0';
      sel <= '1';
      wait for clk_50_period * 10;
      sel <= '0';
      sim_vga_frame;
      assert next_stage /= "00" report "stage did not change after down/select #3" severity error;
      wait for clk_25_period * 10;

      ----------------------------------------- vector 4: test clear
      report "testing clear functionality";
      clrn <= '0';
      wait for clk_50_period * 10;
      clrn <= '1';
      sim_vga_frame;
      assert next_stage = "00" report "stage not reset after clear #4" severity error;
      wait for clk_25_period * 10;

      ----------------------------------------- end of test
      report "end of test vectors";
      wait;
   end process;

end arc_tb_screen_menu;