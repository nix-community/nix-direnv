{ pkgs ? import <nixpkgs> { } }:

with pkgs;
mkShell {
  nativeBuildInputs = [
    python3.pkgs.pytest
    python3.pkgs.mypy
    ruff
    direnv
  ];
}
