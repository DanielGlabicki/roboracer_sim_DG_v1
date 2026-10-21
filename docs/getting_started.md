# ROS 2 - Getting Started

The Robot Operating System (ROS) is a set of software libraries and tools for building robot applications. From drivers and state-of-the-art algorithms to powerful developer tools, ROS has the open source tools you need for your next robotics project.

Since ROS was started in 2007, a lot has changed in the robotics and ROS community. The goal of the ROS 2 project is to adapt to these changes, leveraging what is great about ROS 1 and improving what isn’t. - [ROS 2 Jazzy Documentation](https://docs.ros.org/en/jazzy/).

## System structure

ROS is a software suite that allows for quick and easy building of autonomous robotic systems. ROS should be considered as a set of tools for creating new solutions or adjusting already existing ones. A major advantage of this system is a great set of drivers and implemented algorithms widely used in robotics.

**Nodes**  
The base unit in ROS is called a node. Nodes are in charge of handling devices or computing algorithms - each node for a separate task. Nodes can communicate with each other using topics or services. ROS software is distributed in packages. A single package is usually developed for performing one type of task and can contain one or multiple nodes.

**Topics**  
In ROS, topic is a data stream used to exchange information between nodes. Topics are used to send frequent messages of one type, such as sensor readouts or information on motor goal speed. Each topic is registered under a unique name and with a defined message type. Nodes can connect to the topic to either publish messages or subscribe to them. For a given topic, one node can not publish and subscribe to it at the same time, but there are no restrictions on the number of different nodes publishing or subscribing.

**Services**  
Communication through services resembles a client-server model. In this mode, one node (the server) registers a service in the system. Then, any other node can ask that service and get a response. In contrast to topics, services allow for two-way communication, as a request can also contain some data.

![ROS 2 Nodes, Topic and Service](../images/Nodes-TopicandService.gif)

## ROS 2 Examples

Repozytorium z oficjalnymi przykładami (turtlesim, talker/listener) dla ROS 2 Jazzy:

```bash
git clone https://github.com/ros/ros_tutorials.git -b jazzy
```

## Gazebo Harmonic

Gazebo Harmonic posiada wiele gotowych modeli obiektów oraz światów, zarówno po włączeniu symulatora można wybrać przykładowe środowiska, ale także ściągnąć ze strony [Gazebo](https://app.gazebosim.org/dashboard).

Uruchomienie przykładowej symulacji:

```bash
gz sim sonoma.sdf
```

> [!WARNING]
> Jeśli Gazebo nie startuje albo zachowuje się dziwnie, często w tle działa jeszcze poprzednia instancja. Sprawdź i zakończ ją:
> ```bash
> pgrep -fa "gz sim"      # lista działających procesów Gazebo
> pkill -f "gz sim"       # zakończenie wszystkich
> ```

## Słowniczek

- **DDS** – warstwa komunikacji pod ROS 2. Węzły same odnajdują się w sieci (nie ma centralnego „mastera” jak w ROS 1). Węzły widzą się tylko w obrębie tego samego `ROS_DOMAIN_ID`.
- **Węzeł (node)** – najmniejsza jednostka obliczeniowa w ROS, zwykle jeden proces realizujący jedno zadanie (sterownik czujnika, algorytm).
- **Wiadomość (message)** – struktura danych o ustalonym typie, np. `sensor_msgs/msg/LaserScan`. Typy definiują pliki `.msg` w katalogu `msg/`.
- **Temat (topic)** – nazwany kanał jednokierunkowej, asynchronicznej komunikacji. Wydawca (*publisher*) wysyła na niego wiadomości, subskrybent (*subscriber*) je odbiera. Na jednym temacie może być wielu wydawców i subskrybentów.
- **Usługa (service)** – komunikacja żądanie–odpowiedź. Serwer usługi przyjmuje żądanie i zwraca odpowiedź klientowi. Typy definiują pliki `.srv` (żądanie i odpowiedź oddzielone linią `---`).
- **Akcja (action)** – dłuższe zadanie z informacją zwrotną w trakcie i możliwością anulowania (np. „jedź do punktu”). Typy definiują pliki `.action`.
- **Parametr** – wartość konfiguracyjna węzła, ustawiana przy starcie lub w trakcie działania (`ros2 param`).
- **Pakiet (package)** – jednostka organizacji kodu: węzły, pliki launch, modele, konfiguracja. Opis i zależności są w `package.xml`.
- **Plik launch** – skrypt (zwykle Python) uruchamiający naraz wiele węzłów z parametrami.
- **URDF / xacro** – opis budowy robota: linki (bryły), przeguby, masy, wygląd i kolizje. Xacro to URDF z makrami i zmiennymi.
- **TF** – drzewo układów współrzędnych robota i ich wzajemnych położeń w czasie. Patrz [tf.md](tf.md).
- **colcon** – narzędzie do budowania pakietów w workspace (`colcon build`).
- **rosdep** – narzędzie do instalowania zależności systemowych z `package.xml`. Patrz [rosdep.md](rosdep.md).
- **`CMakeLists.txt`** – konfiguracja budowania pakietu C++ (CMake).

## ROS 2 Package

### C++

- CMakeLists.txt file that describes how to build the code within the package
- `include/<package_name>` directory containing the public headers for the package
- `package.xml` file containing meta information about the package
- `src` directory containing the source code for the package

```bash
ros2 pkg create --build-type ament_cmake --node-name my_node my_package
```

### Python

- `package.xml` file containing meta information about the package
- `resource/<package_name>` marker file for the package
- `setup.cfg` is required when a package has executables, so `ros2 run` can find them
- `setup.py` containing instructions for how to install the package
- `<package_name>` - a directory with the same name as your package, used by ROS 2 tools to find your package, contains `__init__.py`

```bash
ros2 pkg create --build-type ament_python --node-name my_node my_package
```

Przykładowe węzły w Pythonie są w [example.md](example.md), a pełny przykład pakietu z modelem robota w [roboracer_sim.md](roboracer_sim.md).

## List of Tutorials

* [ROS 2 Jazzy Documentation | ROS Docs](https://docs.ros.org/en/jazzy/index.html)
* [ROS2 + Gazebo | ROS Docs](https://docs.ros.org/en/jazzy/Tutorials/Advanced/Simulators/Gazebo/Gazebo.html)
* [Gazebo Sim Docs | Gazebo Sim](https://gazebosim.org/docs/latest/getstarted/)
* [Tutorials | Husarion Docs](https://husarion.com/tutorials/)
* [ROS 2 Jazzy | Industrial Training](https://industrial-training-master.readthedocs.io/en/jazzy/)
* [Getting Started with ROS 2 | Ubuntu](https://ubuntu.com/tutorials/getting-started-with-ros-2#1-overview)
* [Tutorials and Courses | The Robotics Back-End](https://roboticsbackend.com/)


## Github Repositories
* [Gazebo Sim Repositories | Gazebo Sim Github](https://github.com/gazebosim)
* [ROS Gazebo Project Template | Gazebo Sim Github](https://github.com/gazebosim/ros_gz_project_template)
* [URDF Tutorial | ROS Github](https://github.com/ros/urdf_tutorial)
* [ROS GZ Bridge | Gazebo Sim Github](https://github.com/gazebosim/ros_gz)
* [ROS GZ Sim Demos | Gazebo Sim Github](https://github.com/gazebosim/ros_gz/tree/ros2/ros_gz_sim_demos)
* [Gazebo Sim with ROS2 | Youtube](https://www.youtube.com/watch?v=DsjJtC8QTQY&ab_channel=TheConstruct)



