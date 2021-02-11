{
  description = "A very basic flake";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: {
      devShell = import ./shell.nix {
        pkgs = nixpkgs.legacyPackages.${system};
      };
    });
}
