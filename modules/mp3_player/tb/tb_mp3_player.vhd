library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity tb_mp3_player is
  -- test bench for mp3_player
end tb_mp3_player;

architecture arc_tb_mp3_player of tb_mp3_player is
   component mp3_player
      port (
         resetn     : in  std_logic;
         clk_25     : in  std_logic;
         send       : in  std_logic;
         din        : in  std_logic_vector(15 downto 0);
         tx3_mp3    : out std_logic;
         ready      : out std_logic
      );
   end component;

   -- signals
   signal resetn     : std_logic := '1'; -- active-low reset
   signal clk_25     : std_logic := '0'; -- 25 mhz clock
   signal send       : std_logic := '0'; -- send enable
   signal din        : std_logic_vector(15 downto 0) := (others => '0'); -- parallel input
   signal tx3_mp3    : std_logic; -- serial output
   signal ready      : std_logic; -- ready to send

   -- timing constants
   constant clk_period : time := 40 ns; -- 25 mhz clock
   constant bit_time : time := 104166.67 ns; -- 9600 baud (1/9600 s)

begin
   -- mp3_player instantiation (named association)
   eut: mp3_player
      port map (
         resetn     => resetn,
         clk_25     => clk_25,
         send       => send,
         din        => din,
         tx3_mp3    => tx3_mp3,
         ready      => ready
      );

   -- clock process (25 mhz)
   process
   begin
      clk_25 <= '0'; wait for clk_period/2;
      clk_25 <= '1'; wait for clk_period/2;
   end process;

   -- active low reset pulse
   resetn <= '0', '1' after 40 ns;

   -- transmission test vectors process
   process
      variable data_send : std_logic_vector(15 downto 0);
      variable byte1_expected : std_logic_vector(7 downto 0);
      variable byte2_expected : std_logic_vector(7 downto 0);
   begin
      -- initialize inputs
      din <= (others => 'X'); send <= '0';
      wait for 40 ns; -- wait for end of async reset

      ----------------------------------------- vector 1: transmit 0x4142
      report "sending 16-bit data (0x4142)";
      data_send := x"4142"; -- ascii 'ab'
      byte1_expected := x"41"; -- first byte
      byte2_expected := x"42"; -- second byte
      din <= data_send; send <= '1';
      wait for 40 ns;
      send <= '0';
      wait for 11 * bit_time; -- wait for first byte transmission
      wait for 11 * bit_time; -- wait for second byte transmission
      assert ready = '1' report "ready not high after transmission #1" severity error;
      wait for bit_time;

      ----------------------------------------- vector 2: transmit 0x0000
      report "sending 16-bit data (0x0000)";
      data_send := x"0000"; -- all zeros
      byte1_expected := x"00";
      byte2_expected := x"00";
      din <= data_send; send <= '1';
      wait for 40 ns;
      send <= '0';
      wait for 11 * bit_time;
      wait for 11 * bit_time;
      assert ready = '1' report "ready not high after transmission #2" severity error;
      wait for bit_time;

      ----------------------------------------- vector 3: transmit 0xffff
      report "sending 16-bit data (0xffff)";
      data_send := x"FFFF"; -- all ones
      byte1_expected := x"FF";
      byte2_expected := x"FF";
      din <= data_send; send <= '1';
      wait for 40 ns;
      send <= '0';
      wait for 11 * bit_time;
      wait for 11 * bit_time;
      assert ready = '1' report "ready not high after transmission #3" severity error;
      wait for bit_time;

      ----------------------------------------- vector 4: test reset during transmission
      report "testing reset during transmission";
      data_send := x"1234";
      din <= data_send; send <= '1';
      wait for 40 ns;
      send <= '0';
      wait for 5 * bit_time; -- partial transmission
      resetn <= '0';
      wait for 40 ns;
      resetn <= '1';
      wait for bit_time;
      assert ready = '1' report "ready not high after reset #4" severity error;
      wait for bit_time;

      ----------------------------------------- end of test
      report "end of test vectors";
      wait;
   end process;

   -- receiver process to monitor serial data
   process
      variable dint : std_logic_vector(7 downto 0);
   begin
      dint := (others => '0');
      wait until falling_edge(tx3_mp3); -- detect start bit
      wait for bit_time / 2; -- sample in middle of start bit
      if tx3_mp3 = '0' then
         for i in 0 to 7 loop
            wait for bit_time;
            dint(i) := tx3_mp3; -- sample data bits
         end loop;
         wait for bit_time;
         assert tx3_mp3 = '1' report "bad stop bit" severity error;
      else
         report "a too short start bit";
      end if;
   end process;

end arc_tb_mp3_player;