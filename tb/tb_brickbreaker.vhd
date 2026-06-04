library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity tb_brickbreaker is
  -- test bench for brickbreaker
end tb_brickbreaker;

architecture arc_tb_brickbreaker of tb_brickbreaker is
   component brickbreaker
      port (
         clk_50     : in  std_logic;
         resetn     : in  std_logic;
         clrn       : in  std_logic;
         left2      : in  std_logic;
         right2     : in  std_logic;
         rx2_bt     : in  std_logic;
         tx2_bt     : out std_logic;
         tx3_mp3    : out std_logic;
         horiz_sync : out std_logic;
         vert_sync  : out std_logic;
         blue       : out std_logic_vector(3 downto 0);
         green      : out std_logic_vector(3 downto 0);
         red        : out std_logic_vector(3 downto 0);
         sel        : out std_logic_vector(1 downto 0)
      );
   end component;

   -- signals
   signal clk_50     : std_logic := '0'; -- 50 mhz clock
   signal resetn     : std_logic := '1'; -- active-low reset
   signal clrn       : std_logic := '1'; -- active-low clear
   signal left2      : std_logic := '1'; -- active-low player 2 left button
   signal right2     : std_logic := '1'; -- active-low player 2 right button
   signal rx2_bt     : std_logic := '1'; -- bluetooth input
   signal tx2_bt     : std_logic; -- bluetooth output
   signal tx3_mp3    : std_logic; -- mp3 output
   signal horiz_sync : std_logic; -- vga horizontal sync
   signal vert_sync  : std_logic; -- vga vertical sync
   signal blue       : std_logic_vector(3 downto 0); -- blue output
   signal green      : std_logic_vector(3 downto 0); -- green output
   signal red        : std_logic_vector(3 downto 0); -- red output
   signal sel        : std_logic_vector(1 downto 0); -- state select

   -- timing constants
   constant clk_50_period : time := 20 ns; -- 50 mhz clock
   constant clk_25_period : time := 40 ns; -- 25 mhz clock (derived internally)
   constant bit_time : time := 104166.67 ns; -- 9600 baud (1/9600 s)
   constant h_visible : integer := 640; -- visible horizontal pixels
   constant v_visible : integer := 480; -- visible vertical pixels
   constant frame_time : time := 16666667 ns; -- ~60 hz frame (1/60 s)

begin
   -- brickbreaker instantiation (named association)
   eut: brickbreaker
      port map (
         clk_50     => clk_50,
         resetn     => resetn,
         clrn       => clrn,
         left2      => left2,
         right2     => right2,
         rx2_bt     => rx2_bt,
         tx2_bt     => tx2_bt,
         tx3_mp3    => tx3_mp3,
         horiz_sync => horiz_sync,
         vert_sync  => vert_sync,
         blue       => blue,
         green      => green,
         red        => red,
         sel        => sel
      );

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
      procedure send_bt_byte (data : std_logic_vector(7 downto 0)) is
      begin
         -- send one byte over rx2_bt (9600 baud, 8n1)
         rx2_bt <= '0'; -- start bit
         wait for bit_time;
         for i in 0 to 7 loop
            rx2_bt <= data(i);
            wait for bit_time;
         end loop;
         rx2_bt <= '1'; -- stop bit
         wait for bit_time;
      end procedure;

      procedure sim_vga_frame is
      begin
         -- simulate one vga frame (simplified)
         wait for frame_time; -- ~16.67 ms for 60 hz
      end procedure;
   begin
      -- initialize inputs
      clrn <= '1'; left2 <= '1'; right2 <= '1'; rx2_bt <= '1';
      wait for 40 ns; -- wait for end of async reset

      ----------------------------------------- vector 1: test pre to menu transition
      report "testing pre to menu transition";
      sim_vga_frame;
      assert sel = "00" report "sel not 00 in menu state #1" severity error;
      assert red /= "0000" or green /= "0000" or blue /= "0000" report "no vga output in menu #1" severity error;
      wait for frame_time;

      ----------------------------------------- vector 2: select single-player mode via bluetooth
      report "selecting single-player mode via bluetooth";
      send_bt_byte("00010000"); -- assume '00010000' maps to select single-player in hexcon
      wait for frame_time * 2; -- allow state transition
      assert sel = "01" report "sel not 01 in breaker_1p state #2" severity error;
      assert red /= "0000" or green /= "0000" or blue /= "0000" report "no vga output in breaker_1p #2" severity error;
      wait for frame_time;

      ----------------------------------------- vector 3: test player 2 controls in two-player mode
      report "testing two-player mode with player 2 controls";
      send_bt_byte("00100000"); -- assume '00100000' maps to select two-player in hexcon
      wait for frame_time * 2; -- allow state transition
      assert sel = "10" report "sel not 10 in breaker_2p state #3" severity error;
      left2 <= '0'; -- player 2 left button
      wait for frame_time * 5;
      left2 <= '1';
      sim_vga_frame;
      assert red /= "0000" or green /= "0000" or blue /= "0000" report "no vga output in breaker_2p #3" severity error;
      wait for frame_time;

      ----------------------------------------- vector 4: test game over and return to menu
      report "testing game over and return to menu";
      send_bt_byte("00010000"); -- assume '00010000' maps to select in screens to return to menu
      wait for frame_time * 2; -- allow state transition
      assert sel = "00" report "sel not 00 in menu state #4" severity error;
      assert red /= "0000" or green /= "0000" or blue /= "0000" report "no vga output in menu #4" severity error;
      wait for frame_time;

      ----------------------------------------- vector 5: test clear
      report "testing clear functionality";
      clrn <= '0';
      wait for frame_time;
      clrn <= '1';
      sim_vga_frame;
      assert sel = "00" report "sel not 00 after clear #5" severity error;
      wait for frame_time;

      ----------------------------------------- end of test
      report "end of test vectors";
      wait;
   end process;

   -- mp3 monitor process
   process
   begin
      wait until falling_edge(tx3_mp3); -- detect start bit
      wait for bit_time / 2; -- sample in middle of start bit
      if tx3_mp3 = '0' then
         for i in 0 to 7 loop
            wait for bit_time;
            -- sample data bits (no storage, just monitor)
         end loop;
         wait for bit_time;
         assert tx3_mp3 = '1' report "bad stop bit on tx3_mp3" severity error;
      else
         report "a too short start bit on tx3_mp3";
      end if;
   end process;

end arc_tb_brickbreaker;
