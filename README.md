# Procesor 16-bit — instrukcja testowania

> **Szybki start:** tabele testów → [`TESTY.md`](TESTY.md) · wyjaśnienie krok po kroku na zajęcia → [`JAK_DZIALA_PROCESOR.md`](JAK_DZIALA_PROCESOR.md)

Kompletny procesor składający się z: **jednostki sterującej**, **pliku rejestrów**, **ALU**, **busint** i **RAM**.
Program jest wczytywany z pliku `ram_init.mif` — po resecie PC wskazuje adres `0` i wykonanie startuje od pierwszej instrukcji.

---

## Architektura (co jest w środku)

```
                    ┌─────────────┐
                    │   control   │  maszyna stanów: f0→f1→decode→execute
                    │  (sterowanie)│
                    └──────┬──────┘
           Salu,Sbb,Sbc,...│
                           ▼
┌──────────┐   BB,BC    ┌─────────────┐   alu_Y    ┌─────┐
│   RAM    │◄──────────│ register_cpu│───────────►│ ALU │
└────┬─────┘  busint   └─────────────┘            └──┬──┘
     │         ▲              ▲                        │ flagi C,Z,S,P
     └─────────┘              └──── MIO mux: BA = alu_Y lub dane z RAM
```

| Moduł | Plik | Zadanie |
|-------|------|---------|
| **control** | `control.vhd` | Fetch instrukcji z RAM, dekodowanie, generowanie sygnałów sterujących |
| **register_cpu** | `register_cpu.vhd` | Rejestry rA..rF, PC, IR, SP, AD; szyny BB/BC/ADR |
| **alu** | `alu.vhd` | 16 operacji arytmetyczno-logicznych + flagi |
| **busint** | `busint.vhd` | MAR/MBR, segmentacja adresu, szyna danych do RAM |
| **ram** | `ram.vhd` | Pamięć 1024×16 bit, program w `ram_init.mif` |
| **CPU** | `CPU.vhd` | Top-level: łączy moduły + multipleksery + wyświetlacze |

### Multipleksery w `CPU.vhd` (nowe połączenia)

| Mux | Zadanie |
|-----|---------|
| **DI** | `IR[7:0]` rozszerzone do 16 bit → port DI rejestrów (LDI, adresy 8-bit) |
| **BA** | `MIO=0` → wynik ALU; `MIO=1` → dane z pamięci (fetch do IR, LOAD) |
| **Szyna D** | Przy `RD=1` CPU podłącza `ram.q` do busint; przy `WR=1` busint steruje zapisem |

---

## Program testowy (domyślny w `ram_init.mif`)

| Adres | Kod | Instrukcja |
|-------|-----|------------|
| 0 | `4407` | LDI rA, 7 |
| 1 | `4602` | LDI rB, 2 |
| 2 | `2123` | ADD rA, rA, rB |
| 3 | `1F00` | HLT |

**Oczekiwany wynik:** `rA = 9`, procesor w stanie **HLT** (`state_dbg = 1111`).

### Format instrukcji

| IR[15:13] | Mnemonik | Format |
|-----------|----------|--------|
| `000` | NOP/HLT | `IR[12:8]=11111` → HLT |
| `001` | ALU | `001 ooooo dddd ssss` — R[d] = R[d] op R[s] |
| `010` | LDI | `010 dddd 0 iiiiiiii` — R[d] = stała 8-bit |
| `011` | LOAD | `011 dddd 0 aaaaaaaa` — R[d] = MEM[addr] |
| `100` | STORE | `100 ssss 0 aaaaaaaa` — MEM[addr] = R[s] |
| `101` | JMP | `101 0000 0 aaaaaaaa` — skok bezwarunkowy |
| `110` | BRZ | `110 0000 0 aaaaaaaa` — skok gdy Z=1 |

Kody rejestrów: rA=`0010`, rB=`0011`, rC=`0100`.  
Kody ALU (4 bit): ADD=`0010`, SUB=`0011`, … (pełna tabela w `alu.vhd`).

---

## Sterowanie na płytce (DE1/DE2)

### Przyciski KEY (aktywne niskim)

| Przycisk | Funkcja |
|----------|---------|
| **KEY[0]** | Zegar — każde wciśnięcie i puszczenie = **1 cykl** maszyny stanów |
| **KEY[1]** | Reset — zeruje PC, rejestry i wraca do stanu `f0` |

### Przełączniki SW

| Bity | Funkcja |
|------|---------|
| **SW[1:0]** | Wybór widoku na HEX3..HEX0 (patrz tabela poniżej) |
| SW[9:2] | Nieużywane (rezerwa) |

| SW[1:0] | HEX3..HEX0 pokazuje |
|---------|---------------------|
| `00` | **rA** |
| `01` | **rB** |
| `10` | **IR** (aktualna instrukcja) |
| `11` | **PC** [15:0] |

### Wyjścia

| Wyjście | Zawartość |
|---------|-----------|
| **HEX3..HEX0** | Wybrany rejestr (SW[1:0]) |
| **HEX4** | Flagi ALU `{C, Z, S, P}` |
| **HEX5** | Stan FSM (`state_dbg`) |
| **LEDR[3:0]** | Flagi C, Z, S, P |
| **LEDR[4]** | `RD` — odczyt z RAM aktywny |
| **LEDR[5]** | `WR` — zapis do RAM aktywny |
| **LEDR[9:6]** | `state_dbg` (kopia stanu FSM) |

### Stany FSM (`state_dbg` / HEX5 / LEDR[9:6])

| Kod | Stan | Znaczenie |
|-----|------|-----------|
| `0000` | f0 | Fetch: adres = PC, odczyt z RAM |
| `0001` | f1 | Załaduj słowo do IR |
| `0010` | decode | Dekoduj instrukcję |
| `0011` | exec_alu | Wykonaj operację ALU |
| `0100` | exec_ldi | Załaduj stałą do rejestru |
| `0101`–`0111` | load_* | Sekwencja LOAD |
| `1000`–`1010` | store_* | Sekwencja STORE |
| `1011` | jump | Skok JMP |
| `1100` | brz | Skok warunkowy BRZ |
| `1111` | **halt** | Zatrzymanie — program zakończony |

---

## Test na płytce — krok po kroku

### 1. Wgraj projekt

1. Otwórz projekt `CPU.qpf` w Quartus Prime.
2. Skompiluj (**Processing → Start Compilation**).
3. Wgraj `output_files/CPU.sof` na płytkę.

### 2. Reset

- Wszystkie SW w dół (`SW = 0000000000`).
- Wciśnij i puść **KEY[1]**.
- HEX powinno pokazywać zera, stan `0000`.

### 3. Wykonaj program (ręczny zegar)

Klikaj **KEY[0]** wielokrotnie (ok. **20–25 razy** na 4 instrukcje).

Obserwuj:
- **HEX5 / LEDR[9:6]** — stany FSM zmieniają się: `0→1→2→3/4→0→…`
- Po zakończeniu: stan **`1111` (HLT)**
- **SW=00** (domyślnie): **HEX3..HEX0 = `0009`** → rA = 9 ✓

### 4. Podgląd innych rejestrów

| Chcesz zobaczyć | Ustaw SW |
|-----------------|----------|
| rA = 9 | `SW[1:0] = 00` |
| rB = 2 | `SW[1:0] = 01` |
| Ostatnia instrukcja (HLT) | `SW[1:0] = 10` → IR = `1F00` |
| PC po HLT | `SW[1:0] = 11` → PC = 4 |

### 5. Ponowne uruchomienie

Wciśnij **KEY[1]** (reset) i powtórz klikanie KEY[0].

---

## Test w QuestaSim / ModelSim

### Szybki test automatyczny

```tcl
cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU}
do run_tests.do
```

Skrypt uruchamia:
1. **alu_tb** — wszystkie operacje ALU
2. **cpu_tb** — pełny program (LDI, LDI, ADD, HLT → rA=9)

Sukces w Transcript:
```
=== ALU_TB: WSZYSTKIE TESTY PRZESZLY ===
=== CPU_TB: WSZYSTKIE TESTY PRZESZLY ===
```

### Ręczna symulacja procesora

```tcl
cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU}

if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

vcom -93 -work work hex_display.vhd
vcom -93 -work work alu.vhd
vcom -93 -work work busint.vhd
vcom -93 -work work ram.vhd
vcom -93 -work work register_cpu.vhd
vcom -93 -work work control.vhd
vcom -93 -work work CPU.vhd

vsim -voptargs=+acc work.CPU
add wave -r sim:/CPU/*

# Procedury pomocnicze
proc tick {} {
    force sim:/CPU/KEY 10
    run 20ns
    force sim:/CPU/KEY 11
    run 20ns
}
proc reset_cpu {} {
    force sim:/CPU/SW 0000000000
    force sim:/CPU/KEY 01
    run 40ns
    force sim:/CPU/KEY 11
    run 40ns
}

reset_cpu

# Wykonaj ~25 cykli programu
foreach i {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25} { tick }

# Sprawdź wyniki
examine -radix hex sim:/CPU/rA_val      ;# powinno 0x0009
examine -radix hex sim:/CPU/rB_val      ;# powinno 0x0002
examine sim:/CPU/ctrl_state_dbg         ;# powinno 1111 (HLT)
examine -radix hex sim:/CPU/reg_IR      ;# powinno 0x1F00
```

### Co obserwować w Waveform

| Sygnał | Po zakończeniu programu |
|--------|-------------------------|
| `rA_val` | `0009` |
| `rB_val` | `0002` |
| `ctrl_state_dbg` | `1111` (HLT) |
| `reg_IR` | `1F00` |
| `PC_val` | `0004` |
| `bus_RD` | pulsuje `1` w fazie fetch |
| `alu_Y` | zmienia się w fazie exec_alu |

---

## Testowanie komponentów osobno

### ALU

```tcl
vcom -93 -work work alu.vhd alu_tb.vhd
vsim work.alu_tb
run -all
```

### Plik rejestrów (ręcznie)

```tcl
vcom -93 -work work register_cpu.vhd
vsim work.register_cpu

force clk 0 0ns, 1 10ns -repeat 20ns
force reset 1; run 30ns; force reset 0

# Zapisz 7 do rA (Sba=0010, BA=7)
force Sba 0010; force BA 7; run 20ns
force Sbb 0010; run 0
examine -radix unsigned /register_cpu/rA_dbg   ;# = 7
```

### busint + RAM

```tcl
vcom -93 -work work busint.vhd ram.vhd
# (wymaga prostego tb lub testu w top - zapisz 0xABCD pod adres 0, odczytaj)
```

### control (jednostka sterująca)

```tcl
vcom -93 -work work control.vhd
vsim work.control

force clk 0 0ns, 1 10ns -repeat 20ns
force reset 1; run 30ns; force reset 0
force IR 4407   ;# LDI rA, 7
run 80ns
examine /control/state_dbg
examine /control/Sbb
```

---

## Jak zmienić program

1. Edytuj `ram_init.mif` (adresy od `000` w segmencie 0).
2. Przelicz kody instrukcji według formatu powyżej.
3. Przekompiluj projekt w Quartus (MIF jest wczytywany przy syntezie).
4. Dla symulacji skopiuj `ram_init.mif` do katalogu roboczego Questy.

### Przykład: program z LOAD

```
000 : 4407;   -- LDI rA, 7
001 : 4602;   -- LDI rB, 2
002 : 2123;   -- ADD rA, rA, rB
003 : 4100;   -- LOAD rC, MEM[0]  (wczytaj slowo spod adresu 0 = 0x4407)
004 : 1F00;   -- HLT
```

---

## Rozwiązywanie problemów

| Objaw | Przyczyna | Co zrobić |
|-------|-----------|-----------|
| HEX = 0 po wielu kliknięciach | Za mało cykli zegara | Kliknij KEY[0] więcej razy (~25) |
| Stan nie osiąga `1111` | Błąd w programie MIF | Sprawdź kody w `ram_init.mif` |
| rA ≠ 9 | Zła instrukcja ADD | Sprawdź `2123` (ADD rA,rA,rB) |
| Symulacja: błąd kompilacji | Brak `control.vhd` | Dodaj do `vcom` przed `CPU.vhd` |
| RAM pusta w symulacji | Brak MIF | Upewnij się, że `ram_init.mif` jest w cwd |

---

## Pliki projektu

| Plik | Opis |
|------|------|
| `CPU.vhd` | Top-level — pełny procesor |
| `control.vhd` | Jednostka sterująca |
| `register_cpu.vhd` | Plik rejestrów |
| `alu.vhd` | ALU |
| `busint.vhd` | Interfejs pamięci |
| `ram.vhd` | RAM |
| `ram_init.mif` | Program i dane startowe |
| `cpu_tb.vhd` | Testbench end-to-end |
| `alu_tb.vhd` | Testbench ALU |
| `run_tests.do` | Skrypt Questa — oba testy |
| `INSTRUKCJA_QUESTA.md` | Rozszerzona ściągawka komend TCL |
