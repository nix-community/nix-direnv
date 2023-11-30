{ pkgs ? import <nixpkgs> { }, packages ? [ ] }:

with pkgs;
mkShell {
  packages = packages ++ [
    python3.pkgs.pytest
    python3.pkgs.mypy
    ruff
    direnv
  ];
}
