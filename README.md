# Raspberry PI 5 cross compiler Docker container

This project defines a Docker container for cross compiling Raspberry PI 5 CMake projects using vcpkg

The container is used as a devcontainer base image for rapid development with precompiled dependencies identified by the vcpkg.json using the baseline defined in vcpkg-configuration.json and using the target triplet defined in arm64-linux-dynamic.cmake

Build (requires BuildKit; on vcpkg failure, logs are copied to `./vcpkg-logs/`):

```bash
docker build -t ghcr.io/lancerworldwide-oss/bookworm-vcpkg:latest .
```

Run with X11 display forwarding to the host (forward port 6000 for X displays):

```bash
docker run -it -p 6000:6000 ghcr.io/lancerworldwide-oss/bookworm-vcpkg:latest
```