# ISSPS - projekt: wpływ parametrów fizycznych BSP na dynamikę i sterowanie (sekcja P2)

Sprawozdanie i model Simulink do projektu „Badanie wpływu parametrów fizycznych czterowirnikowego bezzałogowego statku powietrznego na jego dynamikę i działanie systemu sterowania” (Inżynieria systemów statków powietrznych - systemy sterowania, Politechnika Śląska), konfiguracja **P2**: m = 1,65 kg, J = diag(0,0114; 0,0073; 0,0083) kg·m², opór jak w konfiguracji referencyjnej.

Model to połączenie modelu z [LAB5](https://github.com/felipekrystianek/issps-lab5-quadrocopter) i układu sterowania z [LAB6](https://github.com/felipekrystianek/issps-lab6-sterowanie) w jednym pliku z przełącznikiem.

## Co tu jest

```
docs/
  ISSPS_Projekt_P2_...pdf   <- gotowe sprawozdanie
  ISSPS_Projekt_P2_...docx    to samo sprawozdanie w wersji Word
  make_docx.py              tworzy wersję Word: python3 make_docx.py <plik.typ> <wynik.docx>
  sprawozdanie_projekt.typ  źródło sprawozdania (Typst)
  wyniki.json               wyniki dla REF i P2, które wczytuje sprawozdanie
  img/                      wykresy (REF i P2 na wspólnych osiach) i zrzut modelu
src/
  quad_P2.slx               model Simulink (przy otwarciu sam wczytuje parametry_P2.m)
  build_P2.m                skrypt, który od zera buduje quad_P2.slx
  parametry_REF.m           parametry konfiguracji referencyjnej (workspace)
  parametry_P2.m            parametry P2: REF z podmienionymi m, J, CDxS
  run_project.m             wszystkie badania z zadań 1 i 2 dla REF i P2, wykresy i wyniki.json
  bodyDrag.m, xy_na_katy.m  kod bloków MATLAB Function
OBRONA.md                   jak pokazać model na zajęciach, wyniki i typowe pytania z odpowiedziami
```

## Jak używać modelu

Model jest sparametryzowany: w blokach są nazwy zmiennych, a wartości są w workspace MATLAB-a. Ustawiają je pliki:

- `parametry_REF.m` - konfiguracja referencyjna (jak w LAB5 i LAB6),
- `parametry_P2.m` - to samo, ale z podmienionymi m, J i CDxS dla P2 (wczytuje się automatycznie przy otwarciu modelu).

Najważniejsze zmienne (zmieniasz je w Command Window, np. `m = 2.15`, albo w oknie Workspace, i klikasz Run):

- `regulator = 1` - stałe prędkości wirników `RotorSpeed` (badania dynamiki jak w LAB5),
- `regulator = 2` - układ sterowania z LAB6; wtedy `tryb` = 1 (skoki `z_cel`, `phi_cel`, `theta_cel`, `r_cel`), 2 (suwaki) albo 3 (punkt `x_cel`, `y_cel`, `z_cel`, `psi_cel`),
- `m`, `I`, `CDxS`, `rho`, `InitialPosition`, `Wind`, `Gust`, `t_gust`.

Wszystko naraz: w folderze `src` wpisz `run_project`.

## Wymagania

- MATLAB + Simulink + Aerospace Blockset (robione na R2026a)
