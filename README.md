# sandbox

```bash
source /opt/ros/$ROS_DISTRO/setup.bash
source /usr/share/gazebo/setup.sh
GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:$(find /opt/ros/$ROS_DISTRO/share \
  -mindepth 1 -maxdepth 2 -type d -name "models" | paste -s -d: -)
ros2 launch ./launch/security_demo_launch.py \
  use_rviz:=False headless:=True
```
