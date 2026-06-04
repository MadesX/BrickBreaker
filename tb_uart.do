transcript off
onerror abort
echo "------- START OF SCRIPT -------"

;# Test bench style (VHDL) - UART
vcom receiver.vhd
vcom transmitter.vhd
vcom uart.vhd
vcom tb_uart.vhd
vsim tb_uart

restart -force
noview *

add wave *

run 5 ms

;# =============== end of stimulus section ===============

puts "choosing a zoom-full timing range:"
wave zoomfull
echo "---------------------- END OF SCRIPT ------------------------"
echo "The time now is $now [ string trim $resolution 01 ] "