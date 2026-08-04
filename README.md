# Raspberry PI 5 cross compiler Docker container

This project defines a Docker container for cross compiling Raspberry PI 5 CMake projects using vcpkg.

The container is used as a devcontainer base image for rapid development with precompiled dependencies identified by [vcpkg.json](vcpkg.json), the baseline defined in [vcpkg-configuration.json](vcpkg-configuration.json), and the target triplet defined in [arm64-linux-dynamic.cmake](arm64-linux-dynamic.cmake).

The base image also includes the .NET 10 SDK and the Linux Native AOT linker prerequisites needed for native publish workflows on Debian Bookworm.

Build (requires BuildKit; on vcpkg failure, logs are copied to `./vcpkg-logs/`):

```bash
docker build -t ghcr.io/lancerworldwide-oss/bookworm-vcpkg:latest .

```

```bash
docker run -it ghcr.io/lancerworldwide-oss/bookworm-vcpkg:latest

```

## Native AOT support

The image includes these Native AOT prerequisites:

- .NET 10 SDK from Microsoft's Debian 12 package feed
- LLVM 18 with unversioned `clang`, `clang++`, and `lld`
- `zlib1g-dev` for the linker inputs required by self-contained native publish

### Architecture notes

- `linux-x64` Native AOT publish is expected to work directly in the container once the image is rebuilt.
- `linux-arm64` Native AOT publish is not handled by the existing GCC cross toolchain alone. Use an arm64 build host, or supply downstream clang target and sysroot arguments for the publish step.

### Verification

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
