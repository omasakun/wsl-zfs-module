# https://flake.parts/index.html

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, systems, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import systems;
      perSystem =
        { pkgs, ... }:
        let
          deps =
            with pkgs;
            [
              # Core build tools
              stdenv # TODO: is this always correct for wsl kernel?
              autoconf
              automake
              libtool

              # ZFS build deps / user-space tools deps
              attr
              curl
              gettext
              libaio
              libtirpc
              libunwind
              libuuid
              openssl
              pam
              pkg-config
              python3
              udev
              zlib
            ]
            ++ pkgs.linux.nativeBuildInputs; # TODO: is this always correct for wsl kernel?
        in
        {
          packages.default = pkgs.stdenv.mkDerivation {
            name = "zfs-module";
            src = ./.;
            nativeBuildInputs = deps;
            buildPhase = ''
              bash build.sh
            '';
            installPhase = ''
              mkdir -p $out
              cp -r .tmp/result/* $out/
            '';
          };

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = deps;
          };
        };
    };
}
