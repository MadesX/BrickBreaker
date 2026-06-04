library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all ;
use ieee.numeric_std.all;

entity buttons_screen is
    port (
        clk_50              : in  std_logic;							         -- 50MHz Clock
        clk_25              : in  std_logic;							         -- 25MHz Clock
        resetN              : in  std_logic;  						         -- Active-low
        clrN                : in  std_logic;							         -- Active-low
		  count_v             : in  std_logic_vector(9 downto 0) ;
        count_h             : in  std_logic_vector(9 downto 0) ;
        enable              : in  std_logic;							         -- '1' to view on screen
        left, right, sel    : in  std_logic;  						         -- Active-high
        vga_r, vga_g, vga_b : out std_logic_vector(3 downto 0);
        next_stage          : out std_logic_vector(1 downto 0) := "11"	-- "01" or "10" for 1st button , "00" for 2nd button
    );
end buttons_screen;

architecture arch_buttons_screen of buttons_screen is
    constant BUTTON_Y      : integer := 300;  	-- Top of buttons_screen
    constant BUTTON_WIDTH  : integer := 112;
    constant BUTTON_HEIGHT : integer := 30;
    constant RESTART_X     : integer := 190;  	-- Left of "Restart" button
    constant MENU_X        : integer := 350;    -- Left of "Menu" button

    -- Button selection state
    type button_state is (RESTART, MENU);
    signal current_button : button_state := RESTART;
    
    signal left_debounced, right_debounced, select_debounced : std_logic := '1';
    signal counter_left, counter_right, counter_select       : integer   := 0;
    constant DEBOUNCE_LIMIT                                  : integer   := 1000000;  -- 20 ms at 50 MHz
begin
    -- Debouncing for left, right, sel keys
    process (clk_50, resetN)
    begin
        if resetN = '0' or clrN = '0' then
            left_debounced   <= '1';
            right_debounced  <= '1';
            select_debounced <= '1';
            counter_left     <= 0;
            counter_right    <= 0;
            counter_select   <= 0;
        elsif rising_edge(clk_50) then
            -- Debounce left
            if left = '1' and counter_left < DEBOUNCE_LIMIT then
                counter_left <= counter_left + 1;
                if counter_left = DEBOUNCE_LIMIT - 1 then
                    left_debounced <= '0';
                end if;
            elsif left = '0' then
                counter_left   <= 0;
                left_debounced <= '1';
            end if;
            -- Debounce right
            if right = '1' and counter_right < DEBOUNCE_LIMIT then
                counter_right <= counter_right + 1;
                if counter_right = DEBOUNCE_LIMIT - 1 then
                    right_debounced <= '0';
                end if;
            elsif right = '0' then
                counter_right   <= 0;
                right_debounced <= '1';
            end if;
            -- Debounce sel
            if sel = '1' and counter_select < DEBOUNCE_LIMIT then
                counter_select <= counter_select + 1;
                if counter_select = DEBOUNCE_LIMIT - 1 then
                    select_debounced <= '0';
                end if;
            elsif sel = '0' then
                counter_select   <= 0;
                select_debounced <= '1';
            end if;
        end if;
    end process;

    -- Button selection logic
    process (clk_50, resetN, enable)
    begin
        if resetN = '0' or clrN = '0' then
            current_button <= RESTART;
            next_stage 	   <= "11";
        elsif rising_edge(clk_50) and enable = '1' then
            if left_debounced = '0' then
                current_button <= RESTART;
            elsif right_debounced = '0' then
                current_button <= MENU;
            elsif select_debounced = '0' then
                if current_button = RESTART then
                    next_stage <= "01";
                else
                    next_stage <= "00";
                end if;
            end if;
        end if;
    end process;

    -- VGA rendering for buttons_screen
    process (clk_25, enable)
    begin
        if rising_edge(clk_25) then
            vga_r <= "0000";
            vga_g <= "0000";
            vga_b <= "0000";
            if enable = '1' then
                -- "Restart" button
                if count_h >= RESTART_X and count_h < RESTART_X + BUTTON_WIDTH and
                   count_v >= BUTTON_Y and count_v < BUTTON_Y + BUTTON_HEIGHT then
                    if current_button = RESTART then
                        vga_r <= "0000"; vga_g <= "0110"; vga_b <= "0000";  -- Green for selected
                    else
                        vga_r <= "1000"; vga_g <= "1000"; vga_b <= "1000";  -- Gray for unselected
                    end if;
                -- "Restart" button border (2-pixel white border when selected)
                elsif current_button = RESTART and
                      ((count_h >= RESTART_X - 2 and count_h < RESTART_X + BUTTON_WIDTH + 2 and
                        count_v >= BUTTON_Y - 2 and count_v < BUTTON_Y) or
                       (count_h >= RESTART_X - 2 and count_h < RESTART_X + BUTTON_WIDTH + 2 and
                        count_v >= BUTTON_Y + BUTTON_HEIGHT and count_v < BUTTON_Y + BUTTON_HEIGHT + 2) or
                       (count_h >= RESTART_X - 2 and count_h < RESTART_X and
                        count_v >= BUTTON_Y - 2 and count_v < BUTTON_Y + BUTTON_HEIGHT + 2) or
                       (count_h >= RESTART_X + BUTTON_WIDTH and count_h < RESTART_X + BUTTON_WIDTH + 2 and
                        count_v >= BUTTON_Y - 2 and count_v < BUTTON_Y + BUTTON_HEIGHT + 2)) then
                    vga_r <= "1111"; vga_g <= "1111"; vga_b <= "1111";  -- White border
                end if;

                -- "Menu" button
                if count_h >= MENU_X and count_h < MENU_X + BUTTON_WIDTH and
                   count_v >= BUTTON_Y and count_v < BUTTON_Y + BUTTON_HEIGHT then
                    if current_button = MENU then
                        vga_r <= "0000"; vga_g <= "0110"; vga_b <= "0000";  -- Green for selected
                    else
                        vga_r <= "1000"; vga_g <= "1000"; vga_b <= "1000";  -- Gray for unselected
                    end if;
                -- "Menu" button border (2-pixel white border when selected)
                elsif current_button = MENU and
                      ((count_h >= MENU_X - 2 and count_h < MENU_X + BUTTON_WIDTH + 2 and
                        count_v >= BUTTON_Y - 2 and count_v < BUTTON_Y) or
                       (count_h >= MENU_X - 2 and count_h < MENU_X + BUTTON_WIDTH + 2 and
                        count_v >= BUTTON_Y + BUTTON_HEIGHT and count_v < BUTTON_Y + BUTTON_HEIGHT + 2) or
                       (count_h >= MENU_X - 2 and count_h < MENU_X and
                        count_v >= BUTTON_Y - 2 and count_v < BUTTON_Y + BUTTON_HEIGHT + 2) or
                       (count_h >= MENU_X + BUTTON_WIDTH and count_h < MENU_X + BUTTON_WIDTH + 2 and
                        count_v >= BUTTON_Y - 2 and count_v < BUTTON_Y + BUTTON_HEIGHT + 2)) then
                    vga_r <= "1111"; vga_g <= "1111"; vga_b <= "1111";  -- White border
                end if;
            end if;
        end if;
    end process;
end arch_buttons_screen;