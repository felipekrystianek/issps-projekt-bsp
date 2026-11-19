# Obrona projektu - sekcja P2

Ściąga: jak pokazać model `src/quad_P2.slx` na zajęciach i co odpowiedzieć na typowe pytania.

## 1. Pokaz modelu krok po kroku

1. W MATLAB-ie przejdź do `Projekt_BSP/src` i otwórz `quad_P2.slx`.
2. **Modeling → Model Explorer → quad_P2 → Model Workspace**: tu są wszystkie parametry. Zmieniasz wartość i klikasz **Apply**.
3. Czas symulacji ustawiasz w polu **Stop Time**, a symulację uruchamiasz przyciskiem **Run**.
4. Przebiegi pokazują Scope'y: z, phi, theta, r, psi, XY. Pozostałe sygnały (oznaczone anteną) są w **Data Inspector**: `Xe`, `Ve`, `eul`, `wb`, `Mrot`, `Frot`, `Omega`.
5. Na koniec **nie zapisuj modelu** (*Don't save*).

### Parametry P2 (domyślne w modelu)
m = 1,65 kg; J = diag(0,0114; 0,0073; 0,0083) kg·m²; CDxS = [0,0390 0,0455 0,0900] m².
Konfiguracja REF: m = 1,5 kg; J = diag(0,0111; 0,0070; 0,0080) kg·m²; CDxS taki sam.

### Zadanie 1 - dynamika (`regulator = 1`)

| Badanie | Ustaw | Stop Time | Gdzie patrzeć |
|---|---|---|---|
| 1.1 spadek bez oporu | `RotorSpeed = [0 0 0 0]`, `CDxS = [0 0 0]`, `InitialPosition = [0 0 -10]` / `-50` / `-100` | 10 | Scope z, chwila h = 0 |
| 1.2 spadek z oporem | jak 1.1, `CDxS = [0.039 0.0455 0.09]` | 10 | Scope z |
| 1.3 zawis m | `RotorSpeed = 533.52*[1 -1 1 -1]` | 20 | Scope z, stałe 10 m |
| 1.3 zawis m + 0,5 kg | `m = 2.15`, `RotorSpeed = 609.02*[1 -1 1 -1]` | 20 | Scope z |
| 1.4 gęstość 1,0 | `rho = 1.0`, `RotorSpeed = 590.50*[1 -1 1 -1]` | 20 | Scope z |
| 1.5 wznoszenie | `RotorSpeed = 640.23*[1 -1 1 -1]`, `CDxS = [0 0 0]` | 15 | Data Inspector `Ve` (3. składowa, ze znakiem minus) |
| 1.6 wiatr | `RotorSpeed = 533.52*[1 -1 1 -1]`, `Wind = [3 0 0]` | 10 | Scope XY, krzywa x |
| 1.7 wirnik +5 % | `RotorSpeed = [560.20 -533.52 533.52 -533.52]` | 0.3 | Data Inspector `Mrot` |

Ω_min dla dowolnej masy: `sqrt(m*9.81/(4*0.0142*1.225*pi*0.127^4))`.

### Zadanie 2 - sterowanie (`regulator = 2`)

| Test | Ustaw | Stop Time | Scope |
|---|---|---|---|
| skok wysokości | `tryb = 1`, `z_cel = 15` | 20 | z |
| skok roll | `tryb = 1`, `z_cel = 10`, `phi_cel = pi/8` | 20 | phi |
| skok pitch | `tryb = 1`, `z_cel = 10`, `theta_cel = pi/8` | 20 | theta |
| skok yaw | `tryb = 1`, `z_cel = 10`, `r_cel = pi/12` | 20 | r, psi |
| lot do punktu | `tryb = 3`, `x_cel = 5`, `y_cel = 5`, `z_cel = 15`, `psi_cel = pi/4` | 50 | XY, z, psi |
| z wiatrem | jak wyżej + `Wind = [5 0 0]`, `Gust = [3 0 0]`, `t_gust = 30` | 50 | XY |
| suwaki | `tryb = 2`, Stop Time `inf`, przesuwaj bloki „suwak …” w trakcie lotu | inf | wszystkie |

Wszystkie badania naraz: w `src` wpisz `run_project` (kilka minut, liczy REF i P2).

## 2. Najważniejsze wyniki (P2 względem REF)

| Wielkość | REF | P2 | Dlaczego |
|---|---|---|---|
| Ω zawisu | 508,69 rad/s | 533,52 rad/s (+4,9 %) | Ω ~ √m |
| spadek ze 100 m bez oporu | 4,52 s | 4,52 s | t = √(2h/g), nie zależy od masy |
| spadek ze 100 m z oporem | 7,27 s | 7,05 s (-3 %) | większa prędkość graniczna v ~ √m |
| wzrost Ω przy ρ = 1,0 | +10,68 % | +10,68 % | √(1,225/1,0), nie zależy od masy |
| przyspieszenie przy 1,2 Ω_min | 4,32 m/s² | 4,32 m/s² | ciąg 1,44 mg, więc a = 0,44 g dla każdej masy |
| przesunięcie wiatrem 3 m/s po 10 s | 5,48 m | 5,09 m (-7 %) | ta sama siła oporu, większa masa |
| moment pitch przy wirniku +5 % | 0,0848 N·m | 0,0933 N·m (+10 %) | moment ~ Ω² ~ m |
| przyspieszenie kątowe pitch | 12,12 rad/s² | 12,78 rad/s² (+5,5 %) | moment +10 %, a J_yy tylko +4,3 % |
| sterowanie | - | prawie identyczne | m·g i mikser liczone z rzeczywistej masy, J większe tylko o 3-4 % |
| odejście od celu po podmuchu | 0,34 m | 0,32 m | większa masa, mniejsze przyspieszenie od podmuchu |

## 3. Pytania i odpowiedzi

### Model

**Z czego składa się model?**
Z modelu BSP z LAB5 i układu sterowania z LAB6 w jednym pliku. Blok Multirotor (DJIF450Rotors, *Quadcopter +*) liczy siły i momenty od wirników, a 6DOF (Quaternion) całkuje równania ruchu. Do sił dodajemy ciężar (m·DCM·g) i opór z funkcji bodyDrag z uwzględnieniem wiatru.

**Do czego służy przełącznik `regulator`?**
Wybiera, skąd biorą się prędkości wirników: 1 = stałe RotorSpeed (badania dynamiki jak w LAB5), 2 = wyjście układu sterowania (jak w LAB6). Dzięki temu oba zadania są w jednym modelu.

**Co zmieniono względem laboratoriów?**
Tylko m, J i CDxS, zgodnie z zasadami projektu. Struktura modelu i nastawy regulatorów zostały takie same.

**Skąd wiadomo, że model działa tak samo jak na laboratoriach?**
Dla parametrów REF wyniki z tego modelu zgadzają się z LAB5 i LAB6 we wszystkich cyfrach.

**Jaki układ współrzędnych?**
NED: x do przodu (północ), y w prawo (wschód), z w dół. Dlatego wysokość to h = -Z_e, a start z 10 m to `InitialPosition = [0 0 -10]`.

**Jak liczony jest opór?**
F = -½·ρ·C_D·S·|V_wzg|·V_wzg osobno w każdej osi, gdzie V_wzg = V_b - V_wiatru (w układzie BSP).

**Dlaczego RotorSpeed ma znaki [1 -1 1 -1]?**
Wirniki na przemian kręcą się w przeciwne strony, dzięki czemu ich momenty reakcyjne się znoszą i BSP nie obraca się wokół osi yaw.

### Zadanie 1

**Jak obliczyłeś Ω_min?**
Z równowagi ciągu i ciężaru: 4·C_T·ρ·π·R⁴·Ω² = m·g, więc Ω_min = √(m·g / (4·C_T·ρ·π·R⁴)). Dla P2 to 533,52 rad/s.

**Dlaczego bez oporu P2 spada tak samo jak REF?**
Jedyną siłą jest ciężar, więc przyspieszenie to g niezależnie od masy.

**Dlaczego z oporem P2 spada szybciej?**
Opór jest taki sam, a ciężar większy, więc prędkość graniczna v = √(2mg / (ρ·C_D·S)) rośnie jak √m. Różnica jest widoczna dopiero przy dłuższym spadku (100 m).

**Dlaczego przyspieszenie przy 1,2 Ω_min jest takie samo?**
Ciąg rośnie z Ω², więc przy 1,2 Ω_min wynosi 1,44 m·g. Wypadkowa siła to 0,44 m·g, czyli a = 0,44 g dla każdej masy. Ω_min jest już policzone dla masy P2.

**Dlaczego prędkość po 15 s to aż 64,7 m/s?**
W tym zadaniu opór jest wyłączony, więc prędkość rośnie liniowo bez ograniczenia. W rzeczywistości opór zatrzymałby ją na dużo niższym poziomie.

**Dlaczego przy wirniku +5 % nie ma momentu roll?**
W układzie „+” wirnik nr 1 leży na osi x (pitch), więc jego większy ciąg pochyla BSP tylko w pitch. Mały moment yaw wynika z różnicy momentów reakcyjnych.

**Dlaczego przyspieszenie kątowe P2 jest większe, skoro BSP jest cięższy?**
Większa masa wymaga większych obrotów, więc 5 % nadwyżki daje o 10 % większy moment. Momenty bezwładności wzrosły tylko o 3-4 %, bo ładunek jest blisko środka masy.

### Zadanie 2 i układ sterowania

**Jak działa układ sterowania?**
Cztery PID-y: wysokości (daje ΔT), roll, pitch i prędkości yaw (dają momenty). Mikser Ω² = A⁻¹·[ΣT, τφ, τθ, τψ] zamienia je na kwadraty prędkości wirników, potem pierwiastek ze znakiem, nasycenie 0-1000 rad/s i kierunki obrotu.

**Co to jest macierz A?**
Macierz efektywności sterowania dla układu „+”: wiąże kwadraty prędkości wirników z ciągiem i trzema momentami (wykład 6, slajd 13). Jej odwrotność rozdziela żądany ciąg i momenty na wirniki.

**Po co bloki -1 przy roll i pitch?**
Macierz A z wykładu zakłada oś z w górę, a model ma oś z w dół (NED), więc momenty roll i pitch mają przeciwny znak. Bez -1 sprzężenie byłoby dodatnie i pętle byłyby niestabilne.

**Dlaczego PID4 reguluje prędkość yaw, a nie kąt?**
Tak jest na wykładzie (slajdy 32 i 40, sygnał z ω_b, wykres „psi′”), tak też działa drążek yaw w aparaturze. Z nastawami z wykładu pętla kąta byłaby niestabilna, bo I_zz·K_i > K_d·K_p (kryterium Routha). Kąt ψ reguluje dodatkowy regulator P w zadaniu z lotem do punktu.

**Po co ograniczenie ΔT (limit dT)?**
Przy skoku wysokości o 5 m PID1 żądał ok. 100 N ciągu, wszystkie wirniki wchodziły w nasycenie i znikała różnica obrotów potrzebna do sterowania kątami. Ograniczenie do ±0,5·m·g jest też na wykładzie (slajd 25).

**Jak działa lot do punktu?**
Uchyby x i y idą do PID X i PID Y, wynik jest obracany o kąt ψ do układu BSP i zamieniany na zadane kąty: lot do przodu to θ < 0 (nos w dół), w prawo to φ > 0. Kąty są ograniczone do ±π/8.

**Po co rampa wartości zadanej x, y?**
Przy skoku o 5 m człon I narastał przez cały przelot i dawał przeregulowanie 1-2 m. Z rampą 0,5 m/s uchyb jest cały czas mały.

**Skąd nastawy PID X i PID Y?**
Na wykładzie ich nie ma, więc dobraliśmy je w LAB6 przeszukaniem siatki wartości: najkrótszy czas ustalania przy przeregulowaniu poniżej 10 % i bez uchybu przy wietrze. P = 0,06, I = 0,01, D = 0,3. W projekcie są bez zmian.

**Dlaczego oś y jest wolniejsza od x?**
Y steruje pętla roll, która z nastawami z wykładu jest wolniejsza od pitch (P = 0,00042 wobec 0,0038).

**Dlaczego dla P2 nie trzeba było zmieniać nastaw?**
Ciąg zawisu m·g i macierz A⁻¹ są liczone z rzeczywistej masy, więc większa masa jest skompensowana. Momenty bezwładności wzrosły tylko o 2,7-4,3 %, czego regulatory roll, pitch i yaw prawie nie odczuwają.

**Jak liczyłeś wskaźniki jakości?**
Przeregulowanie to największe przekroczenie wartości zadanej w procentach skoku. Czas ustalania to ostatnia chwila wyjścia poza pasmo ±2 % (lub ±5 %) skoku, liczona od chwili skoku. Uchyb ustalony to różnica na końcu symulacji.

**Dlaczego roll ma „> 19 s” czasu ustalania?**
Ma przeregulowanie 3,4 % i wraca bardzo wolno, bo człon I jest mały (2,87·10⁻⁶). Do końca symulacji nie wchodzi w pasmo 2 %, ale w pasmo 5 % wchodzi po ok. 2,5 s.

**Jak zachowuje się P2 przy wietrze?**
Stały wiatr 5 m/s wymaga stałego pochylenia pod wiatr. Człon I usuwa uchyb ustalony, a podmuch 3 m/s odsuwa P2 od celu o 0,32 m (REF o 0,34 m), bo większa masa wolniej przyspiesza.

### Wnioski

**Jaki jest główny wniosek?**
Ładunek blisko środka masy (P2) zmienia głównie masę, a mało momenty bezwładności. Rośnie wymagana prędkość wirników i zmniejsza się zapas ciągu, ale sterowanie z nastawami z LAB6 działa prawie tak samo jak dla REF.

**Kiedy różnica byłaby większa?**
Przy dużej zmianie momentów bezwładności (np. P3, P5), bo wtedy te same nastawy dawałyby wyraźnie wolniejsze albo słabiej tłumione pętle orientacji. Przy większym oporze (P4) większy byłby wpływ wiatru.
