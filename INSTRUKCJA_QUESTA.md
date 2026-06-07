# Instrukcja testów QuestaSim — CPU 16-bit

Kompletny przewodnik po testowaniu projektu w **Questa / ModelSim (Intel FPGA)**.
Wszystkie wartości ustawiasz komendami TCL w oknie **Transcript**.

---

## Spis treści

1. [Uruchomienie symulacji](#1-uruchomienie-symulacji)
2. [Testy automatyczne](#2-testy-automatyczne)
3. [Pomocnicze procedury TCL](#3-pomocnicze-procedury-tcl)
4. [Legenda SW i KEY](#4-legenda-sw-i-key)
5. [Test ręczny CPU — 7 + 2](#5-test-ręczny-cpu--7--2)
6. [Wszystkie operacje ALU (CPU)](#6-wszystkie-operacje-alu-cpu)
7. [Test jednostkowy ALU](#7-test-jednostkowy-alu)
8. [Sygnały do obserwacji](#8-sygnały-do-obserwacji)
9. [Rozwiązywanie problemów](#9-rozwiązywanie-problemów)

---

## 1. Uruchomienie symulacji

### Krok 1 — ustaw katalog roboczy

W Transcript wpisz (dostosuj ścieżkę, jeśli projekt leży gdzie indziej):

```tcl
cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU}
```

### Krok 2 — wybierz tryb symulacji

| Tryb | Entity | Kiedy używać |
|------|--------|--------------|
| **A — top-level CPU** | `work.CPU` | Ręczne testy jak na płytce (`force` na SW/KEY) |
| **B — testbench CPU** | `work.cpu_tb` | Scenariusz end-to-end z assertami |
| **C — testbench ALU** | `work.alu_tb` | Szybki test wszystkich 16 operacji ALU |

#### Tryb A — symulacja CPU (ręczne testy)

```tcl
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

vcom -93 -work work hex_display.vhd
vcom -93 -work work alu.vhd
vcom -93 -work work busint.vhd
vcom -93 -work work ram.vhd
vcom -93 -work work register_cpu.vhd
vcom -93 -work work CPU.vhd

vsim -voptargs=+acc work.CPU
add wave -r sim:/CPU/*
```

Ścieżki sygnałów: `sim:/CPU/SW`, `sim:/CPU/KEY`, `sim:/CPU/reg_BB`, itd.

#### Tryb B / C — testbenche

```tcl
do run_tests.do
```

albo tylko jeden testbench:

```tcl
vcom -93 -work work cpu_tb.vhd
vsim -voptargs=+acc work.cpu_tb
add wave -r sim:/cpu_tb/*
run -all
```

Ścieżki przez testbench: `sim:/cpu_tb/uut/SW`, `sim:/cpu_tb/uut/reg_BB`, itd.

---

## 2. Testy automatyczne

Plik `run_tests.do` kompiluje projekt i uruchamia po kolei:

| Testbench | Co sprawdza |
|-----------|-------------|
| `alu_tb` | Wszystkie 16 operacji ALU + flagi C, Z, S, P |
| `cpu_tb` | End-to-end: rA=7, rB=2, ADD=9, zapis do rA |

```tcl
cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU}
do run_tests.do
```

**Sukces** — w Transcript szukaj:

```
=== ALU_TB: WSZYSTKIE TESTY PRZESZLY ===
=== CPU_TB: WSZYSTKIE TESTY PRZESZLY ===
```

**Błąd** — linie zaczynające się od `FAIL [...]`.

---

## 3. Pomocnicze procedury TCL

Wklej raz na początku sesji ręcznej (tryb A). Ułatwiają sterowanie jak przyciskami na płytce.

```tcl
# Impuls zegara: KEY[0] puszczony -> wciśnięty -> puszczony
# (zbocze narastające clk, bo clk = not KEY[0])
proc tick {} {
    force sim:/CPU/KEY 10
    run 20ns
    force sim:/CPU/KEY 11
    run 20ns
}

# Reset asynchroniczny przez KEY[1]
proc reset_cpu {} {
    force sim:/CPU/SW  0000000000
    force sim:/CPU/KEY 01
    run 40ns
    force sim:/CPU/KEY 11
    run 40ns
}

# Ustaw SW i odczekaj propagację
proc set_sw {val} {
    force sim:/CPU/SW $val
    run 20ns
}

# Ustaw SW + jeden cykl zegara
proc set_sw_tick {val} {
    set_sw $val
    tick
}

# Szybki podgląd kluczowych sygnałów
proc peek {} {
    echo "reg_BB (rA) = [examine -radix bin sim:/CPU/reg_BB]"
    echo "reg_BC (rB) = [examine -radix bin sim:/CPU/reg_BC]"
    echo "alu_Y       = [examine -radix hex sim:/CPU/alu_Y]"
    echo "disp_Y      = [examine -radix hex sim:/CPU/disp_Y]"
    echo "flagi CZSP  = [examine sim:/CPU/disp_C][examine sim:/CPU/disp_Z][examine sim:/CPU/disp_S][examine sim:/CPU/disp_P]"
}
```

> **Wersja dla testbencha** — zamień `sim:/CPU/` na `sim:/cpu_tb/uut/` we wszystkich procedurach.

---

## 4. Legenda SW i KEY

### Przełączniki SW[9:0]

```
SW[9]   = DST  — rejestr docelowy zapisu: 0=rA, 1=rB
SW[8]   = WEN  — zapis wyniku do rejestru: 1=tak, 0=nie (podgląd)
SW[7:6] = Sbc  — argument 2 ALU (BC): 00=rA, 01=rB, 10=rC, 11=DI
SW[5:4] = Sbb  — argument 1 ALU (BB): 00=rA, 01=rB, 10=rC, 11=DI
SW[3:0] = S_ALU — kod operacji ALU
```

### Przyciski KEY (aktywne niskim)

```
KEY = 11  — oba puszczone (stan spoczynkowy)
KEY = 01  — KEY[1] wciśnięty = RESET (zeruje rejestry i wyświetlacz)
KEY = 10  — KEY[0] wciśnięty = zbocze zegara (wykonanie operacji)
```

### Kody operacji ALU (SW[3:0])

| Kod | Operacja | Opis |
|-----|----------|------|
| 0000 | PASS BB | przepisz argument 1 na wyjście |
| 0001 | PASS BC | przepisz argument 2 na wyjście |
| 0010 | ADD | BB + BC |
| 0011 | SUB | BB - BC |
| 0100 | OR | BB or BC |
| 0101 | AND | BB and BC |
| 0110 | XOR | BB xor BC |
| 0111 | XNOR | BB xnor BC |
| 1000 | NOT | not BB |
| 1001 | NEG | -BB (U2) |
| 1010 | CLR | wyzeruj |
| 1011 | ADC | BB + BC + C_in |
| 1100 | SBB | BB - BC - C_in |
| 1101 | INC | BB + 1 |
| 1110 | SHL | przesunięcie w lewo o 1 |
| 1111 | SHR | przesunięcie w prawo o 1 |

### Ważna różnica: alu_Y vs disp_Y / HEX

| Sygnał | Kiedy się zmienia |
|--------|-------------------|
| `alu_Y`, `alu_C/Z/S/P` | Natychmiast po zmianie SW (logika kombinacyjna) |
| `disp_Y`, `HEX*`, `LEDR[3:0]` | **Dopiero po impulsie zegara** (`tick`) |

W symulacji możesz sprawdzać `alu_Y` bez klikania zegara.
Wynik na `HEX` i flagach LEDR wymaga `tick` po ustawieniu SW.

### Wpisywanie liczb do rejestrów

`SW[3:0]` to jednocześnie kod ALU **i** wartość DI (gdy Sbb lub Sbc = `11`).
Nie da się wpisać „7" i „ADD" naraz — używamy metody **CLR + INC**:

1. CLR → rejestr = 0 (WEN=1, operacja CLR, Sbb = ten rejestr)
2. INC × N → dodaj N do rejestru

---

## 5. Test ręczny CPU — 7 + 2

Scenariusz: `rA = 7`, `rB = 2`, podgląd `ADD` → wynik `9`, opcjonalny zapis do rA.

### FAZA 1 — Reset

```tcl
reset_cpu
peek
```

Oczekiwane: `reg_BB = 0`, `reg_BC = 0`, `disp_Y = 0000`.

---

### FAZA 2 — Wyzeruj rA (CLR)

```tcl
set_sw_tick 0100001010
peek
```

| Sygnał | Wartość |
|--------|---------|
| `reg_BB` | `0000000000000000` |

---

### FAZA 3 — rA = 7 (INC × 7)

```tcl
set_sw 0100001101
tick
tick
tick
tick
tick
tick
tick
peek
```

| Klik (tick) | reg_BB (rA) |
|-------------|-------------|
| 1 | `...0001` |
| 2 | `...0010` |
| 3 | `...0011` |
| 4 | `...0100` |
| 5 | `...0101` |
| 6 | `...0110` |
| **7** | **`...0111` ✓** |

---

### FAZA 4 — Wyzeruj rB (CLR)

```tcl
set_sw_tick 1100001010
peek
```

| Sygnał | Wartość |
|--------|---------|
| `reg_BC` | `0000000000000000` |

---

### FAZA 5 — rB = 2 (INC × 2)

```tcl
set_sw 1100011101
tick
tick
peek
```

| Klik | reg_BC (rB) |
|------|-------------|
| 1 | `...0001` |
| **2** | **`...0010` ✓** |

---

### FAZA 6 — Podgląd ADD (bez zapisu, WEN=0)

```tcl
set_sw 0001000010
peek
```

Sprawdź `alu_Y` (kombinacyjnie, bez tick):

| Sygnał | Wartość | Znaczenie |
|--------|---------|-----------|
| `alu_BB` | `0000000000000111` | argument 1 = 7 |
| `alu_BC` | `0000000000000010` | argument 2 = 2 |
| `alu_Y` | `0000000000001001` | wynik = **9** |
| `alu_C` | `0` | brak przeniesienia |
| `alu_Z` | `0` | wynik ≠ 0 |
| `alu_S` | `0` | wynik dodatni |
| `alu_P` | `1` | parzysta liczba jedynek |

Aby zobaczyć wynik na HEX (jak na płytce):

```tcl
tick
peek
```

Oczekiwane: `disp_Y = 0009`, `LEDR[3:0] = 0001` (P=1, S=0, Z=0, C=0).

---

### FAZA 7 — Zapis wyniku ADD do rA

```tcl
set_sw_tick 0101000010
peek
```

| Sygnał | Wartość |
|--------|---------|
| `reg_BB` | `0000000000001001` (= 9) ✓ |

---

### Gotowy skrypt (wklej cały blok)

```tcl
cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU}
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work
vcom -93 -work work hex_display.vhd alu.vhd busint.vhd ram.vhd register_cpu.vhd CPU.vhd
vsim -voptargs=+acc work.CPU

proc tick {} { force sim:/CPU/KEY 10; run 20ns; force sim:/CPU/KEY 11; run 20ns }
proc reset_cpu {} { force sim:/CPU/SW 0000000000; force sim:/CPU/KEY 01; run 40ns; force sim:/CPU/KEY 11; run 40ns }
proc set_sw {v} { force sim:/CPU/SW $v; run 20ns }
proc set_sw_tick {v} { set_sw $v; tick }

reset_cpu
set_sw_tick 0100001010
set_sw 0100001101
tick; tick; tick; tick; tick; tick; tick
set_sw_tick 1100001010
set_sw 1100011101
tick; tick
set_sw 0001000010
tick
set_sw_tick 0101000010

echo "=== KONIEC TESTU 7+2 ==="
examine -radix hex sim:/CPU/reg_BB
examine -radix hex sim:/CPU/alu_Y
examine -radix hex sim:/CPU/disp_Y
```

---

## 6. Wszystkie operacje ALU (CPU)

Zakładamy: **rA = 7**, **rB = 2** (po teście z sekcji 5).
Format SW: `WEN=0` (podgląd), `Sbc=01` (rB), `Sbb=00` (rA).

Po `set_sw` sprawdź `alu_Y`. Po `tick` sprawdź `disp_Y` i `LEDR[3:0]`.

### Tabela operacji

| Operacja | SW[9:0] | alu_Y (hex) | C | Z | S | P |
|----------|---------|-------------|---|---|---|---|
| ADD | `0001000010` | `0009` | 0 | 0 | 0 | 1 |
| SUB | `0001000011` | `0005` | 0 | 0 | 0 | 1 |
| OR | `0001000100` | `0007` | 0 | 0 | 0 | 0 |
| AND | `0001000101` | `0002` | 0 | 0 | 0 | 0 |
| XOR | `0001000110` | `0005` | 0 | 0 | 0 | 1 |
| XNOR | `0001000111` | `FFFA` | 0 | 0 | 1 | 1 |
| NOT | `0000001000` | `FFF8` | 0 | 0 | 1 | 0 |
| NEG | `0000001001` | `FFF9` | 0 | 0 | 1 | 1 |
| CLR | `0000001010` | `0000` | 0 | 1 | 0 | 1 |
| ADC* | `0001001011` | `0009` | 0 | 0 | 0 | 1 |
| SBB* | `0001001100` | `0005` | 0 | 0 | 0 | 1 |
| INC | `0000001101` | `0008` | 0 | 0 | 0 | 0 |
| SHL | `0000001110` | `000E` | 0 | 0 | 0 | 0 |
| SHR | `0000001111` | `0003` | 1 | 0 | 0 | 1 |
| PASS BB | `0000000000` | `0007` | 0 | 0 | 0 | 0 |
| PASS BC | `0000010001` | `0002` | 0 | 0 | 0 | 0 |

> \* W `CPU.vhd` sygnał `C_in` ALU jest na stałe `'0'`, więc **ADC = ADD** i **SBB = SUB**.

### Przykłady komend (po przygotowaniu rA=7, rB=2)

```tcl
# SUB: 7 - 2 = 5
set_sw 0001000011
examine -radix hex sim:/CPU/alu_Y
tick

# AND: 7 and 2 = 2
set_sw 0001000101
examine -radix hex sim:/CPU/alu_Y

# SHR: 7 >> 1 = 3, C=1
set_sw 0000001111
examine sim:/CPU/alu_Y
examine sim:/CPU/alu_C
```

### Zapis wyniku do rejestru

Ustaw **SW[8] = 1** (WEN) i wykonaj `tick`:

```tcl
# Zapisz wynik SUB (5) do rA
set_sw_tick 0101000011
examine -radix unsigned sim:/CPU/reg_BB
```

---

## 7. Test jednostkowy ALU

Najszybszy sposób na weryfikację samej ALU, bez pliku rejestrów i przełączników.

### Uruchomienie

```tcl
cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU}
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work
vcom -93 -work work alu.vhd
vcom -93 -work work alu_tb.vhd
vsim -voptargs=+acc work.alu_tb
add wave -r sim:/alu_tb/*
run -all
```

Testbench sam ustawia wejścia i raportuje PASS/FAIL.

### Ręczne testy ALU (bez testbencha)

```tcl
vsim work.alu

# ADD 7+2=9
force sim:/alu/BB 0000000000000111
force sim:/alu/BC 0000000000000010
force sim:/alu/S_ALU 0010
force sim:/alu/C_in 0
run 20ns
examine -radix hex sim:/alu/Y
examine sim:/alu/C
examine sim:/alu/Z
examine sim:/alu/S
examine sim:/alu/P

# ADD z przeniesieniem: FFFF+1=0, C=1, Z=1
force sim:/alu/BB 1111111111111111
force sim:/alu/BC 0000000000000001
force sim:/alu/S_ALU 0010
run 20ns
examine -radix hex sim:/alu/Y
examine sim:/alu/C
examine sim:/alu/Z

# SHL 0x8000 -> C=1, Z=1
force sim:/alu/BB 1000000000000000
force sim:/alu/BC 0000000000000000
force sim:/alu/S_ALU 1110
run 20ns
examine -radix hex sim:/alu/Y
examine sim:/alu/C
examine sim:/alu/Z
```

### Tabela przypadków z alu_tb

| Test | BB | BC | S_ALU | Oczekiwane Y | C | Z | S | P |
|------|----|----|-------|--------------|---|---|---|---|
| PASS BB | `1234` | `0000` | `0000` | `1234` | 0 | 0 | 0 | 0 |
| PASS BC | `0000` | `00FF` | `0001` | `00FF` | 0 | 0 | 0 | 1 |
| ADD 7+2 | `0007` | `0002` | `0010` | `0009` | 0 | 0 | 0 | 1 |
| ADD overflow | `FFFF` | `0001` | `0010` | `0000` | 1 | 1 | 0 | 1 |
| SUB 7-2 | `0007` | `0002` | `0011` | `0005` | 0 | 0 | 0 | 1 |
| SUB 2-7 | `0002` | `0007` | `0011` | `FFFB` | 1 | 0 | 1 | 0 |
| OR | `0007` | `0002` | `0100` | `0007` | 0 | 0 | 0 | 0 |
| AND | `0007` | `0002` | `0101` | `0002` | 0 | 0 | 0 | 0 |
| XOR | `0007` | `0002` | `0110` | `0005` | 0 | 0 | 0 | 1 |
| XNOR | `0007` | `0002` | `0111` | `FFFA` | 0 | 0 | 1 | 1 |
| NOT 7 | `0007` | `0000` | `1000` | `FFF8` | 0 | 0 | 1 | 0 |
| NEG 7 | `0007` | `0000` | `1001` | `FFF9` | 0 | 0 | 1 | 1 |
| CLR | `1234` | `5678` | `1010` | `0000` | 0 | 1 | 0 | 1 |
| ADC 7+2+1 | `0007` | `0002` | `1011` | `000A` | 0 | 0 | 0 | 1 |
| SBB 7-2-1 | `0007` | `0002` | `1100` | `0004` | 0 | 0 | 0 | 0 |
| INC 7 | `0007` | `0000` | `1101` | `0008` | 0 | 0 | 0 | 0 |
| SHL 7 | `0007` | `0000` | `1110` | `000E` | 0 | 0 | 0 | 0 |
| SHL 0x8000 | `8000` | `0000` | `1110` | `0000` | 1 | 1 | 0 | 1 |
| SHR 7 | `0007` | `0000` | `1111` | `0003` | 1 | 0 | 0 | 1 |
| SHR 1 | `0001` | `0000` | `1111` | `0000` | 1 | 1 | 0 | 1 |

Wartości hex wpisuj jako 16-bitowe wektory binarne lub hex w `force`.

---

## 8. Sygnały do obserwacji

### Dodaj fale do Waveform

```tcl
# CPU — porty zewnętrzne
add wave -divider "Porty"
add wave -radix bin sim:/CPU/SW
add wave -radix bin sim:/CPU/KEY
add wave -radix bin sim:/CPU/LEDR
add wave sim:/CPU/HEX0 sim:/CPU/HEX1 sim:/CPU/HEX2 sim:/CPU/HEX3

# CPU — wewnętrzne
add wave -divider "Rejestry i ALU"
add wave -radix hex sim:/CPU/reg_BB
add wave -radix hex sim:/CPU/reg_BC
add wave -radix hex sim:/CPU/alu_Y
add wave -radix hex sim:/CPU/disp_Y
add wave sim:/CPU/alu_C sim:/CPU/alu_Z sim:/CPU/alu_S sim:/CPU/alu_P
add wave sim:/CPU/disp_C sim:/CPU/disp_Z sim:/CPU/disp_S sim:/CPU/disp_P
add wave -radix bin sim:/CPU/wen sim:/CPU/dst
```

### Przydatne komendy examine

```tcl
examine -radix hex sim:/CPU/reg_BB
examine -radix hex sim:/CPU/reg_BC
examine -radix hex sim:/CPU/alu_Y
examine -radix hex sim:/CPU/disp_Y
examine -radix bin sim:/CPU/LEDR
examine sim:/CPU/HEX0
```

### Mapowanie HEX → cyfra

Wyświetlacz 7-segmentowy (aktywny niski). Przykłady z `cpu_tb`:

| Cyfra | HEX0..HEX5 (seg) |
|-------|------------------|
| 0 | `1000000` |
| 2 | `0100100` |
| 7 | `1111000` |
| 9 | `0010000` |

### Flagi LEDR[3:0]

```
LEDR[3] = C  (Carry)
LEDR[2] = Z  (Zero)
LEDR[1] = S  (Sign)
LEDR[0] = P  (Parity even)
LEDR[4] = WEN (na żywo ze SW[8])
LEDR[5] = DST (na żywo ze SW[9])
LEDR[7:6] = Sbb
LEDR[9:8] = Sbc
```

---

## 9. Rozwiązywanie problemów

| Problem | Przyczyna | Rozwiązanie |
|---------|-----------|-------------|
| `force` nie działa | Zła ścieżka lub brak `vsim` | Uruchom `vsim work.CPU` i używaj `sim:/CPU/...` |
| HEX nie zmienia się po `set_sw` | Wynik zatrzaskiwany na zegarze | Wykonaj `tick` po zmianie SW |
| `alu_Y` OK, ale `reg_BB` złe | Brak WEN lub zły DST | Ustaw SW[8]=1 i właściwy SW[9] przed `tick` |
| Po resecie dziwne wartości | Reset nieaktywny | `force sim:/CPU/KEY 01`, potem `11` |
| Kompilacja pada | Brak pliku w QSF | Upewnij się, że wszystkie `.vhd` są w katalogu projektu |
| `run -all` wisi | Testbench zakończony (`wait`) | Normalne — sprawdź Transcript |

### Czyszczenie wymuszeń

```tcl
noforce sim:/CPU/SW
noforce sim:/CPU/KEY
```

### Restart symulacji

```tcl
restart -f
force sim:/CPU/KEY 11
force sim:/CPU/SW 0000000000
run 0
```

---

## Szybka ściągawka — kolejność testów

```
1. do run_tests.do          → testy automatyczne ALU + CPU
2. vsim work.CPU            → testy ręczne jak na płytce
3. reset_cpu                → start od zera
4. CLR + INC                → wpisz rA, rB
5. set_sw + peek            → sprawdź alu_Y
6. tick                     → sprawdź disp_Y / HEX / LEDR
7. set_sw_tick z WEN=1      → zapisz wynik do rejestru
```
