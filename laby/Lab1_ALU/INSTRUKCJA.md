# Lab 1 — Jednostka arytmetyczno-logiczna (ALU)

## Pliki w tym folderze

| Plik | Opis |
|------|------|
| `alu.vhd` | Implementacja ALU (20 operacji, 5-bitowy kod) |
| `alu_tb.vhd` | Testbench automatyczny |
| `run_tests.do` | Skrypt QuestaSim |

---

## Uruchomienie testów w QuestaSim

### Krok 1 — ustaw katalog roboczy

```tcl
cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/laby/Lab1_ALU}
```

### Krok 2 — uruchom skrypt

```tcl
do run_tests.do
```

### Krok 3 — sprawdź wynik

W oknie **Transcript** szukaj:

```
=== ALU_TB: WSZYSTKIE TESTY PRZESZLY ===
```

Błędy mają postać: `FAIL [nazwa_testu] Y` (lub `C`, `Z`, `S`, `P`).

---

## Komendy ręczne (bez skryptu)

```tcl
cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/laby/Lab1_ALU}
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work
vcom -93 -work work alu.vhd
vcom -93 -work work alu_tb.vhd
vsim -voptargs=+acc work.alu_tb
add wave -r sim:/alu_tb/*
run -all
```

### Ręczny test pojedynczej operacji (ADD 7+2)

```tcl
vsim work.alu
force sim:/alu/BB 0000000000000111
force sim:/alu/BC 0000000000000010
force sim:/alu/S_ALU 0010
force sim:/alu/C_in 0
run 20ns
examine -radix hex sim:/alu/Y
examine sim:/alu/C sim:/alu/Z sim:/alu/S sim:/alu/P
```

Oczekiwane: `Y = 0009`, `C=0 Z=0 S=0 P=1`.

---

## Tabela testów — oczekiwane wyniki

| # | Test | BB | BC | S_ALU | C_in | Y (hex) | C | Z | S | P |
|---|------|----|----|-------|------|---------|---|---|---|---|
| 1 | PASS BB | `1234` | `0000` | `00000` | 0 | `1234` | 0 | 0 | 0 | 0 |
| 2 | PASS BC | `0000` | `00FF` | `00001` | 0 | `00FF` | 0 | 0 | 0 | 1 |
| 3 | ADD 7+2 | `0007` | `0002` | `00010` | 0 | `0009` | 0 | 0 | 0 | 1 |
| 4 | ADD overflow | `FFFF` | `0001` | `00010` | 0 | `0000` | 1 | 1 | 0 | 1 |
| 5 | SUB 7-2 | `0007` | `0002` | `00011` | 0 | `0005` | 0 | 0 | 0 | 1 |
| 6 | SUB 2-7 | `0002` | `0007` | `00011` | 0 | `FFFB` | 1 | 0 | 1 | 0 |
| 7 | OR | `0007` | `0002` | `00100` | 0 | `0007` | 0 | 0 | 0 | 0 |
| 8 | AND | `0007` | `0002` | `00101` | 0 | `0002` | 0 | 0 | 0 | 0 |
| 9 | XOR | `0007` | `0002` | `00110` | 0 | `0005` | 0 | 0 | 0 | 1 |
| 10 | XNOR | `0007` | `0002` | `00111` | 0 | `FFFA` | 0 | 0 | 1 | 1 |
| 11 | NOT BB | `0007` | `0000` | `01000` | 0 | `FFF8` | 0 | 0 | 1 | 0 |
| 12 | NEG BB | `0007` | `0000` | `01001` | 0 | `FFF9` | 0 | 0 | 1 | 1 |
| 13 | CLR | `1234` | `5678` | `01010` | 0 | `0000` | 0 | 1 | 0 | 1 |
| 14 | ADC | `0007` | `0002` | `01011` | 1 | `000A` | 0 | 0 | 0 | 1 |
| 15 | SBB | `0007` | `0002` | `01100` | 1 | `0004` | 0 | 0 | 0 | 0 |
| 16 | INC BB | `0007` | `0000` | `01101` | 0 | `0008` | 0 | 0 | 0 | 0 |
| 17 | SHL BB | `0007` | `0000` | `01110` | 0 | `000E` | 0 | 0 | 0 | 0 |
| 18 | SHL carry | `8000` | `0000` | `01110` | 0 | `0000` | 1 | 1 | 0 | 1 |
| 19 | SHR BB | `0007` | `0000` | `01111` | 0 | `0003` | 1 | 0 | 0 | 1 |
| 20 | NOT BC | `0000` | `0003` | `10000` | 0 | `FFFC` | 0 | 0 | 1 | 0 |
| 21 | NEG BC | `0000` | `0007` | `10001` | 0 | `FFF9` | 0 | 0 | 1 | 1 |
| 22 | INC BC | `0000` | `0007` | `10010` | 0 | `0008` | 0 | 0 | 0 | 0 |
| 23 | DEC BB | `0008` | `0000` | `10011` | 0 | `0007` | 0 | 0 | 0 | 0 |

---

## Kody operacji S_ALU

| S_ALU | Operacja |
|-------|----------|
| `00000` | PASS BB |
| `00001` | PASS BC |
| `00010` | ADD |
| `00011` | SUB |
| `00100` | OR |
| `00101` | AND |
| `00110` | XOR |
| `00111` | XNOR |
| `01000` | NOT BB |
| `01001` | NEG BB |
| `01010` | CLR |
| `01011` | ADC |
| `01100` | SBB |
| `01101` | INC BB |
| `01110` | SHL BB |
| `01111` | SHR BB |
| `10000` | NOT BC |
| `10001` | NEG BC |
| `10010` | INC BC |
| `10011` | DEC BB |

---

## Test na płytce FPGA (pełny CPU, tryb laboratoryjny)

Ustaw **SW[9] = 1** (tryb ręczny ALU). Pozostałe przełączniki:

| SW | Funkcja |
|----|---------|
| `SW[3:0]` | Kod operacji ALU |
| `SW[5:4]` | Argument 1: `00`=A, `01`=B, `10`=C, `11`=DI |
| `SW[7:6]` | Argument 2: j.w. |
| `SW[8]` | WEN — zapis wyniku przy impulsie KEY[0] |
| `SW[2]` | DST — `0`=rA, `1`=rB |

**HEX0..3** = wynik ALU, **HEX4** = flagi, **LEDR[3:0]** = C,Z,S,P.
**SW[9]=0** — normalny tryb procesora (program z RAM).

---

## Kryterium zaliczenia

Test zaliczony, gdy w Transcript **nie ma** linii `FAIL` i pojawia się:

`=== ALU_TB: WSZYSTKIE TESTY PRZESZLY ===`
