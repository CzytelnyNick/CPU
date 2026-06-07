# Lab 3 — busint + RAM (test jednostkowy)
# Uruchomienie w QuestaSim:
#   cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/laby/Lab3_Pamiec}
#   do run_tests.do

if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

vcom -93 -work work busint.vhd
vcom -93 -work work ram.vhd
vcom -93 -work work memory_tb.vhd

echo "========================================="
echo " LAB 3: memory_tb"
echo "========================================="
vsim -voptargs="+acc" work.memory_tb
add wave -r /*
run -all

echo "========================================="
echo " KONIEC LAB 3. Szukaj: MEMORY_TB: WSZYSTKIE TESTY PRZESZLY"
echo "========================================="
