# TESTY.md - zbiorcza instrukcja testowania CPU 16-bit

Ten plik zbiera testy, ktore nalezy wykonac dla trzech glownych czesci projektu:

1. **ALU** - 22 rozkazy i flagi.
2. **RAM / program procesora** - program z `ram_init.mif`, zapis i odczyt wyniku.
3. **Controler / jednostka sterujaca** - przejscia stanow i sygnaly sterujace.

Projekt ma dwa tryby pracy na plytce DE1-SoC:

```text
SW9 = 0  tryb demonstratora ALU
SW9 = 1  tryb procesora z jednostka sterujaca
```

Przelaczniki liczymy od prawej strony: `SW0` to skrajny prawy.

---

## 1. Testy automatyczne / symulacyjne

W projekcie sa trzy testbenche:

| Testbench | Co testuje | Oczekiwany rezultat |
|-----------|------------|---------------------|
| `alu_tb.vhd` | wszystkie 22 rozkazy ALU i flagi `C/Z/S/P` | komunikat `ALU_TB: WSZYSTKIE TESTY PRZESZLY` |
| `control_tb.vhd` | sama jednostka sterujaca: fetch, decode, ALU, LDI, BRZ | komunikat `CONTROL_TB: WSZYSTKIE TESTY PRZESZLY` |
| `cpu_tb.vhd` | top-level: ALU demo, fetch z RAM, program demo do wyniku `0012`, HLT | komunikat `CPU_TB: WSZYSTKIE TESTY PRZESZLY` |

W Quartus/ModelSim/Questa wybierz odpowiedni testbench i uruchom symulacje.
Najwazniejszy test zbiorczy to `cpu_tb.vhd`, bo przechodzi przez caly top-level.

> Uwaga: w srodowisku cloud nie bylo dostepnego `ghdl`, `quartus`, `vcom` ani `vsim`,
> wiec lokalnie trzeba uruchomic symulacje w Quartusie/ModelSimie na komputerze z narzedziami FPGA.

---

## 2. Test ALU na plytce (`SW9=0`)

### 2.1. Ustawienie trybu ALU

Ustaw:

```text
SW9 = 0
```

Mapowanie pozostalych przelacznikow:

```text
SW8   SW7   SW6 SW5   SW4 SW3 SW2 SW1 SW0
S_F   C_in  PRESET    ALU opcode 5-bit
```

| Pole | Bity | Znaczenie |
|------|------|-----------|
| `ALU opcode` | `SW[4:0]` | kod rozkazu ALU |
| `PRESET` | `SW[6:5]` | gotowe argumenty `BB` i `BC` |
| `C_in` | `SW[7]` | przeniesienie wejsciowe |
| `S_F` | `SW[8]` | `0` = wynik, `1` = flagi na `HEX3..HEX0` |

Presety argumentow:

| `SW[6:5]` | `BB` | `BC` |
|-----------|------|------|
| `00` | `0007` | `0002` |
| `01` | `8001` | `0001` |
| `10` | `00F0` | `000F` |
| `11` | `FFFF` | `0001` |

Wynik jest na `HEX3..HEX0`, flagi sa na `HEX4` i `LEDR[3:0]`.

### 2.2. Minimalny test ALU - podstawowe operacje

Dla wszystkich ponizszych testow ustaw `SW9=0`, `SW8=0`, `SW7=0`, `SW[6:5]=00`.
Czyli argumenty sa stale:

```text
BB = 0007
BC = 0002
```

| Test | `SW[9:0]` | Operacja | Oczekiwany `HEX3..HEX0` |
|------|-----------|----------|--------------------------|
| ALU-1 | `0000000000` | `ADD 7+2` | `0009` |
| ALU-2 | `0000000001` | `SUB 7-2` | `0005` |
| ALU-3 | `0000000010` | `MUL 7*2` | `000E` |
| ALU-4 | `0000000011` | `DIV 7/2` | `0003` |
| ALU-5 | `0000000100` | `MOD 7%2` | `0001` |
| ALU-6 | `0000000101` | `INC 7` | `0008` |
| ALU-7 | `0000000110` | `DEC 7` | `0006` |
| ALU-8 | `0000000111` | `NEG 7` | `FFF9` |

### 2.3. Test ALU - operacje logiczne

Dalej `SW9=0`, `SW8=0`, `SW7=0`, `SW[6:5]=00`.

| Test | `SW[9:0]` | Operacja | Oczekiwany `HEX3..HEX0` |
|------|-----------|----------|--------------------------|
| ALU-9  | `0000001000` | `AND` | `0002` |
| ALU-10 | `0000001001` | `OR` | `0007` |
| ALU-11 | `0000001010` | `XOR` | `0005` |
| ALU-12 | `0000001011` | `NOT BB` | `FFF8` |
| ALU-13 | `0000001100` | `NAND` | `FFFD` |
| ALU-14 | `0000001101` | `NOR` | `FFF8` |

### 2.4. Test ALU - przesuniecia i rotacje

Dla przesuniec najlepiej ustawic preset `01`:

```text
SW9=0, SW8=0, SW7=0, SW[6:5]=01
BB = 8001
BC = 0001
```

| Test | `SW[9:0]` | Operacja | Oczekiwany `HEX3..HEX0` |
|------|-----------|----------|--------------------------|
| ALU-15 | `0000101110` | `SHL 8001` | `0002` |
| ALU-16 | `0000101111` | `SHR 8001` | `4000` |
| ALU-17 | `0000110000` | `SAR 8001` | `C000` |
| ALU-18 | `0000110001` | `ROL 8001` | `0003` |
| ALU-19 | `0000110010` | `ROR 8001` | `C000` |

### 2.5. Test ALU - porownania

Preset `00`, czyli `BB=7`, `BC=2`.

| Test | `SW[9:0]` | Operacja | Oczekiwany `HEX3..HEX0` |
|------|-----------|----------|--------------------------|
| ALU-20 | `0000010011` | `CMP_EQ 7==2` | `0000` |
| ALU-21 | `0000010100` | `CMP_LT 7<2` | `0000` |
| ALU-22 | `0000010101` | `CMP_GT 7>2` | `0001` |

### 2.6. Test flag ALU

Ustaw test `ADD 7+2`, ale wlacz `S_F`:

```text
SW = 0100000000
```

Oczekiwane:

```text
HEX3..HEX0 = 0001
```

bo flagi dla `7+2=9` sa:

```text
{C,Z,S,P} = 0001
```

---

## 3. Test RAM i programu procesora (`SW9=1`)

Ten test sprawdza RAM, `busint`, rejestr `IR`, jednostke sterujaca i wykonanie programu z `ram_init.mif`.

### 3.1. Program w RAM

Po resecie `PC=0`, wiec CPU wykonuje program od adresu `000`:

| Adres | Kod | Instrukcja |
|-------|-----|------------|
| `000` | `4407` | `LDI rA, 0x07` |
| `001` | `4602` | `LDI rB, 0x02` |
| `002` | `2023` | `ADD rA, rB` |
| `003` | `2223` | `MUL rA, rB` |
| `004` | `8420` | `STORE rA, [0x20]` |
| `005` | `6820` | `LOAD rC, [0x20]` |
| `006` | `1F00` | `HLT` |

Wynik programu:

```text
(7 + 2) * 2 = 18 = 0x0012
```

Instrukcja `STORE` zapisuje `0012` do RAM pod adresem `0x20`, a `LOAD` odczytuje ten wynik.

### 3.2. Ustawienia plytki

1. Ustaw `SW9=1`, czyli tryb procesora.
2. Wcisnij i pusc `KEY1`, czyli reset.
3. Ustaw `SW[7:6]=00`, zeby `HEX3..HEX0` pokazywalo `IR`.
4. Klikaj `KEY0` - kazde klikniecie to jeden takt mikrosterowania.

Podglady w trybie procesora:

| `SW[7:6]` | Co pokazuje `HEX3..HEX0` |
|-----------|---------------------------|
| `00` | `IR` |
| `01` | biezacy wynik ALU |
| `10` | `DI`, czyli dane odczytane z RAM przez `busint` |
| `11` | adres fizyczny RAM |

### 3.3. Oczekiwana sekwencja klikniec

| Liczba klikniec `KEY0` od resetu | Ustawienie podgladu | Oczekiwany wynik |
|----------------------------------|---------------------|------------------|
| `2` | `SW[7:6]=00` | `IR = 4407` |
| `6` | `SW[7:6]=00` | `IR = 4602` |
| `10` | `SW[7:6]=00` | `IR = 2023` |
| `14` | `SW[7:6]=00` | `IR = 2223` |
| `20` | `SW[7:6]=00` | `IR = 8420` |
| `26` | `SW[7:6]=00` | `IR = 6820` |
| `28` | `SW[7:6]=10` | `DI = 0012` |
| `31` | `SW[7:6]=00` | `IR = 1F00`, a `HEX5 = F` |

Jesli po 28 kliknieciach i ustawieniu `SW[7:6]=10` widzisz:

```text
HEX3..HEX0 = 0012
```

to test RAM/programu przeszedl.

---

## 4. Test controlera / jednostki sterujacej

Controler jest w pliku `control.vhd`. Najprostszy test automatyczny to `control_tb.vhd`.

### 4.1. Co sprawdza `control_tb.vhd`

Testbench sprawdza:

1. po resecie controler jest w stanie `f0`,
2. w `f0` wystawia:
   - `Sa = 01`, czyli adres z `PC`,
   - `Sid = 001`, czyli `PC = PC + 1`,
   - `Smar = 1`,
   - `RD = 1`,
3. po jednym takcie przechodzi do `f1`,
4. w `f1` wystawia:
   - `Sba = 0000`, czyli zapis do `IR`,
   - `MIO = 1`, czyli dane z pamieci,
5. dla instrukcji `2023` przechodzi do `exec_alu`,
6. dla instrukcji `4407` przechodzi do `exec_ldi`,
7. dla instrukcji `C004` sprawdza `BRZ` przy `Z=0` i `Z=1`.

### 4.2. Test reczny controlera na plytce

Ustaw:

```text
SW9 = 1
SW[7:6] = 00
```

Po resecie klikaj `KEY0` i obserwuj `HEX5`, ktory pokazuje stan controlera:

| Kod na `HEX5` | Stan controlera | Znaczenie |
|---------------|-----------------|-----------|
| `0` | `f0` | pobranie instrukcji z RAM pod adresem PC |
| `1` | `f1` | zapis slowa z pamieci do IR |
| `2` | `decode` | dekodowanie IR |
| `3` | `exec_alu` | wykonanie instrukcji ALU |
| `4` | `exec_ldi` | wykonanie LDI |
| `5` | `load_addr` | przygotowanie adresu LOAD |
| `6` | `load_read` | odczyt RAM dla LOAD |
| `7` | `load_write` | zapis danych z RAM do rejestru |
| `8` | `store_addr` | przygotowanie adresu STORE |
| `9` | `store_prep` | zaladowanie MAR/MBR dla STORE |
| `A` | `store_write` | zapis do RAM |
| `B` | `jump_addr` | zapis adresu skoku do PC |
| `C` | `brz_check` | sprawdzenie flagi Z dla BRZ |
| `D` | `int_ack` | potwierdzenie przerwania |
| `F` | `halt` | zatrzymanie procesora |

Dla programu z `ram_init.mif` po 31 kliknieciach powinno byc:

```text
HEX5 = F
IR   = 1F00
```

To oznacza, ze controler doszedl do instrukcji `HLT`.

---

## 5. Szybka lista zaliczeniowa

Do pokazania prowadzacemu wystarczy przejsc przez te punkty:

1. **ALU:** ustaw `SW9=0`, wykonaj testy `ADD`, `MUL`, `SAR`, `CMP_GT`.
2. **Flagi:** ustaw `SW=0100000000`, sprawdz `HEX3..HEX0=0001`.
3. **RAM/program:** ustaw `SW9=1`, reset, kliknij `KEY0` 28 razy, ustaw `SW[7:6]=10`, sprawdz `0012`.
4. **Controler:** kliknij do 31 taktu, ustaw `SW[7:6]=00`, sprawdz `IR=1F00` i `HEX5=F`.
5. **Symulacja:** uruchom `alu_tb.vhd`, `control_tb.vhd`, `cpu_tb.vhd`.

Jesli wszystkie punkty przejda, to przetestowane sa: ALU, flagi, RAM, busint,
plik rejestrow, jednostka sterujaca i top-level `CPU.vhd`.
