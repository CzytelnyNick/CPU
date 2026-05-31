# Instrukcja obsługi — CPU 16-bit (ALU + rejestry + RAM)

## Zasady ogólne

- Przełączniki SW: **w górę = 1, w dół = 0** (SW0 = skrajny prawy)
- KEY[0] = zegar — wciśnij i puść = 1 cykl zegarowy
- KEY[1] = reset — zeruje rejestry (NIE czyści RAM)
- Wynik / dana widoczne na **HEX3..HEX0** w czasie rzeczywistym
- **Zawsze sprawdź HEX zanim wciśniesz KEY[0]** — na płytce nie ma cofnij

---

## Tryb pracy — SW[9:8]

| SW[9:8] | Tryb       | Opis                                  |
|---------|------------|---------------------------------------|
| `00`    | ALU        | operacje ALU na rejestrach            |
| `01`    | RAM WRITE  | zapis do pamięci RAM                   |
| `10`    | RAM READ   | odczyt z pamięci RAM                   |
| `11`    | INSPECT    | podgląd dowolnego rejestru            |

Tryb pracy jest pokazywany na `LEDR[7:6]`.

---

## TRYB ALU (SW[9:8] = `00`)

```
SW9 SW8 | SW7 SW6 | SW5 SW4 | SW3 SW2 SW1 SW0
 0   0  |  Sbc    |  Sbb    |     S_ALU
```

| Pole  | Bity    | Wartości                                   |
|-------|---------|--------------------------------------------|
| Sbc   | SW[7:6] | argument 2: 00=rA 01=rB 10=rC 11=DI        |
| Sbb   | SW[5:4] | argument 1 **oraz rejestr docelowy**: 00=rA 01=rB 10=rC 11=DI |
| S_ALU | SW[3:0] | kod operacji (tabela niżej)                |

**Zapis wyniku:** w trybie ALU wciśnięcie **KEY[0]** zapisuje wynik ALU do rejestru
wskazanego przez **Sbb** (argument 1). Sam podgląd wyniku jest na HEX bez wciskania KEY.
Gdy Sbb=DI (11) zapis jest pomijany (chroni rejestry).

### Tabela kodów operacji ALU (SW[3:0])

| Kod  | Operacja | Opis                   |
|------|----------|------------------------|
| 0000 | PASS BB  | przepisz arg1 (Sbb)    |
| 0001 | PASS BC  | przepisz arg2 (Sbc)    |
| 0010 | ADD      | arg1 + arg2            |
| 0011 | SUB      | arg1 - arg2            |
| 0100 | OR       | arg1 or arg2           |
| 0101 | AND      | arg1 and arg2          |
| 0110 | XOR      | arg1 xor arg2          |
| 0111 | XNOR     | arg1 xnor arg2         |
| 1000 | NOT      | not arg1               |
| 1001 | NEG      | -arg1                  |
| 1010 | CLR      | wyzeruj                |
| 1011 | ADC      | arg1 + arg2 + C_in*    |
| 1100 | SBB      | arg1 - arg2 - C_in*    |
| 1101 | INC      | arg1 + 1               |
| 1110 | SHL      | przesuń w lewo o 1     |
| 1111 | SHR      | przesuń w prawo o 1    |

\* `C_in` jest na stałe `0` w `CPU.vhd` (brak rejestru flagi C), więc **ADC = ADD** i **SBB = SUB**.

### Odczyt flag z LEDR

| LED     | Flaga | Znaczenie                        |
|---------|-------|----------------------------------|
| LEDR[3] | C     | przeniesienie (Carry)            |
| LEDR[2] | Z     | wynik = 0 (Zero)                 |
| LEDR[1] | S     | wynik ujemny (Sign)              |
| LEDR[0] | P     | parzysta liczba jedynek (Parity) |

`HEX4` koduje te same flagi jako jedną cyfrę hex w kolejności **C Z S P** (bit3=C … bit0=P).

---

## Test dodawania 7 + 2 (tryb ALU)

> Nie da się wpisać liczby wprost — `SW[3:0]` to jednocześnie kod operacji i dana DI.
> Liczby budujemy metodą **CLR + INC**. Cel zapisu = rejestr Sbb (SW[5:4]).

### Krok 1 — Reset
`SW = 0000000000`, wciśnij i puść KEY[1]. HEX = `0000`.

### Krok 2 — rA = 7
- CLR rA: `SW = 0000001010` (Sbb=rA), KEY[0]
- INC rA: `SW = 0000001101` (Sbb=rA), KEY[0] **×7** → HEX rośnie do `0007`

### Krok 3 — rB = 2
- CLR rB: `SW = 0000011010` (Sbb=rB), KEY[0]
- INC rB: `SW = 0000011101` (Sbb=rB), KEY[0] **×2** → `0002`

### Krok 4 — Podgląd ADD (nie wciskaj KEY)
`SW = 0001000010` (Sbc=rB, Sbb=rA, ADD) → HEX = `0009`, LEDR: C=0 S=0 Z=0 P=1

### Krok 5 — Zapis wyniku do rA
Przy tym samym `SW = 0001000010` wciśnij **KEY[0]** → rA = 9.
Podgląd: `SW = 0000000000` → HEX = `0009`.

---

## Wszystkie operacje ALU (rA=7, rB=2)

Ustaw SW (tryb `00`) i **odczytaj HEX bez wciskania KEY**. `HEX5`=kod operacji, `HEX4`=flagi.

| Operacja | SW[9:0]      | HEX5 | HEX4 (C Z S P) | HEX (wynik) | C | Z | S | P |
|----------|--------------|------|----------------|-------------|---|---|---|---|
| PASS BB  | `0000000000` | `0`  | `0`            | `0007`      | 0 | 0 | 0 | 0 |
| PASS BC  | `0001000001` | `1`  | `0`            | `0002`      | 0 | 0 | 0 | 0 |
| ADD      | `0001000010` | `2`  | `1`            | `0009`      | 0 | 0 | 0 | 1 |
| SUB      | `0001000011` | `3`  | `1`            | `0005`      | 0 | 0 | 0 | 1 |
| OR       | `0001000100` | `4`  | `0`            | `0007`      | 0 | 0 | 0 | 0 |
| AND      | `0001000101` | `5`  | `0`            | `0002`      | 0 | 0 | 0 | 0 |
| XOR      | `0001000110` | `6`  | `1`            | `0005`      | 0 | 0 | 0 | 1 |
| XNOR     | `0001000111` | `7`  | `3`            | `FFFA`      | 0 | 0 | 1 | 1 |
| NOT      | `0000001000` | `8`  | `2`            | `FFF8`      | 0 | 0 | 1 | 0 |
| NEG      | `0000001001` | `9`  | `3`            | `FFF9`      | 0 | 0 | 1 | 1 |
| CLR      | `0000001010` | `A`  | `5`            | `0000`      | 0 | 1 | 0 | 1 |
| ADC*     | `0001001011` | `b`  | `1`            | `0009`      | 0 | 0 | 0 | 1 |
| SBB*     | `0001001100` | `C`  | `1`            | `0005`      | 0 | 0 | 0 | 1 |
| INC      | `0000001101` | `d`  | `0`            | `0008`      | 0 | 0 | 0 | 0 |
| SHL      | `0000001110` | `E`  | `0`            | `000E`      | 0 | 0 | 0 | 0 |
| SHR      | `0000001111` | `F`  | `9`            | `0003`      | 1 | 0 | 0 | 1 |

\* `C_in=0`, więc ADC=ADD i SBB=SUB. P=1 = parzysta liczba jedynek.

Aby zapisać dowolny wynik do rejestru Sbb — przy ustawionym SW wciśnij **KEY[0]**.

---

## TRYB RAM WRITE (SW[9:8] = `01`)

```
SW9 SW8 | SW7 SW6 SW5 SW4 SW3 SW2 SW1 SW0
 0   1  |        adres = dana (offset, segment 0)
```

- `SW[7:0]` = **adres ORAZ dana** (zapisujemy wartość X pod adres X)
- Wciśnij **KEY[0]** → zapis do RAM
- `HEX3..0` = zapisywana dana, `HEX5..4` = adres fizyczny, `LEDR[8]` = WR

**Przykład:** zapis `0x42` pod adres `0x42`:
`SW = 0101000010`, KEY[0]. HEX3..0 = `0042`, HEX5..4 = `42`.

---

## TRYB RAM READ (SW[9:8] = `10`)

```
SW9 SW8 | SW7 SW6 SW5 SW4 SW3 SW2 SW1 SW0
 1   0  |        adres (offset, segment 0)
```

- `SW[7:0]` = adres do odczytu
- Dana pojawia się na HEX **na bieżąco** (bez KEY)
- `HEX3..0` = odczytana dana, `HEX5..4` = adres fizyczny, `LEDR[9]` = RD

**Przykłady (wartości wstępne z `ram_init.mif`):**

| SW[9:0]      | Adres | HEX (dana) |
|--------------|-------|------------|
| `1000000000` | 0x00  | `0001`     |
| `1000000011` | 0x03  | `ABCD`     |
| `1000000100` | 0x04  | `1234`     |
| `1000000101` | 0x05  | `FFFF`     |
| `1001000010` | 0x42  | `0042` (po wcześniejszym zapisie) |

> Uwaga: wartości z `ram_init.mif` ładują się przy programowaniu układu (Quartus).
> W czystej symulacji RTL komórki niezainicjowane mogą być nieokreślone — najpierw
> zapisz komórkę (tryb WRITE), potem ją odczytaj.

---

## TRYB INSPECT (SW[9:8] = `11`)

```
SW9 SW8 | SW7 SW6 SW5 SW4 | SW3 SW2 SW1 SW0
 1   1  |   kod rejestru  |   (bez znaczenia)
```

- `SW[7:4]` = kod rejestru do podglądu (mapa Sbb pliku rejestrów):
  `0010`=rA, `0011`=rB, `0100`=rC, `0101`=rD, `0110`=rE, `0111`=rF,
  `1000`=IR, `1001`=PC[15:0], …
- `HEX3..0` = zawartość rejestru, `HEX5` = kod rejestru, `HEX4` = flagi

**Przykład:** podgląd rA → `SW = 1100100000` (SW[7:4]=0010).

---

## Mapa pamięci RAM (`ram_init.mif`)

| Adres (hex) | Adres (dec) | Wartość | Segment |
|-------------|-------------|---------|---------|
| 000 | 0   | 0001 | 0 |
| 001 | 1   | 0002 | 0 |
| 002 | 2   | 0003 | 0 |
| 003 | 3   | ABCD | 0 |
| 004 | 4   | 1234 | 0 |
| 005 | 5   | FFFF | 0 |
| 100 | 256 | 0010 | 1 |
| 200 | 512 | 0020 | 2 |
| 300 | 768 | 0030 | 3 |
| pozostałe | — | 0000 | — |

> Przez przełączniki adresujemy tylko segment 0 (offset 0..255), bo SW[9:8] zajmuje tryb.
