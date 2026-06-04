library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity buttons_menu is
    port (
        clk_50              : in  std_logic;							-- 50 MHz clock
        clk_25              : in  std_logic;							-- 25 MHz clock
        resetN              : in  std_logic;							-- Active-low
        clrN                : in  std_logic;							-- Active-low
        count_v             : in  std_logic_vector(9 downto 0);
        count_h             : in  std_logic_vector(9 downto 0);
        enable              : in  std_logic;							-- '1' to view on screen
        up, down, sel       : in  std_logic;							-- Active-high
        vga_r, vga_g, vga_b : out std_logic_vector(3 downto 0);	
        next_stage          : out std_logic_vector(1 downto 0) := "00"	-- "01" for 1st button , "10" for 2nd button
    );
end buttons_menu;

architecture arch_buttons_menu of buttons_menu is
    constant BUTTON_X      : integer := 270;   	-- Left of buttons
    constant BUTTON_WIDTH  : integer := 112;
    constant BUTTON_HEIGHT : integer := 30;
    constant BUTTON_1_Y    : integer := 270;  	-- Top of 1st button
    constant BUTTON_2_Y    : integer := 334;    -- Top of 2nd button

    -- Button selection state
    type button_state is (RESTART, MENU);
    signal current_button : button_state := RESTART;
	
    signal up_debounced, down_debounced, select_debounced : std_logic := '1';
    signal counter_up, counter_down, counter_select       : integer   := 0;
    constant DEBOUNCE_LIMIT                               : integer   := 1000000;  -- 20 ms at 50 MHz
begin
    -- Debouncing for up, down, sel keys
    process (clk_50, resetN)
    begin
        if resetN = '0' or clrN = '0' then
            up_debounced     <= '1';
            down_debounced   <= '1';
            select_debounced <= '1';
            counter_up       <= 0;
            counter_down     <= 0;
            counter_select   <= 0;
        elsif rising_edge(clk_50) then
            -- Debounce up
            if up = '1' and counter_up < DEBOUNCE_LIMIT then
                counter_up <= counter_up + 1;
                if counter_up = DEBOUNCE_LIMIT - 1 then
                    up_debounced <= '0';
                end if;
            elsif up = '0' then
                counter_up   <= 0;
                up_debounced <= '1';
            end if;
            -- Debounce down
            if down = '1' and counter_down < DEBOUNCE_LIMIT then
                counter_down <= counter_down + 1;
                if counter_down = DEBOUNCE_LIMIT - 1 then
                    down_debounced <= '0';
                end if;
            elsif down = '0' then
                counter_down   <= 0;
                down_debounced <= '1';
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
    process (clk_50, resetN)
    begin
        if resetN = '0' or clrN = '0' then
            current_button <= RESTART;
            next_stage     <= "00";
        elsif rising_edge(clk_50) then
            if up_debounced = '0' then
                current_button <= RESTART;
            elsif down_debounced = '0' then
                current_button <= MENU;
            elsif select_debounced = '0' then
                if current_button = RESTART then
                    next_stage <= "01";
                else
                    next_stage <= "10";
                end if;
            end if;
        end if;
    end process;

    -- VGA rendering for buttons 
    process (clk_25)
    begin
        if rising_edge(clk_25) then
            vga_r <= "0000";
            vga_g <= "0000";
            vga_b <= "0000";
            if enable = '1' then
                -- "Restart" button
                if count_h >= BUTTON_X and count_h < BUTTON_X + BUTTON_WIDTH and
                   count_v >= BUTTON_1_Y and count_v < BUTTON_1_Y + BUTTON_HEIGHT then
                    if current_button = RESTART then
                        vga_r <= "0000"; vga_g <= "0110"; vga_b <= "0000";  -- Green for selected
                    else
                        vga_r <= "1000"; vga_g <= "1000"; vga_b <= "1000";  -- Gray for unselected
                    end if;
                -- "Restart" button border (2-pixel white border when selected)
                elsif current_button = RESTART and
                      ((count_h >= BUTTON_X - 2 and count_h < BUTTON_X + BUTTON_WIDTH + 2 and
                        count_v >= BUTTON_1_Y - 2 and count_v < BUTTON_1_Y) or
                       (count_h >= BUTTON_X - 2 and count_h < BUTTON_X + BUTTON_WIDTH + 2 and
                        count_v >= BUTTON_1_Y + BUTTON_HEIGHT and count_v < BUTTON_1_Y + BUTTON_HEIGHT + 2) or
                       (count_h >= BUTTON_X - 2 and count_h < BUTTON_X and
                        count_v >= BUTTON_1_Y - 2 and count_v < BUTTON_1_Y + BUTTON_HEIGHT + 2) or
                       (count_h >= BUTTON_X + BUTTON_WIDTH and count_h < BUTTON_X + BUTTON_WIDTH + 2 and
                        count_v >= BUTTON_1_Y - 2 and count_v < BUTTON_1_Y + BUTTON_HEIGHT + 2)) then
                    vga_r <= "1111"; vga_g <= "1111"; vga_b <= "1111";  -- White border
                end if;

                -- "Menu" button
                if count_h >= BUTTON_X and count_h < BUTTON_X + BUTTON_WIDTH and
                   count_v >= BUTTON_2_Y and count_v < BUTTON_2_Y + BUTTON_HEIGHT then
                    if current_button = MENU then
                        vga_r <= "0000"; vga_g <= "0110"; vga_b <= "0000";  -- Green for selected
                    else
                        vga_r <= "1000"; vga_g <= "1000"; vga_b <= "1000";  -- Gray for unselected
                    end if;
                -- "Menu" button border (2-pixel white border when selected)
                elsif current_button = MENU and
                      ((count_h >= BUTTON_X - 2 and count_h < BUTTON_X + BUTTON_WIDTH + 2 and
                        count_v >= BUTTON_2_Y - 2 and count_v < BUTTON_2_Y) or
                       (count_h >= BUTTON_X - 2 and count_h < BUTTON_X + BUTTON_WIDTH + 2 and
                        count_v >= BUTTON_2_Y + BUTTON_HEIGHT and count_v < BUTTON_2_Y + BUTTON_HEIGHT + 2) or
                       (count_h >= BUTTON_X - 2 and count_h < BUTTON_X and
                        count_v >= BUTTON_2_Y - 2 and count_v < BUTTON_2_Y + BUTTON_HEIGHT + 2) or
                       (count_h >= BUTTON_X + BUTTON_WIDTH and count_h < BUTTON_X + BUTTON_WIDTH + 2 and
                        count_v >= BUTTON_2_Y - 2 and count_v < BUTTON_2_Y + BUTTON_HEIGHT + 2)) then
                    vga_r <= "1111"; vga_g <= "1111"; vga_b <= "1111";  -- White border
                end if;
            end if;
        end if;
    end process;
end arch_buttons_menu;
