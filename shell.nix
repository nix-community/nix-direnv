{ pkgs ? import <nixpkgs> { } }:

with pkgs;
mkShell {
  nativeBuildInputs = [
    python3.pkgs.pytest
    python3.pkgs.mypy
    python3.pkgs.black
    python3.pkgs.flake8
    ruff
    shellcheck
    direnv
  ];
}
