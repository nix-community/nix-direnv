{
  description = "A faster, persistent implementation of `direnv`'s `use_nix`, to replace the built-in one.";

  nixConfig.extra-substituters = [ "https://cache.thalheim.io" ];
  nixConfig.extra-trusted-public-keys = [ "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc=" ];

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

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
            bash4 = pkgs.bash.overrideAttrs (_old: {
              name = "bash-4.4";
              src = pkgs.fetchurl {
                url = "https://ftp.gnu.org/gnu/bash/bash-4.4.tar.gz";
                hash = "sha256-2GszksEgLo/1pCOzAuYoTbf49DXqnzm1sbIP06w238s=";
              };
              patches = [ ];
            });
            direnv-bash4 = pkgs.direnv.override {
              bash = config.packages.bash4;
            };
            test-runner-bash4 = pkgs.callPackage ./test-runner.nix {
              nixVersion = "stable";
              direnv = config.packages.direnv-bash4;
            };
          };

          devShells.default = pkgs.callPackage ./shell.nix {
            packages = [ config.treefmt.build.wrapper ];
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
