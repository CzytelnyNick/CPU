# Lab 2 — Plik rejestrow (test jednostkowy)
# Uruchomienie w QuestaSim:
#   cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/laby/Lab2_Rejestry}
#   do run_tests.do

if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

vcom -93 -work work register_cpu.vhd
vcom -93 -work work register_cpu_tb.vhd

echo "========================================="
echo " LAB 2: register_cpu_tb"
echo "========================================="
vsim -voptargs="+acc" work.register_cpu_tb
add wave -r /*
run -all

echo "========================================="
echo " KONIEC LAB 2. Szukaj: REGISTER_CPU_TB: WSZYSTKIE TESTY PRZESZLY"
echo "========================================="
