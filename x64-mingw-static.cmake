set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

# The stock community triplet tracks PATH in the package ABI. This image puts
# Emscripten on PATH after the MinGW stage, so a tracked PATH would miss the
# binary cache. The compiler itself is still hashed.
set(VCPKG_ENV_PASSTHROUGH_UNTRACKED PATH)

set(VCPKG_CMAKE_SYSTEM_NAME MinGW)
