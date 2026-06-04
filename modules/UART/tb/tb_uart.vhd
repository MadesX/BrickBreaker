library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity tb_uart is
  -- test bench for uart (transmitter and receiver)
end tb_uart;

architecture arc_tb_uart of tb_uart is
   component uart
      port(
         resetn     : in  std_logic;
         write_din  : in  std_logic;
         read_dout  : in  std_logic;
         clk        : in  std_logic;
         rx         : in  std_logic;
         din        : in  std_logic_vector(7 downto 0);
         tx         : out std_logic;
         tx_ready   : out std_logic;
         rx_ready   : out std_logic;
         dout_new   : out std_logic;
         dout_ready : out std_logic;
         dout       : out std_logic_vector(7 downto 0)
      );
   end component;

   -- signals
   signal resetn     : std_logic := '1';                                -- active-low reset
   signal clk        : std_logic := '0';                                -- clock
   signal write_din  : std_logic := '0';                                -- transmit enable
   signal read_dout  : std_logic := '0';                                -- receive acknowledge
   signal rx         : std_logic := '1';                                -- serial input (idle high)
   signal din        : std_logic_vector(7 downto 0) := (others => '0'); -- parallel input
   signal tx         : std_logic;                                       -- serial output
   signal tx_ready   : std_logic;                                       -- transmitter ready
   signal rx_ready   : std_logic;                                       -- receiver ready
   signal dout_new   : std_logic;                                       -- new data received
   signal dout_ready : std_logic;                                       -- data ready to read
   signal dout       : std_logic_vector(7 downto 0);                    -- parallel output
   signal txrx       : std_logic;                                       -- loopback from tx to rx for testing

   -- timing constants
   constant clk_period : time := 40 ns;      -- 25 mhz clock
   constant bit_time : time := 104166.67 ns; -- 9600 baud (1/9600 s)

begin
   -- uart instantiation (named association)
   eut: uart
      port map (
         resetn     => resetn,
         write_din  => write_din,
         read_dout  => read_dout,
         clk        => clk,
         rx         => txrx,
         din        => din,
         tx         => tx,
         tx_ready   => tx_ready,
         rx_ready   => rx_ready,
         dout_new   => dout_new,
         dout_ready => dout_ready,
         dout       => dout
      );

   -- loopback for testing (tx to rx)
   txrx <= tx;

   -- clock process (25 mhz)
   process
   begin
      clk <= '0'; wait for clk_period/2;
      clk <= '1'; wait for clk_period/2;
   end process;

   -- active low reset pulse
   resetn <= '0', '1' after 40 ns;

   -- transmission and reception test vectors process
   process
      variable data_send : std_logic_vector(7 downto 0);
   begin
      -- initialize inputs
      din <= "XXXXXXXX"; write_din <= '0'; read_dout <= '0';
      wait for 40 ns; -- wait for end of async reset

      ----------------------------------------- vector 1: transmit and receive 'h'
      report "sending and receiving the h character (01001000b=48h=72d)";
      data_send := "00000000" + character'pos('h');
      din <= data_send; write_din <= '1';
      wait for 40 ns;
      write_din <= '0';
      wait until dout_new = '1'; -- wait for received data
      read_dout <= '1';
      wait for clk_period;
      read_dout <= '0';
      assert dout = data_send report "bad transmission/reception #1" severity error;
      wait for bit_time;

      ----------------------------------------- vector 2: transmit and receive 'i'
      report "sending and receiving the i character (01101001b=69h=105d)";
      data_send := "00000000" + character'pos('i');
      din <= data_send; write_din <= '1';
      wait for 40 ns;
      write_din <= '0';
      wait until dout_new = '1';
      read_dout <= '1';
      wait for clk_period;
      read_dout <= '0';
      assert dout = data_send report "bad transmission/reception #2" severity error;
      wait for bit_time;

      ----------------------------------------- vector 3: transmit and receive cr
      report "sending and receiving the cr character (00001101b=0dh=13d)";
      data_send := "00000000" + character'pos(cr);
      din <= data_send; write_din <= '1';
      wait for 40 ns;
      write_din <= '0';
      wait until dout_new = '1';
      read_dout <= '1';
      wait for clk_period;
      read_dout <= '0';
      assert dout = data_send report "bad transmission/reception #3" severity error;
      wait for bit_time;

      ----------------------------------------- vector 4: transmit and receive lf
      report "sending and receiving the lf character (00001010b=0ah=10d)";
      data_send := "00000000" + character'pos(lf);
      din <= data_send; write_din <= '1';
      wait for 40 ns;
      write_din <= '0';
      wait until dout_new = '1';
      read_dout <= '1';
      wait for clk_period;
      read_dout <= '0';
      assert dout = data_send report "bad transmission/reception #4" severity error;
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
      wait until falling_edge(txrx); -- detect start bit
      wait for bit_time / 2;  -- sample in middle of start bit
      if txrx = '0' then
         for i in 0 to 7 loop
            wait for bit_time;
            dint(i) := txrx;  -- sample data bits
         end loop;
         wait for bit_time;
         assert txrx = '1' report "bad stop bit" severity error;
      else
         report "a too short start bit";
      end if;
   end process;

end arc_tb_uart;