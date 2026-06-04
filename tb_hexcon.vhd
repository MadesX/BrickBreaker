library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity tb_hexcon is
  -- test bench for hexcon
end tb_hexcon;

architecture arc_tb_hexcon of tb_hexcon is
   component hexcon
      port (
         clk_25      : in  std_logic;
         resetn      : in  std_logic;
         rx          : in  std_logic;
         clr_reg     : in  std_logic;
         send_serial : in  std_logic;
         din         : in  std_logic_vector(63 downto 0);
         tx          : out std_logic;
         new_hex     : out std_logic;
         up_out      : out std_logic;
         down_out    : out std_logic;
         left_out    : out std_logic;
         right_out   : out std_logic;
         select_out  : out std_logic;
         ready       : out std_logic;
         dout        : out std_logic_vector(63 downto 0)
      );
   end component;

   -- signals
   signal clk_25      : std_logic := '0'; -- 25 mhz clock
   signal resetn      : std_logic := '1'; -- active-low reset
   signal rx          : std_logic := '1'; -- serial input
   signal clr_reg     : std_logic := '0'; -- active-high clear
   signal send_serial : std_logic := '0'; -- trigger serial transmit
   signal din         : std_logic_vector(63 downto 0) := (others => '0'); -- input data
   signal tx          : std_logic; -- serial output
   signal new_hex     : std_logic; -- new data indicator
   signal up_out      : std_logic; -- up button output
   signal down_out    : std_logic; -- down button output
   signal left_out    : std_logic; -- left button output
   signal right_out   : std_logic; -- right button output
   signal select_out  : std_logic; -- select button output
   signal ready       : std_logic; -- ready signal
   signal dout        : std_logic_vector(63 downto 0); -- output data

   -- timing constants
   constant clk_25_period : time := 40 ns; -- 25 mhz clock
   constant bit_time : time := 104166.67 ns; -- 9600 baud

begin
   -- hexcon instantiation (named association)
   eut: hexcon
      port map (
         clk_25      => clk_25,
         resetn      => resetn,
         rx          => rx,
         clr_reg     => clr_reg,
         send_serial => send_serial,
         din         => din,
         tx          => tx,
         new_hex     => new_hex,
         up_out      => up_out,
         down_out    => down_out,
         left_out    => left_out,
         right_out   => right_out,
         select_out  => select_out,
         ready       => ready,
         dout        => dout
      );

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
      procedure send_byte (data : std_logic_vector(7 downto 0)) is
      begin
         -- send one byte over rx (9600 baud, 8n1)
         rx <= '0'; -- start bit
         wait for bit_time;
         for i in 0 to 7 loop
            rx <= data(i);
            wait for bit_time;
         end loop;
         rx <= '1'; -- stop bit
         wait for bit_time;
      end procedure;

      procedure check_outputs (
         up_exp, down_exp, left_exp, right_exp, sel_exp : std_logic;
         msg : string
      ) is
      begin
         wait for bit_time * 2; -- wait for hexcon to process
         assert up_out = up_exp report "up_out mismatch: " & msg severity error;
         assert down_out = down_exp report "down_out mismatch: " & msg severity error;
         assert left_out = left_exp report "left_out mismatch: " & msg severity error;
         assert right_out = right_exp report "right_out mismatch: " & msg severity error;
         assert select_out = sel_exp report "select_out mismatch: " & msg severity error;
         assert new_hex = '1' report "new_hex not set: " & msg severity error;
         assert ready = '0' report "ready not cleared: " & msg severity error;
         wait for bit_time;
         assert ready = '1' report "ready not set after processing: " & msg severity error;
      end procedure;
   begin
      -- initialize inputs
      clr_reg <= '0'; send_serial <= '0'; din <= (others => '0');
      wait for 40 ns; -- wait for end of async reset

      ----------------------------------------- vector 1: send 'U' (up)
      report "sending 'U' for up";
      send_byte("01010101"); -- ascii 'U' = 0x55
      check_outputs('1', '0', '0', '0', '0', "after 'U' #1");

      ----------------------------------------- vector 2: send 'N' (down)
      report "sending 'N' for down";
      send_byte("01001110"); -- ascii 'N' = 0x4E
      check_outputs('0', '1', '0', '0', '0', "after 'N' #2");

      ----------------------------------------- vector 3: send 'L' (left)
      report "sending 'L' for left";
      send_byte("01001100"); -- ascii 'L' = 0x4C
      check_outputs('0', '0', '1', '0', '0', "after 'L' #3");

      ----------------------------------------- vector 4: send 'R' (right)
      report "sending 'R' for right";
      send_byte("01010010"); -- ascii 'R' = 0x52
      check_outputs('0', '0', '0', '1', '0', "after 'R' #4");

      ----------------------------------------- vector 5: send 'V' (select)
      report "sending 'V' for select";
      send_byte("01010110"); -- ascii 'V' = 0x56
      check_outputs('0', '0', '0', '0', '1', "after 'V' #5");

      ----------------------------------------- vector 6: send invalid byte
      report "sending invalid byte 'Z'";
      send_byte("01011010"); -- ascii 'Z' = 0x5A
      wait for bit_time * 2;
      assert new_hex = '0' report "new_hex set for invalid byte #6" severity error;
      assert up_out = '0' and down_out = '0' and left_out = '0' and right_out = '0' and select_out = '0'
         report "outputs set for invalid byte #6" severity error;

      ----------------------------------------- vector 7: test clear
      report "testing clear functionality";
      send_byte("01010101"); -- send 'U' again
      wait for bit_time * 2;
      clr_reg <= '1';
      wait for clk_25_period * 2;
      clr_reg <= '0';
      assert up_out = '0' and down_out = '0' and left_out = '0' and right_out = '0' and select_out = '0'
         report "outputs not cleared #7" severity error;
      assert new_hex = '0' report "new_hex not cleared #7" severity error;
      wait for bit_time;

      ----------------------------------------- vector 8: test serial transmit
      report "testing serial transmit";
      din <= x"1234567890ABCDEF"; -- arbitrary data
      send_serial <= '1';
      wait for clk_25_period * 2;
      send_serial <= '0';
      wait for bit_time * 10; -- wait for one byte to transmit
      assert tx = '1' report "tx not idle after transmit #8" severity error;
      wait for bit_time;

      ----------------------------------------- end of test
      report "end of test vectors";
      wait;
   end process;

   -- tx monitor process
   process
   begin
      wait until falling_edge(tx); -- detect start bit
      wait for bit_time / 2; -- sample in middle of start bit
      if tx = '0' then
         for i in 0 to 7 loop
            wait for bit_time;
            -- sample data bits (no storage, just monitor)
         end loop;
         wait for bit_time;
         assert tx = '1' report "bad stop bit on tx" severity error;
      else
         report "a too short start bit on tx";
      end if;
   end process;

end arc_tb_hexcon;