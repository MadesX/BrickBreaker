library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bricks_two_player is
   generic ( BRICK_WIDTH   : integer := 60;
             BRICK_HEIGHT  : integer := 20;
             BALL_SIZE     : integer := 8;
             BRICK_START_Y : integer := 180 );
   port (
        clk             : in std_logic;
        resetN          : in std_logic;
        clrN            : in std_logic;
        ball_x, ball_y  : in unsigned(9 downto 0);
        brick_hit       : out std_logic;
        brick_matrix    : out std_logic_vector(0 to 31);  -- 8x4 grid
        brick_count_out : out std_logic_vector(5 downto 0)
   );
end bricks_two_player;

architecture arch of bricks_two_player is
   signal matrix : std_logic_vector(0 to 31) := (others => '0');
   type int_array is array (0 to 3) of integer;
begin
    process (clk, resetN)
        variable temp_matrix : std_logic_vector(0 to 31);
        variable lfsr : std_logic_vector(15 downto 0);
        variable feedback : std_logic;
        variable brick_count : integer range 0 to 32 := 0;
        variable row_count : int_array := (others => 0);
        variable rand_index : integer range 0 to 31;
    begin
        if resetN = '0' or clrN = '0' then
            temp_matrix := (others => '0');
            lfsr := "1011010110011011";  -- Fixed seed
            brick_count := 0;
            row_count := (others => 0);
            -- Phase 1: Ensure at least 15 bricks
            for i in 0 to 31 loop
                if brick_count < 15 then
                    feedback := lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10);
                    lfsr := lfsr(14 downto 0) & feedback;
                    if lfsr /= "0000000000000000" then
                        rand_index := to_integer(unsigned(lfsr(4 downto 0))) mod 32;
                        if temp_matrix(rand_index) = '0' and row_count(rand_index/8) < 6 then
                            temp_matrix(rand_index) := '1';
                            brick_count := brick_count + 1;
                            row_count(rand_index/8) := row_count(rand_index/8) + 1;
                        end if;
                    end if;
                end if;
            end loop;
            -- Phase 2: Add up to 24 bricks
            for i in 0 to 31 loop
                if brick_count < 24 then
                    feedback := lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10);
                    lfsr := lfsr(14 downto 0) & feedback;
                    if lfsr /= "0000000000000000" then
                        rand_index := to_integer(unsigned(lfsr(4 downto 0))) mod 32;
                        if temp_matrix(rand_index) = '0' and row_count(rand_index/8) < 6 then
                            temp_matrix(rand_index) := '1';
                            brick_count := brick_count + 1;
                            row_count(rand_index/8) := row_count(rand_index/8) + 1;
                        end if;
                    end if;
                end if;
            end loop;
            matrix <= temp_matrix;
            brick_count_out <= std_logic_vector(to_unsigned(brick_count, 6));
            brick_hit <= '0';
        elsif rising_edge(clk) then
            brick_hit <= '0';
            for i in 0 to 31 loop
                if matrix(i) = '1' and
                   ball_x + BALL_SIZE >= (i mod 8) * (BRICK_WIDTH + 10) + 60 and
                   ball_x <= (i mod 8) * (BRICK_WIDTH + 10) + 120 and
                   ball_y + BALL_SIZE >= (i/8) * (BRICK_HEIGHT + 10) + BRICK_START_Y and
                   ball_y <= (i/8) * (BRICK_HEIGHT + 10) + BRICK_START_Y + BRICK_HEIGHT then
                    matrix(i) <= '0';
                    brick_hit <= '1';
                end if;
            end loop;
            brick_count_out <= std_logic_vector(to_unsigned(brick_count, 6));
        end if;
    end process;
    brick_matrix <= matrix;
end arch;