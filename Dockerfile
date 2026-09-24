# Raspberry Pi 5 cross-compilation devcontainer base image
# Precompiles vcpkg dependencies for x64-linux, wasm32-emscripten, and arm64-linux-dynamic

FROM debian:bookworm-slim AS base

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# X11 client display. The container connects to the host X server; do not publish
# port 6000. host.docker.internal exists on Docker Desktop; on Linux add it via
# extra_hosts.
ENV DISPLAY=host.docker.internal:0

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
    ccache \
    clazy \
    cppcheck \
    curl \
    dbus \
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
    libcap-dev \
    libcap-dev:arm64 \
    libdrm-dev \
    libdrm-dev:arm64 \
    libavcodec-dev \
    libavcodec-dev:arm64 \
    libavformat-dev \
    libavformat-dev:arm64 \
    libavutil-dev \
    libavutil-dev:arm64 \
    libswscale-dev \
    libswscale-dev:arm64 \
    libgstreamer1.0-dev \
    libgstreamer1.0-dev:arm64 \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer-plugins-base1.0-0:arm64 \
    libgstreamer-gl1.0-0:arm64 \
    libevdev-dev \
    libevdev-dev:arm64 \
    libinput-dev \
    libinput-dev:arm64 \
    libwayland-dev \
    libwayland-dev:arm64 \
    wayland-protocols \
    libcurl4-openssl-dev \
    libcurl4-openssl-dev:arm64 \
    libdbus-1-dev \
    libdbus-1-dev:arm64 \
    libegl1-mesa-dev \
    libegl1-mesa-dev:arm64 \
    libglu1-mesa-dev \
    libglu1-mesa-dev:arm64 \
    libgtest-dev \
    libgtest-dev:arm64 \
    libiptc-dev \
    libiptc-dev:arm64 \
    libltdl-dev \
    libltdl-dev:arm64 \
    '^libxcb.*-dev' \
    '^libxcb.*-dev:arm64' \
    libsystemd-dev \
    libsystemd-dev:arm64 \
    libtool \
    libudev-dev \
    libudev-dev:arm64 \
    libx11-dev \
    libx11-dev:arm64 \
    libx11-xcb-dev \
    libx11-xcb-dev:arm64 \
    libxext-dev \
    libxext-dev:arm64 \
    libxi-dev \
    libxi-dev:arm64 \
    libxkbcommon-dev \
    libxkbcommon-dev:arm64 \
    libxkbcommon-x11-dev \
    libxkbcommon-x11-dev:arm64 \
    libxrandr-dev \
    libxrandr-dev:arm64 \
    libxrender-dev \
    libxrender-dev:arm64 \
    libxss-dev \
    libxss-dev:arm64 \
    libxtables-dev \
    libxtables-dev:arm64 \
    linux-libc-dev \
    linux-libc-dev:arm64 \
    lsb-release \
    make \
    meson \
    ninja-build \
    patchelf \
    pkg-config \
    plantuml \
    policykit-1 \
    python3 \
    python3-distutils \
    python3-jinja2 \
    python3.11-venv \
    qemu-user-static \
    qt6-base-dev:arm64 \
    qt6-base-dev \
    qt6-webview-dev \
    qt6-webview-dev:arm64 \
    qt6-tools-dev \
    qt6-tools-dev:arm64 \
    ssh \
    software-properties-common \
    sudo \
    systemd \
    systemd-sysv \
    systemd-timesyncd \
    tar \
    unzip \
    gdb \
    gdb-multiarch \
    valgrind \
    wget \
    xz-utils \
    zlib1g-dev \
    zip && \
    update-binfmts --enable && \
    ln -sf /usr/bin/ccache /usr/lib/ccache/aarch64-linux-gnu-gcc && \
    ln -sf /usr/bin/ccache /usr/lib/ccache/aarch64-linux-gnu-g++ && \
    cd /tmp && \
    apt-get download libgstreamer-plugins-base1.0-dev:arm64 && \
    dpkg-deb -x libgstreamer-plugins-base1.0-dev_*_arm64.deb / && \
    rm -f libgstreamer-plugins-base1.0-dev_*_arm64.deb && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

# Kitware CMake from apt.kitware.com. There is no Debian bookworm suite; jammy
# packages are built against glibc 2.35, which runs on Bookworm 2.36.
# noble/resolute need a newer glibc. Pin amd64 so multiarch apt does not install
# Kitware's arm64 cmake (that index exists).
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor -o /usr/share/keyrings/kitware-archive-keyring.gpg && \
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ jammy main' > /etc/apt/sources.list.d/kitware.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends kitware-archive-keyring cmake && \
    printf 'Package: cmake cmake-data\nPin: origin apt.kitware.com\nPin-Priority: 990\n' > /etc/apt/preferences.d/kitware-cmake && \
    rm -rf /var/lib/apt/lists/*

# LLVM 18 from apt.llvm.org. Pin amd64: multiarch is enabled and llvm.sh is an
# unmaintained entry point for 18 (apt.llvm.org documents only 21/22 on Bookworm).
RUN wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc >/dev/null && \
    echo 'deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/apt.llvm.org.asc] https://apt.llvm.org/bookworm/ llvm-toolchain-bookworm-18 main' > /etc/apt/sources.list.d/llvm-toolchain-bookworm-18.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends clang-18 clang-format-18 clang-tidy-18 lld-18 && \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-18 100 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-18 100 && \
    update-alternatives --install /usr/bin/lld lld /usr/bin/lld-18 100 && \
    update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-18 100 && \
    update-alternatives --install /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-18 100 && \
    rm -rf /var/lib/apt/lists/*

# libgstreamer-plugins-base1.0-dev is not Multi-Arch: same, so amd64 and arm64
# -dev cannot be co-installed. The arm64 -dev is extracted above (not dpkg -i)
# to provide aarch64 .so linker names, pkg-config files, and gstglconfig.h.

# Prefer ccache wrappers for native and cross compilers
ENV PATH="/usr/lib/ccache:${PATH}"
ENV CCACHE_DIR=/home/user/.cache/ccache

RUN groupadd -g 1000 user && \
    useradd -m -u 1000 -g user -d /home/user -s /bin/bash user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/user

RUN systemctl enable systemd-timedated

# .NET 10 SDK — commented out until re-enabled after testing.
# LLVM 18 (clang, clang++, lld, clang-format, clang-tidy) is installed above.
#
# RUN wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb && \
#     dpkg -i /tmp/packages-microsoft-prod.deb && \
#     rm /tmp/packages-microsoft-prod.deb && \
#     apt-get update && \
#     apt-get install -y --no-install-recommends dotnet-sdk-10.0 && \
#     rm -rf /var/lib/apt/lists/*

# Microsoft ODBC Driver 18 from Microsoft Debian 12 feed
RUN wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb && \
    dpkg -i /tmp/packages-microsoft-prod.deb && \
    rm /tmp/packages-microsoft-prod.deb && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js 22.x from NodeSource (includes npm and npx)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*



# Install vcpkg and check out the baseline commit from vcpkg-configuration.json.
# Full clone, then checkout; the baseline is not fetched shallow.
ENV VCPKG_ROOT=/home/user/vcpkg
ARG VCPKG_BASELINE=9e593bb18ea69cc5095e012465dcd675a822ed0d

RUN git clone https://github.com/microsoft/vcpkg.git ${VCPKG_ROOT} && \
    cd ${VCPKG_ROOT} && \
    git checkout ${VCPKG_BASELINE} && \
    ./bootstrap-vcpkg.sh -disableMetrics

ENV PATH="${VCPKG_ROOT}:${PATH}"

# Binary cache for precompiled dependencies (used by devcontainer)
ENV VCPKG_DEFAULT_BINARY_CACHE=/home/user/.cache/vcpkg/archives
ENV X_VCPKG_REGISTRIES_CACHE=/home/user/.cache/vcpkg/registries
RUN mkdir -p /home/user/.cache/vcpkg/archives /home/user/.cache/vcpkg/overlay-ports /home/user/.cache/vcpkg/registries /home/user/.cache/ccache

# Manifest and community triplets. ports/ is the overlay-ports path named in
# vcpkg-configuration.json; no port recipes are checked in. The dbus session
# socket dir for cross builds is set in arm64-linux-dynamic.cmake.
COPY vcpkg.json vcpkg-configuration.json /tmp/
COPY ports/ /home/user/.cache/vcpkg/overlay-ports/
COPY arm64-linux-dynamic.cmake /home/user/vcpkg/triplets/community/
COPY wasm32-emscripten.cmake /home/user/vcpkg/triplets/community/

RUN chown -R user:user /home/user && \
    chmod -R 755 /home/user/vcpkg /home/user/.cache

# ---- Stage: native x64-linux deps (also produces host tools for later stages) ----
FROM base AS x64-linux

ENV VCPKG_TARGET_ARCHITECTURE=x64
ENV VCPKG_CRT_LINKAGE=static
ENV VCPKG_LIBRARY_LINKAGE=static
ENV VCPKG_CMAKE_SYSTEM_NAME=Linux
ENV VCPKG_FIXUP_ELF_RPATH=ON
ENV VCPKG_DISABLE_METRICS=1
ENV VCPKG_DEFAULT_TRIPLET=x64-linux
ENV VCPKG_TARGET_TRIPLET=x64-linux

RUN vcpkg install --clean-buildtrees-after-build && \
    rm -rf /tmp/vcpkg_installed && \
    chown -R user:user /home/user && \
    chmod -R 755 /home/user/vcpkg /home/user/.cache

# ---- Stage: wasm32-emscripten deps ----
FROM x64-linux AS wasm

ENV VCPKG_TARGET_ARCHITECTURE=wasm32
ENV VCPKG_CRT_LINKAGE=dynamic
ENV VCPKG_LIBRARY_LINKAGE=static
ENV VCPKG_CMAKE_SYSTEM_NAME=Emscripten
ENV VCPKG_FIXUP_ELF_RPATH=
ENV VCPKG_DISABLE_METRICS=1
ENV VCPKG_DEFAULT_TRIPLET=wasm32-emscripten
ENV VCPKG_TARGET_TRIPLET=wasm32-emscripten

# Install Emscripten SDK under the user home directory
ENV EMSDK=/home/user/emsdk
ENV EMSCRIPTEN_ROOT=/home/user/emsdk/upstream/emscripten
ARG EMSDK_VERSION=6.0.9

RUN git clone https://github.com/emscripten-core/emsdk.git ${EMSDK} && \
    cd ${EMSDK} && \
    ./emsdk install ${EMSDK_VERSION} && \
    ./emsdk activate ${EMSDK_VERSION} --embedded && \
    echo '. /home/user/emsdk/emsdk_env.sh >/dev/null 2>&1' >> /home/user/.bashrc

ENV PATH="${EMSDK}:${EMSCRIPTEN_ROOT}:${EMSDK}/upstream/bin:${PATH}"

RUN . /home/user/emsdk/emsdk_env.sh && \
    vcpkg install --clean-buildtrees-after-build && \
    rm -rf /tmp/vcpkg_installed && \
    chown -R user:user /home/user && \
    chmod -R 755 /home/user/vcpkg /home/user/.cache && \
    ccache -C

# ---- Stage: final image with arm64-linux-dynamic ----
FROM wasm AS final

ENV VCPKG_TARGET_ARCHITECTURE=arm64
ENV VCPKG_CRT_LINKAGE=dynamic
ENV VCPKG_LIBRARY_LINKAGE=dynamic
ENV VCPKG_CMAKE_SYSTEM_NAME=Linux
ENV VCPKG_FIXUP_ELF_RPATH=ON
ENV VCPKG_DISABLE_METRICS=1
ENV VCPKG_DEFAULT_TRIPLET=arm64-linux-dynamic
ENV VCPKG_TARGET_TRIPLET=arm64-linux-dynamic

# FORCE_SYSTEM_BINARIES only for this arm64 install (cross tools). Do not leave it as
# a persistent ENV: empty ENV VAR= is still defined and breaks native x64 vcpkg-make
# (microsoft/vcpkg#52050) when cmake --preset runs in the published image.
RUN VCPKG_FORCE_SYSTEM_BINARIES=1 vcpkg install --clean-buildtrees-after-build && \
    rm -rf /tmp/vcpkg.json /tmp/vcpkg_installed && \
    chown -R user:user /home && \
    chmod -R 755 /home/user/vcpkg /home/user/.cache && \
    ccache -C
    
# Set the build-time VCPKG_* variables to empty strings. They remain defined;
# an empty ENV does not unset a variable. FORCE_SYSTEM_BINARIES is omitted so it
# stays unset for native x64 configures in the running container.
ENV VCPKG_CRT_LINKAGE= \
    VCPKG_LIBRARY_LINKAGE= \
    VCPKG_CMAKE_SYSTEM_NAME= \
    VCPKG_FIXUP_ELF_RPATH= \
    VCPKG_DISABLE_METRICS= \
    VCPKG_DEFAULT_TRIPLET= \
    VCPKG_TARGET_TRIPLET= \
    VCPKG_TARGET_ARCHITECTURE=

WORKDIR /workspace

VOLUME ["/run", "/run/lock"]

VOLUME ["/sys/fs/cgroup"]

CMD ["/sbin/init"]
