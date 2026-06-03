# Instrukcja obsługi płytki DE1-SoC / DE0 — CPU 16-bit

## Zasady ogólne

- Przełączniki SW: **w górę = 1, w dół = 0** (liczymy od prawej: SW0 = skrajny prawy)
- KEY[0] = zegar — wciśnij i puść = 1 cykl zegarowy
- KEY[1] = reset — wciśnij i puść = zeruje wszystkie rejestry **oraz wyświetlany wynik**
- **Wynik ALU pojawia się na HEX3..HEX0 dopiero PO kliknięciu KEY[0]** —
  operacja jest wykonywana na zboczu zegara i zatrzaskiwana w rejestrze wyniku.
  Sam wybór operacji przełącznikami nie zmienia jeszcze wyświetlacza.
- Flagi na **LEDR[3:0]** również pokazują wynik OSTATNIO wykonanej (klikniętej)
  operacji. LEDR[9:4] pokazują bieżący stan przełączników na żywo.
- Aby zobaczyć wynik operacji: ustaw SW, **kliknij KEY[0]**, odczytaj HEX.

---

## Legenda przełączników SW[9:0]

```
SW9  SW8  SW7  SW6  SW5  SW4  SW3  SW2  SW1  SW0
DST  WEN  Sbc  Sbc  Sbb  Sbb  ALU  ALU  ALU  ALU
```

| Pole   | Bity   | Wartości                              |
|--------|--------|---------------------------------------|
| DST    | SW[9]  | 0 = zapisz do rA, 1 = zapisz do rB   |
| WEN    | SW[8]  | 0 = tylko podgląd, 1 = zapisz wynik  |
| Sbc    | SW[7:6]| 00=rA, 01=rB, 10=rC, 11=DI           |
| Sbb    | SW[5:4]| 00=rA, 01=rB, 10=rC, 11=DI           |
| ALU    | SW[3:0]| patrz tabela operacji poniżej         |

### Tabela kodów operacji ALU (SW[3:0])

| Kod  | Operacja | Opis                   |
|------|----------|------------------------|
| 0000 | PASS BB  | przepisz rA na wyjście |
| 0001 | PASS BC  | przepisz rB na wyjście |
| 0010 | ADD      | rA + rB                |
| 0011 | SUB      | rA - rB                |
| 0100 | OR       | rA or rB               |
| 0101 | AND      | rA and rB              |
| 0110 | XOR      | rA xor rB              |
| 0111 | XNOR     | rA xnor rB             |
| 1000 | NOT      | not rA                 |
| 1001 | NEG      | -rA                    |
| 1010 | CLR      | wyzeruj                |
| 1011 | ADC      | rA + rB + C            |
| 1100 | SBB      | rA - rB - C            |
| 1101 | INC      | rA + 1                 |
| 1110 | SHL      | przesuń lewo o 1 bit   |
| 1111 | SHR      | przesuń prawo o 1 bit  |

### Odczyt flag z LEDR

| LED    | Flaga | Znaczenie                        |
|--------|-------|----------------------------------|
| LEDR[3]| C     | przeniesienie (Carry)            |
| LEDR[2]| Z     | wynik = 0 (Zero)                 |
| LEDR[1]| S     | wynik ujemny (Sign)              |
| LEDR[0]| P     | parzysta liczba jedynek (Parity) |

> Dodatkowo: LEDR[4]=WEN, LEDR[5]=DST, LEDR[7:6]=Sbb, LEDR[9:8]=Sbc.

---

## Test dodawania 7 + 2

> Uwaga: nie można wpisać 7 bezpośrednio przez SW — używamy metody CLR + INC.

### Krok 1 — Reset

Ustaw wszystkie SW w dół. Wciśnij KEY[1] i puść.

```
SW  = 0000000000
KEY[1]: wciśnij ↓ puść ↑
```

HEX = `0000`, wszystkie LEDy zgaszone.

---

### Krok 2 — Wyzeruj rA (CLR)

```
SW9=0  SW8=1  SW7=0  SW6=0  SW5=0  SW4=0  SW3=1  SW2=0  SW1=1  SW0=0
SW = 0100001010
```

Sprawdź HEX = `0000`, potem: KEY[0] wciśnij ↓ puść ↑

---

### Krok 3 — Wpisz 7 do rA (INC × 7)

```
SW9=0  SW8=1  SW7=0  SW6=0  SW5=0  SW4=0  SW3=1  SW2=1  SW1=0  SW0=1
SW = 0100001101
```

Klikaj KEY[0] **7 razy**. HEX powinno rosnąć po każdym kliknięciu:

| Kliknięcie | HEX      |
|------------|----------|
| 1          | `0001`   |
| 2          | `0002`   |
| 3          | `0003`   |
| 4          | `0004`   |
| 5          | `0005`   |
| 6          | `0006`   |
| **7**      | **`0007` ✓** |

---

### Krok 4 — Wyzeruj rB (CLR)

```
SW9=1  SW8=1  SW7=0  SW6=0  SW5=0  SW4=0  SW3=1  SW2=0  SW1=1  SW0=0
SW = 1100001010
```

Sprawdź HEX = `0000`, potem: KEY[0] wciśnij ↓ puść ↑

---

### Krok 5 — Wpisz 2 do rB (INC × 2)

```
SW9=1  SW8=1  SW7=0  SW6=0  SW5=1  SW4=0  SW3=1  SW2=1  SW1=0  SW0=1
SW = 1100011101
```

Klikaj KEY[0] **2 razy**:

| Kliknięcie | HEX      |
|------------|----------|
| 1          | `0001`   |
| **2**      | **`0002` ✓** |

---

### Krok 6 — Oblicz ADD (kliknij KEY[0])

```
SW9=0  SW8=0  SW7=0  SW6=1  SW5=0  SW4=0  SW3=0  SW2=0  SW1=1  SW0=0
SW = 0001000010
```

Ponieważ WEN=0 (SW[8]=0), kliknięcie tylko **wyświetli** wynik, bez zapisu
do rejestru. Ustaw SW i **kliknij KEY[0]**, potem odczytaj HEX:

- HEX = `0009` ✓ — kontynuuj
- HEX ≠ `0009` — wróć do Kroku 1

LEDR: C=0, S=0, Z=0, P=1

---

### Krok 7 — Zapisz wynik do rA

```
SW9=0  SW8=1  SW7=0  SW6=1  SW5=0  SW4=0  SW3=0  SW2=0  SW1=1  SW0=0
SW = 0101000010
```

KEY[0] wciśnij ↓ puść ↑

**HEX = `0009` ✓ — wynik 9 zapisany w rA.**

---

## Wszystkie operacje ALU na płytce

Zakładamy że rA=7 i rB=2 są już wpisane (po teście dodawania).  
Ustaw SW, **kliknij KEY[0]** i odczytaj HEX (wynik zostaje zatrzaśnięty po kliknięciu).
Przy WEN=0 (SW[8]=0) wynik jest tylko wyświetlany; aby go zapisać — ustaw SW[8]=1 i kliknij KEY[0].

---

### ADD — 7 + 2 = 9

```
SW = 0001000010
```
HEX = `0009` | LEDR: C=0 S=0 Z=0 P=1

---

### SUB — 7 - 2 = 5

```
SW = 0001000011
```
HEX = `0005` | LEDR: C=0 S=0 Z=0 P=1

---

### AND — 7 and 2 = 2

```
SW = 0001000101
```
HEX = `0002` | LEDR: C=0 S=0 Z=0 P=0  (wynik 2 ma nieparzysta liczbe jedynek)

---

### OR — 7 or 2 = 7

```
SW = 0001000100
```
HEX = `0007` | LEDR: C=0 S=0 Z=0 P=0  (wynik 7 = trzy jedynki, nieparzysta)

---

### XOR — 7 xor 2 = 5

```
SW = 0001000110
```
HEX = `0005` | LEDR: C=0 S=0 Z=0 P=1

---

### NOT — not 7 = FFF8

```
SW = 0000001000
```
HEX = `FFF8` | LEDR: S=1 (wynik ujemny w U2)

---

### NEG — -7 = FFF9

```
SW = 0000001001
```
HEX = `FFF9` | LEDR: S=1

---

### INC — 7 + 1 = 8

```
SW = 0000001101
```
HEX = `0008`

---

### SHL — 7 × 2 = 14

```
SW = 0000001110
```
HEX = `000E`

---

### SHR — 7 ÷ 2 = 3

```
SW = 0000001111
```
HEX = `0003` | LEDR: C=1 (wypadł bit LSB)

---

### CLR — zerowanie

```
SW = 0000001010
```
HEX = `0000` | LEDR: Z=1

---

### ADC — 7 + 2 + C_in

```
SW = 0001001011
```
> UWAGA: w obecnej wersji `CPU.vhd` wejscie `C_in` ALU jest na stale ustawione na `0`
> (nie ma rejestru flagi przeniesienia). Dlatego na plytce **ADC dziala jak ADD**:
> HEX = `0009`. Aby uzyskac `000A`, trzeba doprowadzic do `C_in` zapamietana flage C.

---

### SBB — 7 - 2 - C_in

```
SW = 0001001100
```
> UWAGA: jak wyzej — `C_in = 0`, wiec **SBB dziala jak SUB**: HEX = `0005`.

---

## Tabela wszystkich operacji — szybka ściągawka

| Operacja | SW[9:0]      | HEX     | C | Z | S | P |
|----------|--------------|---------|---|---|---|---|
| ADD      | `0001000010` | `0009`  | 0 | 0 | 0 | 1 |
| SUB      | `0001000011` | `0005`  | 0 | 0 | 0 | 1 |
| AND      | `0001000101` | `0002`  | 0 | 0 | 0 | 0 |
| OR       | `0001000100` | `0007`  | 0 | 0 | 0 | 0 |
| XOR      | `0001000110` | `0005`  | 0 | 0 | 0 | 1 |
| NOT      | `0000001000` | `FFF8`  | 0 | 0 | 1 | 0 |
| NEG      | `0000001001` | `FFF9`  | 0 | 0 | 1 | 1 |
| INC      | `0000001101` | `0008`  | 0 | 0 | 0 | 0 |
| SHL      | `0000001110` | `000E`  | 0 | 0 | 0 | 0 |
| SHR      | `0000001111` | `0003`  | 1 | 0 | 0 | 1 |
| CLR      | `0000001010` | `0000`  | 0 | 1 | 0 | 1 |
| ADC*     | `0001001011` | `0009`  | 0 | 0 | 0 | 1 |
| SBB*     | `0001001100` | `0005`  | 0 | 0 | 0 | 1 |

> \* `C_in` jest na stale `0` w `CPU.vhd`, wiec ADC=ADD i SBB=SUB (patrz uwagi wyzej).
> P = 1 oznacza **parzysta** liczba jedynek w wyniku.

---

## Jak zapisać wynik dowolnej operacji

Weź SW z kolumny tabeli, zmień **SW[8] na 1** i kliknij KEY[0].

Przykład — zapisz wynik SUB (5) do rA:
```
SW = 0101000011   (SW[8]=1, reszta jak dla SUB)
KEY[0]: wciśnij ↓ puść ↑
```
HEX = `0005` pozostaje, rA = 5 zapisane.
