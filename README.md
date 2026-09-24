# Raspberry PI 5 cross compiler Docker container

This project defines a Docker container for cross compiling Raspberry PI 5 CMake projects using vcpkg.

The container is used as a devcontainer base image for rapid development with precompiled dependencies identified by [vcpkg.json](vcpkg.json) and the baseline defined in [vcpkg-configuration.json](vcpkg-configuration.json). The image precompiles the same manifest for three triplets:

- `x64-linux` (static)
- `wasm32-emscripten` (Emscripten/WASM; Qt ports are blocked in the overlay triplet)
- `arm64-linux-dynamic` (custom community triplet in [arm64-linux-dynamic.cmake](arm64-linux-dynamic.cmake))

The base image also includes:

- `ccache` (wrappers on `PATH` via `/usr/lib/ccache` for native GCC and `aarch64-linux-gnu-*`)
- Emscripten SDK 6.0.9 at `/home/user/emsdk` (`emcc` / `em++` on `PATH`)
- vcpkg at `/home/user/vcpkg` (`VCPKG_ROOT=/home/user/vcpkg`), checked out at the baseline in `vcpkg-configuration.json` (full clone, then checkout)
- LLVM 18, with unversioned `clang`, `clang++`, `lld`, `clang-format`, and `clang-tidy`
- Microsoft ODBC Driver 18 and Node.js 22

Each triplet install writes `/tmp/vcpkg_installed` and the Dockerfile removes that tree. Precompiled packages are kept in the binary cache at `/home/user/.cache/vcpkg/archives`. `ports/` is copied to the overlay path in `vcpkg-configuration.json`; no overlay port recipes are checked in. The dbus session socket dir for arm64 cross builds is set in `arm64-linux-dynamic.cmake`.

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
vcpkg version
test -d /home/user/vcpkg && echo "VCPKG_ROOT ok"
clang --version
lld --version
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
