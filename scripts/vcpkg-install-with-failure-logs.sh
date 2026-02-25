#!/bin/bash
set -e
VCPKG_ROOT="${VCPKG_ROOT:-/opt/vcpkg}"
LOG_DEST="${VCPKG_FAILURE_LOGS:-/vcpkg-logs}"

if ! vcpkg install; then
  EXIT_CODE=$?
  mkdir -p "$LOG_DEST"
  # Copy vcpkg-manifest-install.log if present (preserve port subdir to avoid overwrites)
  find "$VCPKG_ROOT/buildtrees" -name "vcpkg-manifest-install.log" -exec sh -c 'port=$(basename "$(dirname "$1")"); mkdir -p "$2/$port"; cp "$1" "$2/$port/"' _ {} "$LOG_DEST" \; 2>/dev/null || true
  # Copy all .log files from each port's buildtrees as fallback
  for port_dir in "$VCPKG_ROOT/buildtrees"/*/; do
    [ -d "$port_dir" ] || continue
    port=$(basename "$port_dir")
    mkdir -p "$LOG_DEST/$port"
    cp -n "$port_dir"*.log "$LOG_DEST/$port/" 2>/dev/null || true
  done
  exit $EXIT_CODE
fi
