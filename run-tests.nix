{
  writeScript,
  shellcheck,
  direnv,
  mypy,
  python3,
  lib,
  ruff
}:
writeScript "run-tests" ''
  set -e
  PATH="''${PATH}''${PATH:+":"}${direnv}/bin"
  echo run shellcheck
  ${shellcheck}/bin/shellcheck direnvrc
  echo run black
  LC_ALL=en_US.utf-8 ${lib.getExe python3.pkgs.black} --check .
  echo run ruff
  ${lib.getExe ruff} tests
  echo run mypy
  ${lib.getExe mypy} tests

  echo run unittest
  ${lib.getExe python3.pkgs.pytest} .
''
