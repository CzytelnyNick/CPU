# Uruchamia wszystkie 4 laboratoria po kolei.
# W QuestaSim (Transcript):
#   cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/laby}
#   do run_all_tests.do

set LAB_ROOT {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/laby}

echo "#########################################"
echo " URUCHAMIAM WSZYSTKIE LABY (1-4)"
echo "#########################################"

cd $LAB_ROOT/Lab1_ALU
do run_tests.do

cd $LAB_ROOT/Lab2_Rejestry
do run_tests.do

cd $LAB_ROOT/Lab3_Pamiec
do run_tests.do

cd $LAB_ROOT/Lab4_Sterowanie
do run_tests.do

echo "#########################################"
echo " KONIEC WSZYSTKICH LABOW"
echo " Sprawdz w Transcript 4 komunikaty:"
echo "   ALU_TB: WSZYSTKIE TESTY PRZESZLY"
echo "   REGISTER_CPU_TB: WSZYSTKIE TESTY PRZESZLY"
echo "   MEMORY_TB: WSZYSTKIE TESTY PRZESZLY"
echo "   CONTROL_TB: WSZYSTKIE TESTY PRZESZLY"
echo "#########################################"
