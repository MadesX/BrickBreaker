transcript off
onerror abort
echo "------- START OF SCRIPT -------"

;# Test bench style (VHDL) - screen_menu
vcom buttons_menu.vhd
vcom lpm_or_r.vhd
vcom lpm_or_g.vhd
vcom lpm_or_b.vhd
vcom txtgen_menu.vhd
vcom pipe.vhd
vcom dup4.vhd
vcom chrgen8.vhd
vcom screen_menu.vhd
vcom tb_screen_menu.vhd
vsim tb_screen_menu

restart -force
noview *

add wave *

run 50 ms

;# =============== end of stimulus section ===============

puts "choosing a zoom-full timing range:"
wave zoomfull
echo "---------------------- END OF SCRIPT ------------------------"
echo "The time now is $now [ string trim $resolution 01 ] "