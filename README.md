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

**On WSL Environments**

```bash
# Get the current kernel and latest ZFS tags
KERNEL_TAG="kernel-$(uname -r | cut -d '-' -f1)"
ZFS_TAG="$(curl -s https://api.github.com/repos/openzfs/zfs/releases/latest | grep '"tag_name":' | cut -d '"' -f 4)"
RELEASE_URL="https://github.com/omasakun/wsl-zfs-module/releases/download/$ZFS_TAG-$KERNEL_TAG"

# Download the kernel modules
curl -L "$RELEASE_URL/zfs-modules.tar.gz" | tar -xz

# Load the module and verify
sudo insmod spl.ko zfs.ko
sudo zfs --version
```

<br>

**On NixOS-WSL + Flakes**

You can also add the following snippet to your `flake.nix` to automatically fetch and load the ZFS kernel modules on system boot.
I recommend saving the script as `wsl-zfs.nix` and importing it in your main `flake.nix`.

```nix
{ pkgs, ... }:

let
  wsl-zfs-module = pkgs.fetchzip {
    # Replace the URL with your environment's appropriate version
    url = "https://github.com/omasakun/wsl-zfs-module/releases/download/zfs-2.3.5-kernel-6.6.87.2/zfs-modules.tar.gz";
    hash = "sha256-lZYUMjPrwAwM4mZlzXsDB5RFqCaczFz8TiR5wb7YxuQ=";
    stripRoot = false;
  };
in

{
  assertions = [
    {
      assertion = pkgs.zfs.version == "2.3.5";
      message = "zfs version is ${pkgs.zfs.version}. update the fetchzip URL and hash accordingly.";
    }
  ];

  environment.systemPackages = with pkgs; [
    kmod
    zfs
  ];

  systemd.services.wsl-zfs-load-modules = {
    description = "Load WSL ZFS kernel modules";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = ''
        ${pkgs.bash}/bin/bash -c '
          ${pkgs.kmod}/bin/lsmod | grep -q spl || ${pkgs.kmod}/bin/insmod ${wsl-zfs-module}/spl.ko
          ${pkgs.kmod}/bin/lsmod | grep -q zfs || ${pkgs.kmod}/bin/insmod ${wsl-zfs-module}/zfs.ko
        '
      '';
    };
  };
}
```

## License

This project is licensed under the [MIT License](LICENSE).

Copyright 2025 omasakun
