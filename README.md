# Raspberry PI 5 cross compiler Docker container

This project defines a Docker container for cross compiling Raspberry PI 5 CMake projects using vcpkg

The container is used as a devcontainer base image for rapid development with precompiled dependencies identified by the vcpkg.json using the baseline defined in vcpkg-configuration.json and using the target triplet defined in arm64-linux-dynamic.cmake

Build (requires BuildKit; on vcpkg failure, logs are copied to `./vcpkg-logs/`):

```bash
DOCKER_BUILDKIT=1 docker build -t fu .
```