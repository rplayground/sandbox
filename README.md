# RPlayground Sandbox

An example sandbox playground for teaching robotics development.

## Background

For more related documentation:

- [Nav2 Documentation](https://navigation.ros.org)
  - [Development Guides](https://navigation.ros.org/development_guides)
    - [Dev Containers](https://navigation.ros.org/development_guides/devcontainer_docs)

## Demo

- Open the project from VS Code with the Dev Container extension installed
- From the command palette ``(Crtl+Shift+P)``, type and enter `Dev containers: Reopen in Container`
- Open open a new shell ``(Crtl+Shift+`)`` from the terminal panel and run:

```bash
source /opt/ros/$ROS_DISTRO/setup.bash
source /usr/share/gazebo/setup.sh
GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:$(find /opt/ros/$ROS_DISTRO/share \
  -mindepth 1 -maxdepth 2 -type d -name "models" | paste -s -d: -)
ros2 launch ./launch/security_demo_launch.py \
  use_rviz:=False headless:=True
```

- From the command palette, type and enter `Tasks: Run Task` and select `Start Visualizations`
- From the port panel, click the `Open in Browser` button for port `8080` forwarded from the container
- Finally, play around with the various sandboxed web apps using the include launcher page
