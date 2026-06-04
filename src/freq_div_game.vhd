library ieee;
use ieee.std_logic_1164.all;

entity freq_div_game is
    port (
        clk : in std_logic;
        clkout : out std_logic
    );
end freq_div_game;

architecture arch of freq_div_game is
    signal count : integer range 0 to 833333 := 0;
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if count = 833333 then  -- 50 MHz / 833333 ≈ 60 Hz
                count <= 0;
                clkout <= '1';
            else
                count <= count + 1;
                clkout <= '0';
            end if;
        end if;
    end process;
end arch;