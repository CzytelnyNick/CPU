# 22 rozkazy ALU

Kod operacji ma 5 bitow: `S_ALU = SW[4:0]`.

| Nr | Kod | Rozkaz | Opis |
|----|-----|--------|------|
| 0  | `00000` | `ADD` | dodawanie `BB + BC` |
| 1  | `00001` | `SUB` | odejmowanie `BB - BC` |
| 2  | `00010` | `MUL` | mnozenie, wynik = dolne 16 bitow `BB * BC` |
| 3  | `00011` | `DIV` | dzielenie calkowite `BB / BC` |
| 4  | `00100` | `MOD` | reszta z dzielenia `BB mod BC` |
| 5  | `00101` | `INC` | inkrementacja `BB + 1` |
| 6  | `00110` | `DEC` | dekrementacja `BB - 1` |
| 7  | `00111` | `NEG` | negacja arytmetyczna `-BB` w U2 |
| 8  | `01000` | `AND` | bitowe `BB and BC` |
| 9  | `01001` | `OR` | bitowe `BB or BC` |
| 10 | `01010` | `XOR` | bitowe `BB xor BC` |
| 11 | `01011` | `NOT` | bitowe `not BB` |
| 12 | `01100` | `NAND` | bitowe `not (BB and BC)` |
| 13 | `01101` | `NOR` | bitowe `not (BB or BC)` |
| 14 | `01110` | `SHL` | logiczne przesuniecie w lewo o 1 |
| 15 | `01111` | `SHR` | logiczne przesuniecie w prawo o 1 |
| 16 | `10000` | `SAR` | arytmetyczne przesuniecie w prawo o 1 |
| 17 | `10001` | `ROL` | rotacja w lewo o 1 |
| 18 | `10010` | `ROR` | rotacja w prawo o 1 |
| 19 | `10011` | `CMP_EQ` | wynik `0001`, gdy `BB = BC`, inaczej `0000` |
| 20 | `10100` | `CMP_LT` | wynik `0001`, gdy `signed(BB) < signed(BC)` |
| 21 | `10101` | `CMP_GT` | wynik `0001`, gdy `signed(BB) > signed(BC)` |

## Flagi

| Flaga | Znaczenie |
|-------|-----------|
| `C` | carry/borrow; dla `DIV`/`MOD` ustawiana na `1` przy dzieleniu przez zero |
| `Z` | `1`, gdy wynik = `0000` |
| `S` | znak wyniku, czyli bit `Y(15)` |
| `P` | parzystosc, `1` gdy wynik ma parzysta liczbe jedynek |

## DE1-SoC - obsluga z przelacznikow

```text
SW9   SW8   SW7   SW6 SW5   SW4 SW3 SW2 SW1 SW0
SWAP  S_F   C_in  PRESET    ALU opcode 5-bit
```

Presety argumentow:

| `SW[6:5]` | `BB` | `BC` |
|-----------|------|------|
| `00` | `0007` | `0002` |
| `01` | `8001` | `0001` |
| `10` | `00F0` | `000F` |
| `11` | `FFFF` | `0001` |

Wynik jest na `HEX3..HEX0`, flagi sa na `HEX4` oraz `LEDR[3:0]`.
