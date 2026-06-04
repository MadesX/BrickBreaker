transcript off
onerror abort
echo "------- START OF SCRIPT -------"

;# Test bench style (VHDL) - hexcon
vcom rise.vhd
vcom uart.vhd
vcom bytes2reg.vhd
vcom reg2bytes.vhd
vcom hexcon.vhd
vcom tb_hexcon.vhd
vsim tb_hexcon

restart -force
noview *

add wave *

run 15 ms

;# =============== end of stimulus section ===============

puts "choosing a zoom-full timing range:"
wave zoomfull
echo "---------------------- END OF SCRIPT ------------------------"
echo "The time now is $now [ string trim $resolution 01 ] "