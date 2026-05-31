# =============================================================
# Skrypt symulacji dla Questa / ModelSim
#
# Uruchomienie:
#   1. Otworz Questa (Intel FPGA) lub ModelSim.
#   2. Ustaw katalog roboczy na katalog projektu (tam gdzie sa pliki .vhd):
#        cd {d:/procesor}
#   3. W oknie Transcript wpisz:
#        do run_tests.do
#
# Skrypt kompiluje caly projekt i uruchamia po kolei oba testbenche:
#   - alu_tb  (test jednostkowy ALU: wszystkie operacje + flagi)
#   - cpu_tb  (test end-to-end: rA=7, rB=2, ADD => 0009)
#
# Wynik: w Transcripcie szukaj linii "WSZYSTKIE TESTY PRZESZLY".
# Kazdy blad jest raportowany jako "FAIL [...]".
# =============================================================

# Swieza biblioteka roboczra
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

# Kompilacja zrodel (VHDL-93, zgodnie z projektem Quartus)
vcom -93 -work work hex_display.vhd
vcom -93 -work work alu.vhd
vcom -93 -work work busint.vhd
vcom -93 -work work ram.vhd
vcom -93 -work work register_cpu.vhd
vcom -93 -work work CPU.vhd

# Kompilacja testbenchy
vcom -93 -work work alu_tb.vhd
vcom -93 -work work cpu_tb.vhd

# ---------------- TEST 1: ALU ----------------
echo "========================================="
echo " URUCHAMIAM alu_tb"
echo "========================================="
vsim -voptargs="+acc" work.alu_tb
add wave -r /*
run -all

# ---------------- TEST 2: CPU (end-to-end) ----------------
echo "========================================="
echo " URUCHAMIAM cpu_tb"
echo "========================================="
vsim -voptargs="+acc" work.cpu_tb
add wave -r /*
run -all

echo "========================================="
echo " KONIEC. Sprawdz powyzej komunikaty PASS/FAIL."
echo "========================================="
