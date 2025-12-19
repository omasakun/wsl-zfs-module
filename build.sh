#!/bin/bash

# http://openzfs.github.io/openzfs-docs/Developer%20Resources/Building%20ZFS.html
# https://www.kernel.org/doc/html/latest/kbuild/modules.html

set -euo pipefail

KERNEL_TAG="${1:-}"
ZFS_TAG="${2:-}"

# Fallback for manual execution
if [ -z "$KERNEL_TAG" ]; then
  KERNEL_TAG="$(curl -s https://api.github.com/repos/microsoft/WSL2-Linux-Kernel/releases/latest | grep '"tag_name":' | cut -d '"' -f 4)"
  # Or, use the kernel version of the current environment
  KERNEL_TAG="linux-msft-wsl-$(uname -r | cut -d '-' -f1)"
fi

if [ -z "$ZFS_TAG" ]; then
  ZFS_TAG="$(curl -s https://api.github.com/repos/openzfs/zfs/releases/latest | grep '"tag_name":' | cut -d '"' -f 4)"
fi

ROOT_DIR="$(pwd)/.tmp"
KERNEL_REPO="https://github.com/microsoft/WSL2-Linux-Kernel.git"
ZFS_REPO="https://github.com/openzfs/zfs.git"

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

ensure_repo "$ZFS_REPO" "$ZFS_TAG" "$ROOT_DIR/zfs"
ensure_repo "$KERNEL_REPO" "$KERNEL_TAG" "$ROOT_DIR/kernel"

# Prepare kernel build
(
  cd "$ROOT_DIR/kernel" || exit

  # Use the WSL2 kernel configuration
  cp Microsoft/config-wsl .config

  # Or, use configuration from current environment
  # cat /proc/config.gz | gunzip > .config

  # Apply new options with defaults
  make olddefconfig

  # Prepare the kernel (Module.symvers is needed for ZFS)
  # TODO: we probably only need to run some targets
  make -j"$(nproc)"
)

# Build ZFS kernel module
(
  cd "$ROOT_DIR/zfs" || exit

  # Prepare the build system
  sh autogen.sh
  sh configure \
    --with-config=kernel \
    --with-linux="$ROOT_DIR/kernel" \
    --with-linux-obj="$ROOT_DIR/kernel"

  # Build the kernel module
  make -j"$(nproc)"
)

# Collect results
rm -rf "$ROOT_DIR/result"
mkdir "$ROOT_DIR/result"
cp "$ROOT_DIR/zfs/module/zfs.ko" "$ROOT_DIR/result/"
