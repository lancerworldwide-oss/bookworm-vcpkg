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
COPY arm64-linux-dynamic.cmake /opt/vcpkg/triplets/community/

# Precompile all dependencies for arm64-linux-dynamic
WORKDIR /tmp
RUN mkdir -p ${VCPKG_DEFAULT_BINARY_CACHE}

RUN vcpkg install 2>&1 | tee /vcpkg-install-log.txt && rm -rf /tmp/*

RUN chown -R user:user /opt/vcpkg \
    && chmod -R 755 /opt/vcpkg

WORKDIR /workspace
USER user

CMD ["/bin/bash"]
