transcript off
onerror abort
echo "------- START OF SCRIPT -------"

;# Test bench style (VHDL) - breakout_single
vcom freq_div_game.vhd
vcom paddle.vhd
vcom bricks.vhd
vcom ball.vhd
vcom breakout_single.vhd
vcom tb_breakout_single.vhd
vsim tb_breakout_single

restart -force
noview *

add wave *

run 50 ms

;# =============== end of stimulus section ===============

puts "choosing a zoom-full timing range:"
wave zoomfull
echo "---------------------- END OF SCRIPT ------------------------"
echo "The time now is $now [ string trim $resolution 01 ] "