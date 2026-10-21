# ROS 2 + Gazebo Harmonic docker

Repozytorium zawiera kod do wykorzystania przez studentów w celu realizacji zajęć z Percepcja i Sterowanie Robotów Autonomicznych (PiSRA) w semestrze zimowym 2026/2027.

## Wymagania

- [Docker](https://docs.docker.com/engine/install/ubuntu/)
- [Nvidia Docker](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#container-device-interface-cdi-support)
- [VS Code devcontainer plugin](https://code.visualstudio.com/docs/devcontainers/containers#_quick-start-open-an-existing-folder-in-a-container)

> [!IMPORTANT]  
> System operacyjnym Ubuntu jest wymagany ze względu na obsługę GUI (wymaga innego podejścia przy wykorzystaniu Windowsa).

## Start

Otwórz VS Code w katalogu z projektem.
Przejdź do lewego dolnego rogu i kliknij niebieską ikonę z dwiema strzałkami skierowanymi do siebie. Z rozwijanego menu wybierz **"Open Folder in Container... ”** i poczekaj, aż docker się zbuduje. Może to potrwać do 10 minut przy wolniejszym połączeniu internetowym.

> [!TIP]
> Dla osób korzystających z Windowsa oraz WSL 2 przygotowano `compose.windows.yaml` (ten sam `Dockerfile`, inne ustawienia GPU dla WSL). 

Po zalogowaniu się do dockera będzie on działał w sposób podobny do uruchamiania ROS na komputerze hosta. Wszystkie aplikacje GUI będą korzystać z domyślnego menedżera okien hosta, będziesz mieć również dostęp do wszystkich urządzeń na hoście, a także akceleracji GPU.
Docker ma preinstalowany [ROS 2 Jazzy](https://docs.ros.org/en/jazzy/Tutorials.html) i większość potrzebnych zależności oraz symulator [Gazebo Harmonic](https://gazebosim.org/docs/harmonic/getstarted/).

## Dwie osoby na jednym komputerze

Każda osoba pracuje we własnym kontenerze (wspólny jest tylko obraz `psra-ros2-jazzy`, budowany raz).

1. Każda osoba klonuje repozytorium do **własnego** katalogu, np. `~/psra_ania` i `~/psra_bartek`.
2. W swoim klonie tworzy plik `.devcontainer/.env` na podstawie `.devcontainer/.env.example` (plik nie jest commitowany):

   ```bash
   cp .devcontainer/.env.example .devcontainer/.env
   ```

   i ustawia **różne** wartości:

   | Zmienna         | Osoba 1  | Osoba 2  | Do czego służy                          |
   |-----------------|----------|----------|-----------------------------------------|
   | `DEV_NAME`      | `ania`   | `bartek` | nazwa kontenera (`psra-<DEV_NAME>`)     |
   | `ROS_DOMAIN_ID` | `11`     | `22`     | izolacja topiców ROS 2                  |
   | `GZ_PARTITION`  | `ania`   | `bartek` | izolacja komunikacji Gazebo             |

3. Otwiera swój klon w VS Code i wybiera **"Reopen in Container"**.

> [!WARNING]
> Kontenery działają w sieci hosta (`network_mode: host`). Bez różnych `ROS_DOMAIN_ID` i `GZ_PARTITION` obie osoby widziałyby nawzajem swoje topici i symulacje.

Sprawdzenie w kontenerze: `echo $ROS_DOMAIN_ID $GZ_PARTITION`, a na hoście: `docker ps` (dwa kontenery `psra-<DEV_NAME>-workspace-1`).

## Pierwsze uruchomienie

Dla osób, które nie miały doczynienia ze środowiskiem ROS 2 + Gazebo, zachęcam do przerobienia tutorialu: [Gazebo Tutorial](https://gazebosim.org/docs/harmonic/tutorials/). Pozwoli to zaznajomić się z tym środowiskiem i tworzyć w przyszłości zaawansowane symulacje.

Następnie pomocne będzie odpowiednia kontrola robotami w środowisku symulacyjnym, na dobry start proszę zaznajomić się z repozytorium: [Gazebo ROS 2 Control](https://github.com/ros-controls/gz_ros2_control/).

Na sam koniec pewnym podsumowaniem, a także praktycznym podejściem do tematu jest dostarczony od [Husariona](https://husarion.com/tutorials/ros2-tutorials/1-ros2-introduction/) tutorial dla ich kilku robotów.

> [!IMPORTANT] 
Należy pamiętać, aby po zbudowaniu wywołać komendę lub pracować w nowym terminalu:
>
> ```bash
> source ~/.bashrc
> ```
>
> W tym pliku dodane są już dwie ważne ścieżki:
>
> ```bash
> /opt/ros/$ROS_DISTRO/setup.bash
> /home/developer/ros2_ws/install/setup.bash
> ```

## Przykład

Model samochodu 1:10 (F1TENTH) z lidarem RPLIDAR C1 i kamerą RealSense D435 jest w osobnym repozytorium `roboracer_description`, pobieranym do `src/vcs_repos/` z pliku [`roboracer.repos`](roboracer.repos). Symulację samochodu na torze budujesz sam we własnym pakiecie `roboracer_sim` według instrukcji [docs/roboracer_sim.md](docs/roboracer_sim.md). Pakiet `simple_example` pokazuje podstawowe połączenie Gazebo z ROS 2.

```bash
bash ~/ros2_ws/src/.devcontainer/setup.sh   # model (vcs import) + zależności (rosdep), raz na nowy kontener
cd ~/ros2_ws && ./build.sh && source install/setup.bash

ros2 launch simple_example example.launch.py         # kamera z Gazebo w RViz (mostek ROS <-> Gazebo)
ros2 launch roboracer_description display.launch.py   # model samochodu w RViz, bez symulacji
```

Sterowanie samochodem w symulacji (drugi terminal): `ros2 run teleop_twist_keyboard teleop_twist_keyboard`.

## Dokumentacja

Kolejność odpowiada kolejności nauki.

| | Dokument | Zawartość |
|---|---|---|
| 1 | [Getting Started](docs/getting_started.md) | podstawy ROS 2: węzły, tematy, usługi, słowniczek, linki do kursów |
| 2 | [Ściąga komend](docs/cheatsheet.md) | `colcon`, `ros2 topic/node/param`, TF, `gz`, narzędzia graficzne |
| 3 | [Pakiety w Pythonie](docs/example.md) | publisher, subscriber i plik launch |
| 4 | [Zależności przez rosdep](docs/rosdep.md) | `package.xml`, instalacja zależności, najczęstsze błędy |
| 5 | [Mostek ROS ↔ Gazebo](docs/ros_gz_bridge.md) | `ros_gz_bridge`, typy wiadomości, konfiguracja YAML |
| 6 | [TF dla kamery i lidaru](docs/tf.md) | ramki czujników, `gz_frame_id`, weryfikacja w RViz |
| 7 | [Własny pakiet z symulacją](docs/roboracer_sim.md) | pakiet `roboracer_sim` krok po kroku: symulacja, RViz, sterowanie, własna wersja modelu |
