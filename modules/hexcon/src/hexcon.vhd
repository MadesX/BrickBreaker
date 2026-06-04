-- Copyright (C) 1991-2010 Altera Corporation
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, Altera MegaCore Function License 
-- Agreement, or other applicable license agreement, including, 
-- without limitation, that your use is for the sole purpose of 
-- programming logic devices manufactured by Altera and sold by 
-- Altera or its authorized distributors.  Please refer to the 
-- applicable agreement for further details.

-- PROGRAM		"Quartus II"
-- VERSION		"Version 9.1 Build 350 03/24/2010 Service Pack 2 SJ Web Edition"
-- CREATED		"Fri Oct 17 15:09:31 2025"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY hexcon IS 
	PORT
	(
		resetN :  IN  STD_LOGIC;
		rx :  IN  STD_LOGIC;
		clr_reg :  IN  STD_LOGIC;
		send_serial :  IN  STD_LOGIC;
		clk_25 :  IN  STD_LOGIC;
		din :  IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
		tx :  OUT  STD_LOGIC;
		new_hex :  OUT  STD_LOGIC;
		ready :  OUT  STD_LOGIC;
		select_out :  OUT  STD_LOGIC;
		up_out :  OUT  STD_LOGIC;
		down_out :  OUT  STD_LOGIC;
		left_out :  OUT  STD_LOGIC;
		right_out :  OUT  STD_LOGIC;
		dout :  OUT  STD_LOGIC_VECTOR(63 DOWNTO 0)
	);
END hexcon;

ARCHITECTURE bdf_type OF hexcon IS 

COMPONENT rise
	PORT(din : IN STD_LOGIC;
		 clk : IN STD_LOGIC;
		 resetN : IN STD_LOGIC;
		 dout : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT uart
	PORT(resetN : IN STD_LOGIC;
		 clk : IN STD_LOGIC;
		 write_din : IN STD_LOGIC;
		 rx : IN STD_LOGIC;
		 read_dout : IN STD_LOGIC;
		 din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 tx : OUT STD_LOGIC;
		 tx_ready : OUT STD_LOGIC;
		 rx_ready : OUT STD_LOGIC;
		 dout_new : OUT STD_LOGIC;
		 dout_ready : OUT STD_LOGIC;
		 dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END COMPONENT;

COMPONENT bytes2reg
	PORT(resetN : IN STD_LOGIC;
		 clk : IN STD_LOGIC;
		 enable : IN STD_LOGIC;
		 clr_reg : IN STD_LOGIC;
		 din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 new_hex : OUT STD_LOGIC;
		 g_out : OUT STD_LOGIC;
		 stop : OUT STD_LOGIC;
		 up_out : OUT STD_LOGIC;
		 down_out : OUT STD_LOGIC;
		 left_out : OUT STD_LOGIC;
		 right_out : OUT STD_LOGIC;
		 select_out : OUT STD_LOGIC;
		 cout : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
		 dout : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
		 hexout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END COMPONENT;

COMPONENT reg2bytes
GENERIC (timer_active : INTEGER;
			timer_count : INTEGER
			);
	PORT(resetN : IN STD_LOGIC;
		 clk : IN STD_LOGIC;
		 send : IN STD_LOGIC;
		 stop : IN STD_LOGIC;
		 din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
		 to_write_din : OUT STD_LOGIC;
		 ready : OUT STD_LOGIC;
		 to_din : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END COMPONENT;

SIGNAL	clk :  STD_LOGIC;
SIGNAL	more_to_send :  STD_LOGIC;
SIGNAL	send_now :  STD_LOGIC;
SIGNAL	tx_busy :  STD_LOGIC;
SIGNAL	xoff_stop :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_0 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_1 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_2 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_3 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_4 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_5 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_6 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_7 :  STD_LOGIC;


BEGIN 
SYNTHESIZED_WIRE_0 <= '0';



b2v_inst : rise
PORT MAP(din => send_serial,
		 clk => clk,
		 resetN => resetN,
		 dout => SYNTHESIZED_WIRE_3);


b2v_inst10 : uart
PORT MAP(resetN => resetN,
		 clk => clk,
		 write_din => send_now,
		 rx => rx,
		 read_dout => SYNTHESIZED_WIRE_0,
		 din => SYNTHESIZED_WIRE_1,
		 tx => tx,
		 tx_ready => SYNTHESIZED_WIRE_2,
		 dout_new => SYNTHESIZED_WIRE_5,
		 dout => SYNTHESIZED_WIRE_6);



tx_busy <= NOT(SYNTHESIZED_WIRE_2);



SYNTHESIZED_WIRE_7 <= tx_busy OR xoff_stop;


more_to_send <= SYNTHESIZED_WIRE_3 OR SYNTHESIZED_WIRE_4;


b2v_inst6 : bytes2reg
PORT MAP(resetN => resetN,
		 clk => clk,
		 enable => SYNTHESIZED_WIRE_5,
		 clr_reg => clr_reg,
		 din => SYNTHESIZED_WIRE_6,
		 new_hex => new_hex,
		 g_out => SYNTHESIZED_WIRE_4,
		 stop => xoff_stop,
		 up_out => up_out,
		 down_out => down_out,
		 left_out => left_out,
		 right_out => right_out,
		 select_out => select_out,
		 dout => dout);


b2v_inst9 : reg2bytes
GENERIC MAP(timer_active => 1,
			timer_count => 2500000
			)
PORT MAP(resetN => resetN,
		 clk => clk,
		 send => more_to_send,
		 stop => SYNTHESIZED_WIRE_7,
		 din => din,
		 to_write_din => send_now,
		 ready => ready,
		 to_din => SYNTHESIZED_WIRE_1);

clk <= clk_25;

END bdf_type;
