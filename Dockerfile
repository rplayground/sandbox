ARG FROM_IMAGE=ros:humble

# multi-stage for building
FROM $FROM_IMAGE AS builder

# install ros dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
      ros-$ROS_DISTRO-aws-robomaker-small-warehouse-world \
      ros-$ROS_DISTRO-foxglove-bridge \
      ros-$ROS_DISTRO-nav2-bringup \
      ros-$ROS_DISTRO-rviz2 \
      ros-$ROS_DISTRO-turtlebot3-description \
      ros-$ROS_DISTRO-turtlebot3-simulations \
    && rm -rf /var/lib/apt/lists/*

# multi-stage for developing
FROM builder AS dever

# edit apt for caching
RUN mv /etc/apt/apt.conf.d/docker-clean /etc/apt/

# install developer dependencies
RUN apt-get update && apt-get install -y \
      bash-completion \
      python3-pip \
      wget && \
    pip3 install \
      bottle \
      glances

# multi-stage for caddy
FROM caddy:builder AS caddyer

# build custom modules
RUN xcaddy build \
    --with github.com/caddyserver/replace-response

# multi-stage for visualizing
FROM dever AS visualizer

ENV ROOT_SRV /srv
RUN mkdir -p $ROOT_SRV

# install gzweb dependacies
RUN apt-get install -y --no-install-recommends \
      imagemagick \
      libboost-all-dev \
      libgazebo-dev \
      libgts-dev \
      libjansson-dev \
      libtinyxml-dev \
      nodejs \
      npm \
      psmisc \
      xvfb

# clone gzweb
ENV GZWEB_WS /opt/gzweb
RUN git clone https://github.com/osrf/gzweb.git $GZWEB_WS

# setup gzweb
RUN cd $GZWEB_WS && . /usr/share/gazebo/setup.sh && \
    GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:$(find /opt/ros/$ROS_DISTRO/share \
      -mindepth 1 -maxdepth 2 -type d -name "models" | paste -s -d: -) && \
    sed -i "s|var modelList =|var modelList = []; var oldModelList =|g" gz3d/src/gzgui.js && \
    xvfb-run -s "-screen 0 1280x1024x24" ./deploy.sh -m local && \
    ln -s $GZWEB_WS/http/client/assets http/client/assets/models && \
    ln -s $GZWEB_WS/http/client/assets/turtlebot3_common/meshes \
      $GZWEB_WS/http/client/assets/turtlebot3_waffle/meshes && \
    ln -s $GZWEB_WS/http/client $ROOT_SRV/gzweb

# patch gzsever
RUN GZSERVER=$(which gzserver) && \
    mv $GZSERVER $GZSERVER.orig && \
    echo '#!/bin/bash' > $GZSERVER && \
    echo 'exec xvfb-run -s "-screen 0 1280x1024x24" gzserver.orig "$@"' >> $GZSERVER && \
    chmod +x $GZSERVER

# setup foxglove
# Use custom fork until PR is merged:
# https://github.com/foxglove/studio/pull/5987
# COPY --from=ghcr.io/foxglove/studio /src $ROOT_SRV/foxglove
COPY --from=ghcr.io/ruffsl/foxglove_studio@sha256:8a2f2be0a95f24b76b0d7aa536f1c34f3e224022eed607cbf7a164928488332e /src $ROOT_SRV/foxglove

# install web server
COPY --from=caddyer /usr/bin/caddy /usr/bin/caddy

# download media files
RUN mkdir -p $ROOT_SRV/media && cd /tmp && \
    export ICONS="icons.tar.gz" && wget https://github.com/ros-planning/navigation2/files/11506823/$ICONS && \
    echo "cae5e2a5230f87b004c8232b579781edb4a72a7431405381403c6f9e9f5f7d41 $ICONS" | sha256sum -c && \
    tar xvz -C $ROOT_SRV/media -f $ICONS && rm $ICONS
