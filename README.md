# ALU 16-bit na DE1-SoC - 22 rozkazy

Projekt uruchamia demonstrator ALU na plytce **DE1-SoC**. Wynik jest
pokazywany na wyswietlaczach HEX w czasie rzeczywistym, bez klikania zegara.

Kod operacji ALU ma teraz **5 bitow**, wiec mozna wybrac wiecej niz 16 rozkazow:

```text
2^4 = 16  za malo
2^5 = 32  wystarczy dla 22 rozkazow
```

## Mapowanie przelacznikow SW[9:0]

```text
SW9   SW8   SW7   SW6 SW5   SW4 SW3 SW2 SW1 SW0
SWAP  S_F   C_in  PRESET    ALU opcode 5-bit
```

| Pole | Bity | Znaczenie |
|------|------|-----------|
| `ALU opcode` | `SW[4:0]` | kod rozkazu ALU, zakres `00000`..`10101` |
| `PRESET` | `SW[6:5]` | wybor gotowych argumentow `BB` i `BC` |
| `C_in` | `SW[7]` | przeniesienie wejsciowe do ALU |
| `S_F` | `SW[8]` | `0` = pokaz wynik, `1` = pokaz flagi w `HEX3..HEX0` |
| `SWAP` | `SW[9]` | `0` = normalnie `BB,BC`, `1` = zamien argumenty |

## Gotowe argumenty BB/BC

| `SW[6:5]` | `BB` | `BC` | Do czego dobre |
|-----------|------|------|----------------|
| `00` | `0007` | `0002` | podstawowe ADD/SUB/MUL/DIV/MOD/CMP |
| `01` | `8001` | `0001` | przesuniecia, rotacje, znak i carry |
| `10` | `00F0` | `000F` | operacje logiczne |
| `11` | `FFFF` | `0001` | carry, overflow dolnych 16 bitow, zero |

Jesli `SW9=1`, ALU dostaje argumenty zamienione miejscami.

## Wyswietlacze i LED

| Wyjscie | Znaczenie |
|---------|-----------|
| `HEX3..HEX0` | 16-bitowy wynik ALU albo flagi, gdy `SW8=1` |
| `HEX4` | flagi jako nibble `{C,Z,S,P}` |
| `HEX5` | mlodsze 4 bity kodu operacji |
| `LEDR[0]` | `P` - parity, parzysta liczba jedynek |
| `LEDR[1]` | `S` - sign, najstarszy bit wyniku |
| `LEDR[2]` | `Z` - zero, wynik rowny zero |
| `LEDR[3]` | `C` - carry/borrow/blad dzielenia |
| `LEDR[4]` | piaty bit kodu operacji `S_ALU[4]` |
| `LEDR[6:5]` | aktualny preset |
| `LEDR[7]` | `C_in` |
| `LEDR[8]` | `S_F` |
| `LEDR[9]` | `SWAP` |

## Pelna tabela 22 rozkazow ALU

Domyslny preset dla przykladow: `SW[6:5]=00`, czyli `BB=0007`, `BC=0002`.

| Nr | Kod `SW[4:0]` | Rozkaz | Dzialanie | Przyklad HEX |
|----|---------------|--------|-----------|--------------|
| 0  | `00000` | `ADD`    | `BB + BC` | `0009` |
| 1  | `00001` | `SUB`    | `BB - BC` | `0005` |
| 2  | `00010` | `MUL`    | `BB * BC`, dolne 16 bitow | `000E` |
| 3  | `00011` | `DIV`    | `BB / BC` | `0003` |
| 4  | `00100` | `MOD`    | `BB mod BC` | `0001` |
| 5  | `00101` | `INC`    | `BB + 1` | `0008` |
| 6  | `00110` | `DEC`    | `BB - 1` | `0006` |
| 7  | `00111` | `NEG`    | `-BB` w U2 | `FFF9` |
| 8  | `01000` | `AND`    | `BB and BC` | `0002` |
| 9  | `01001` | `OR`     | `BB or BC` | `0007` |
| 10 | `01010` | `XOR`    | `BB xor BC` | `0005` |
| 11 | `01011` | `NOT`    | `not BB` | `FFF8` |
| 12 | `01100` | `NAND`   | `not (BB and BC)` | `FFFD` |
| 13 | `01101` | `NOR`    | `not (BB or BC)` | `FFF8` |
| 14 | `01110` | `SHL`    | przesuniecie logiczne w lewo o 1 | `000E` |
| 15 | `01111` | `SHR`    | przesuniecie logiczne w prawo o 1 | `0003` |
| 16 | `10000` | `SAR`    | przesuniecie arytmetyczne w prawo o 1 | preset `01`: `C000` |
| 17 | `10001` | `ROL`    | rotacja w lewo o 1 | preset `01`: `0003` |
| 18 | `10010` | `ROR`    | rotacja w prawo o 1 | preset `01`: `C000` |
| 19 | `10011` | `CMP_EQ` | `1` gdy `BB = BC`, inaczej `0` | `0000` |
| 20 | `10100` | `CMP_LT` | `1` gdy `signed(BB) < signed(BC)` | `0000` |
| 21 | `10101` | `CMP_GT` | `1` gdy `signed(BB) > signed(BC)` | `0001` |

Uwagi:

- `DIV` i `MOD` dla `BC=0` zwracaja `0000` i ustawiaja flage `C=1`.
- `MUL` zwraca dolne 16 bitow wyniku; `C=1`, gdy gorne 16 bitow nie sa zerem.
- `CMP_LT` i `CMP_GT` porownuja liczby jako signed/U2.
- Kody `10110`..`11111` sa wolne i zwracaja `0000`.

## Szybkie testy na plytce

Ustaw `SW[6:5]=00`, `SW8=0`, `SW9=0`.

| Operacja | `SW[9:0]` | Oczekiwany wynik |
|----------|-----------|------------------|
| `ADD 7+2` | `0000000000` | `HEX3..HEX0 = 0009` |
| `SUB 7-2` | `0000000001` | `HEX3..HEX0 = 0005` |
| `MUL 7*2` | `0000000010` | `HEX3..HEX0 = 000E` |
| `DIV 7/2` | `0000000011` | `HEX3..HEX0 = 0003` |
| `MOD 7%2` | `0000000100` | `HEX3..HEX0 = 0001` |
| `CMP_GT 7>2` | `0000010101` | `HEX3..HEX0 = 0001` |
| `CMP_GT 2>7` z `SWAP` | `1000010101` | `HEX3..HEX0 = 0000` |

Test przesuniec/rotacji z presetem `01`:

| Operacja | `SW[9:0]` | Oczekiwany wynik |
|----------|-----------|------------------|
| `SAR 8001` | `0000110000` | `C000` |
| `ROL 8001` | `0000110001` | `0003` |
| `ROR 8001` | `0000110010` | `C000` |

Podglad flag:

```text
SW8 = 1
HEX3..HEX0 pokazuje wtedy 000{C,Z,S,P}
HEX4 zawsze pokazuje {C,Z,S,P}
```

Przyklad dla `ADD 7+2`:

```text
SW = 0100000000
HEX3..HEX0 = 0001
```

bo flagi sa `{C,Z,S,P} = 0001`.

## Pliki

- `alu.vhd` - ALU z 22 rozkazami i 5-bitowym `S_ALU`
- `CPU.vhd` - top-level pod DE1-SoC z mapowaniem `SW/HEX/LEDR`
- `ALU_OPERACJE_22.md` - sama tabela rozkazow do skopiowania
- `alu_tb.vhd` - testbench wszystkich 22 operacji
- `cpu_tb.vhd` - testbench mapowania plytki
