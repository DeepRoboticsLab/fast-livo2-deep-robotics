# Hardware extension for Lite3 Robot. Reproduce FAST-LIVO2 as an example.
[![Discord](https://img.shields.io/badge/-Discord-5865F2?style=flat&logo=Discord&logoColor=white)](https://discord.gg/gdM9mQutC8)
## 0. Overview
This repo documents the process of installing and reproducing FAST-LIVO2 on DEEP Robotics Lite3 robot, including camera/lidar installation, onboard compute extension and how to test this in an outdoor environment. Original [repo](https://github.com/hku-mars/FAST-LIVO2) and [paper](https://arxiv.org/abs/2408.14035). And you can watch our tutorial videos on Bilibili or Youtube.

**System Environment:** Ubuntu 22.04, ROS2 Humble, Lite3 Venture (ONLY THIS VERSION!), AGX Jetson Orin (or other onboard compute)

## 1. Hardware setup
### 1.1 Onboard compute setup and ROS2 installation

Please setup your onboard compute and install ROS2 on it. For details, please check their websites. We've tested the repo on [AGX Jetson Orin](https://developer.nvidia.com/embedded/learn/get-started-jetson-agx-orin-devkit) with [ROS2 Humble](https://docs.ros.org/en/humble/index.html). Note: we are using Jetpack 6.1 and the cmake version is 3.22.


### 1.2 Intergration with Lite3 robot

If you have Lite3 pro/lidar, you don't need further hardware extension cause there is already a Orin NX and you can use that as additional onboard compute. If you have Lite3 venture, you can follow the installation process in our video. For the 3d printed structure parts, you can download them from [here](https://drive.google.com/drive/folders/1KmWNuOF0Qg5XM6EQKRiWrkJJhoBknjIZ?usp=drive_link). 

## 2. FAST-LIVO2 Installation and Reproduction

### 2.1 Install Livox_ros_driver2 and Livox-SDK2
#### 2.1.1 Lidar connection

This repo supports two Livox lidar variants:

- **Mid-360** (original): use the `MID360` launch files and `MID360_config.json`.
- **Mid-360s** (new variant): use the `MID360s` launch files and `MID360s_config.json`. Both the Livox-SDK2 and `livox_ros_driver2` in this repo have been extended to support the Mid-360s protocol (new command handler, host net info schema, and dedicated config samples under `src/Livox-SDK2/samples/*/mid360s_config.json`).

Connect your lidar following the official user manual for your variant: [Mid-360 user manual](https://terra-1-g.djicdn.com/851d20f7b9f64838a34cd02351370894/Livox/Livox_Mid-360_User_Manual_EN.pdf) or [Mid-360s user manual](https://terra-1-g.djicdn.com/65c028cd298f4669a7f0e40e50ba1131/Mid-360S/UM/Livox_Mid-360s_User_Manual_en.pdf). You will need a cable like this:

<img src="cable.jpg" alt="My screenshot" width="400">

Plug the xt30 end to the 24V xt30 of lite3 and plug the ethernet end to a normal x86 ubuntu system. If you open Livoxviewer2 and see that lidar is connected, this step is successful. 

#### 2.1.2 Compiling and installing
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


### 2.2 Install librealsense and realsense-ros

#### 2.2.1 Install librealsense

Please follow this [doc](https://github.com/realsenseai/librealsense/blob/master/doc/libuvc_installation.md) to install intel realsense on your AGX Jetson Orin. It's tested to work in the widest range of cases.

Known issues:
```
06/11 17:00:12,985 ERROR [281473429722208] (context.cpp:40) No valid configuration file found at : /home/fjwjetson/.realsense-config.json loading defaults
06/11 17:00:13,098 ERROR [281473429722208] (rs.cpp:256) [rs2_create_device( info_list:0xaaab00eb1d90, index:0 ) UNKNOWN] bad optional access
06/11 17:00:13,098 ERROR [281473429722208] (rs.cpp:256) [rs2_delete_device( device:nullptr ) UNKNOWN] null pointer passed for argument "device"
Could not create device - bad optional access . Check SDK logs for details
No device detected. Is it plugged in?
```

This indicates that the kernel layer has recognized the camera, but the librealsense RSUSB driver lacks permission to access the device node. In simple terms, the permission rules are not being applied correctly. You can try the following command first:

```bash
sudo rs-enumerate-devices
```

If the above command outputs normally, then the root cause is identified: a library version conflict, meaning there are two sets of librealsense in the system:
| Path               | Version         | Source          | Status                     |
|--------------------|-----------------|-----------------|----------------------------|
| /usr/local/lib     | librealsense2.so.2.56.5 | Self-compiled (supports RSUSB) | ✅ |
| /opt/ros/humble/lib| librealsense2.so.2.56.4 | Automatically installed by ROS2 (older version) | ❌ |

When launching without sudo, the older library is loaded, preventing the device from being opened.

### Library Version Conflict Resolution Method

Force the system to prioritize `/usr/local/lib`:

```bash
echo "/usr/local/lib" | sudo tee /etc/ld.so.conf.d/99-realsense-local.conf
sudo ldconfig
```

Then permanently set the environment variable to take effect automatically in all terminals:

```bash
echo 'export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
```

Verify using the following command:

```bash
ldd $(which rs-enumerate-devices) | grep realsense
```

Successful result:

```
librealsense2.so.2.56 => /usr/local/lib/librealsense2.so.2.56.5
```

After this, the launch command should be able to start the depth camera normally.

#### 2.2.2 Install realsense-ros

Please follow this [doc](https://github.com/realsenseai/realsense-ros) to install realsense-ros. For example: 
`sudo apt -y install ros-humble-realsense2-*`.

If you can run this `ros2 launch realsense2_camera rs_pointcloud_launch.py` and see reasonable visualization, this step is successful. 


### 2.3 Build FAST-LIVO2

Install required ROS2 packages:

```bash
sudo apt update
sudo apt -y install ros-humble-pcl-ros ros-humble-compressed-image-transport ros-humble-sophus 
```

Build FAST-LIVO2:

```bash
cd fast-livo2-deep-robotics/src/livox_ros_driver2/
source /opt/ros/humble/setup.bash
./build.sh humble
```

If successful, you should see output indicating completion.

Verify packages:

```bash
cd fast-livo2-deep-robotics
source install/setup.bash
ros2 pkg list | grep livo
```

Expected output should include `fast_livo` and `livox_ros_driver2`.

Change the ip in the matching config file to use the ip from step 2.1.1. Fill the host with the actual host ip and the lidar ip with the actual lidar ip.

- **If you are using Mid-360**, edit `src/livox_ros_driver2/config/MID360_config.json` and run:
  ```bash
  ros2 launch livox_ros_driver2 rviz_MID360_launch.py
  ```
- **If you are using Mid-360s**, edit `src/livox_ros_driver2/config/MID360s_config.json` and run:
  ```bash
  ros2 launch livox_ros_driver2 rviz_MID360s_launch.py
  ```

If you can see lidar points in RViz, this step is successful.


## 3. Run FAST-LIVO2 through ROS2 bag

You can download the ROS2 dataset from the original FAST-LIVO2 (Retail_Street.bag) [here](https://drive.google.com/drive/folders/15RL0__M6ZcCCf0qx8_IM40qhhoPoYnNf?usp=drive_link).

> **Note:** The original dataset was recorded using the older `livox_ros_driver`. Since we are using the newer `livox_ros_driver2`, you must update the topic type inside the dataset database before playing it. Otherwise, the lidar data will be ignored.

**Step 1: Install the sqlite3 tool**
Open your terminal and install `sqlite3` to modify the bag file:
```bash
sudo apt update && sudo apt install sqlite3
```
**Step 2: Update the topic type in the dataset**
Go to the directory where you downloaded the dataset (e.g., `data`), and run the following command to modify the database:
```bash
sqlite3 Retail_Street.db3 "UPDATE topics SET type = 'livox_ros_driver2/msg/CustomMsg' WHERE name = '/livox/lidar';"
```

Run the algorithm:

```bash
cd fast-livo2-deep-robotics
source install/setup.bash
ros2 launch fast_livo mapping_avia.launch.py use_rviz:=True
```

Go to the place where you download the dataset and open a new terminal:

```bash
source install/setup.bash
ros2 bag play Retail_Street.db3  # Use space bar to control play/pause
```

This should launch the mapping process with RViz visualization.
## 4. Run FAST-LIVO2 on real Lite3 robot

modify config and recompile on AGX Jetson Orin.
then open 3 terminals


```bash 
# 1 
cd fast-livo2-deep-robotics
source install/setup.bash
# Use msg_MID360_launch.py for Mid-360, or msg_MID360s_launch.py for Mid-360s
ros2 launch livox_ros_driver2 msg_MID360_launch.py
```

```bash 
# 2
cd fast-livo2-deep-robotics
source install/setup.bash
ros2 launch realsense2_camera rs_launch.py enable_rgbd:=false enable_sync:=false align_depth.enable:=false enable_color:=true enable_depth:=false
```

```bash 
# 3
cd fast-livo2-deep-robotics
source install/setup.bash
ros2 launch fast_livo mapping_avia.launch.py use_rviz:=True
```
## 5. Multi-Sensor Time Synchronization Improvement
 
The Livox Mid-360s LiDAR and IMU run on separate hardware clocks with no shared reference. Without correction, the timestamp lag between them grows by roughly one second per second, causing FAST-LIVO2 to stall within ~20 seconds of runtime. Hardware synchronization (PTP, GPIO) was not viable here: PTP reaches the Livox unit but not its internal IMU oscillator, and the RealSense D435i's RGB and depth sensors sit on separate PCBs, so GPIO sync cannot reach the RGB stream this pipeline depends on.
 
Software correction in `src/fast_livo/src/LIVMapper.cpp`:
 
- **IMU-LiDAR offset:** an Exponential Moving Average filter (`α = 0.01`) continuously re-estimates the clock offset from live timestamp comparisons in `imu_cbk`, replacing the previous static/disabled offset correction.
- **Camera offset:** the RealSense stream is corrected independently via a fixed `img_time_offset`, since its driver already timestamps frames against the host clock rather than drifting the way the Livox IMU does. This value is set in the launch/config YAML rather than computed at runtime.
- **Non-blocking timestamp handling:** packet-drop traps that previously discarded IMU/image frames on a detected timestamp jump were replaced with logged warnings, so the pipeline no longer stalls on transient jitter.
- **Thread safety:** all shared buffers (`mtx_buffer`, `mtx_buffer_imu_prop`) are now guarded with `std::lock_guard` for RAII-safe locking across callbacks, and reusable point cloud containers were made `static` to reduce per-frame heap allocation.
 
**Sensor clock sync pipeline:**
 
<img src="sync_pipeline.png" alt="Sensor clock sync pipeline diagram" width="500">

**Demonstration — plant reconstruction (baseline vs. improved):**
 
| Baseline (unsynchronized) | Improved (EMA sync) |
|---|---|
| <img src="plant_old.png" alt="Plant reconstruction baseline" width="380"> | <img src="plant_new.png" alt="Plant reconstruction with software sync" width="380"> |
 
*Without sync, the reconstruction halts early and leaves the flowerpot base and surrounding floor incomplete. With the EMA-based correction active, the flowerpot and surrounding area are captured near-completely.*
 
**Known limitation:** this is a software approximation, not a true hardware sync. Sharp turns can still cause visible camera-LiDAR frame misalignment and accumulated drift in very large environments can eventually exceed what the filter can correct for. For applications needing tighter synchronization, hardware sync via the Livox M12 PPS pin and replacing the D435i with the D415.
 
**Full results and test breakdown:** see the [project poster](poster.pdf)

## License

This project is licensed under the GNU General Public License v2.0 (GPL-2.0).

This project incorporates or derives from the following open-source projects:

- [FAST-LIVO2](https://github.com/hku-mars/FAST-LIVO2) (GPL-2.0)
- [livox_ros_driver2](https://github.com/Livox-SDK/livox_ros_driver2) (MIT License)
- [Livox-SDK2](https://github.com/Livox-SDK/Livox-SDK2) (MIT License)

See the LICENSE file for details.
