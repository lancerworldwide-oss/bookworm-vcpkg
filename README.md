# Raspberry PI 5 cross compiler Docker container

This project defines a Docker container for cross compiling Raspberry PI 5 CMake projects using vcpkg.

The container is used as a devcontainer base image for rapid development with precompiled dependencies identified by [vcpkg.json](vcpkg.json) and the baseline defined in [vcpkg-configuration.json](vcpkg-configuration.json). The image precompiles the same manifest for three triplets:

- `x64-linux` (static)
- `wasm32-emscripten` (Emscripten/WASM; Qt ports are blocked in the overlay triplet)
- `arm64-linux-dynamic` (custom community triplet in [arm64-linux-dynamic.cmake](arm64-linux-dynamic.cmake))

The base image also includes:

- `ccache` (wrappers on `PATH` via `/usr/lib/ccache` for native GCC and `aarch64-linux-gnu-*`)
- Emscripten SDK 6.0.9 at `/home/user/emsdk` (`emcc` / `em++` on `PATH`)
- vcpkg at `/home/user/vcpkg` (`VCPKG_ROOT=/home/user/vcpkg`)
- PowerShell (`pwsh`) from Microsoft’s Debian 12 feed

Native AOT / .NET support (LLVM 18 + .NET 10 SDK) is present in the Dockerfile but currently commented out until re-enabled after testing.

Build (requires BuildKit; on vcpkg failure, logs are copied to `./vcpkg-logs/`):

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
pwsh --version


```

Confirm WASM did not install Qt via vcpkg:

```bash
vcpkg list | grep -i '^qt' || echo "no Qt packages (expected)"


```

## Native AOT support (disabled)

These install steps are commented out in the Dockerfile for now. Uncomment them to restore:

- .NET 10 SDK from Microsoft's Debian 12 package feed
- LLVM 18 with unversioned `clang`, `clang++`, and `lld`
- `zlib1g-dev` (still installed in the base apt layer) for the linker inputs required by self-contained native publish

### Architecture notes

- `linux-x64` Native AOT publish is expected to work directly in the container once the image is rebuilt with these layers enabled.
- `linux-arm64` Native AOT publish is not handled by the existing GCC cross toolchain alone. Use an arm64 build host, or supply downstream clang target and sysroot arguments for the publish step.

### Verification (after re-enabling)

```bash
dotnet --version
clang --version
lld --version


```

Then run a Native AOT publish from the consuming repository:

```bash
dotnet publish <project-path> -c Release -r linux-x64


```

If the publish step fails with `clang: not found` or `cannot find -lz`, the image is still missing one of the required Native AOT prerequisites.
