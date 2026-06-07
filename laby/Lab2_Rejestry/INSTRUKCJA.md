# Lab 2 — Plik rejestrów procesora

## Pliki w tym folderze

| Plik | Opis |
|------|------|
| `register_cpu.vhd` | 16 rejestrów A..P + IR, TMP, PC, SP, AD, ATMP |
| `register_cpu_tb.vhd` | Testbench automatyczny |
| `run_tests.do` | Skrypt QuestaSim |

---

## Uruchomienie testów w QuestaSim

```tcl
cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/laby/Lab2_Rejestry}
do run_tests.do
```

**Sukces:**

```
=== REGISTER_CPU_TB: WSZYSTKIE TESTY PRZESZLY ===
```

---

## Komendy ręczne

```tcl
cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/laby/Lab2_Rejestry}
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work
vcom -93 -work work register_cpu.vhd
vcom -93 -work work register_cpu_tb.vhd
vsim -voptargs=+acc work.register_cpu_tb
add wave -r sim:/register_cpu_tb/*
run -all
```

### Przydatne sygnały do obserwacji

```tcl
add wave -radix decimal sim:/register_cpu_tb/rA_dbg
add wave -radix decimal sim:/register_cpu_tb/rB_dbg
add wave -radix decimal sim:/register_cpu_tb/PC_dbg
add wave -radix hex sim:/register_cpu_tb/IRout
add wave -radix hex sim:/register_cpu_tb/BB
add wave -radix hex sim:/register_cpu_tb/BC
```

---

## Tabela testów — oczekiwane wyniki

| # | Test | Operacja | Wejścia | Oczekiwany wynik | Komunikat |
|---|------|----------|---------|------------------|-----------|
| 1 | Zapis rejestru A | `Sba=00010`, `BA=7` | Kod 2 = rejestr A | `rA_dbg = 7` | `PASS A write` |
| 2 | Odczyt BB = A | `Sbb=00010` | Selektor A na BB | `BB = 7` | `PASS BB=A` |
| 3 | Zapis rejestru B | `Sba=00011`, `BA=2` | Kod 3 = rejestr B | `rB_dbg = 2`, `BC = 2` | `PASS B` |
| 4 | Inkrementacja PC | `Sa=01`, `Sid=001` (2× tick) | PC++ | `PC_dbg = 2` | `PASS PC++` |
| 5 | Zapis IR | `Sba=00000`, `BA=A5A5` | Kod 0 = IR | `IRout = A5A5` | `PASS IR` |
| 6 | Rejestr flag | `LDF=1`, `FI=1001` | C=1,P=1 | `flag_C=1, flag_P=1` | `PASS FLAGS LDF` |
| 7 | Odczyt flag | `Sbb=10010` | FLAGS na BB | `BB(3:0)=1001` | `PASS FLAGS read` |
| 8 | Rejestr SEG1 | `Sba=11101`, `BA=1` | SEG1=1 | `SEGout=1` przy `Sas=01` | `PASS SEG1` |

---

## Kody selektorów 5-bitowych (Sba / Sbb / Sbc)

| Kod | Rejestr |
|-----|---------|
| `00000` | IR |
| `00001` | TMP |
| `00010` | A |
| `00011` | B |
| `00100` | C |
| … | … |
| `10001` | P |
| `10100` | PC (dolne 16 bit) |
| `10101` | PC (górne 16 bit) |
| `11000` | AD (dolne 16 bit) |
| `10010` | **FLAGS** (C,Z,S,P w bitach 3:0) |
| `10011` | **SEG0** (rejestr segmentowy) |
| `11101` | **SEG1** |
| `11110` | **SEG2** |
| `11111` | **SEG3** |

### Kody Sas (wybór rejestru segmentowego)

| Sas | Aktywny segment |
|-----|-----------------|
| `00` | SEG0 |
| `01` | SEG1 |
| `10` | SEG2 |
| `11` | SEG3 |

### Kody Sid (inkrement/dekrement)

| Sid | Operacja |
|-----|----------|
| `001` | PC := PC + 1 |
| `010` | SP := SP + 1 |
| `011` | SP := SP - 1 |
| `100` | AD := AD + 1 |
| `101` | AD := AD - 1 |

### Kody Sa (wybór ADR)

| Sa | ADR wskazuje na |
|----|-----------------|
| `00` | AD |
| `01` | PC |
| `10` | SP |
| `11` | ATMP |

---

## Sekwencja testu (co robi testbench)

1. **Reset** — wszystkie rejestry = 0
2. Zapis `7` do rejestru **A** (`Sba=2`)
3. Odczyt **A** na szynę **BB** (`Sbb=2`)
4. Zapis `2` do rejestru **B** (`Sba=3`)
5. Dwa cykle **PC++** (`Sid=1`, `Sa=1`)
6. Zapis `A5A5` do **IR** (`Sba=0`)

---

## Kryterium zaliczenia

Brak linii `FAIL` w Transcript + komunikat:

`=== REGISTER_CPU_TB: WSZYSTKIE TESTY PRZESZLY ===`
