transcript off
onerror abort
echo "------- START OF SCRIPT -------"

;# Test bench style (VHDL) - breakout_two_player
vcom freq_div_game.vhd
vcom paddle_two_player.vhd
vcom bricks_two_player.vhd
vcom ball_two_player.vhd
vcom breakout_two_player.vhd
vcom tb_breakout_two_player.vhd
vsim tb_breakout_two_player

restart -force
noview *

add wave *

run 50 ms

;# =============== end of stimulus section ===============

puts "choosing a zoom-full timing range:"
wave zoomfull
echo "---------------------- END OF SCRIPT ------------------------"
echo "The time now is $now [ string trim $resolution 01 ] "