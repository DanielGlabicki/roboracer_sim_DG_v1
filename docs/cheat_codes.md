bash ~/ros2_ws/src/.devcontainer/setup.sh   # pobiera roboracer_description (vcs) i instaluje zależności (rosdep)
cd ~/ros2_ws && ./build.sh && source install/setup.bash

ros2 launch roboracer_description display.launch.py   # sam model w RViz, bez symulacji


unset AMENT_PREFIX_PATH CMAKE_PREFIX_PATH COLCON_PREFIX_PATH
source /opt/ros/jazzy/setup.bash

cd ~/ros2_ws
colcon build --symlink-install --packages-up-to roboracer_sim
source install/setup.bash
ros2 launch roboracer_sim simulation.launch.py

ros2 run teleop_twist_keyboard teleop_twist_keyboard

ros2 topic pub -r 10 /cmd_vel geometry_msgs/msg/Twist '{linear: {x: 0.5}, angular: {z: 0.3}}'


sudo apt update
sudo apt install ros-jazzy-realsense2-description
sudo apt install ros-jazzy-joint-state-publisher-gui