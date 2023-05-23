{ shellcheck
, mypy
, python3
, lib
, ruff
, runCommand
}:
runCommand "lint" {} ''
  set -e
  mkdir source
  cp -r ${./.}/* source
  chmod +w source
  cd source

  echo run shellcheck
  ${shellcheck}/bin/shellcheck direnvrc
  echo run black
  ${lib.getExe python3.pkgs.black} --check .
  echo run ruff
  ${lib.getExe ruff} tests
  echo run mypy
  ${lib.getExe mypy} tests
  touch $out
''
