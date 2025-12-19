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

              # ZFS build deps / build scripts deps
              attr
              curl
              git
              gettext
            ]
            ++ pkgs.linux.nativeBuildInputs; # TODO: is this always correct for wsl kernel?
        in
        {
          # TODO: current build script is impure
          # packages.default = pkgs.stdenv.mkDerivation {
          #   name = "zfs-module";
          #   src = ./.;
          #   nativeBuildInputs = deps;
          #   buildPhase = ''
          #     bash build.sh
          #   '';
          #   installPhase = ''
          #     mkdir -p $out
          #     cp -r .tmp/result/* $out/
          #   '';
          # };

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = deps;
          };
        };
    };
}
