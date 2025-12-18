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
          deps = with pkgs; [
            bash
          ];
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
