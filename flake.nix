{
  description = "A faster, persistent implementation of `direnv`'s `use_nix`, to replace the built-in one.";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  nixConfig.extra-substituters = [ "https://cache.garnix.io" ];
  nixConfig.extra-trusted-public-keys = [ "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          packages = {
            default = pkgs.callPackage ./default.nix { };
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
            program = "${self.packages.${system}.test-runner}";
          };
          checks = {
            lint = pkgs.callPackage ./lint.nix { };
          };
        }) // {
      overlay = final: prev: {
        nix-direnv = final.callPackage ./default.nix { };
      };
      templates.default = {
        path = ./templates/flake;
        description = "nix flake new -t github:Mic92/nix-direnv .";
      };
    };
}
