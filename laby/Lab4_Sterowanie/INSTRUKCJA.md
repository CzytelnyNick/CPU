# Lab 4 — Układ sterujący (control)

## Pliki w tym folderze

| Plik | Opis |
|------|------|
| `control.vhd` | Maszyna stanów — dekodowanie instrukcji |
| `control_tb.vhd` | Testbench automatyczny |
| `run_tests.do` | Skrypt QuestaSim |

---

## Uruchomienie testów w QuestaSim

```tcl
cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/laby/Lab4_Sterowanie}
do run_tests.do
```

**Sukces:**

```
=== CONTROL_TB: WSZYSTKIE TESTY PRZESZLY ===
```

---

## Komendy ręczne

```tcl
cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/laby/Lab4_Sterowanie}
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work
vcom -93 -work work control.vhd
vcom -93 -work work control_tb.vhd
vsim -voptargs=+acc work.control_tb
add wave -r sim:/control_tb/*
run -all
```

### Sygnały do obserwacji

```tcl
add wave -radix unsigned sim:/control_tb/state_dbg
add wave -radix bin sim:/control_tb/Salu
add wave -radix bin sim:/control_tb/Sbb
add wave -radix bin sim:/control_tb/Sbc
add wave -radix bin sim:/control_tb/Sba
add wave sim:/control_tb/Smar sim:/control_tb/RD sim:/control_tb/WR
add wave sim:/control_tb/LDF sim:/control_tb/MIO
add wave -radix hex sim:/control_tb/IR
```

---

## Stany maszyny (state_dbg)

| state_dbg | Stan | Znaczenie |
|-----------|------|-----------|
| `0000` | f0 | Pobranie instrukcji z RAM (PC→MAR, RD) |
| `0001` | f1 | Załadowanie IR z pamięci |
| `0010` | decode | Rozpoznanie typu instrukcji |
| `0011` | exec_alu | Wykonanie operacji ALU |
| `0100` | exec_ldi | Załadowanie stałej (LDI) |
| `0101`..`1010` | load/store | Operacje pamięciowe |
| `1011` | jump_addr | Skok bezwarunkowy |
| `1100` | brz_check | Skok warunkowy (BRZ) |
| `1101` | int_ack | Obsługa przerwania |
| `1111` | halt | Zatrzymanie (HLT) |

---

## Tabela testów — oczekiwane wyniki

### Scenariusz 1 — LDI A, 7 (`IR = 4007`)

| Krok | Stan (state_dbg) | Kluczowe sygnały | Oczekiwane |
|------|------------------|------------------|------------|
| f0 | `0000` | Smar=1, RD=1, Sa=`01`, Sid=`001` | Pobranie z PC |
| f1 | `0001` | Sba=`00000`, MIO=1 | Ładowanie IR |
| decode | `0010` | — | Rozpoznanie opcode `010` |
| exec_ldi | `0100` | Salu=`00000`, Sba=`00010`, LDF=1, MIO=1 | Zapis 7 do A |

### Scenariusz 2 — ADD A, A, B (`IR = 2201`)

| Krok | Stan | Kluczowe sygnały | Oczekiwane |
|------|------|------------------|------------|
| decode | `0010` | opcode `001` | Przejście do ALU |
| exec_alu | `0011` | Salu=`00010`, Sbb=`00010`, Sbc=`00011`, Sba=`00010`, LDF=1 | ADD, wynik→A |

### Scenariusz 3 — HLT (`IR = 1F00`)

| Krok | Stan | Kluczowe sygnały | Oczekiwane |
|------|------|------------------|------------|
| decode | `0010` | opcode `000`, pole `11111` | Rozpoznanie HLT |
| halt | `1111` | Smar=0, RD=0 | Procesor zatrzymany |

### Scenariusz 4 — BRZ (`IR = C000`, Z=1)

| Krok | Stan | Kluczowe sygnały | Oczekiwane |
|------|------|------------------|------------|
| decode | `0010` | opcode `110` | Skok warunkowy |
| brz_check | `1100` | Sba=`10100` (gdy Z=1) | Ładowanie PC z IR |

---

## Format instrukcji (IR)

```
IR(15:13) — opcode (typ instrukcji)
IR(12:8)  — pole ALU / HLT / operand
IR(7:4)   — rejestr 1 (kod 4-bit: 0000=A .. 1111=P)
IR(3:0)   — rejestr 2
```

| Opcode IR(15:13) | Instrukcja |
|------------------|------------|
| `000` | NOP / HLT (gdy IR(12:8)=11111) |
| `001` | ALU |
| `010` | LDI |
| `011` | LOAD |
| `100` | STORE |
| `101` | JUMP |
| `110` | BRZ |

Mapowanie rejestru 4-bit → selektor 5-bit: `kod_5bit = kod_4bit + 2`
(np. A=`0000` → `00010`, B=`0001` → `00011`).

---

## Przykładowe instrukcje z programu testowego

| Hex | Binarnie (skrót) | Znaczenie |
|-----|------------------|-----------|
| `4007` | `010` + A + 7 | LDI A, 7 |
| `4202` | `010` + B + 2 | LDI B, 2 |
| `2201` | `001` ADD A,A,B | ADD A, A, B |
| `1F00` | `000` HLT | Zatrzymaj |

---

## Kryterium zaliczenia

Brak `FAIL` + komunikat:

`=== CONTROL_TB: WSZYSTKIE TESTY PRZESZLY ===`

Wszystkie 4 scenariusze (LDI, ADD, HLT, BRZ) muszą przejść.
