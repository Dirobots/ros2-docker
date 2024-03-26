#!/usr/bin/env -S docker build . --tag=dirobots/turtle:v1 --progress=plain --network=host --file

ARG DEBIAN_FRONTEND=noninteractive

# Start from nvidia's cuda image for ubuntu 22.04
#FROM nvidia/cuda:12.3.2-runtime-ubuntu22.04
FROM nvidia/opengl:1.0-glvnd-devel-ubuntu22.04

# Install the packages suggested by the official documentation of ros2 iron

RUN apt update \
    && DEBIAN_FRONTEND=noninteractive \
        apt -y --quiet --no-install-recommends install \
        locales \
        software-properties-common \
        curl \
    && apt -y autoremove \
    && apt clean autoclean \
    && rm -fr /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

# Setup the locale
RUN locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

ENV LANG en_US.UTF-8

RUN add-apt-repository universe \
    && apt update

RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && sh -c 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null'

# Install development tools and ROS tools
RUN apt update \
    && DEBIAN_FRONTEND=noninteractive \
        apt -y --quiet --no-install-recommends install \
        build-essential \
        cmake \
        git \
        python3-colcon-common-extensions \
        python3-pip \
        python3-rosdep \
        python3-vcstool \
        wget \
        ros-dev-tools \
    && apt -y autoremove \
    && apt clean autoclean \
    && rm -fr /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

# Install ros-iron-desktop
RUN apt update \
    && DEBIAN_FRONTEND=noninteractive \
        apt -y --quiet --no-install-recommends install \
        ros-iron-desktop \
    && apt -y autoremove \
    && apt clean autoclean \
    && rm -fr /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

# Make sure we are up to date
RUN apt update && apt upgrade -y \
    && rm -rf /var/lib/apt/lists/*


ENV NVIDIA_VISIBLE_DEVICES ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES ${NVIDIA_DRIVER_CAPABILITIES:-all}

# Source ROS2
RUN echo "source /opt/ros/iron/setup.bash" >> /root/.bashrc
