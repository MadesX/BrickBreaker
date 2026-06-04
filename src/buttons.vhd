library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all ;
use ieee.numeric_std.all;

entity buttons is
    port (
        clk_50              : in std_logic;
        clk_25              : in std_logic;
        reset               : in std_logic;  -- Active-high (DE0 KEY[3])
		count_v   : in    std_logic_vector(9 downto 0) ;
        count_h   : in    std_logic_vector(9 downto 0) ;
        enable              : in std_logic;
        left, right, sel : in std_logic;  -- Active-low (KEY[1], KEY[0], KEY[2])
        vga_r, vga_g, vga_b : out std_logic_vector(3 downto 0);
        restart_game        : out std_logic;  -- '1' when Restart selected
        to_menu             : out std_logic   -- '1' when Menu selected
    );
end buttons;

architecture arch of buttons is
    constant BUTTON_Y : integer := 300;  -- Top of buttons
    constant BUTTON_WIDTH : integer := 80;
    constant BUTTON_HEIGHT : integer := 40;
    constant RESTART_X : integer := 200;  -- Left of "Restart" button
    constant MENU_X : integer := 360;    -- Left of "Menu" button

    -- Button selection state
    type button_state is (RESTART, MENU);
    signal current_button : button_state := RESTART;
    signal left_debounced, right_debounced, select_debounced : std_logic := '1';
    signal counter_left, counter_right, counter_select : integer := 0;
    constant DEBOUNCE_LIMIT : integer := 1000000;  -- 20 ms at 50 MHz
begin
    -- Debouncing for left, right, sel keys
    process (clk_50, reset)
    begin
        if reset = '1' then
            left_debounced <= '1';
            right_debounced <= '1';
            select_debounced <= '1';
            counter_left <= 0;
            counter_right <= 0;
            counter_select <= 0;
        elsif rising_edge(clk_50) then
            -- Debounce left
            if left = '0' and counter_left < DEBOUNCE_LIMIT then
                counter_left <= counter_left + 1;
                if counter_left = DEBOUNCE_LIMIT - 1 then
                    left_debounced <= '0';
                end if;
            elsif left = '1' then
                counter_left <= 0;
                left_debounced <= '1';
            end if;
            -- Debounce right
            if right = '0' and counter_right < DEBOUNCE_LIMIT then
                counter_right <= counter_right + 1;
                if counter_right = DEBOUNCE_LIMIT - 1 then
                    right_debounced <= '0';
                end if;
            elsif right = '1' then
                counter_right <= 0;
                right_debounced <= '1';
            end if;
            -- Debounce sel
            if sel = '0' and counter_select < DEBOUNCE_LIMIT then
                counter_select <= counter_select + 1;
                if counter_select = DEBOUNCE_LIMIT - 1 then
                    select_debounced <= '0';
                end if;
            elsif sel = '1' then
                counter_select <= 0;
                select_debounced <= '1';
            end if;
        end if;
    end process;

    -- Button selection logic
    process (clk_50, reset)
    begin
        if reset = '1' then
            current_button <= RESTART;
            restart_game <= '0';
            to_menu <= '0';
        elsif rising_edge(clk_50) then
            restart_game <= '0';
            to_menu <= '0';
            if left_debounced = '0' then
                current_button <= RESTART;
            elsif right_debounced = '0' then
                current_button <= MENU;
            elsif select_debounced = '0' then
                if current_button = RESTART then
                    restart_game <= '1';
                else
                    to_menu <= '1';
                end if;
            end if;
        end if;
    end process;

    -- VGA rendering for buttons only
    process (clk_25)
    begin
        if rising_edge(clk_25) then
            vga_r <= "0000";
            vga_g <= "0000";
            vga_b <= "0000";
            if enable = '1' then
                -- "Restart" button (x=200 to 280, y=300 to 340)
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

                -- "Menu" button (x=360 to 440, y=300 to 340)
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
end arch;