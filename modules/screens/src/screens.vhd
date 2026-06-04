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
-- CREATED		"Fri Oct 17 19:03:43 2025"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY screens IS 
	PORT
	(
		mode :  IN  STD_LOGIC;
		video :  IN  STD_LOGIC;
		resetN :  IN  STD_LOGIC;
		clk_25 :  IN  STD_LOGIC;
		clk_50 :  IN  STD_LOGIC;
		left :  IN  STD_LOGIC;
		right :  IN  STD_LOGIC;
		enable :  IN  STD_LOGIC;
		sel :  IN  STD_LOGIC;
		clrN :  IN  STD_LOGIC;
		count_h :  IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
		count_v :  IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
		BLUE :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
		GREEN :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
		next_stage :  OUT  STD_LOGIC_VECTOR(1 DOWNTO 0);
		RED :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0)
	);
END screens;

ARCHITECTURE bdf_type OF screens IS 

COMPONENT buttons_screen
	PORT(clk_50 : IN STD_LOGIC;
		 clk_25 : IN STD_LOGIC;
		 resetN : IN STD_LOGIC;
		 clrN : IN STD_LOGIC;
		 enable : IN STD_LOGIC;
		 left : IN STD_LOGIC;
		 right : IN STD_LOGIC;
		 sel : IN STD_LOGIC;
		 count_h : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		 count_v : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		 next_stage : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
		 vga_b : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		 vga_g : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		 vga_r : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
	);
END COMPONENT;

COMPONENT txtgen_screen
	PORT(clk : IN STD_LOGIC;
		 mode : IN STD_LOGIC;
		 size : IN STD_LOGIC;
		 count_h : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		 count_v : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		 char_code : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
		 pospix_h : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		 pospix_v : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
	);
END COMPONENT;

COMPONENT lpm_or_r
	PORT(data0x : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 data1x : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 data2x : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 result : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
	);
END COMPONENT;

COMPONENT lpm_or_g
	PORT(data0x : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 data1x : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 data2x : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 result : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
	);
END COMPONENT;

COMPONENT lpm_or_b
	PORT(data0x : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 data1x : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 data2x : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 result : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
	);
END COMPONENT;

COMPONENT pipe
GENERIC (depth : INTEGER
			);
	PORT(resetN : IN STD_LOGIC;
		 clk : IN STD_LOGIC;
		 din : IN STD_LOGIC;
		 dout : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT dup4
	PORT(din_r : IN STD_LOGIC;
		 din_g : IN STD_LOGIC;
		 din_b : IN STD_LOGIC;
		 ena : IN STD_LOGIC;
		 dout_b : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		 dout_g : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		 dout_r : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
	);
END COMPONENT;

COMPONENT chrgen8
	PORT(clk : IN STD_LOGIC;
		 char_code : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		 pospix_h : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		 pospix_v : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		 dout : OUT STD_LOGIC
	);
END COMPONENT;

SIGNAL	clk :  STD_LOGIC;
SIGNAL	dout_b1 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	dout_b2 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	dout_b3 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	dout_g1 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	dout_g2 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	dout_g3 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	dout_r1 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	dout_r2 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	dout_r3 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_0 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_1 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_2 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_18 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_19 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_20 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_12 :  STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_13 :  STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_14 :  STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_15 :  STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_16 :  STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_17 :  STD_LOGIC_VECTOR(2 DOWNTO 0);


BEGIN 
SYNTHESIZED_WIRE_1 <= '1';
SYNTHESIZED_WIRE_2 <= '0';



b2v_inst10 : buttons_screen
PORT MAP(clk_50 => clk_50,
		 clk_25 => clk,
		 resetN => resetN,
		 clrN => clrN,
		 enable => SYNTHESIZED_WIRE_0,
		 left => left,
		 right => right,
		 sel => sel,
		 count_h => count_h,
		 count_v => count_v,
		 next_stage => next_stage,
		 vga_b => dout_b3,
		 vga_g => dout_g3,
		 vga_r => dout_r3);


b2v_inst11 : txtgen_screen
PORT MAP(clk => clk,
		 mode => mode,
		 size => SYNTHESIZED_WIRE_1,
		 count_h => count_h,
		 count_v => count_v,
		 char_code => SYNTHESIZED_WIRE_12,
		 pospix_h => SYNTHESIZED_WIRE_13,
		 pospix_v => SYNTHESIZED_WIRE_14);


b2v_inst13 : txtgen_screen
PORT MAP(clk => clk,
		 mode => mode,
		 size => SYNTHESIZED_WIRE_2,
		 count_h => count_h,
		 count_v => count_v,
		 char_code => SYNTHESIZED_WIRE_15,
		 pospix_h => SYNTHESIZED_WIRE_16,
		 pospix_v => SYNTHESIZED_WIRE_17);


b2v_inst14 : lpm_or_r
PORT MAP(data0x => dout_r1,
		 data1x => dout_r2,
		 data2x => dout_r3,
		 result => RED);


b2v_inst15 : lpm_or_g
PORT MAP(data0x => dout_g1,
		 data1x => dout_g2,
		 data2x => dout_g3,
		 result => GREEN);


b2v_inst16 : lpm_or_b
PORT MAP(data0x => dout_b1,
		 data1x => dout_b2,
		 data2x => dout_b3,
		 result => BLUE);




b2v_inst2 : pipe
GENERIC MAP(depth => 2
			)
PORT MAP(resetN => resetN,
		 clk => clk,
		 din => video,
		 dout => SYNTHESIZED_WIRE_18);


SYNTHESIZED_WIRE_0 <= enable AND SYNTHESIZED_WIRE_18;


b2v_inst6 : dup4
PORT MAP(din_r => SYNTHESIZED_WIRE_19,
		 din_g => SYNTHESIZED_WIRE_19,
		 din_b => SYNTHESIZED_WIRE_19,
		 ena => SYNTHESIZED_WIRE_18,
		 dout_b => dout_b1,
		 dout_g => dout_g1,
		 dout_r => dout_r1);


b2v_inst7 : dup4
PORT MAP(din_r => SYNTHESIZED_WIRE_20,
		 din_g => SYNTHESIZED_WIRE_20,
		 din_b => SYNTHESIZED_WIRE_20,
		 ena => SYNTHESIZED_WIRE_18,
		 dout_b => dout_b2,
		 dout_g => dout_g2,
		 dout_r => dout_r2);


b2v_inst8 : chrgen8
PORT MAP(clk => clk,
		 char_code => SYNTHESIZED_WIRE_12,
		 pospix_h => SYNTHESIZED_WIRE_13,
		 pospix_v => SYNTHESIZED_WIRE_14,
		 dout => SYNTHESIZED_WIRE_19);


b2v_inst9 : chrgen8
PORT MAP(clk => clk,
		 char_code => SYNTHESIZED_WIRE_15,
		 pospix_h => SYNTHESIZED_WIRE_16,
		 pospix_v => SYNTHESIZED_WIRE_17,
		 dout => SYNTHESIZED_WIRE_20);

clk <= clk_25;

END bdf_type;