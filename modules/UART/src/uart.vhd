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
-- CREATED		"Sat Oct 25 22:54:01 2025"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY uart IS 
	PORT
	(
		resetN :  IN  STD_LOGIC;
		write_din :  IN  STD_LOGIC;
		read_dout :  IN  STD_LOGIC;
		clk :  IN  STD_LOGIC;
		rx :  IN  STD_LOGIC;
		din :  IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		tx :  OUT  STD_LOGIC;
		tx_ready :  OUT  STD_LOGIC;
		rx_ready :  OUT  STD_LOGIC;
		dout_new :  OUT  STD_LOGIC;
		dout_ready :  OUT  STD_LOGIC;
		dout :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END uart;

ARCHITECTURE bdf_type OF uart IS 

COMPONENT receiver
GENERIC (baud : INTEGER;
			clockfreq : INTEGER
			);
	PORT(resetN : IN STD_LOGIC;
		 clk : IN STD_LOGIC;
		 rx : IN STD_LOGIC;
		 read_dout : IN STD_LOGIC;
		 rx_ready : OUT STD_LOGIC;
		 dout_new : OUT STD_LOGIC;
		 dout_ready : OUT STD_LOGIC;
		 dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END COMPONENT;

COMPONENT transmitter
	PORT(resetN : IN STD_LOGIC;
		 clk : IN STD_LOGIC;
		 write_din : IN STD_LOGIC;
		 din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 tx : OUT STD_LOGIC;
		 tx_ready : OUT STD_LOGIC
	);
END COMPONENT;



BEGIN 



b2v_inst : receiver
GENERIC MAP(baud => 9600,
			clockfreq => 25000000
			)
PORT MAP(resetN => resetN,
		 clk => clk,
		 rx => rx,
		 read_dout => read_dout,
		 rx_ready => rx_ready,
		 dout_new => dout_new,
		 dout_ready => dout_ready,
		 dout => dout);


b2v_inst1 : transmitter
PORT MAP(resetN => resetN,
		 clk => clk,
		 write_din => write_din,
		 din => din,
		 tx => tx,
		 tx_ready => tx_ready);


END bdf_type;