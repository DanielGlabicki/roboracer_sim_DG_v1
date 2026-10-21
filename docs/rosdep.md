# Zależności przez rosdep

Wszystkie zależności pakietów z `src/` instalują się jednym poleceniem `rosdep`. Nie trzeba ręcznie wpisywać `apt install`. Warunek: każdy pakiet ma swoje zależności wpisane w `package.xml`.

## Czym jest rosdep

`rosdep` to narzędzie ROS, które czyta zależności zapisane w `package.xml` i instaluje je jako pakiety systemowe (`apt`, `pip` itd.).

W `package.xml` wpisuje się abstrakcyjną nazwę, czyli **klucz**, a nie sposób instalacji. rosdep tłumaczy klucz na pakiet dla danego systemu. Używa do tego centralnej bazy reguł, którą pobiera `rosdep update`:

| klucz w `package.xml` | Ubuntu 24.04 + Jazzy (apt)  |
|-----------------------|-----------------------------|
| `ros_gz_sim`          | `ros-jazzy-ros-gz-sim`      |
| `librealsense2`       | `ros-jazzy-librealsense2`   |
| `eigen`               | `libeigen3-dev`             |
| `python3-requests`    | `python3-requests`          |

Ten sam `package.xml` działa więc na różnych systemach. Nikt nie musi pamiętać nazw pakietów apt.

**rosdep odpowiada za:**
- instalację zależności systemowych opisanych w `package.xml`,
- pomijanie pakietów, które już są zainstalowane albo leżą w `src/` (flaga `-i`).

**rosdep nie odpowiada za:**
- **pobieranie kodu źródłowego.** To robią `git clone` albo `vcs import` (w tym repozytorium: plik `roboracer.repos`).
- **budowanie.** To robi `colcon build`.
- **zgodność wersji.** rosdep instaluje wersję, która jest w apt. Patrz [Pakiety binarne zamiast kodu źródłowego](#pakiety-binarne-zamiast-kodu-źródłowego).
- **biblioteki spoza bazy reguł.** Takie trzeba dopisać do Dockerfile.

Kolejność pracy w workspace:

```
git clone … && vcs import …     pobranie kodu (repozytorium kursu + roboracer_description)
rosdep install --from-paths src  doinstalowanie zależności z package.xml
colcon build                     zbudowanie pakietów z src/
ros2 launch …                    uruchomienie
```

Pominięcie kroku `rosdep install` kończy się w `colcon build` błędem typu `Could not find a package configuration file provided by "diagnostic_updater"`.

## Jak to działa w tym repozytorium

1. Każdy pakiet wpisuje w `package.xml`, czego potrzebuje, np. `<exec_depend>ros_gz_sim</exec_depend>`.
2. `rosdep` zamienia te nazwy (klucze) na pakiety systemowe, np. `ros_gz_sim` na `ros-jazzy-ros-gz-sim`, i instaluje brakujące przez `apt`/`pip`.
3. Skrypt `.devcontainer/setup.sh` najpierw pobiera repozytoria zewnętrzne z `roboracer.repos` (`vcs import`, m.in. model `roboracer_description`), a potem robi `rosdep update` i `rosdep install` dla całego `src/`. Obraz Dockera nie zawiera zależności pakietów, więc ten krok trzeba wykonać w każdym nowym kontenerze.

> [!TIP]
> Po odkomentowaniu `onCreateCommand` w `.devcontainer/devcontainer.json` skrypt uruchomi się sam przy tworzeniu kontenera.

## Pierwsze uruchomienie

Sklonuj repozytorium i otwórz projekt w kontenerze (**Reopen in Container**). Następnie zainstaluj zależności i zbuduj workspace:

```bash
bash ~/ros2_ws/src/.devcontainer/setup.sh
cd ~/ros2_ws && ./build.sh
```

## Ręczne uruchomienie (np. po dodaniu nowej zależności)

```bash
cd ~/ros2_ws
rosdep update --rosdistro $ROS_DISTRO
rosdep install -i --from-paths src --rosdistro $ROS_DISTRO -y
```

Żeby tylko sprawdzić, czego brakuje, bez instalowania:

```bash
rosdep check -i --from-paths src --rosdistro $ROS_DISTRO
```

Poprawny wynik to `All system dependencies have been satisfied`.

## Dodawanie zależności do własnego pakietu

1. Sprawdź, czy klucz istnieje w rosdep:

   ```bash
   rosdep resolve nazwa_pakietu --rosdistro $ROS_DISTRO
   ```

   Dla pakietów ROS kluczem jest ich nazwa, np. `nav_msgs`. Dla bibliotek Pythona klucze mają postać np. `python3-numpy`.
2. Dopisz klucz do `package.xml` swojego pakietu:

   | Tag              | Kiedy                                                   |
   |------------------|---------------------------------------------------------|
   | `<depend>`       | potrzebne przy budowaniu i uruchamianiu (pakiety C++)   |
   | `<exec_depend>`  | tylko przy uruchamianiu (Python, launch, pliki xacro)   |
   | `<build_depend>` | tylko przy budowaniu                                    |
   | `<test_depend>`  | tylko w testach                                         |

3. Uruchom `rosdep install` jak wyżej i zacommituj `package.xml`. Pozostali dostaną zależność przy następnym `rosdep install`.

Przykład z `simple_example/package.xml` (pełna lista jest w tym pliku):

```xml
<exec_depend>xacro</exec_depend>
<exec_depend>ros_gz_sim</exec_depend>
```

Jeśli biblioteki nie ma w rosdep (`rosdep resolve` zwraca błąd), dopisz ją do `apt install` w `.devcontainer/Dockerfile` i przebuduj obraz (**Rebuild Container**).

## Pakiety binarne zamiast kodu źródłowego

Jeśli pakiet jest wydany jako paczka ROS (`ros-jazzy-...`), dodaj go jako zależność w `package.xml` zamiast klonować jego repozytorium do `src/`. Przykład: model kamery D435 pochodzi z `<exec_depend>realsense2_description</exec_depend>`, a nie z repozytorium `realsense-ros`.

Paczki binarne są zbudowane na zgodnych wersjach bibliotek. Kod źródłowy trzeba ręcznie dopasowywać: gałąź `ros2-master` repozytorium `realsense-ros` wymaga SDK 2.59, a apt dostarcza 2.58, więc budowanie kończy się błędem `RealSense SDK 2.0 is missing`. Klonuj kod źródłowy tylko wtedy, gdy zamierzasz go zmieniać.

## Najczęstsze problemy

| Objaw | Przyczyna i rozwiązanie |
|-------|-------------------------|
| `rosdep installation has not been initialized` | Uruchom `rosdep update`. Bazę rosdep pobiera się osobno dla każdego użytkownika. |
| `Could not find a package configuration file provided by "X"` przy `colcon build` | Brakuje zależności w `package.xml` albo nie uruchomiono `rosdep install`. |
| `Cannot locate rosdep definition for [X]` | Nazwa klucza jest błędna. Sprawdź ją przez `rosdep resolve`. |
| `E: Unable to locate package ros-jazzy-...` | Nieaktualna lista pakietów apt. Uruchom `sudo apt-get update` i ponów `rosdep install`. |
