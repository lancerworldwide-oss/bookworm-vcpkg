set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE dynamic)

set(VCPKG_CMAKE_SYSTEM_NAME Linux)

set(VCPKG_FIXUP_ELF_RPATH ON)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
# Prefer arm64 libraries over host
set(CMAKE_FIND_ROOT_PATH "/usr/aarch64-linux-gnu")
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)

# dbus cannot autodetect session socket dir when cross-compiling (vcpkg#40031)
if(PORT STREQUAL "dbus")
    set(VCPKG_CMAKE_CONFIGURE_OPTIONS "-DDBUS_SESSION_SOCKET_DIR=/tmp")
endif()

# vcpkg-make drops default --prefix when VCPKG_FORCE_SYSTEM_BINARIES is set
# (microsoft/vcpkg#52050). Explicit per-config options still reach configure.
set(VCPKG_MAKE_CONFIGURE_OPTIONS_RELEASE
    "--prefix=${CURRENT_INSTALLED_DIR}"
    "--libdir=\\\${prefix}/lib"
)
set(VCPKG_MAKE_CONFIGURE_OPTIONS_DEBUG
    "--prefix=${CURRENT_INSTALLED_DIR}/debug"
    "--libdir=\\\${prefix}/lib"
    "--includedir=\\\${prefix}/../include"
)
