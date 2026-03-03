# Raspberry Pi 5 cross-compilation devcontainer base image
# Precompiles vcpkg dependencies for arm64-linux-dynamic triplet

FROM debian:bookworm-slim

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# X11 display forwarding to host (use with -p 6000:6000 when running)
ENV DISPLAY=host.docker.internal:0
EXPOSE 6000

# Install build essentials, cross-compilation toolchain, and multiarch support
RUN dpkg --add-architecture arm64 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    autoconf \
    autoconf-archive \
    automake \
    binfmt-support \
    binutils-aarch64-linux-gnu \
    bison \
    build-essential \
    ca-certificates \
    clazy \
    cmake \
    cppcheck \
    curl \
    debhelper \
    debmake \
    doxygen \
    flex \
    g++-aarch64-linux-gnu \
    gcc-aarch64-linux-gnu \
    gcovr \
    git \
    gnupg \
    gperf \
    graphviz \
    openjdk-17-jre-headless \
    lcov \
    libc6-dev:arm64 \
    libcap-dev:arm64 \
    libdrm-dev:arm64 \
    libcurl4-openssl-dev:arm64 \
    libdbus-1-dev:arm64 \
    libegl1-mesa-dev:arm64 \
    libglu1-mesa-dev:arm64 \
    libgtest-dev:arm64 \
    libiptc-dev:arm64 \
    libltdl-dev:arm64 \
    libsystemd-dev:arm64 \
    libtool \
    libudev-dev \
    libudev-dev:arm64 \
    libx11-dev:arm64 \
    libx11-xcb-dev:arm64 \
    libxext-dev:arm64 \
    libxi-dev:arm64 \
    libxkbcommon-dev:arm64 \
    libxkbcommon-x11-dev \
    libxrandr-dev:arm64 \
    libxrender-dev:arm64 \
    libxss-dev:arm64 \
    libxtables-dev:arm64 \
    linux-libc-dev:arm64 \
    lsb-release \
    make \
    meson \
    ninja-build \
    pkg-config \
    plantuml \
    python3 \
    python3-distutils \
    python3-jinja2 \
    python3.11-venv \
    qemu-user-static \
    qt6-base-dev:arm64 \
    qt6-webview-dev:arm64 \
    qt6-tools-dev \
    qt6-tools-dev:arm64 \ 
    ssh \
    software-properties-common \
    sudo \
    tar \
    unzip \
    valgrind \
    wget \
    zip \
    && update-binfmts --enable \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 1000 user && \
    useradd -m -u 1000 -g user -d /home/user -s /bin/bash user \
    && echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/user

RUN wget https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh 18 && \
    apt install -y --no-install-recommends clang-format-18 clang-tidy-18 && \
    update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-18 100 && \
    update-alternatives --install /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-18 100 && \
    rm -rf llvm.sh && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js 22.x from NodeSource (includes npm and npx)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

# Install vcpkg (shallow clone at baseline from vcpkg-configuration.json)
ENV VCPKG_ROOT=/opt/vcpkg
ARG VCPKG_BASELINE=4acadb7d732e662bbf130c4849be6d3a0aa6f6b9

RUN git clone https://github.com/microsoft/vcpkg.git ${VCPKG_ROOT} && \
    cd ${VCPKG_ROOT} && \
    git checkout ${VCPKG_BASELINE} && \
    ./bootstrap-vcpkg.sh -disableMetrics

ENV PATH="${VCPKG_ROOT}:${PATH}"

# Binary cache for precompiled dependencies (used by devcontainer)
ENV VCPKG_DEFAULT_BINARY_CACHE=/home/user/.cache/vcpkg/archives
RUN mkdir -p /home/user/.cache/vcpkg/archives /home/user/.cache/vcpkg/overlay-ports

# Copy manifest, triplet, overlay ports (dbus cross-compile fix, libsystemd system gperf), and vcpkg install script
COPY vcpkg.json vcpkg-configuration.json /tmp/
COPY ports/ /home/user/.cache/vcpkg/overlay-ports/
COPY arm64-linux-dynamic.cmake /opt/vcpkg/triplets/community/

ENV VCPKG_TARGET_ARCHITECTURE=x64
ENV VCPKG_CRT_LINKAGE=static
ENV VCPKG_LIBRARY_LINKAGE=static
ENV VCPKG_CMAKE_SYSTEM_NAME=Linux
ENV VCPKG_FIXUP_ELF_RPATH=ON
ENV VCPKG_DISABLE_METRICS=1
ENV VCPKG_DEFAULT_TRIPLET=x64-linux
ENV VCPKG_TARGET_TRIPLET=x64-linux

RUN vcpkg install --clean-buildtrees-after-build && rm -rf /opt/vcpkg/downloads/* /tmp/vcpkg_installed && chown -R user:user /opt/vcpkg /home/user/.cache/vcpkg && chmod -R 755 /opt/vcpkg /home/user/.cache/vcpkg

ENV VCPKG_FORCE_SYSTEM_BINARIES=1
ENV VCPKG_TARGET_ARCHITECTURE=arm64
ENV VCPKG_CRT_LINKAGE=dynamic
ENV VCPKG_LIBRARY_LINKAGE=dynamic
ENV VCPKG_CMAKE_SYSTEM_NAME=Linux
ENV VCPKG_FIXUP_ELF_RPATH=ON
ENV VCPKG_DISABLE_METRICS=1
ENV VCPKG_DEFAULT_TRIPLET=arm64-linux-dynamic
ENV VCPKG_TARGET_TRIPLET=arm64-linux-dynamic

RUN vcpkg install --clean-buildtrees-after-build && rm -rf /opt/vcpkg/downloads/* /tmp/vcpkg.json /tmp/vcpkg_installed && chown -R user:user /opt/vcpkg /home/user/.cache/vcpkg && chmod -R 755 /opt/vcpkg /home/user/.cache/vcpkg

# Unset VCPKG_ build-time variables after install
ENV VCPKG_CRT_LINKAGE= \
    VCPKG_LIBRARY_LINKAGE= \
    VCPKG_CMAKE_SYSTEM_NAME= \
    VCPKG_FIXUP_ELF_RPATH= \
    VCPKG_DISABLE_METRICS= \
    VCPKG_DEFAULT_TRIPLET= \
    VCPKG_TARGET_TRIPLET= \
    VCPKG_FORCE_SYSTEM_BINARIES=

WORKDIR /workspace
USER user 

CMD ["/bin/bash"]
