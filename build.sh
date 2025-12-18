#!/bin/bash

set -euo pipefail

ROOT_DIR="$(pwd)/.tmp"
KERNEL_REPO="https://github.com/microsoft/WSL2-Linux-Kernel.git"
# KERNEL_TAG="linux-msft-wsl-$(uname -r | cut -d '-' -f1)"
KERNEL_TAG="$(curl -s https://api.github.com/repos/microsoft/WSL2-Linux-Kernel/releases/latest | grep '"tag_name":' | cut -d '"' -f 4)"

ZFS_REPO="https://github.com/openzfs/zfs.git"
ZFS_TAG="$(curl -s https://api.github.com/repos/openzfs/zfs/releases/latest | grep '"tag_name":' | cut -d '"' -f 4)"

# ensure_repo <repo_url> <tag> <destination>
ensure_repo() {
  (
    if [ ! -d "$3" ]; then
      mkdir -p "$3"
      git clone --depth 1 --single-branch --branch "$2" "$1" "$3"
    else
      cd "$3" || exit
      git fetch --depth 1 origin tag "$2"
      git checkout --force "$2"
    fi
  )
}

# TODO: lock with commit hash
ensure_repo "$ZFS_REPO" "$ZFS_TAG" "$ROOT_DIR/zfs"
ensure_repo "$KERNEL_REPO" "$KERNEL_TAG" "$ROOT_DIR/kernel"

# Prepare kernel build
(
  cd "$ROOT_DIR/kernel" || exit

  # Use the WSL2 kernel configuration
  cp Microsoft/config-wsl .config

  # Or, use configuration from current environment
  # cat /proc/config.gz | gunzip > .config

  # Apply new options with defaults (non-interactive)
  make olddefconfig

  # Prepare the kernel
  # TODO: we probably only need to run some targets
  make -j"$(nproc)" -s
)

# Build ZFS kernel module
(
  cd "$ROOT_DIR/zfs" || exit

  sh autogen.sh
  sh configure \
    --with-linux="$ROOT_DIR/kernel" \
    --with-linux-obj="$ROOT_DIR/kernel"

  make -j"$(nproc)" -s
  cp -r . "$ROOT_DIR/result"  # TODO
)
