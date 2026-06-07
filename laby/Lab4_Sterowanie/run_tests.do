# Lab 4 — Jednostka sterujaca control (test jednostkowy)
# Uruchomienie w QuestaSim:
#   cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/laby/Lab4_Sterowanie}
#   do run_tests.do

if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

vcom -93 -work work control.vhd
vcom -93 -work work control_tb.vhd

echo "========================================="
echo " LAB 4: control_tb"
echo "========================================="
vsim -voptargs="+acc" work.control_tb
add wave -r /*
run -all

echo "========================================="
echo " KONIEC LAB 4. Szukaj: CONTROL_TB: WSZYSTKIE TESTY PRZESZLY"
echo "========================================="
