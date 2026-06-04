transcript off
onerror abort
echo "------- START OF SCRIPT -------"

;# Test bench style (VHDL) - brickbreaker
vcom hexcon.vhd
vcom pulse_reg.vhd
vcom freq_div.vhd
vcom vgasync.vhd
vcom pipe.vhd
vcom screen_menu.vhd
vcom breakout_single.vhd
vcom breakout_two_player.vhd
vcom screens.vhd
vcom mp3_player.vhd
vcom tb_brickbreaker.vhd
vsim tb_brickbreaker

restart -force
noview *

add wave *

run 200 ms

;# =============== end of stimulus section ===============

puts "choosing a zoom-full timing range:"
wave zoomfull
echo "---------------------- END OF SCRIPT ------------------------"
echo "The time now is $now [ string trim $resolution 01 ] "