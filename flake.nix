{
  description = "A faster, persistent implementation of `direnv`'s `use_nix`, to replace the built-in one.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  nixConfig = {
    extra-substituters = ["https://cache.garnix.io"];
    extra-trusted-public-keys = ["cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="];
  };

  outputs = {self, nixpkgs, flake-utils}:
    flake-utils.lib.eachDefaultSystem
    (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (pkgs) lib;
    in rec {

      packages.default = pkgs.callPackage ./default.nix {};

      devShells.default = pkgs.mkShellNoCC {
        inputsFrom = [ self.checks.${system}.lint self.checks.${system}.test ];
        nativeBuildInputs = with pkgs; [
          gnumake
          jq
        ];
      };

      checks =
        packages.default.passthru.tests
        // lib.mapAttrs' (name: test: lib.nameValuePair ("test_" + name) test) (
          lib.genAttrs (
            builtins.filter (
              version:
              let
                pkg = pkgs.nixVersions.${version};
              in
                (builtins.tryEval pkg).success
                && builtins.isAttrs pkg
                && pkg ? version
                && builtins.compareVersions pkg.version "2.4" >= 0
            )
            (builtins.attrNames pkgs.nixVersions)
          ) (version:
            (pkgs.callPackage ./default.nix {
              nix = pkgs.nixVersions.${version};
            })
            .tests
            .test)
        );

    })
    // {

      overlays.default = final: _prev: {
        nix-direnv = final.callPackage ./default.nix {};
      };

      templates.default = {
        path = ./templates/flake;
        description = "nix flake new -t github:nix-community/nix-direnv .";
      };

    };
}
