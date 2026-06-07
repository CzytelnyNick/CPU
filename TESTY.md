# Testy procesora — prosta checklista

Wszystkie testy zakładają, że projekt jest wgrany na płytkę (lub symulowany w QuestaSim) z domyślnym programem z `ram_init.mif`.

**Program w pamięci:**

| Adres | Kod hex | Instrukcja |
|-------|---------|------------|
| 0 | `4007` | LDI A, 7 |
| 1 | `4202` | LDI B, 2 |
| 2 | `2201` | ADD A, A, B |
| 3 | `1F00` | HLT |

---

## Ustawienia wspólne (przed każdym testem)

| Element | Ustaw | Uwagi |
|---------|-------|-------|
| SW[9:2] | wszystkie **w dół** (0) | nieużywane |
| SW[1:0] | zależy od testu (tabela poniżej) | wybór widoku HEX |
| KEY[1] | **wciśnij i puść** | reset — zawsze na początku |
| KEY[0] | klikaj tylko gdy test tego wymaga | 1 klik = 1 cykl procesora |

### Co oznaczają SW[1:0]

| SW[1:0] | HEX3..HEX0 pokazuje |
|---------|---------------------|
| `00` (oba w dół) | **A** (rejestr 0) |
| `01` (SW0 w górę) | **B** (rejestr 1) |
| `10` (SW1 w górę) | **IR** (aktualna instrukcja) |
| `11` (oba w górę) | **PC** |

### Jak czytać HEX5 i LEDR[9:6] (stan procesora)

| Kod na HEX5 / LEDR[9:6] | Znaczenie |
|-------------------------|-----------|
| `0` | f0 — pobieranie instrukcji z RAM |
| `1` | f1 — ładowanie instrukcji do IR |
| `2` | decode — rozpoznawanie typu instrukcji |
| `3` | exec_alu — wykonanie operacji ALU |
| `4` | exec_ldi — wpisanie stałej do rejestru |
| **F** (15) | **HLT — program zakończony** |

> Na wyświetlaczu 7-seg stan `1111` może wyglądać nietypowo — wtedy patrz na **LEDR[9:6] = 1111**.

---

## Test 0 — Reset

| Krok | Co ustawić | Co zrobić | Co powinno się stać |
|------|------------|-----------|---------------------|
| 1 | SW = `0000000000` | — | — |
| 2 | — | KEY[1]: wciśnij ↓, puść ↑ | reset |
| 3 | SW[1:0] = `00` | — | HEX3..HEX0 = **0000** (rA = 0) |
| 4 | — | patrz HEX5 / LEDR[9:6] | stan = **0** (f0) |
| 5 | SW[1:0] = `11` | — | HEX3..HEX0 = **0000** (PC = 0) |

**Wynik:** procesor gotowy, PC = 0, rA = 0, czeka na pierwszy cykl zegara.

---

## Test 1 — Główny test (cały program) ⭐

**Cel:** sprawdzić, czy procesor sam wykonuje program i liczy **7 + 2 = 9**.

| Krok | Co ustawić | Co zrobić | Co powinno się stać |
|------|------------|-----------|---------------------|
| 1 | SW = `0000000000` | KEY[1] reset | jak w Teście 0 |
| 2 | SW[1:0] = `00` | KEY[0] kliknij **16 razy** (wciśnij ↓, puść ↑) | stany na HEX5 się zmieniają: 0→1→2→4→0→… |
| 3 | — | po 16. kliknięciu | LEDR[9:6] = **1111** (HLT) |
| 4 | SW[1:0] = `00` | — | HEX3..HEX0 = **0009** |

| Sprawdzasz | Oczekiwana wartość | OK? |
|------------|-------------------|-----|
| rA (SW=00, HEX) | **0009** | ☐ |
| Stan (LEDR[9:6]) | **1111** (HLT) | ☐ |
| rB (SW=01, HEX) | **0002** | ☐ |
| PC (SW=11, HEX) | **0004** | ☐ |
| IR (SW=10, HEX) | **1F00** (HLT) | ☐ |

**Jeśli rA = 0009 i stan = HLT → test zaliczony.**

---

## Test 2 — Sprawdzenie rejestru rB

| Krok | Co ustawić | Co zrobić | Oczekiwany wynik |
|------|------------|-----------|------------------|
| 1 | — | wykonaj **Test 1** do końca | — |
| 2 | SW[1:0] = `01` | — | HEX3..HEX0 = **0002** |

| Sprawdzasz | Oczekiwana wartość | OK? |
|------------|-------------------|-----|
| rB | **0002** | ☐ |

---

## Test 3 — Sprawdzenie IR (ostatnia instrukcja)

| Krok | Co ustawić | Co zrobić | Oczekiwany wynik |
|------|------------|-----------|------------------|
| 1 | — | wykonaj **Test 1** do końca | — |
| 2 | SW[1:0] = `10` | — | HEX3..HEX0 = **1F00** |

| Sprawdzasz | Oczekiwana wartość | OK? |
|------------|-------------------|-----|
| IR | **1F00** (kod HLT) | ☐ |

---

## Test 4 — Sprawdzenie PC po programie

| Krok | Co ustawić | Co zrobić | Oczekiwany wynik |
|------|------------|-----------|------------------|
| 1 | — | wykonaj **Test 1** do końca | — |
| 2 | SW[1:0] = `11` | — | HEX3..HEX0 = **0004** |

| Sprawdzasz | Oczekiwana wartość | OK? |
|------------|-------------------|-----|
| PC | **0004** (pobrano 4 instrukcje) | ☐ |

---

## Test 5 — Flagi ALU po ADD

Po wykonaniu programu, przy operacji ADD (7+2=9):

| Flaga | LEDR | Oczekiwana wartość | Znaczenie |
|-------|------|-------------------|-----------|
| C | LEDR[3] | **0** (zgaszona) | brak przeniesienia |
| Z | LEDR[2] | **0** | wynik ≠ 0 |
| S | LEDR[1] | **0** | wynik dodatni |
| P | LEDR[0] | **1** (świeci) | parzysta liczba jedynek w wyniku |

| Sprawdzasz | Oczekiwane LEDR[3:0] | OK? |
|------------|---------------------|-----|
| Flagi | **0001** (tylko P=1) | ☐ |

---

## Test 6 — Ponowne uruchomienie

| Krok | Co ustawić | Co zrobić | Oczekiwany wynik |
|------|------------|-----------|------------------|
| 1 | SW = `0000000000` | KEY[1] reset | HEX = 0000, stan = 0 |
| 2 | SW[1:0] = `00` | KEY[0] × 16 | znowu rA = **0009**, HLT |

Potwierdza, że program startuje od początku po resecie.

---

## Test 7 — QuestaSim (automatyczny)

| Krok | Co zrobić | Oczekiwany wynik |
|------|-----------|------------------|
| 1 | W QuestaSim: `do run_tests.do` | kompilacja bez błędów |
| 2 | Szukaj w Transcript | `=== CPU_TB: WSZYSTKIE TESTY PRZESZLY ===` |
| 3 | Szukaj w Transcript | `=== ALU_TB: WSZYSTKIE TESTY PRZESZLY ===` |

| Sprawdzasz | Oczekiwane | OK? |
|------------|------------|-----|
| cpu_tb | PASS (rA=9, HLT) | ☐ |
| alu_tb | PASS (16 operacji) | ☐ |

---

## Tabela kontrolna — co powinno się dziać po każdym etapie programu

Po resecie klikaj KEY[0] i możesz sprawdzać postęp (SW[1:0]=`00` dla rA, `11` dla PC):

| Po ok. kliknięciach KEY[0] | Co się właśnie stało | rA (HEX) | PC (HEX) | Stan (LEDR[9:6]) |
|----------------------------|----------------------|----------|----------|------------------|
| 0 (reset) | — | 0000 | 0000 | 0 |
| 4 | LDI rA,7 wykonane | **0007** | 0001 | 0 |
| 8 | LDI rB,2 wykonane | 0007 | 0002 | 0 |
| 12 | ADD wykonane | **0009** | 0003 | 0 |
| 16 | HLT — koniec | **0009** | 0004 | **1111** |

> Liczba kliknięć może różnić się o 1–2 w zależności od momentu resetu — ważny jest **końcowy** wynik: rA=9, HLT.

---

## Co zrobić gdy test nie przechodzi

| Objaw | Możliwa przyczyna | Co zrobić |
|-------|-------------------|-----------|
| HEX = 0000 po 16 kliknięciach | za mało cykli | kliknij KEY[0] jeszcze 5–10 razy |
| HEX ≠ 0009 | błąd kompilacji / stary SOF | przebuduj projekt, wgraj ponownie |
| Stan ≠ 1111 | program nie doszedł do HLT | sprawdź `ram_init.mif`, reset i powtórz |
| Wszystko 0 po resecie | OK | to prawidłowe — dopiero kliknięcia KEY[0] uruchamiają program |

---

## Szybka ściąga — jeden test na zajęcia

```
1. SW = 0000000000
2. KEY[1] — reset
3. KEY[0] — kliknij 16×
4. SW[1:0] = 00  →  HEX musi pokazać 0009
5. LEDR[9:6] = 1111  →  HLT
```

**Sukces = rA = 9, procesor zatrzymany (HLT).**
