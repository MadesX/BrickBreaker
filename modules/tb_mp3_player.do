transcript off
onerror abort
echo "------- START OF SCRIPT -------"

;# Test bench style (VHDL) - mp3_player
vcom bytes_to_mp3.vhd
vcom uart.vhd
vcom mp3_player.vhd
vcom tb_mp3_player.vhd
vsim tb_mp3_player

restart -force
noview *

add wave *

run 10 ms

;# =============== end of stimulus section ===============

puts "choosing a zoom-full timing range:"
wave zoomfull
echo "---------------------- END OF SCRIPT ------------------------"
echo "The time now is $now [ string trim $resolution 01 ] "