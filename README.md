# Hardware extension for Lite3 Robot. Reproduce FAST-LIVO2 as an example.
This repo documents the process of installing and reproducing FAST-LIVO2 on DEEP Robotics Lite3 robot, including camera/lidar installation, onboard compute extension and how to test this in an outdoor environment. Original [repo](https://github.com/hku-mars/FAST-LIVO2) and [paper](https://arxiv.org/abs/2408.14035).

**System Environment:** Ubuntu 22.04, ROS2 Humble, Lite3 Venture, AGX Jetson Orin (or other onboard compute)

## 1. Hardware setup
### 1.1 Onboard compute setup and ROS2 installation

Please setup your onboard compute and install ROS2 on it. For details, please check their websites. We've tested the repo on [AGX Jetson Orin](https://developer.nvidia.com/embedded/learn/get-started-jetson-agx-orin-devkit) with [ROS2 Humble](https://docs.ros.org/en/humble/index.html). Note: we are using Jetpack 6.1 and the cmake version is 3.22.


### 1.2 Intergration with Lite3 robot

If you have Lite3 pro/lidar, you don't need further hardware extension cause there is already a Orin NX and you can use that as additional onboard compute. If you have Lite3 venture, you can follow this guide.

## 2. FAST-LIVO2 Installation and Reproduction

### 2.1 Install Livox_ros_driver2 and Livox-SDK2
#### 2.1.1 Lidar connection

Connect the Mid360 following the [user manual](https://terra-1-g.djicdn.com/851d20f7b9f64838a34cd02351370894/Livox/Livox_Mid-360_User_Manual_EN.pdf). You will need a cable like this:

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

Change the ip in src/livox_ros_driver2/config/MID360_config.json to use the ip from step 2.1.1. Fill the host with the actual host ip and the lidar ip with the actual lidar ip. If you can `ros2 launch livox_ros_driver2 rviz_MID360_launch.py` and see lidar points, this step is successful.

## 3. Run FAST-LIVO2 through ROS2 bag

You can download the ROS2 dataset from the original FAST-LIVO2 (Retail_Street.bag) [here](https://drive.google.com/drive/folders/15RL0__M6ZcCCf0qx8_IM40qhhoPoYnNf?usp=drive_link).

Run the algorithm:

```bash
cd fast-livo2-deep-robotics
source install/setup.bash
ros2 launch fast_livo mapping_avia.launch.py use_rviz:=True
```

Go to the place where you download the dataset and open a new terminal:

```bash
source install/setup.bash
ros2 bag play Retail_Street  # Use space bar to control play/pause
```

This should launch the mapping process with RViz visualization.

## 4. Setup self-developed locomotion policy through ROS2 on Lite3 robot

Upgrade your Lite3 robot through OTA to version ???. Turn on your robot, put it on a flat ground and switch to SDK mode.

``` 
git clone https://github.com/DeepRoboticsLab/sdk_deploy.git
```

sim-to-sim

sim-to-real



## 5. Run FAST-LIVO2 on real Lite3 robot

modify config and recompile on AGX Jetson Orin.
then open 3 terminals


```bash 
# 1 
cd fast-livo2-deep-robotics
source install/setup.bash
ros2 launch livox_ros_driver2 msg_MID360_launch.py
```

```bash 
# 2
cd fast-livo2-deep-robotics
source install/setup.bash
ros2 launch realsense2_camera rs_launch.py enable_rgbd:=false enable_sync:=false align_depth.enable:=false enable_color:=true enable_depth:=false color_fps:=15.0 color_width:=640 color_height:=360
```

```bash 
# 3
cd sdk_deploy
source install/setup.bash
ros2 run lite3_sdk_deploy sdk_deploy
```

```bash 
# 4
cd fast-livo2-deep-robotics
source install/setup.bash
ros2 launch fast_livo mapping_avia.launch.py use_rviz:=True
```

Full ROS2 graph:

## License

This project is licensed under the GNU General Public License v2.0 (GPL-2.0).

This project incorporates or derives from the following open-source projects:

- [FAST-LIVO2](https://github.com/hku-mars/FAST-LIVO2) (GPL-2.0)
- [livox_ros_driver2](https://github.com/Livox-SDK/livox_ros_driver2) (MIT License)
- [Livox-SDK2](https://github.com/Livox-SDK/Livox-SDK2) (MIT License)

See the LICENSE file for details.
