# Raspberry PI 5 cross compiler Docker container

This project defines a Docker container for cross compiling Raspberry PI 5 CMake projects using vcpkg.

The container is used as a devcontainer base image for rapid development with precompiled dependencies identified by [vcpkg.json](vcpkg.json) and the baseline defined in [vcpkg-configuration.json](vcpkg-configuration.json). The image precompiles the same manifest for four triplets:

- `x64-linux` (static)
- `wasm32-emscripten` (Emscripten/WASM; Qt ports are blocked in the overlay triplet)
- `x64-mingw-static` (community triplet in [x64-mingw-static.cmake](x64-mingw-static.cmake); static libraries, dynamic MinGW runtime)
- `arm64-linux-dynamic` (custom community triplet in [arm64-linux-dynamic.cmake](arm64-linux-dynamic.cmake))

The base image also includes:

- `ccache` (wrappers on `PATH` via `/usr/lib/ccache` for native GCC, `aarch64-linux-gnu-*`, and `x86_64-w64-mingw32-gcc` / `x86_64-w64-mingw32-g++`)
- MinGW-w64 x64 with the POSIX thread model (`x86_64-w64-mingw32-gcc` / `x86_64-w64-mingw32-g++` on `PATH`)
- Emscripten SDK 6.0.9 at `/home/user/emsdk` (`emcc` / `em++` on `PATH`)
- vcpkg at `/home/user/vcpkg` (`VCPKG_ROOT=/home/user/vcpkg`), checked out at the baseline in `vcpkg-configuration.json` (full clone, then checkout)
- LLVM 18, with unversioned `clang`, `clang++`, `lld`, `clang-format`, and `clang-tidy`
- Microsoft ODBC Driver 18 and Node.js 22
- mdBook 0.4.44 at `/usr/local/bin/mdbook`

Each triplet install writes `/tmp/vcpkg_installed` and the Dockerfile removes that tree. Precompiled packages are kept in the binary cache at `/home/user/.cache/vcpkg/archives`. The MinGW stage builds in parallel with wasm from the x64-linux stage, and the final image copies that stage's archives into the same cache. No overlay recipes are checked in. `grpc` 1.81.1#1, including `00017-mingw-bigobj.patch`, and `nanodbc` 2.14.0#1 come from the `vcpkg-updates` registry at baseline `d12733af6035920d109118e5b82a85a2abd6ea48`. The dbus session socket dir for arm64 cross builds is set in `arm64-linux-dynamic.cmake`.

`x64-mingw-static` matches vcpkg's community triplet except that `PATH` is not part of the package ABI. The published image adds Emscripten to `PATH`, which would miss a cache built without it. The compiler is still hashed. Debian's MinGW-w64 packages provide `x86_64-w64-mingw32-gcc` and `x86_64-w64-mingw32-g++`, pinned to the POSIX thread model. These ports are excluded on MinGW: `sentry-native` (`!emscripten & !mingw`) because its Windows backend selects Crashpad, and `tbb` (`!emscripten & !mingw`) plus `lvgl` (`!mingw`) because they failed to build for `x64-mingw-static`. `lvgl` is still installed for Linux and Emscripten. `grpc` and `nanodbc` are prebuilt for `x64-mingw-static`. The `vcpkg-updates` `grpc` 1.81.1#1 patch `00017-mingw-bigobj.patch` adds `-Wa,-mbig-obj` on MinGW, because grpc 1.81.1 Debug objects exceed binutils 2.40's limit of 32768 COFF sections and that flag selects the PE bigobj format. `nanodbc` 2.14.0#1 comes from `vcpkg-updates` because the stock port's Windows config path does not match the MinGW install path: nanodbc installs the export to `lib/cmake/nanodbc` when `MINGW` is set, and the stock port looks for `cmake/`. The triplet file itself is unchanged: vcpkg uses its SHA-256 as `triplet_abi`, so a flag in the triplet would rebuild every `x64-mingw-static` archive. Consuming projects set `VCPKG_TARGET_TRIPLET=x64-mingw-static`.

The arm64 install runs with `VCPKG_FORCE_SYSTEM_BINARIES=1` so cross tools resolve from `PATH`. That also records `cmake|0` in every arm64 package ABI. Do not persist the variable as an image `ENV` (it breaks native x64 vcpkg-make; see microsoft/vcpkg#52050). Consuming projects must set `VCPKG_FORCE_SYSTEM_BINARIES=1` again when configuring `arm64-linux-*` so the binary cache restores; leave it unset for `x64-linux`, `wasm32-emscripten`, and `x64-mingw-static`.

The .NET 10 SDK install is commented out in the Dockerfile until it is re-enabled after testing. LLVM 18 is installed.

Build (requires BuildKit):

```bash {"terminalRows":"33"}
docker build -t ghcr.io/lancerworldwide-oss/bookworm-vcpkg:latest .
```

```bash
docker run -it ghcr.io/lancerworldwide-oss/bookworm-vcpkg:latest
```

## Toolchain verification

```bash
ccache --version
emcc --version
em++ --version
aarch64-linux-gnu-g++ --version
x86_64-w64-mingw32-g++ --version
vcpkg version
test -d /home/user/vcpkg && echo "VCPKG_ROOT ok"
clang --version
lld --version
mdbook --version
```

`vcpkg list` in a new container is empty because `/tmp/vcpkg_installed` is deleted after each stage. Qt ports are rejected by `wasm32-emscripten.cmake` if a Qt port is requested for that triplet. System Qt6 development packages are still installed with apt.

## Native AOT support

Already installed:

- LLVM 18 with unversioned `clang`, `clang++`, and `lld`
- `zlib1g-dev` in the base apt layer

Commented out until re-enabled:

- .NET 10 SDK from Microsoft's Debian 12 package feed

### Architecture notes

- `linux-x64` Native AOT publish needs the .NET SDK block uncommented and the image rebuilt. Clang and zlib are already in the image.
- `linux-arm64` Native AOT publish is not handled by the existing GCC cross toolchain alone. Use an arm64 build host, or supply downstream clang target and sysroot arguments for the publish step.

### Verification

```bash
clang --version
lld --version
```

After uncommenting the .NET SDK and rebuilding:

```bash
dotnet --version
```

Then run a Native AOT publish from the consuming repository:

```bash
dotnet publish <project-path> -c Release -r linux-x64


```

If the publish step fails with `clang: not found` or `cannot find -lz`, the image is still missing one of the required Native AOT prerequisites.
