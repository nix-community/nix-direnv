{
  description = "A faster, persistent implementation of `direnv`'s `use_nix`, to replace the built-in one.";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";
  inputs.treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

  nixConfig.extra-substituters = [ "https://cache.garnix.io" ];
  nixConfig.extra-trusted-public-keys = [ "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; }
      ({ lib, ... }: {
        imports = [ ./treefmt.nix ];
        systems = [
          "aarch64-linux"
          "x86_64-linux"

          "x86_64-darwin"
          "aarch64-darwin"
        ];
        perSystem = { config, pkgs, self', ... }: {
          packages = {
            nix-direnv = pkgs.callPackage ./default.nix { };
            default = config.packages.nix-direnv;
            test-runner-stable = pkgs.callPackage ./test-runner.nix {
              nixVersion = "stable";
            };
            test-runner-unstable = pkgs.callPackage ./test-runner.nix {
              nixVersion = "unstable";
            };
          };
          devShells.default = pkgs.callPackage ./shell.nix { };
          apps.test-runner = {
            type = "app";
            program = "${config.packages.test-runner}";
          };

          checks =
            let
              packages = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") self'.packages;
              devShells = lib.mapAttrs' (n: lib.nameValuePair "devShell-${n}") self'.devShells;
            in
            packages // devShells;
        };
        flake = {
          overlays.default = final: _prev: {
            nix-direnv = final.callPackage ./default.nix { };
          };
          templates.default = {
            path = ./templates/flake;
            description = "nix flake new -t github:Mic92/nix-direnv .";
          };
        };
      });
}
