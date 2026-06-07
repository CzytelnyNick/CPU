# Lab 1 — ALU (test jednostkowy)
# Uruchomienie w QuestaSim:
#   cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/laby/Lab1_ALU}
#   do run_tests.do

if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

vcom -93 -work work alu.vhd
vcom -93 -work work alu_tb.vhd

echo "========================================="
echo " LAB 1: alu_tb"
echo "========================================="
vsim -voptargs="+acc" work.alu_tb
add wave -r /*
run -all

echo "========================================="
echo " KONIEC LAB 1. Szukaj: ALU_TB: WSZYSTKIE TESTY PRZESZLY"
echo "========================================="
