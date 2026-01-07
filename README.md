# Hardware extension for Lite3 Robot. Reproduce FAST-LIVO2 as an example.
This repo documents the process of installing and reproducing FAST-LIVO2 on DEEP Robotics Lite3 robot, including camera/lidar installation, onboard compute extension and how to combine these with a self-developed locomotion policy through ROS2.

**System Environment:** Ubuntu 22.04, ROS2 Humble, Lite3 Venture, AGX Jetson Orin (or other onboard compute)

## 1. Hardware setup
### 1.1 Onboard compute setup and ROS2 installation

Please setup your onboard compute and install ROS2 on it. For details, please check their websites. We've tested the repo on [AGX Jetson Orin](https://developer.nvidia.com/embedded/learn/get-started-jetson-agx-orin-devkit) with [ROS2 Humble](https://docs.ros.org/en/humble/index.html).

### 1.2 Intergration with Lite3 robot

If you have Lite3 pro/lidar, you don't need further hardware extension cause there is already a Orin NX and you can use that as additional onboard compute. If you have Lite3 venture, you can follow this guide.

## 2. FAST-LIVO2 Installation and Reproduction

### 2.1 Install Livox_ros_driver2 and Livox-SDK2

First, git clone this repo: 
```
git clone https://github.com/DeepRoboticsLab/fast-livo2-deep-robotics.git
cd fast-livo2-deep-robotics
```

Compile Livox-SDK2 separately:

```bash
cd fast-livo2-deep-robotics/src/Livox-SDK2
mkdir build && cd build
cmake .. && make -j
sudo make install
```

Note: we are using Jetpack 6.1 and the cmake version is 3.22.

### 2.2 Build FAST-LIVO2

Install required ROS2 packages:

```bash
sudo apt update
sudo apt install ros-humble-pcl-ros ros-humble-compressed-image-transport ros-humble-sophus
```

**Important Note on Cloning:** For FAST-LIVO2, livox_ros_driver2, and Livox-SDK2, use `git clone` to ensure complete cloning (including branches and submodules). Do not download as ZIP, as it may cause errors when running launch files due to missing branches.

| Aspect | git clone | Download ZIP |
|--------|-----------|--------------|
| Downloaded Content | Complete repository (including .git history, branches, submodules, etc.) | Only files from the current branch |
| Includes .git Folder | ✔️ Yes (full) | ❌ No |
| Includes Submodules | ❌ No by default (use --recursive) | ❌ Never |
| Can Update Code (pull) | ✔️ Yes | ❌ No (static files) |
| Download Branch | Default main/master, can specify others | Always current branch |
| File Version | Exact match to branch HEAD | Sometimes lagged or cached by GitHub |


Build FAST-LIVO2:

```bash
cd fast-livo2-deep-robotics/src/livox_ros_driver2/
source /opt/ros/humble/setup.bash
./build.sh humble
```

If successful, you should see output indicating completion.

Verify packages:

```bash
source fast-livo2-deep-robotics/install/setup.bash
ros2 pkg list | grep livo
```

Expected output should include `fast_livo` and `livox_ros_driver2`.

## 3. Run FAST-LIVO2 through ROS2 bag

You can download the ROS2 dataset from the original FAST-LIVO2 (Retail_Street.bag) [here](https://drive.google.com/drive/folders/15RL0__M6ZcCCf0qx8_IM40qhhoPoYnNf?usp=drive_link).

Run the algorithm:

```bash
cd fast-livo2-deep-robotics
source install/setup.bash
ros2 launch fast_livo mapping_avia.launch.py use_rviz:=True
```

In a new terminal:

```bash
ros2 bag play Retail_Street  # Use space bar to control play/pause
```

This should launch the mapping process with RViz visualization.

## 4. Setup self-developed locomotion policy through ROS2 on Lite3 robot

## 5. Run FAST-LIVO2 on real Lite3 robot

