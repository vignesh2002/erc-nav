FROM ros:melodic

# These values will be overrided by `docker run --env <key>=<value>` command
ENV ROS_IP 127.0.0.1
ENV ROS_MASTER_URI http://127.0.0.1:11311


# Install some basic dependencies
RUN apt-get update && apt-get -y upgrade && apt-get -y install \
  curl ssh python-pip python3-pip \
  x11-xserver-utils \
  && rm -rf /var/lib/apt/lists/*


# Set root password
RUN echo 'root:root' | chpasswd

# Permit SSH root login
RUN sed -i 's/#*PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

ARG FR_VERBOSE="false"
ENV FR_VERSION="latest"
ENV FR_ACCOUNT="INSTALL_ONLY"
ENV FR_DEVICE="GENERIC_DEVICE"
ENV FR_TOKEN="INSTALL_ONLY_DEVICE_TOKEN"
ENV FR_URL="https://api.freedomrobotics.ai/accounts/${FR_ACCOUNT}/devices/${FR_DEVICE}/installscript?\
mc_token=${FR_TOKEN}\
&code_version=${FR_VERSION}\
&install_elements=no_credentials,service_none,webrtc\
&auto_install_deps=true\
&ppa_is_allowed=true\
&verbose=${FR_VERBOSE}"
RUN curl -s "${FR_URL}" | python \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /root/.cache/pip/* 

RUN apt-get update && apt-get install -y python-catkin-tools \
  && rm -rf /var/lib/apt/lists/*

# Install Freedom scripts
RUN mkdir /freedom
COPY ./freedom_register.py /freedom/
COPY ./freedom_keep_alive.py /freedom/
COPY ./entrypoint.sh /freedom/

# Upgrade packages and install some tools
RUN apt-get update && apt-get -y upgrade && apt-get install -y \
    python-rosdep \
    python-catkin-tools \
    ros-melodic-ar-track-alvar \
    ros-melodic-depthimage-to-laserscan \
  && rm -rf /var/lib/apt/lists/*


# Clone the source code
WORKDIR /catkin_ws
COPY src ./src

# Install dependencies
RUN apt-get update \
  && rosdep update \
  && rosdep install --from-paths src -iy \
  && rm -rf /var/lib/apt/lists/*

# Build the workspace
RUN catkin config --extend /opt/ros/melodic --install -i /opt/ros/leo-sim \
  && catkin build --no-status

# Modify the entrypoint file
RUN sed -i "s|\$ROS_DISTRO|leo-sim|" /ros_entrypoint.sh

# Run launch file
# CMD ["roslaunch", "leo_erc_gazebo", "leo_marsyard.launch"]

RUN cd ..

RUN chmod +x /freedom/entrypoint.sh

ENTRYPOINT ["/freedom/entrypoint.sh"]

