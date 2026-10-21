#!/bin/bash
set -e

cd /home/developer/ros2_ws

# vcs import --recursive < /home/developer/ros2_ws/src/px4.repos src

# Repozytoria zewnętrzne (model samochodu roboracer_description); istniejące katalogi są pomijane
vcs import --skip-existing src < src/roboracer.repos

# Zależności z package.xml wszystkich pakietów w src/ (obraz Dockera ich nie zawiera)
sudo apt-get update
rosdep update --rosdistro $ROS_DISTRO
rosdep install -i --from-path src --rosdistro $ROS_DISTRO -y
