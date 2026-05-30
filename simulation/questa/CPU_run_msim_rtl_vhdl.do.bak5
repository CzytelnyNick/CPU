transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/hex_display.vhd}
vcom -93 -work work {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/alu.vhd}
vcom -93 -work work {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/busint.vhd}
vcom -93 -work work {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/ram.vhd}
vcom -93 -work work {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/register_cpu.vhd}
vcom -93 -work work {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/CPU.vhd}

vcom -93 -work work {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/cpu_tb.vhd}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L cyclonev -L cyclonev_hssi -L rtl_work -L work -voptargs="+acc"  cpu_tb

add wave *
view structure
view signals
run -all
