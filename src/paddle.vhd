library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity paddle is
   generic ( PAD_WIDTH    : integer := 80;
             SCREEN_WIDTH : integer := 640  );
   port (
        clk : in std_logic;  		 	-- Game clock (~60 Hz)
        resetN : in std_logic;
        clrN   : in std_logic;
        left, right : in std_logic;		-- Active-high
        pos_x : out unsigned(9 downto 0);
        pos_y : out unsigned(9 downto 0)
   );
end paddle;

architecture arch of paddle is
    signal x_reg : unsigned(9 downto 0) := to_unsigned((SCREEN_WIDTH - PAD_WIDTH)/2 -40, 10);
    constant PADDLE_Y : unsigned(9 downto 0) := to_unsigned(460, 10);
begin
    process (clk, resetN)
    begin
        if resetN = '0' or clrN = '0' then
            x_reg <= to_unsigned((SCREEN_WIDTH - PAD_WIDTH)/2, 10);
        elsif rising_edge(clk) then
            if left = '1' and x_reg > 0 then
                x_reg <= x_reg - 4;
            elsif right = '1' and x_reg < SCREEN_WIDTH - PAD_WIDTH then
                x_reg <= x_reg + 4;
            end if;
        end if;
    end process;
    pos_x <= x_reg;
    pos_y <= PADDLE_Y;
end arch;