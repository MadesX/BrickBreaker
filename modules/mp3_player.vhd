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
-- CREATED		"Sat Oct 18 11:22:37 2025"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY mp3_player IS 
	PORT
	(
		resetN :  IN  STD_LOGIC;
		clk_25 :  IN  STD_LOGIC;
		send :  IN  STD_LOGIC;
		din :  IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		TX3_MP3 :  OUT  STD_LOGIC;
		ready :  OUT  STD_LOGIC
	);
END mp3_player;

ARCHITECTURE bdf_type OF mp3_player IS 

COMPONENT bytes_to_mp3
GENERIC (timer_active : INTEGER;
			timer_count : INTEGER
			);
	PORT(resetN : IN STD_LOGIC;
		 clk : IN STD_LOGIC;
		 send : IN STD_LOGIC;
		 stop : IN STD_LOGIC;
		 din : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		 to_write_din : OUT STD_LOGIC;
		 ready : OUT STD_LOGIC;
		 to_din : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
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

SIGNAL	SYNTHESIZED_WIRE_0 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_1 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_2 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_3 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_4 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_5 :  STD_LOGIC;


BEGIN 
SYNTHESIZED_WIRE_2 <= '1';
SYNTHESIZED_WIRE_3 <= '0';



b2v_inst : bytes_to_mp3
GENERIC MAP(timer_active => 0,
			timer_count => 2500000
			)
PORT MAP(resetN => resetN,
		 clk => clk_25,
		 send => send,
		 stop => SYNTHESIZED_WIRE_0,
		 din => din,
		 to_write_din => SYNTHESIZED_WIRE_1,
		 ready => ready,
		 to_din => SYNTHESIZED_WIRE_4);


b2v_inst1 : uart
PORT MAP(resetN => resetN,
		 clk => clk_25,
		 write_din => SYNTHESIZED_WIRE_1,
		 rx => SYNTHESIZED_WIRE_2,
		 read_dout => SYNTHESIZED_WIRE_3,
		 din => SYNTHESIZED_WIRE_4,
		 tx => TX3_MP3,
		 tx_ready => SYNTHESIZED_WIRE_5);




SYNTHESIZED_WIRE_0 <= NOT(SYNTHESIZED_WIRE_5);



END bdf_type;