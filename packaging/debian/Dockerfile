FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gcc-mingw-w64 bison flex pkg-config python3 curl ca-certificates \
    git patch xz-utils dpkg-dev file binutils \
    libfreetype-dev libfontconfig-dev libgnutls28-dev libunwind-dev \
    libx11-dev libxext-dev libxrender-dev libxrandr-dev libxi-dev libxcursor-dev \
    libxinerama-dev libxxf86vm-dev libvulkan-dev libgl-dev libosmesa6-dev \
    libasound2-dev libpulse-dev libdbus-1-dev libudev-dev libcups2-dev \
    libsdl2-dev libusb-1.0-0-dev libkrb5-dev libgphoto2-dev libpcsclite-dev \
    libwayland-dev libxkbcommon-dev libegl-dev libgbm-dev libpcap-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    fonts-ipaexfont-gothic fonts-ipaexfont-mincho 7zip xvfb xauth \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends autoconf automake libtool g++-mingw-w64 gettext && rm -rf /var/lib/apt/lists/*
WORKDIR /work
ENTRYPOINT ["bash", "/src/packaging/debian/build.sh"]
