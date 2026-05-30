# Instrukcja ModelSim — CPU 16-bit

## Legenda przełączników SW[9:0]

```
SW[9]   = DST  — rejestr docelowy: 0=rA, 1=rB
SW[8]   = WEN  — zapis do rejestru: 1=tak, 0=nie
SW[7:6] = Sbc  — argument 2 ALU:  00=rA, 01=rB, 10=rC, 11=DI
SW[5:4] = Sbb  — argument 1 ALU:  00=rA, 01=rB, 10=rC, 11=DI
SW[3:0] = ALU  — kod operacji:    1010=CLR, 1101=INC, 0010=ADD
```

Kody KEY (aktywne niskim):
```
KEY = 11  — bezczynny (oba przyciski puszczone)
KEY = 01  — KEY[1] wciśnięty = RESET aktywny
KEY = 10  — KEY[0] wciśnięty = zbocze zegara
```

Wpisuj komendy w oknie **Transcript**. Po każdej komendzie `force` wykonaj `run 100ns`.

> **Najpierw uruchom symulację top-level entity (nazywa się `CPU`):**
>
> ```tcl
> vlib work
> vcom -93 hex_display.vhd alu.vhd busint.vhd ram.vhd register_cpu.vhd CPU.vhd
> vsim work.CPU
> ```
>
> Dopiero potem działają poniższe komendy `force`. Ścieżki sygnałów mają
> postać `sim:/CPU/<sygnal>` (np. `sim:/CPU/reg_BB`, `sim:/CPU/alu_Y`).

> **Uwaga:** Nie można wpisać liczby bezpośrednio — `SW[3:0]` pełni jednocześnie
> rolę kodu operacji ALU i wartości DI. Używamy metody **CLR + INC**.

---

## Test dodawania 7 + 2

### FAZA 1 — Reset

```tcl
force sim:/CPU/SW 0000000000
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/KEY 01
run 100ns
force sim:/CPU/KEY 11
run 100ns
```

Sprawdź: `reg_BB = 0`, `reg_BC = 0`, `alu_Z = 1`

---

### FAZA 2 — CLR → rA

```tcl
force sim:/CPU/SW 0100001010
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
```

Sprawdź: `reg_BB = 0000000000000000`

---

### FAZA 3 — INC rA × 7

```tcl
force sim:/CPU/SW 0100001101
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
```

| Kliknięcie | reg_BB (rA)              |
|------------|--------------------------|
| 1          | `0000000000000001`       |
| 2          | `0000000000000010`       |
| 3          | `0000000000000011`       |
| 4          | `0000000000000100`       |
| 5          | `0000000000000101`       |
| 6          | `0000000000000110`       |
| **7**      | **`0000000000000111` ✓** |

---

### FAZA 4 — CLR → rB

```tcl
force sim:/CPU/SW 1100001010
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
```

Sprawdź: `reg_BC = 0000000000000000`

---

### FAZA 5 — INC rB × 2

```tcl
force sim:/CPU/SW 1100011101
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
```

| Kliknięcie | reg_BC (rB)              |
|------------|--------------------------|
| 1          | `0000000000000001`       |
| **2**      | **`0000000000000010` ✓** |

---

### FAZA 6 — Podgląd ADD (bez zapisu)

> Nie klikaj KEY[0] — tylko sprawdź alu_Y!

```tcl
force sim:/CPU/SW 0001000010
run 100ns
```

| Sygnał   | Oczekiwana wartość   | Znaczenie            |
|----------|---------------------|----------------------|
| `alu_BB` | `0000000000000111`  | argument 1 = 7       |
| `alu_BC` | `0000000000000010`  | argument 2 = 2       |
| `alu_Y`  | `0000000000001001`  | wynik = **9 ✓**      |
| `alu_C`  | `0`                 | brak przeniesienia   |
| `alu_Z`  | `0`                 | wynik niezerowy      |
| `alu_S`  | `0`                 | wynik dodatni        |
| `alu_P`  | `1`                 | parzysta l. jedynek  |

Jeśli `alu_Y ≠ 0000000000001001` — wróć do FAZY 1.

---

### FAZA 7 — Zapisz wynik do rA

```tcl
force sim:/CPU/SW 0101000010
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
```

Sprawdź: `reg_BB = 0000000000001001` = **9 ✓**

---

### Gotowy skrypt (wklej cały blok do Transcript)

```tcl
force sim:/CPU/SW 0000000000
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/KEY 01
run 100ns
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/SW 0100001010
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/SW 0100001101
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/SW 1100001010
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/SW 1100011101
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
force sim:/CPU/SW 0001000010
run 100ns
force sim:/CPU/SW 0101000010
run 100ns
force sim:/CPU/KEY 10
run 100ns
force sim:/CPU/KEY 11
run 100ns
```

---

## Inne operacje ALU w ModelSim

Zakładamy że rA=7 i rB=2 są już wpisane (po teście dodawania).  
Każda komenda poniżej to tylko podgląd (WEN=0). Aby zapisać wynik — zmień SW[8] na 1 i kliknij KEY[0].

### ADD — 7 + 2 = 9
```tcl
force sim:/CPU/SW 0001000010
run 100ns
```
Wynik: `alu_Y = 0000000000001001`, C=0, Z=0, S=0, P=1

---

### SUB — 7 - 2 = 5
```tcl
force sim:/CPU/SW 0001000011
run 100ns
```
Wynik: `alu_Y = 0000000000000101`, C=0, Z=0, S=0, P=1

---

### AND — 7 and 2 = 2
```tcl
force sim:/CPU/SW 0001000101
run 100ns
```
Wynik: `alu_Y = 0000000000000010`, Z=0, S=0

---

### OR — 7 or 2 = 7
```tcl
force sim:/CPU/SW 0001000100
run 100ns
```
Wynik: `alu_Y = 0000000000000111`

---

### XOR — 7 xor 2 = 5
```tcl
force sim:/CPU/SW 0001000110
run 100ns
```
Wynik: `alu_Y = 0000000000000101`

---

### NOT — not 7 = -8 (U2)
```tcl
force sim:/CPU/SW 0000001000
run 100ns
```
Wynik: `alu_Y = 1111111111111000`, S=1

---

### NEG — -7 (U2)
```tcl
force sim:/CPU/SW 0000001001
run 100ns
```
Wynik: `alu_Y = 1111111111111001`, S=1

---

### INC — 7 + 1 = 8
```tcl
force sim:/CPU/SW 0000001101
run 100ns
```
Wynik: `alu_Y = 0000000000001000`

---

### SHL — 7 << 1 = 14
```tcl
force sim:/CPU/SW 0000001110
run 100ns
```
Wynik: `alu_Y = 0000000000001110`

---

### SHR — 7 >> 1 = 3
```tcl
force sim:/CPU/SW 0000001111
run 100ns
```
Wynik: `alu_Y = 0000000000000011`, C=1

---

### CLR — wyzeruj
```tcl
force sim:/CPU/SW 0000001010
run 100ns
```
Wynik: `alu_Y = 0000000000000000`, Z=1

---

### ADC — 7 + 2 + C_in
```tcl
force sim:/CPU/SW 0001001011
run 100ns
```
Wynik: `alu_Y = 0000000000001001` (= 9). W tym projekcie `C_in=0`, więc ADC = ADD.

---

### SBB — 7 - 2 - C_in
```tcl
force sim:/CPU/SW 0001001100
run 100ns
```
Wynik: `alu_Y = 0000000000000101` (= 5). W tym projekcie `C_in=0`, więc SBB = SUB.

---

## Tabela wyników dla rA=7, rB=2

| Operacja | SW[9:0]      | Wynik (dec) | alu_Y (hex) | C | Z | S | P |
|----------|--------------|-------------|-------------|---|---|---|---|
| ADD      | `0001000010` | 9           | 0x0009      | 0 | 0 | 0 | 1 |
| SUB      | `0001000011` | 5           | 0x0005      | 0 | 0 | 0 | 1 |
| AND      | `0001000101` | 2           | 0x0002      | 0 | 0 | 0 | 0 |
| OR       | `0001000100` | 7           | 0x0007      | 0 | 0 | 0 | 0 |
| XOR      | `0001000110` | 5           | 0x0005      | 0 | 0 | 0 | 1 |
| NOT      | `0000001000` | -8 (U2)     | 0xFFF8      | 0 | 0 | 1 | 0 |
| NEG      | `0000001001` | -7 (U2)     | 0xFFF9      | 0 | 0 | 1 | 1 |
| INC      | `0000001101` | 8           | 0x0008      | 0 | 0 | 0 | 0 |
| SHL      | `0000001110` | 14          | 0x000E      | 0 | 0 | 0 | 0 |
| SHR      | `0000001111` | 3           | 0x0003      | 1 | 0 | 0 | 1 |
| CLR      | `0000001010` | 0           | 0x0000      | 0 | 1 | 0 | 1 |
| ADC*     | `0001001011` | 9           | 0x0009      | 0 | 0 | 0 | 1 |
| SBB*     | `0001001100` | 5           | 0x0005      | 0 | 0 | 0 | 1 |

> \* W `CPU.vhd` wejście `C_in` ALU jest na stałe `0` (brak rejestru flagi C),
> więc w tym projekcie **ADC = ADD** i **SBB = SUB**. P=1 = parzysta liczba jedynek.
