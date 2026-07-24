#!/bin/bash

readonly VERSION_ROS1="ROS1"
readonly VERSION_ROS2="ROS2"
readonly VERSION_HUMBLE="humble"
readonly VERSION_JAZZY="jazzy"

pushd `pwd` > /dev/null
cd `dirname $0`
echo "Working Path: "`pwd`

ROS_VERSION=""
ROS_DISTRO=""

# Set working ROS version
if [ "$1" = "ROS2" ]; then
    ROS_VERSION=${VERSION_ROS2}
elif [ "$1" = "humble" ]; then
    ROS_VERSION=${VERSION_ROS2}
    ROS_DISTRO=${VERSION_HUMBLE}
elif [ "$1" = "jazzy" ]; then
    ROS_VERSION=${VERSION_ROS2}
    ROS_DISTRO=${VERSION_JAZZY}
elif [ "$1" = "ROS1" ]; then
    ROS_VERSION=${VERSION_ROS1}
else
    echo "Invalid Argument"
    exit
fi
echo "ROS version is: "$ROS_VERSION

# Will not clear these folders, if the last build is based on the same ROS version
LAST_BUILD_FILE=../../last_build
OLD_VALUE=""
if [ -f ${LAST_BUILD_FILE} ]; then
    OLD_VALUE=$(cat ${LAST_BUILD_FILE})
fi

if [ "$OLD_VALUE" != "$ROS_VERSION$ROS_DISTRO" ]; then
    # clear `build/` folder.
    echo "Version changed -> full clean build"
    rm -rf ../../build/
    rm -rf ../../devel/
    rm -rf ../../install/
else 
    echo "Same version as last time -> Incremental build"
fi
echo "$ROS_VERSION$ROS_DISTRO" > ${LAST_BUILD_FILE}

# clear src/CMakeLists.txt if it exists.
if [ -f ../CMakeLists.txt ]; then
    rm -f ../CMakeLists.txt
fi

# exit

# substitute the files/folders: CMakeList.txt, package.xml(s)
if [ ${ROS_VERSION} = ${VERSION_ROS1} ]; then
    if [ -f package.xml ]; then
        rm package.xml
    fi
    cp -f package_ROS1.xml package.xml
elif [ ${ROS_VERSION} = ${VERSION_ROS2} ]; then
    if [ -f package.xml ]; then
        rm package.xml
    fi
    cp -f package_ROS2.xml package.xml
    cp -rf launch_ROS2/ launch/
fi

# build
pushd `pwd` > /dev/null
if [ $ROS_VERSION = ${VERSION_ROS1} ]; then
    cd ../../
    catkin_make -DROS_EDITION=${VERSION_ROS1}
elif [ $ROS_VERSION = ${VERSION_ROS2} ]; then
    cd ../../
    colcon build --cmake-args -DROS_EDITION=${VERSION_ROS2} -DDISTRO_ROS=${ROS_DISTRO}
fi
popd > /dev/null

# remove the substituted folders/files
if [ $ROS_VERSION = ${VERSION_ROS2} ]; then
    rm -rf launch/
fi

popd > /dev/null
