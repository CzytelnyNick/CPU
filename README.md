# CPU 16-bit na DE1-SoC - ALU 22 rozkazy + jednostka sterujaca

Projekt ma teraz dwa tryby pracy wybierane przełącznikiem `SW9`:

```text
SW9 = 0  demonstrator ALU na 22 rozkazy
SW9 = 1  prosty procesor: RAM -> IR -> control -> rejestry/ALU/busint
```

`KEY[0]` jest ręcznym zegarem w trybie procesora, a `KEY[1]` jest resetem
aktywnym niskim stanem. Sygnały pamięci są wygaszane poza trybem procesora,
więc demonstrator ALU nie wykonuje ukrytych cykli RAM w tle.

---

## Tryb 1: demonstrator ALU (`SW9=0`)

```text
SW8   SW7   SW6 SW5   SW4 SW3 SW2 SW1 SW0
S_F   C_in  PRESET    ALU opcode 5-bit
```

| Pole | Bity | Znaczenie |
|------|------|-----------|
| `ALU opcode` | `SW[4:0]` | kod rozkazu ALU, zakres `00000`..`10101` |
| `PRESET` | `SW[6:5]` | gotowe argumenty `BB` i `BC` |
| `C_in` | `SW[7]` | przeniesienie wejściowe do ALU |
| `S_F` | `SW[8]` | `0` = wynik, `1` = flagi na `HEX3..HEX0` |

Presety argumentów:

| `SW[6:5]` | `BB` | `BC` |
|-----------|------|------|
| `00` | `0007` | `0002` |
| `01` | `8001` | `0001` |
| `10` | `00F0` | `000F` |
| `11` | `FFFF` | `0001` |

Wynik jest na `HEX3..HEX0`, flagi na `HEX4`, a młodsze 4 bity kodu ALU na
`HEX5`.

---

## 22 rozkazy ALU

| Nr | Kod `SW[4:0]` / `Salu` | Rozkaz | Działanie |
|----|------------------------|--------|-----------|
| 0  | `00000` | `ADD`    | `BB + BC` |
| 1  | `00001` | `SUB`    | `BB - BC` |
| 2  | `00010` | `MUL`    | `BB * BC`, dolne 16 bitów |
| 3  | `00011` | `DIV`    | `BB / BC` |
| 4  | `00100` | `MOD`    | `BB mod BC` |
| 5  | `00101` | `INC`    | `BB + 1` |
| 6  | `00110` | `DEC`    | `BB - 1` |
| 7  | `00111` | `NEG`    | `-BB` w U2 |
| 8  | `01000` | `AND`    | `BB and BC` |
| 9  | `01001` | `OR`     | `BB or BC` |
| 10 | `01010` | `XOR`    | `BB xor BC` |
| 11 | `01011` | `NOT`    | `not BB` |
| 12 | `01100` | `NAND`   | `not (BB and BC)` |
| 13 | `01101` | `NOR`    | `not (BB or BC)` |
| 14 | `01110` | `SHL`    | przesunięcie logiczne w lewo |
| 15 | `01111` | `SHR`    | przesunięcie logiczne w prawo |
| 16 | `10000` | `SAR`    | przesunięcie arytmetyczne w prawo |
| 17 | `10001` | `ROL`    | rotacja w lewo |
| 18 | `10010` | `ROR`    | rotacja w prawo |
| 19 | `10011` | `CMP_EQ` | `0001`, gdy `BB = BC` |
| 20 | `10100` | `CMP_LT` | `0001`, gdy `signed(BB) < signed(BC)` |
| 21 | `10101` | `CMP_GT` | `0001`, gdy `signed(BB) > signed(BC)` |

---

## Tryb 2: procesor z jednostką sterującą (`SW9=1`)

W tym trybie `control.vhd` steruje całym datapath:

```text
RAM -> busint -> register_cpu(IR/rejestry/PC/AD) -> ALU -> register_cpu
```

Cykl jednostki sterującej:

```text
f0      pobranie instrukcji z RAM pod adresem PC, PC = PC + 1
f1      wpisanie pobranego słowa do IR
decode  dekodowanie IR
execute wykonanie mikrooperacji danej instrukcji
```

### Przełączniki w trybie procesora

```text
SW9 = 1
SW8 = INT
SW7 SW6 = wybór podglądu na HEX3..HEX0
```

| `SW[7:6]` | `HEX3..HEX0` pokazuje |
|-----------|------------------------|
| `00` | `IR` - aktualny rejestr rozkazu |
| `01` | bieżący wynik ALU |
| `10` | `DI` - dane odebrane z pamięci przez busint |
| `11` | adres fizyczny RAM (`phys_addr`) |

`HEX4` pokazuje zatrzaśnięte flagi `{C,Z,S,P}` procesora, a `HEX5` pokazuje
aktualny stan jednostki sterującej.

### LED w trybie procesora

| LED | Znaczenie |
|-----|-----------|
| `LEDR[3:0]` | flagi `{P,S,Z,C}` |
| `LEDR[4]` | `LDF`, ładowanie flag |
| `LEDR[5]` | `RD` z busint |
| `LEDR[6]` | `WR` z busint |
| `LEDR[7]` | `MIO`, wybór danych z pamięci do zapisu w rejestrach |
| `LEDR[8]` | `INTA` |
| `LEDR[9]` | tryb procesora aktywny |

---

## Format instrukcji IR

Rejestry używają kodów z `register_cpu.vhd`:

```text
0000=DI   0001=TMP  0010=rA  0011=rB
0100=rC   0101=rD   0110=rE  0111=rF
1000=IR   1001=PC low  1010=PC high
1011=SP low 1100=SP high 1101=AD low
1110=ATMP low 1111=ATMP high
```

### `NOP` / `HLT`

```text
000 xxxxx ........
```

- `IR[12:8] = 11111` oznacza `HLT`
- inne wartości w grupie `000` działają jak `NOP`

### Instrukcja ALU

```text
001 ooooo dddd ssss
```

| Pole | Znaczenie |
|------|-----------|
| `ooooo` | 5-bitowy kod ALU, ta sama tabela co wyżej |
| `dddd` | rejestr docelowy i argument `BB` |
| `ssss` | rejestr źródłowy `BC` |

Działanie:

```text
R[dddd] = R[dddd] op R[ssss]
```

Przykład:

```text
2023 = ADD rA, rB
2223 = MUL rA, rB
```

### `LDI` - załaduj natychmiastową wartość 8-bit

```text
010 dddd 0 iiiiiiii
```

Przykład:

```text
4407 = LDI rA, 0x07
4602 = LDI rB, 0x02
```

### `LOAD` / `STORE`

```text
011 dddd 0 aaaaaaaa   LOAD  R[dddd] = MEM[addr8]
100 ssss 0 aaaaaaaa   STORE MEM[addr8] = R[ssss]
```

Przykład:

```text
8420 = STORE rA, [0x20]
6820 = LOAD  rC, [0x20]
```

### `JMP` / `BRZ`

```text
101 0000 0 aaaaaaaa   JMP addr8
110 0000 0 aaaaaaaa   BRZ addr8, gdy Z=1
```

---

## Program startowy w `ram_init.mif`

Po resecie `PC=0`, więc procesor wykonuje program od adresu `000`:

| Adres | Kod | Instrukcja |
|-------|-----|------------|
| `000` | `4407` | `LDI rA, 0x07` |
| `001` | `4602` | `LDI rB, 0x02` |
| `002` | `2023` | `ADD rA, rB` |
| `003` | `2223` | `MUL rA, rB` |
| `004` | `8420` | `STORE rA, [0x20]` |
| `005` | `6820` | `LOAD rC, [0x20]` |
| `006` | `1F00` | `HLT` |

Obsługa na płytce:

1. Ustaw `SW9=1`.
2. Wciśnij i puść `KEY1`, żeby zrobić reset.
3. Ustaw `SW[7:6]=00`, żeby oglądać `IR`.
4. Klikaj `KEY0`, każdy klik to jeden takt mikrosterowania.
5. `HEX5` pokazuje stan control, a `HEX3..HEX0` pokazuje wybrany podgląd.

Praktyczna sekwencja dla programu demo:

| Liczba kliknięć `KEY0` od resetu | Co powinno być widać |
|----------------------------------|----------------------|
| `2` | `IR = 4407`, czyli `LDI rA, 7` |
| `6` | `IR = 4602`, czyli `LDI rB, 2` |
| `10` | `IR = 2023`, czyli `ADD rA, rB` |
| `14` | `IR = 2223`, czyli `MUL rA, rB` |
| `20` | `IR = 8420`, czyli `STORE rA, [0x20]` |
| `26` | `IR = 6820`, czyli `LOAD rC, [0x20]` |
| `28` | ustaw `SW[7:6]=10`; `HEX3..HEX0 = 0012`, czyli odczytany wynik |
| `31` | `IR = 1F00`, `HEX5 = F`, czyli `HLT` |

Dla tego programu wynik `0012` bierze się z obliczenia `(7 + 2) * 2 = 18`.

---

---

## Testbenche

W projekcie sa trzy testbenche:

| Plik | Co sprawdza |
|------|-------------|
| `alu_tb.vhd` | wszystkie 22 rozkazy ALU i flagi |
| `control_tb.vhd` | sama jednostka sterujaca: `f0`, `f1`, `decode`, `exec_alu`, `exec_ldi`, `BRZ` |
| `cpu_tb.vhd` | integracja top-level: tryb ALU oraz pierwsze pobranie instrukcji do `IR` |

Najbardziej przydatny do pokazania control jest `control_tb.vhd`, bo nie wymaga
calego datapath ani RAM. Oczekiwane przejscie dla `ADD rA,rB`:

```text
reset -> f0 -> f1 -> decode -> exec_alu -> f0
```

W stanie `exec_alu` testbench sprawdza:

```text
Salu = 00000  -- ADD
Sbb  = 0010   -- rA jako BB
Sbc  = 0011   -- rB jako BC
Sba  = 0010   -- zapis do rA
LDF  = 1      -- ladowanie flag
```

## Najważniejsze pliki

- `control.vhd` - jednostka sterująca procesora
- `control_tb.vhd` - osobny testbench jednostki sterującej
- `CPU.vhd` - top-level DE1-SoC z trybem ALU i trybem procesora
- `alu.vhd` - ALU 16-bit z 22 rozkazami
- `register_cpu.vhd` - plik rejestrów, PC, SP, AD, IR
- `busint.vhd` - interfejs pamięci
- `ram.vhd` + `ram_init.mif` - pamięć programu/danych
- `ALU_OPERACJE_22.md` - sama tabela rozkazów ALU
