# Lab 3 — Pamięć (busint + RAM)

## Pliki w tym folderze

| Plik | Opis |
|------|------|
| `busint.vhd` | Interfejs pamięci (MAR, MBR, segmentacja adresu) |
| `ram.vhd` | RAM 1024×16 bit |
| `ram_init.mif` | Program startowy i dane testowe |
| `memory_tb.vhd` | Testbench łączący busint z RAM |
| `run_tests.do` | Skrypt QuestaSim |

---

## Uruchomienie testów w QuestaSim

```tcl
cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/laby/Lab3_Pamiec}
do run_tests.do
```

**Sukces:**

```
=== MEMORY_TB: WSZYSTKIE TESTY PRZESZLY ===
```

> **Uwaga:** `ram_init.mif` musi leżeć w tym samym katalogu co `ram.vhd` (atrybut `ram_init_file`).

---

## Komendy ręczne

```tcl
cd {C:/Users/odrow/OneDrive/Dokumenty/quartus/CPU/laby/Lab3_Pamiec}
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work
vcom -93 -work work busint.vhd
vcom -93 -work work ram.vhd
vcom -93 -work work memory_tb.vhd
vsim -voptargs=+acc work.memory_tb
add wave -r sim:/memory_tb/*
run -all
```

### Sygnały do obserwacji

```tcl
add wave -radix hex sim:/memory_tb/ADR
add wave -radix hex sim:/memory_tb/phys_addr
add wave -radix hex sim:/memory_tb/bus_DI
add wave -radix hex sim:/memory_tb/ram_data_out
add wave sim:/memory_tb/bus_WR sim:/memory_tb/bus_RD
add wave sim:/memory_tb/Smar sim:/memory_tb/Smbr
```

---

## Mapa pamięci (segmentacja)

Adres fizyczny 10-bit = `segment(ADR(9:8)) << 8 + offset(ADR(7:0))`

| Segment | Zakres adresów fizycznych |
|---------|---------------------------|
| 0 | 0..255 (`0x000`..`0x0FF`) |
| 1 | 256..511 (`0x100`..`0x1FF`) |
| 2 | 512..767 (`0x200`..`0x2FF`) |
| 3 | 768..1023 (`0x300`..`0x3FF`) |

---

## Tabela testów — oczekiwane wyniki

### Grupa A — translacja adresu (phys_addr_out)

| # | Test | ADR (logiczny) | phys_addr (hex) | Komunikat |
|---|------|----------------|-----------------|-----------|
| 1 | PC = 0 | `00000000` | `000` | `PASS [addr PC=0]` |
| 2 | offset 5 | `00000105` | `105` | `PASS [addr offset 5]` |
| 3 | segment 2 (SEG=2) | offset `00`, SEG=`0002` | `0200` | `PASS [addr segment 2 offset 0]` |
| 11 | nakładanie segmentów | SEG1+off0 = SEG0+off100 | `0100` = `0100` | `PASS [overlap ...]` |

### Grupa B — odczyt z ram_init.mif

| # | Test | Adres | Oczekiwane DI | Znaczenie | Komunikat |
|---|------|-------|---------------|-----------|-----------|
| 4 | Program[0] | `00000000` | `4007` | LDI A, 7 | `PASS [MIF addr0 LDI A,7]` |
| 5 | Program[1] | `00000001` | `4202` | LDI B, 2 | `PASS [MIF addr1 LDI B,2]` |
| 6 | Program[2] | `00000002` | `2201` | ADD A,A,B | `PASS [MIF addr2 ADD]` |
| 7 | Program[3] | `00000003` | `1F00` | HLT | `PASS [MIF addr3 HLT]` |
| 8 | Dane testowe | `00000010` | `00AB` | stała w MIF | `PASS [MIF addr16 test data]` |

### Grupa C — zapis i odczyt

| # | Test | Adres | Zapis | Odczyt DI | Komunikat |
|---|------|-------|-------|-----------|-----------|
| 9 | RAM R/W | `00000020` | `BEEF` | `BEEF` | `PASS [write-read 0x20]` |
| 10 | Segment 1 | `00000100` | `1234` | `1234` | `PASS [write-read segment1]` |

---

## Zawartość ram_init.mif (fragment)

| Adres | Dane | Opis |
|-------|------|------|
| `000` | `4007` | LDI A, 7 |
| `001` | `4202` | LDI B, 2 |
| `002` | `2201` | ADD A, A, B |
| `003` | `1F00` | HLT |
| `010` | `00AB` | dane testowe LOAD |

---

## Jak działa połączenie busint ↔ RAM (jak w CPU)

```
bus_D <= ram.q        gdy RD = '1'  (odczyt)
bus_D <= MBRout       gdy WR = '1'  (zapis, steruje busint)
ram.address <= phys_addr_out   (z bieżącego ADR)
```

Sekwencja odczytu:
1. Ustaw `ADR` (adres logiczny)
2. `Smar=1`, `RDin=1` — impuls zegara
3. Sprawdź `DI` (dane z pamięci)

Sekwencja zapisu:
1. Ustaw `ADR` i `DO` (dane)
2. `Smar=1`, `Smbr=1`, `WRin=1` — impuls zegara
3. Odczytaj z tego samego adresu i porównaj

---

## Kryterium zaliczenia

Brak `FAIL` + komunikat:

`=== MEMORY_TB: WSZYSTKIE TESTY PRZESZLY ===`
