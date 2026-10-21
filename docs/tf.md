# TF dla kamery i lidaru w symulacji Gazebo + ROS 2

Instrukcja opisuje, jak działają ramki TF czujników robota symulowanego w Gazebo Harmonic i jak dodać nowy czujnik. Przykładem jest samochód `roboracer` (model `urdf/roboracer.urdf.xacro` z pakietu `roboracer_description`, symulacja w pakiecie `roboracer_sim` z instrukcji [roboracer_sim.md](roboracer_sim.md)) z lidarem RPLIDAR C1 i kamerą RealSense D435.

## Po co jest TF

Każdy czujnik publikuje dane we własnym układzie współrzędnych, wskazanym w polu `header.frame_id`. Skan lidaru jest w ramce `laser`, a obraz z kamery w `camera_color_optical_frame`. Żeby RViz albo algorytm (np. SLAM) mógł połączyć te dane z robotem, musi znać położenie każdej ramki czujnika względem korpusu. Tę wiedzę dostarcza TF:

- ramki przymocowane na stałe (przeguby `fixed`) trafiają na `/tf_static`,
- ramki ruchome (koła, zwrotnice, pozycja robota w świecie) trafiają na `/tf`.

Każda ramka ma **dokładnie jednego rodzica**, a każdą transformację publikuje jedno źródło.

## Osie (REP-103)

| Ramka | x | y | z |
|---|---|---|---|
| `base_link`, `laser`, `camera_link`, `camera_depth_frame` | do przodu | w lewo | w górę |
| ramki optyczne kamery (`*_optical_frame`) | w prawo | w dół | do przodu |

- Układy są prawoskrętne. Kąty: roll wokół x, pitch wokół y, yaw wokół z. Jednostki: metry i radiany.
- **Lidar (`sensor_msgs/LaserScan`):** kąt 0 to oś +x (przód), kąty rosną przeciwnie do ruchu wskazówek zegara (w stronę +y, w lewo). W tym modelu skan obejmuje pełne 360°, od `angle_min = -π` (tył) przez 0 (przód) do `angle_max = +π`.
- **Kamera:** obrazy w ROS są w ramce optycznej (z do przodu). Chmura punktów z kamery głębi Gazebo jest w konwencji linku (x do przodu), więc ma `frame_id` `camera_depth_frame`.

## Drzewo TF w tym projekcie

```
odom                                   ← wtyczka AckermannSteering (Gazebo), /tf
└── base_footprint                     (punkt na ziemi pod środkiem tylnej osi)
    └── base_link                      (środek tylnej osi, wysokość osi kół)
        ├── laser                      (RPLIDAR C1)
        ├── camera_bottom_screw_frame  (śruba statywu kamery)
        │   └── camera_link            (RealSense D435, środek lewej kamery IR)
        │       ├── camera_color_frame → camera_color_optical_frame
        │       ├── camera_depth_frame → camera_depth_optical_frame
        │       ├── camera_infra1_frame → camera_infra1_optical_frame
        │       └── camera_infra2_frame → camera_infra2_optical_frame
        ├── rear_left_wheel, rear_right_wheel                  ← /joint_states
        ├── front_left_steering_hinge → front_left_wheel       ← /joint_states
        ├── front_right_steering_hinge → front_right_wheel     ← /joint_states
        └── lidar_mast, camera_bracket, … (elementy ozdobne)
```

Wszystko poniżej `base_footprint` publikuje `robot_state_publisher` na podstawie modelu xacro: przeguby `fixed` na `/tf_static`, a koła i zwrotnice na `/tf` ze stanów przegubów (`/joint_states`).

Zmierzone położenia (`ros2 run tf2_ros tf2_echo base_link <ramka>`):

| Ramka | Translacja względem `base_link` [m] | Obrót (RPY, stopnie) |
|---|---|---|
| `laser` | `[0.325, 0.000, 0.175]` | `[0, 0, 0]` |
| `camera_link` | `[0.406, 0.018, 0.070]` | `[0, 0, 0]` |
| `camera_color_optical_frame` | `[0.406, 0.033, 0.070]` | `[-90, 0, -90]` |
| `camera_depth_frame` | `[0.406, 0.018, 0.070]` | `[0, 0, 0]` |

## Krok 1. Czujnik we własnym linku

Czujnik umieść w osobnym linku, przymocowanym do korpusu przegubem `fixed`. **Nazwa linku staje się nazwą ramki w TF.** W xacro pozycję wyraża się właściwościami, żeby zmieniać ją w jednym miejscu:

```xml
<xacro:property name="lidar_height" value="0.175"/>

<link name="laser">
  <collision>...</collision>
  <xacro:cylinder_inertial m="0.11" r="0.0275" h="0.04">   <!-- masa wymagana przez Gazebo -->
    <origin xyz="0 0 -0.01" rpy="0 0 0"/>
  </xacro:cylinder_inertial>
</link>

<joint name="laser_joint" type="fixed">
  <parent link="base_link"/>
  <child link="laser"/>
  <origin xyz="${wheelbase} 0 ${lidar_height}" rpy="0 0 0"/>
</joint>
```

Orientację czujnika zadaje `rpy` w `<origin>` przegubu. Przykładowo czujnik pochylony o 15° w dół to `rpy="0 ${radians(15)} 0"`, bo dodatni pitch obraca oś x w dół.

Kamera D435 nie jest opisywana ręcznie. Makro `sensor_d435` z pakietu `realsense2_description` tworzy wszystkie ramki z drzewa powyżej, w tych samych odstępach co prawdziwa kamera. Podajesz tylko punkt montażu (śrubę statywu):

```xml
<xacro:include filename="$(find realsense2_description)/urdf/_d435.urdf.xacro"/>

<xacro:sensor_d435 parent="base_link" name="camera" use_nominal_extrinsics="true">
  <origin xyz="${camera_mount_x} 0 ${camera_mount_z}" rpy="0 0 0"/>
</xacro:sensor_d435>
```

## Krok 2. Czujnik Gazebo i `<gz_frame_id>`

Czujnik Gazebo dodaje się w bloku `<gazebo reference="nazwa_linku">`. Wskazany link decyduje o tym, **gdzie** czujnik jest i w którą stronę patrzy (kamera Gazebo patrzy wzdłuż osi +x linku). Element `<gz_frame_id>` decyduje o tym, **jaki `frame_id`** dostaną dane:

```xml
<gazebo reference="laser">
  <sensor type="gpu_lidar" name="rplidar_c1">
    <gz_frame_id>laser</gz_frame_id>
    <topic>/scan</topic>
    ...
  </sensor>
</gazebo>

<!-- czujnik w ramce x-do-przodu, ale obraz opisany ramką optyczną -->
<gazebo reference="camera_color_frame">
  <sensor type="camera" name="d435_color">
    <gz_frame_id>camera_color_optical_frame</gz_frame_id>
    ...
  </sensor>
</gazebo>
```

Bez `<gz_frame_id>` Gazebo wpisuje do `frame_id` długą nazwę złożoną z modelu, linku i czujnika, np. `roboracer::base_footprint::rplidar_c1`. Gazebo scala linki połączone przegubami `fixed` z rodzicem, stąd `base_footprint` w nazwie. Takiej ramki nie ma w drzewie TF, więc RViz nie wyświetli danych (*No transform from ...*).

Ostrzeżenie `XML Element[gz_frame_id] ... not defined in SDF` przy starcie można zignorować, bo element i tak jest odczytywany.

## Krok 3. Publikowanie TF z modelu: robot_state_publisher

Nie przepisuj pozycji czujników ręcznie do `static_transform_publisher`. `robot_state_publisher` dostaje cały model i sam publikuje wszystkie transformacje, więc pozycje są zapisane w jednym miejscu. W `simulation.launch.py`:

```python
robot_description = ParameterValue(
    Command(['xacro ', xacro_file, ' body:=', LaunchConfiguration('body')]),
    value_type=str
)

robot_state_publisher = Node(
    package='robot_state_publisher',
    executable='robot_state_publisher',
    parameters=[{'robot_description': robot_description, 'use_sim_time': True}],
)
```

- Przeguby `fixed` (lidar, kamera) trafiają na `/tf_static`.
- Koła i zwrotnice są przegubami ruchomymi i potrzebują `/joint_states`. Publikuje je wtyczka `JointStatePublisher` w modelu (30 Hz), a mostek przekazuje temat do ROS. Bez tego czujniki nadal działają, ale w RViz koła „wiszą” w miejscu (*No transform*).
- Ramkę `odom → base_footprint` publikuje wtyczka `AckermannSteering` na `/tf`, a mostek przekazuje ją do ROS. To pozycja robota z odometrii.

Po zmianie pozycji czujnika w xacro wystarczy ponownie uruchomić launch (przy `colcon build --symlink-install` nie trzeba nawet budować). TF zmieni się sam.

## Krok 4. Czas symulacji

Wszystkie węzły, które publikują albo czytają TF (`robot_state_publisher`, RViz, Twoje węzły), uruchamiaj z `use_sim_time: True`. Mostek musi przekazywać `/clock`. Mieszanie czasu ściennego i symulacyjnego daje błędy typu *extrapolation into the future* / *past*.

## Przejście na prawdziwy sprzęt

- **RealSense:** `realsense2_camera` sam publikuje ramki kamery (`camera_link`, `camera_color_optical_frame`, `camera_depth_optical_frame`, ...) z kalibracji. W modelu robota użyj makra z `use_nominal_extrinsics="false"`. Wtedy model publikuje tylko pozycję montażu `base_link → camera_link`, a resztę sterownik. Uwaga: prawdziwy sterownik publikuje chmurę punktów w ramce **optycznej** (`camera_depth_optical_frame`), a symulacja w `camera_depth_frame`.
- **RPLIDAR C1:** `rplidar_ros` publikuje skan z ramką ustawianą parametrem `frame_id`, domyślnie `laser`, czyli tak samo jak w modelu. Sprawdź też, w którą stronę wskazuje 0° skanu: postaw przeszkodę przed robotem i zobacz, gdzie pojawia się w RViz. W razie potrzeby obróć ramkę lidaru o yaw π.

## Krok 5. Weryfikacja

Uruchom symulację:

```bash
ros2 launch roboracer_sim simulation.launch.py
```

Obraz całego drzewa (zapisuje `frames_<data>.pdf` w bieżącym katalogu):

```bash
ros2 run tf2_tools view_frames
```

Pozycje czujników względem korpusu (wartości z tabeli powyżej):

```bash
ros2 run tf2_ros tf2_echo base_link laser         # Translation: [0.325, 0.000, 0.175]
ros2 run tf2_ros tf2_echo base_link camera_link   # Translation: [0.406, 0.018, 0.070]
```

`frame_id` danych musi zgadzać się z nazwami w drzewie:

```bash
ros2 topic echo --once /scan --field header.frame_id                     # laser
ros2 topic echo --once /camera/color/image_raw --field header.frame_id   # camera_color_optical_frame
ros2 topic echo --once /camera/depth/points --field header.frame_id      # camera_depth_frame
```

W RViz włącz wyświetlacz **TF** (*Fixed Frame*: `odom`). Skan lidaru i chmura punktów powinny pokrywać się z przeszkodami. Dobry test to wstawienie w Gazebo pudełka przed pojazdem: oba czujniki muszą pokazać je w tym samym miejscu.

Przy *Fixed Frame* `odom` robot jeździ po siatce. Przy `base_link` robot stoi w miejscu, a przesuwa się otoczenie.

## Typowe błędy

| Objaw | Przyczyna | Rozwiązanie |
|---|---|---|
| RViz: *No transform from [...] to [odom]* | `frame_id` danych nie istnieje w drzewie | ustaw `<gz_frame_id>` równe nazwie linku (krok 2) |
| Brak ramek czujników w `view_frames` | nie działa `robot_state_publisher` albo czujnik nie ma przegubu `fixed` | krok 1 i 3 |
| Brak ramki `odom` | mostek nie przekazuje `/tf` z Gazebo albo robot nie ma wtyczki `AckermannSteering` | wpis `/tf` w `bridge_config.yaml` |
| Skan i chmura punktów nie pokrywają się | zła pozycja albo orientacja w `<origin>` przegubu | popraw xacro, sprawdź `tf2_echo` |
| Chmura punktów obrócona o 90° | ramka optyczna użyta dla danych w konwencji linku (lub odwrotnie) | chmura z Gazebo: `camera_depth_frame`; obraz: ramka optyczna |
| Lidar widzi własny pojazd (punkty tuż przy robocie) | płaszczyzna skanu przecina karoserię lub inne elementy | podnieś lidar (`lidar_height`) |
| Skan lidaru odwrócony o 180° (prawdziwy lidar) | 0° skanu wskazuje inny kierunek niż w modelu | obróć ramkę lidaru o yaw π |
| *Lookup would require extrapolation into the future/past* | mieszanie czasu ściennego i symulacji | `use_sim_time: True` wszędzie, mostek `/clock` |
| Koła nie pojawiają się w RViz | brak `/joint_states` | wtyczka `JointStatePublisher` + wpis w moście |
