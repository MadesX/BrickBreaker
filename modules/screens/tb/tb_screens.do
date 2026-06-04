transcript off
onerror abort
echo "------- START OF SCRIPT -------"

;# Test bench style (VHDL) - screens
vcom buttons_screen.vhd
vcom txtgen_screen.vhd
vcom lpm_or_r.vhd
vcom lpm_or_g.vhd
vcom lpm_or_b.vhd
vcom pipe.vhd
vcom dup4.vhd
vcom chrgen8.vhd
vcom screens.vhd
vcom tb_screens.vhd
vsim tb_screens

restart -force
noview *

add wave *

run 50 ms

;# =============== end of stimulus section ===============

puts "choosing a zoom-full timing range:"
wave zoomfull
echo "---------------------- END OF SCRIPT ------------------------"
echo "The time now is $now [ string trim $resolution 01 ] "