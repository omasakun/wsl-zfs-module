<div align="center">
  <h1>WSL2 ZFS Module</h1>
  <p>ZFS Kernel Module Builds for WSL2</p>
</div>
<br>
<br>

WSL2 supports custom kernel modules since kernel version 6.

This project provides a ZFS kernel module automatically built with GitHub Actions for easy installation on WSL2.

Originally made for [NixOS-WSL](https://github.com/nix-community/NixOS-WSL), but should work on any WSL2 distribution.

## Installation

1. Download `zfs-modules.tar.gz` from the [Releases](https://github.com/omasakun/wsl-zfs-module/releases) page.
2. `tar -xzf zfs-modules.tar.gz` to extract the modules.
3. `insmod spl.ko zfs.ko` to load the modules.
4. `zfs --version` to verify the installation. (You may need to install ZFS userland tools separately)

Make sure to download the version that matches your WSL2 kernel version (`uname -r`).

<br>

**On NixOS-WSL**

```bash
# Get the current kernel and latest ZFS tags
KERNEL_TAG="kernel-$(uname -r | cut -d '-' -f1)"
ZFS_TAG="$(curl -s https://api.github.com/repos/openzfs/zfs/releases/latest | grep '"tag_name":' | cut -d '"' -f 4)"
RELEASE_URL="https://github.com/omasakun/wsl-zfs-module/releases/download/$ZFS_TAG-$KERNEL_TAG"

# Download the kernel modules
curl -L "$RELEASE_URL/zfs-modules.tar.gz" | tar -xz

# Load the module and verify
nix shell nixpkgs#kmod nixpkgs#zfs
sudo insmod spl.ko zfs.ko
sudo zfs --version
```

## License

This project is licensed under the [MIT License](LICENSE).

Copyright 2025 omasakun
