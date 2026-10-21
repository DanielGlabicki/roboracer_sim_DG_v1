# ROS 2 Command Cheat Sheet

## Workspace
### Clone repositories `vcs import`

Repozytoria zewnętrzne opisane w pliku `.repos` trafiają do `src/vcs_repos/` (katalog ignorowany przez git). Model samochodu:

```bash
cd ~/ros2_ws
vcs import --skip-existing src < src/roboracer.repos   # pobierz brakujące
vcs pull src/vcs_repos                                 # zaktualizuj pobrane
```

Biblioteki PX4:

```bash
vcs import --recursive < /home/developer/ros2_ws/src/px4.repos src
```

### Update dependencies `rosdep update`

```bash
rosdep update --rosdistro $ROS_DISTRO
```

### Install dependencies `rosdep install`

Dobrą praktyką jest sprawdzanie zależności za każdym razem, gdy dodajemy coś do obszaru roboczego.
Wywołujemy komendę z poziomu folderu, który zawiera `/src` (np. `~/ros2_ws`). Szczegóły w [rosdep.md](rosdep.md).

```bash
rosdep install -i --from-path src --rosdistro $ROS_DISTRO -y
```

W przypadku powodzenia pojawi się komunikat: `#All required rosdeps installed successfully`

### Build workspace `colcon build`

Budowanie obszaru roboczego odbywa się z poziomu foldera `~/ros2_ws`.

```bash
colcon build --symlink-install
```

Skrypt `~/ros2_ws/build.sh` uruchamia `colcon build --merge-install --symlink-install` z typem budowania `RelWithDebInfo`. Po budowaniu (w każdym nowym terminalu) wczytaj środowisko:

```bash
source ~/ros2_ws/install/setup.bash
```

Podczas budowania za pomocą `colcon` można wykorzystać następujące flagi ([Więcej informacji](https://colcon.readthedocs.io/en/released/reference/verb/build.html)):

`--packages-up-to` builds the package you want, plus all its dependencies, but not the whole workspace (saves time).  
`--packages-select` select the packages with the passed names.  
`--symlink-install` saves you from having to rebuild every time you tweak python scripts.  
`--event-handlers` console_direct+ shows console output while building (can otherwise be found in the log directory).  
`--executor` sequential processes the packages one by one instead of using parallelism.  
`--merge-install` With this option most of the paths added to environment variables will be the same, resulting in shorter environment variable values. The disadvantage of using this option is that it doesn’t provide proper isolation between packages.

### Test workspace

W celu przetestowania poprawności zbudowania obszaru roboczego można wywołać:

```bash
colcon test
```

### Clean workspace

Usunięcie folderów `build`, `install`, `log`.

```bash
colcon clean workspace
```

## ROS 2 Package

### Verbs
* `create` - Create a new ROS 2 package.
* `executables` - Output a list of package specific executables.
* `list` - Output a list of available packages.
* `prefix` - Output the prefix path of a package.
* `xml` - Output the information contained in the package `xml` manifest


**C++ / Python**

```bash
ros2 pkg create --build-type ament_cmake/ament_python --node-name <node_name> <package_name>
```


**Example:**
```bash
ros2 pkg create --build-type ament_python --node-name simple_example simple_example
```
## ROS 2 Launch
```bash
ros2 launch <package> <launch_file_name>
```
**Example:**
```bash
ros2 launch simple_example example.launch.py
ros2 launch roboracer_sim simulation.launch.py body:=open rviz:=false   # pakiet z docs/roboracer_sim.md
ros2 launch roboracer_sim simulation.launch.py --show-args              # lista argumentów
```

## ROS 2 Topic

### Verbs
* `bw` - Display bandwith used by topic.
* `delay` - Display delay of topic from timestamp in header.
* `echo` - Output messages of a given topic to screen.
* `find` - Find topics of a given type.
* `hz` - Display publishing rate of topic.
* `info` - Output information about a given topic.
* `list` - Output list of active topics.
* `pub` - Publish data to a topic.
* `type` - Output topic's type.

**Usage:**
```bash
ros2 topic bw <topic>
ros2 topic echo <topic>
ros2 topic info <topic>
ros2 topic list
ros2 topic pub <topic> <message_type> <data>

```
**Example** (symulacja `roboracer_sim`):
```bash
ros2 topic pub -r 10 /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.5}, angular: {z: 0.3}}"
ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist "{}"      # stop
```

```bash
ros2 topic echo /odom --field pose.pose.position      # tylko wybrane pole
ros2 topic echo --once /scan --field header           # jedna wiadomość
ros2 topic hz /scan                                   # częstotliwość
```

## ROS 2 Run

**Usage:**
```bash
ros2 run <package> <executable>
```

**Example:**
```bash
ros2 run demo_nodes_cpp talker
ros2 run teleop_twist_keyboard teleop_twist_keyboard     # sterowanie /cmd_vel z klawiatury
```

## ROS 2 Node, Param, Interface

```bash
ros2 node list                         # działające węzły
ros2 node info /robot_state_publisher  # tematy i usługi węzła
ros2 param list /robot_state_publisher
ros2 param get /robot_state_publisher use_sim_time
ros2 interface show geometry_msgs/msg/Twist   # pola typu wiadomości
```

## TF

```bash
ros2 run tf2_tools view_frames                 # PDF z drzewem ramek
ros2 run tf2_ros tf2_echo base_link laser      # transformacja między ramkami
```

Więcej w [tf.md](tf.md).

## Gazebo (gz)

```bash
gz sim -r sonoma.sdf                 # uruchom świat (-r: od razu start symulacji)
gz topic -l                          # tematy Gazebo (inne niż tematy ROS!)
gz topic -e -t /scan                 # podgląd wiadomości w Gazebo
gz topic -i -t /cmd_vel              # kto publikuje/subskrybuje
pgrep -fa "gz sim"                   # działające instancje
```

Tematy z Gazebo trafiają do ROS tylko przez mostek, patrz [ros_gz_bridge.md](ros_gz_bridge.md).

## Narzędzia graficzne

```bash
rviz2                                  # wizualizacja: model, TF, czujniki
ros2 run rqt_graph rqt_graph           # graf węzłów i tematów
ros2 run rqt_image_view rqt_image_view # podgląd obrazu z kamery
```

## Izolacja (kilka osób na jednym komputerze)

```bash
echo $ROS_DOMAIN_ID $GZ_PARTITION
```

Węzły ROS widzą się tylko przy tym samym `ROS_DOMAIN_ID`, a instancje Gazebo przy tej samej `GZ_PARTITION`. Patrz README, sekcja „Dwie osoby na jednym komputerze”.




