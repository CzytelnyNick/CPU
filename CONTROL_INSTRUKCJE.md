# Jednostka sterujaca - format instrukcji

Plik `control.vhd` realizuje cykl:

```text
f0 -> f1 -> decode -> execute -> f0
```

## Grupy instrukcji

| `IR[15:13]` | Instrukcja | Format |
|-------------|------------|--------|
| `000` | `NOP` / `HLT` | `HLT`, gdy `IR[12:8]=11111` |
| `001` | ALU | `001 ooooo dddd ssss` |
| `010` | `LDI` | `010 dddd 0 iiiiiiii` |
| `011` | `LOAD` | `011 dddd 0 aaaaaaaa` |
| `100` | `STORE` | `100 ssss 0 aaaaaaaa` |
| `101` | `JMP` | `101 0000 0 aaaaaaaa` |
| `110` | `BRZ` | `110 0000 0 aaaaaaaa` |

## Przykładowy program z `ram_init.mif`

| Adres | Kod | Znaczenie |
|-------|-----|-----------|
| `000` | `4407` | `LDI rA, 0x07` |
| `001` | `4602` | `LDI rB, 0x02` |
| `002` | `2023` | `ADD rA, rB` |
| `003` | `2223` | `MUL rA, rB` |
| `004` | `8420` | `STORE rA, [0x20]` |
| `005` | `6820` | `LOAD rC, [0x20]` |
| `006` | `1F00` | `HLT` |
