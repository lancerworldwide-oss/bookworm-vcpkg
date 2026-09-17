# Raspberry Pi 5 cross-compilation devcontainer base image
# Precompiles vcpkg dependencies for x64-linux, wasm32-emscripten, and arm64-linux-dynamic

FROM debian:bookworm-slim AS base

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# X11 display forwarding to host (use with -p 6000:6000 when running)
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
    cmake \
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
    zip \
    && update-binfmts --enable \
    && ln -sf /usr/bin/ccache /usr/lib/ccache/aarch64-linux-gnu-gcc \
    && ln -sf /usr/bin/ccache /usr/lib/ccache/aarch64-linux-gnu-g++ \
    && rm -rf /var/lib/apt/lists/*

# Prefer ccache wrappers for native and cross compilers
ENV PATH="/usr/lib/ccache:${PATH}"
ENV CCACHE_DIR=/home/user/.cache/ccache

RUN groupadd -g 1000 user && \
    useradd -m -u 1000 -g user -d /home/user -s /bin/bash user \
    && echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/user

RUN systemctl enable systemd-timedated

# Native AOT / .NET components — commented out until re-enabled after testing
# RUN wget https://apt.llvm.org/llvm.sh && \
#     chmod +x llvm.sh && \
#     ./llvm.sh 18 && \
#     apt install -y --no-install-recommends clang-18 clang-format-18 clang-tidy-18 lld-18 && \
#     update-alternatives --install /usr/bin/clang clang /usr/bin/clang-18 100 && \
#     update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-18 100 && \
#     update-alternatives --install /usr/bin/lld lld /usr/bin/lld-18 100 && \
#     update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-18 100 && \
#     update-alternatives --install /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-18 100 && \
#     rm -rf llvm.sh && \
#     rm -rf /var/lib/apt/lists/*
#
# RUN wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb && \
#     dpkg -i /tmp/packages-microsoft-prod.deb && \
#     rm /tmp/packages-microsoft-prod.deb && \
#     apt-get update && \
#     apt-get install -y --no-install-recommends dotnet-sdk-10.0 && \
#     rm -rf /var/lib/apt/lists/*

# PowerShell (pwsh) from Microsoft Debian 12 feed
RUN wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb && \
    dpkg -i /tmp/packages-microsoft-prod.deb && \
    rm /tmp/packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends powershell && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js 22.x from NodeSource (includes npm and npx)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

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

# Install vcpkg (shallow clone at baseline from vcpkg-configuration.json)
ENV VCPKG_ROOT=/home/user/vcpkg
ARG VCPKG_BASELINE=4acadb7d732e662bbf130c4849be6d3a0aa6f6b9

RUN git clone https://github.com/microsoft/vcpkg.git ${VCPKG_ROOT} && \
    cd ${VCPKG_ROOT} && \
    git checkout ${VCPKG_BASELINE} && \
    ./bootstrap-vcpkg.sh -disableMetrics

ENV PATH="${VCPKG_ROOT}:${PATH}"

# Binary cache for precompiled dependencies (used by devcontainer)
ENV VCPKG_DEFAULT_BINARY_CACHE=/home/user/.cache/vcpkg/archives
ENV X_VCPKG_REGISTRIES_CACHE=/home/user/.cache/vcpkg/registries
RUN mkdir -p /home/user/.cache/vcpkg/archives /home/user/.cache/vcpkg/overlay-ports /home/user/.cache/vcpkg/registries /home/user/.cache/ccache

# Copy manifest, triplets, and overlay ports (dbus cross-compile fix, libsystemd system gperf)
COPY vcpkg.json vcpkg-configuration.json /tmp/
COPY ports/ /home/user/.cache/vcpkg/overlay-ports/
COPY arm64-linux-dynamic.cmake /home/user/vcpkg/triplets/community/
COPY wasm32-emscripten.cmake /home/user/vcpkg/triplets/community/

RUN chown -R user:user /home/user/vcpkg /home/user/emsdk /home/user/.cache && \
    chmod -R 755 /home/user/vcpkg /home/user/.cache/vcpkg

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
    chown -R user:user /home/user/vcpkg /home/user/.cache/vcpkg && \
    chmod -R 755 /home/user/vcpkg /home/user/.cache/vcpkg

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
ENV VCPKG_MAX_CONCURRENCY=3

RUN . /home/user/emsdk/emsdk_env.sh && \
    vcpkg install --clean-buildtrees-after-build \
    || (echo "===== vcpkg failure logs =====" \
        && if [ -f /tmp/vcpkg_installed/vcpkg/issue_body.md ]; then \
             echo "===== /tmp/vcpkg_installed/vcpkg/issue_body.md =====" \
             && cat /tmp/vcpkg_installed/vcpkg/issue_body.md; \
           fi \
        && for f in /home/user/vcpkg/buildtrees/*/install-wasm32-emscripten-*-out.log \
                    /home/user/vcpkg/buildtrees/*/config-wasm32-emscripten-out.log; do \
             if [ -f "$f" ]; then \
               echo "===== FAILED / errors in $f =====" \
               && grep -nE 'FAILED:|error:|undefined reference|Killed|No space left|FATAL_ERROR' "$f" \
                    | tail -n 80 || true \
               && echo "===== tail $f =====" \
               && tail -n 80 "$f"; \
             fi; \
           done \
        && false) \
    && if vcpkg list | grep -qiE '^qt'; then \
         echo "Qt must not be installed for wasm32-emscripten" \
         && vcpkg list \
         && exit 1; \
       fi \
    && rm -rf /tmp/vcpkg_installed \
    && chown -R user:user /home/user/vcpkg /home/user/emsdk /home/user/.cache \
    && chmod -R 755 /home/user/vcpkg /home/user/.cache/vcpkg

ENV VCPKG_MAX_CONCURRENCY=

# ---- Stage: final image with arm64-linux-dynamic ----
FROM wasm AS final

ENV VCPKG_FORCE_SYSTEM_BINARIES=1
ENV VCPKG_TARGET_ARCHITECTURE=arm64
ENV VCPKG_CRT_LINKAGE=dynamic
ENV VCPKG_LIBRARY_LINKAGE=dynamic
ENV VCPKG_CMAKE_SYSTEM_NAME=Linux
ENV VCPKG_FIXUP_ELF_RPATH=ON
ENV VCPKG_DISABLE_METRICS=1
ENV VCPKG_DEFAULT_TRIPLET=arm64-linux-dynamic
ENV VCPKG_TARGET_TRIPLET=arm64-linux-dynamic

RUN vcpkg install --clean-buildtrees-after-build && \
    rm -rf /tmp/vcpkg.json /tmp/vcpkg_installed && \
    chown -R user:user /home/user/vcpkg /home/user/emsdk /home/user/.cache && \
    chmod -R 755 /home/user/vcpkg /home/user/.cache && \
    ccache -C

# Unset VCPKG_ build-time variables after install
ENV VCPKG_CRT_LINKAGE= \
    VCPKG_LIBRARY_LINKAGE= \
    VCPKG_CMAKE_SYSTEM_NAME= \
    VCPKG_FIXUP_ELF_RPATH= \
    VCPKG_DISABLE_METRICS= \
    VCPKG_DEFAULT_TRIPLET= \
    VCPKG_TARGET_TRIPLET= \
    VCPKG_FORCE_SYSTEM_BINARIES= \
    VCPKG_TARGET_ARCHITECTURE=

WORKDIR /workspace

VOLUME ["/run", "/run/lock"]

VOLUME ["/sys/fs/cgroup"]

CMD ["/sbin/init"]
