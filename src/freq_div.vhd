library ieee;
use ieee.std_logic_1164.all;

entity freq_div is
    port (
        clkin : in std_logic;
        clkout : out std_logic
    );
end freq_div;

architecture arch of freq_div is
    signal count : std_logic := '0';
begin
    process (clkin)
    begin
        if rising_edge(clkin) then
            count <= not count;
        end if;
    end process;
    clkout <= count;
end arch;