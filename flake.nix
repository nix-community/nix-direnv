{
  description = "A faster, persistent implementation of `direnv`'s `use_nix`, to replace the built-in one.";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages = {
        default = pkgs.callPackage ./default.nix { };
        test-runner = pkgs.callPackage ./run-tests.nix {};
      };
      defaultPackage = self.packages.${system}.default;
      devShell = pkgs.callPackage ./shell.nix { };
      apps.test-runner = {
        type = "app";
        program = "${self.packages.${system}.test-runner}";
      };
    }) // {
      overlay = final: prev: {
        nix-direnv = final.callPackage ./default.nix { };
      };
      defaultTemplate = {
        path = ./template;
        description = "nix flake new -t github:Mic92/nix-direnv .";
      };
    };
}
