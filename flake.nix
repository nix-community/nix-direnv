{
  description = "A faster, persistent implementation of `direnv`'s `use_nix`, to replace the built-in one.";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      defaultPackage = pkgs.callPackage ./default.nix {};
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
