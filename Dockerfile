# Raspberry Pi 5 cross-compilation devcontainer base image
# Precompiles vcpkg dependencies for arm64-linux-dynamic triplet

FROM debian:bookworm-slim

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install build essentials, cross-compilation toolchain, and multiarch support
RUN dpkg --add-architecture arm64 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    '^libxcb.*-dev' \
    autoconf \
    autoconf-archive \
    automake \
    binfmt-support \
    binutils \
    bison \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    debhelper \
    debmake \
    flex \
    g++ \
    g++-aarch64-linux-gnu \
    gcc \
    gcc-aarch64-linux-gnu \
    git \
    gnupg \
    gperf \
    libcap-dev \
    libcap-dev:arm64 \
    libdrm-dev \
    libdrm-dev:arm64 \
    libcurl4-openssl-dev \
    libdbus-1-dev \
    libegl1-mesa-dev \
    libglu1-mesa-dev \
    libgtest-dev \
    libiptc-dev \
    libltdl-dev \
    libsystemd-dev \
    libtool \
    libudev-dev \
    libudev-dev:arm64 \
    libx11-dev \
    libx11-xcb-dev \
    libxext-dev \
    libxi-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    libxrandr-dev \
    libxrender-dev \
    libxss-dev \
    libxtables-dev \
    linux-libc-dev \
    lsb-release \
    make \
    meson \
    ninja-build \
    pkg-config \
    python3 \
    python3-distutils \
    python3-jinja2 \
    python3.11-venv \
    qemu-user-static \
    software-properties-common \
    sudo \
    tar \
    unzip \
    wget \
    zip \
    && update-binfmts --enable \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 1000 user && \
    useradd -m -u 1000 -g user -d /home/user -s /bin/bash user \
    && echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/user


# Install vcpkg (shallow clone at baseline from vcpkg-configuration.json)
ENV VCPKG_ROOT=/opt/vcpkg
ARG VCPKG_BASELINE=4acadb7d732e662bbf130c4849be6d3a0aa6f6b9
#RUN git init ${VCPKG_ROOT} && cd ${VCPKG_ROOT} \
#    && git remote add origin https://github.com/microsoft/vcpkg.git \
#    && git fetch --depth 1 origin ${VCPKG_BASELINE} \
#    && git checkout FETCH_HEAD \
#    && ${VCPKG_ROOT}/bootstrap-vcpkg.sh -disableMetrics

RUN git clone https://github.com/microsoft/vcpkg.git ${VCPKG_ROOT} && cd ${VCPKG_ROOT} && ./bootstrap-vcpkg.sh -disableMetrics

ENV PATH="${VCPKG_ROOT}:${PATH}"

# Binary cache for precompiled dependencies (used by devcontainer)
ENV VCPKG_DEFAULT_BINARY_CACHE=/opt/vcpkg/binary_cache

ENV VCPKG_DEFAULT_TRIPLET=arm64-linux-dynamic
ENV VCPKG_FORCE_SYSTEM_BINARIES=1
ENV VCPKG_TARGET_ARCHITECTURE=arm64
ENV VCPKG_CRT_LINKAGE=dynamic
ENV VCPKG_LIBRARY_LINKAGE=dynamic
ENV VCPKG_CMAKE_SYSTEM_NAME=Linux
ENV VCPKG_FIXUP_ELF_RPATH=ON

# Copy manifest, triplet, overlay ports (dbus cross-compile fix, libsystemd system gperf), and vcpkg install script
COPY vcpkg.json vcpkg-configuration.json /tmp/
COPY ports/ /tmp/ports/
COPY scripts/vcpkg-install-with-failure-logs.sh /tmp/
COPY arm64-linux-dynamic.cmake /opt/vcpkg/triplets/community/

# Precompile all dependencies for arm64-linux-dynamic
WORKDIR /tmp
RUN mkdir -p /opt/vcpkg/binary_cache
# Symlink system gperf to where libsystemd expects it during cross-compilation
RUN mkdir -p /tmp/vcpkg_installed/x64-linux/tools/gperf && ln -s /usr/bin/gperf /tmp/vcpkg_installed/x64-linux/tools/gperf/gperf
# Ensure pkg-config finds arm64 libcap (prefer vcpkg, then arm64 sysroot) over host x86_64
ENV PKG_CONFIG_LIBDIR="/opt/vcpkg/packages/libxcrypt_arm64-linux-dynamic/usr/local/lib/pkgconfig:/tmp/vcpkg_installed/arm64-linux-dynamic/lib/pkgconfig:/tmp/vcpkg_installed/arm64-linux-dynamic/debug/lib/pkgconfig:/usr/lib/aarch64-linux-gnu/pkgconfig"

# On vcpkg failure, logs are copied to /vcpkg-logs (bind-mounted from ./vcpkg-logs in build context).
# Requires BuildKit: DOCKER_BUILDKIT=1 docker build -t fu .
RUN --mount=type=bind,source=./vcpkg-logs,target=/vcpkg-logs,rw \
    chmod +x /tmp/vcpkg-install-with-failure-logs.sh && /tmp/vcpkg-install-with-failure-logs.sh
#temp test start
#WORKDIR /workspace
#RUN vcpkg install openssl:arm64-linux-dynamic 
#RUN vcpkg install openssl:x64-linux
#
#RUN vcpkg install abseil[core,cxx17]:arm64-linux-dynamic 
#RUN vcpkg install abseil[core,cxx17]:x64-linux
#
#RUN vcpkg install c-ares:arm64-linux-dynamic
#RUN vcpkg install c-ares:x64-linux
#
#RUN vcpkg install curl[tool,ssl]:arm64-linux-dynamic
#RUN vcpkg install curl[tool,ssl]:x64-linux
#
#RUN vcpkg install paho-mqtt:arm64-linux-dynamic
#RUN vcpkg install paho-mqtt:x64-linux
#
#RUN vcpkg install protobuf:arm64-linux-dynamic
#RUN vcpkg install protobuf:x64-linux
#
#RUN vcpkg install grpc[codegen,core]:arm64-linux-dynamic
#RUN vcpkg install grpc[codegen,core]:x64-linux
#
#
#RUN vcpkg install cpp-jwt:arm64-linux-dynamic
#RUN vcpkg install cpp-jwt:x64-linux
#
#RUN vcpkg install dbus[core,systemd]:arm64-linux-dynamic
#RUN vcpkg install dbus[core,systemd]:x64-linux
#
#RUN vcpkg install sdbus-cpp:arm64-linux-dynamic
#RUN vcpkg install sdbus-cpp:x64-linux
#
#RUN vcpkg install libusb:arm64-linux-dynamic
#RUN vcpkg install libusb:x64-linux
#
#WORKDIR /tmp
#RUN vcpkg install

#temp test end

RUN chown -R user:user /opt/vcpkg \
    && chmod -R 755 /opt/vcpkg

WORKDIR /workspace
USER user

CMD ["/bin/bash"]
