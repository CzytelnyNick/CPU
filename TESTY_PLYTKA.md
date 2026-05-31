# Procesor 16-bit — Checklista testów na płytce FPGA

Kompletny przewodnik „co po kolei sprawdzić" na płytce (DE1-SoC / DE2i-150 / DE10)
po wgraniu projektu. Obejmuje cały procesor: reset, plik rejestrów, ALU, flagi,
wyświetlacze HEX oraz **zapis i odczyt RAM** (aktywne tryby pamięci).

> Konwencja: SW w górę = `1`, w dół = `0`. SW0 = skrajny prawy.
> KEY są **aktywne niskim** (wciśnięcie = 0), wewnątrz odwracane.
> Wynik widać na HEX **na bieżąco** — sprawdzaj HEX **zanim** wciśniesz KEY[0].

---

## 0. Przygotowanie projektu

- [ ] Top-Level Entity = **CPU**
- [ ] Dodane: `CPU.vhd`, `alu.vhd`, `register_cpu.vhd`, `busint.vhd`, `ram.vhd`, `hex_display.vhd`
- [ ] Dodany plik inicjalizacji pamięci `ram_init.mif`
- [ ] Wybrany właściwy układ FPGA i przypisane piny SW/KEY/HEX/LEDR (Pin Planner)
- [ ] Kompilacja bez błędów, wgranie na płytkę (Programmer)

---

## 1. Legenda wejść / wyjść

### Tryb pracy — SW[9:8]

| SW[9:8] | Tryb      | SW[7:0]                                |
|---------|-----------|----------------------------------------|
| `00`    | ALU       | Sbc[7:6], Sbb[5:4], S_ALU[3:0]         |
| `01`    | RAM WRITE | adres = dana (offset, segment 0)       |
| `10`    | RAM READ  | adres (offset, segment 0)              |
| `11`    | INSPECT   | SW[7:4] = kod rejestru                  |

### Przyciski KEY

| KEY    | Funkcja                                       |
|--------|-----------------------------------------------|
| KEY[0] | zegar — 1 wciśnij-puść = 1 cykl               |
| KEY[1] | reset asynchroniczny (zeruje rejestry, nie RAM)|

### Wyświetlacze HEX

| HEX  | Tryb ALU / INSPECT       | Tryb RAM WRITE / READ      |
|------|--------------------------|----------------------------|
| HEX0 | wynik / rejestr [3:0]    | dana [3:0]                 |
| HEX1 | wynik / rejestr [7:4]    | dana [7:4]                 |
| HEX2 | wynik / rejestr [11:8]   | dana [11:8]                |
| HEX3 | wynik / rejestr [15:12]  | dana [15:12]               |
| HEX4 | flagi (C Z S P)          | adres fizyczny [3:0]       |
| HEX5 | kod operacji / rejestru  | adres fizyczny [7:4]       |

### Diody LEDR

| LED       | Znaczenie                       |
|-----------|---------------------------------|
| LEDR[0]   | flaga P (parzystość)            |
| LEDR[1]   | flaga S (znak)                  |
| LEDR[2]   | flaga Z (zero)                  |
| LEDR[3]   | flaga C (przeniesienie)         |
| LEDR[7:6] | tryb pracy (echo SW[9:8])       |
| LEDR[8]   | WR — zapis do RAM aktywny       |
| LEDR[9]   | RD — odczyt z RAM aktywny       |

---

## 2. Checklista testów — krok po kroku

### Test 0 — Reset
- [ ] `SW = 0000000000`, wciśnij i puść KEY[1]
- [ ] **Oczekiwane:** HEX = `00 00 00`, HEX4 = `5` (Z=1, P=1), LEDR Z i P świecą

### Test 1 — Wyświetlacze 7-segmentowe
- [ ] `SW = 0000001000` (NOT na pustym rA) → HEX = `FFF8` (sprawdza cyfry `F` i `8`)
- [ ] `SW = 0000001010` (CLR) → HEX = `0000`

### Test 2 — Rejestr rA = 7 (tryb ALU, metoda CLR + INC)
> Cel zapisu = rejestr Sbb (SW[5:4]). Tu Sbb=rA.
- [ ] CLR rA: `SW = 0000001010`, KEY[0]
- [ ] INC rA: `SW = 0000001101`, KEY[0] **×7**

| Klik | HEX  |
|------|------|
| 1    | 0001 |
| …    | …    |
| 7    | **0007 ✓** |

- [ ] Podgląd rA: `SW = 0000000000` (PASS BB, Sbb=rA) → HEX = `0007`

### Test 3 — Rejestr rB = 2
- [ ] CLR rB: `SW = 0000011010` (Sbb=rB), KEY[0]
- [ ] INC rB: `SW = 0000011101` (Sbb=rB), KEY[0] **×2** → `0002`
- [ ] Podgląd rB: `SW = 0000010000` → HEX = `0002`

### Test 4 — ALU: 7 + 2 (podgląd, bez zapisu)
- [ ] `SW = 0001000010` (Sbc=rB, Sbb=rA, ADD) → HEX = `0009`, HEX4 = `1`, HEX5 = `2`
- [ ] LEDR: C=0 S=0 Z=0 **P=1**

### Test 5 — Zapis wyniku do rejestru
- [ ] Przy `SW = 0001000010` wciśnij **KEY[0]** → rA = 9
- [ ] Podgląd rA: `SW = 0000000000` → HEX = `0009` ✓
- [ ] Wynik do rB: `SW = 0000010010` (Sbc=rA, Sbb=rB, ADD), KEY[0]; podgląd `SW=0000010000` → `0009`

### Test 6 — Wszystkie operacje ALU
- [ ] Przejdź tabelę z sekcji 5 i porównaj HEX/flagi (tryb `00`, bez KEY = podgląd)

### Test 7 — Flagi w skrajnych przypadkach
- [ ] **Zero (Z):** CLR `SW = 0000001010` → HEX=`0000`, LEDR Z=1, P=1
- [ ] **Znak (S):** NOT `SW = 0000001000` → HEX=`FFF8`, LEDR S=1
- [ ] **Carry (C):** SHR `SW = 0000001111` → HEX=`0003`, LEDR C=1

### Test 8 — RAM: zapis i odczyt (tryby `01` / `10`)
- [ ] **Zapis 0x42:** `SW = 0101000010` (WRITE, adres=dana=0x42), wciśnij KEY[0]
      → HEX3..0 = `0042`, HEX5..4 = `42`, LEDR[8] świeci
- [ ] **Odczyt 0x42:** `SW = 1001000010` (READ, adres=0x42)
      → HEX3..0 = `0042`, HEX5..4 = `42`, LEDR[9] świeci ✓
- [ ] **Odczyt wartości wstępnej (z MIF):** `SW = 1000000011` (adres 0x03) → HEX = `ABCD`
- [ ] **Odczyt 0x04:** `SW = 1000000100` → HEX = `1234`
- [ ] **Odczyt 0x05:** `SW = 1000000101` → HEX = `FFFF`

### Test 9 — INSPECT (tryb `11`)
- [ ] Podgląd rA: `SW = 1100100000` (SW[7:4]=0010) → HEX = `0009` (po zapisie z testu 5)
- [ ] Podgląd rB: `SW = 1100110000` (SW[7:4]=0011) → HEX = `0002`

---

## 3. Tabela punktów kontrolnych (pełna sekwencja)

| Etap | SW | Akcja | HEX5 | HEX4 | HEX3..0 |
|------|----|-------|------|------|---------|
| Reset | `0000000000` | KEY[1] | `0` | `5` | `0000` |
| CLR rA | `0000001010` | KEY[0] | `A` | `5` | `0000` |
| INC rA ×7 | `0000001101` | KEY[0]×7 | `d` | `0` | `0007` |
| Podgląd rA | `0000000000` | — | `0` | `0` | `0007` |
| CLR rB | `0000011010` | KEY[0] | `A` | `5` | `0000` |
| INC rB ×2 | `0000011101` | KEY[0]×2 | `d` | `0` | `0002` |
| ADD (podgląd) | `0001000010` | — | `2` | `1` | `0009` |
| Zapis do rA | `0001000010` | KEY[0] | `2` | `1` | `0009` |
| RAM zapis 0x42 | `0101000010` | KEY[0] | `4` | `2` | `0042` |
| RAM odczyt 0x42 | `1001000010` | — | `4` | `2` | `0042` |

---

## 4. Ściągawka — wszystkie operacje ALU (rA=7, rB=2)

`HEX5`=kod operacji, `HEX4`=flagi (C Z S P), `HEX3..0`=wynik. Tryb `00`, podgląd bez KEY.

| Operacja | SW[9:0] | HEX5 | HEX4 | Wynik | C | Z | S | P |
|----------|---------|------|------|-------|---|---|---|---|
| PASS BB  | `0000000000` | `0` | `0` | `0007` | 0 | 0 | 0 | 0 |
| PASS BC  | `0001000001` | `1` | `0` | `0002` | 0 | 0 | 0 | 0 |
| ADD      | `0001000010` | `2` | `1` | `0009` | 0 | 0 | 0 | 1 |
| SUB      | `0001000011` | `3` | `1` | `0005` | 0 | 0 | 0 | 1 |
| OR       | `0001000100` | `4` | `0` | `0007` | 0 | 0 | 0 | 0 |
| AND      | `0001000101` | `5` | `0` | `0002` | 0 | 0 | 0 | 0 |
| XOR      | `0001000110` | `6` | `1` | `0005` | 0 | 0 | 0 | 1 |
| XNOR     | `0001000111` | `7` | `3` | `FFFA` | 0 | 0 | 1 | 1 |
| NOT      | `0000001000` | `8` | `2` | `FFF8` | 0 | 0 | 1 | 0 |
| NEG      | `0000001001` | `9` | `3` | `FFF9` | 0 | 0 | 1 | 1 |
| CLR      | `0000001010` | `A` | `5` | `0000` | 0 | 1 | 0 | 1 |
| ADC*     | `0001001011` | `b` | `1` | `0009` | 0 | 0 | 0 | 1 |
| SBB*     | `0001001100` | `C` | `1` | `0005` | 0 | 0 | 0 | 1 |
| INC      | `0000001101` | `d` | `0` | `0008` | 0 | 0 | 0 | 0 |
| SHL      | `0000001110` | `E` | `0` | `000E` | 0 | 0 | 0 | 0 |
| SHR      | `0000001111` | `F` | `9` | `0003` | 1 | 0 | 0 | 1 |

\* `C_in=0` w `CPU.vhd`, więc ADC=ADD i SBB=SUB. P=1 = parzysta liczba jedynek.

---

## 5. Mapa pamięci RAM (`ram_init.mif`)

| Adres (hex) | Adres (dec) | Wartość | Segment |
|-------------|-------------|---------|---------|
| 000 | 0 | 0001 | 0 |
| 001 | 1 | 0002 | 0 |
| 002 | 2 | 0003 | 0 |
| 003 | 3 | ABCD | 0 |
| 004 | 4 | 1234 | 0 |
| 005 | 5 | FFFF | 0 |
| 100 | 256 | 0010 | 1 |
| 200 | 512 | 0020 | 2 |
| 300 | 768 | 0030 | 3 |
| pozostałe | — | 0000 | — |

> Przez przełączniki adresujemy segment 0 (offset 0..255). Wartości z MIF widać na
> płytce po zaprogramowaniu (Quartus inicjuje pamięć). W symulacji RTL najpierw zapisz
> komórkę, potem odczytaj.

---

## 6. Najczęstsze problemy (troubleshooting)

| Objaw | Prawdopodobna przyczyna |
|-------|--------------------------|
| HEX nie reaguje na SW | Top-Level Entity ≠ CPU, albo złe przypisanie pinów |
| Zegar „przeskakuje" o 2 | Drganie styków KEY — sprawdzaj HEX po każdym kliknięciu |
| Wartość rejestru znika | Wciśnięty reset KEY[1] (aktywny niskim) |
| ADC/SBB = ADD/SUB | Tak ma być — `C_in=0` na stałe |
| RAM READ pokazuje śmieci w symulacji | Komórka niezapisana — najpierw zapisz (tryb WRITE) |
| Zły zapis do rejestru w trybie ALU | Cel zapisu = Sbb (SW[5:4]); ustaw Sbb na właściwy rejestr |
