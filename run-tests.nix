{
  writeScript,
  shellcheck,
  direnv,
  mypy,
  python3,
}:
writeScript "run-tests" ''
  set -e
  PATH="''${PATH}''${PATH:+":"}${direnv}/bin"
  echo run shellcheck
  ${shellcheck}/bin/shellcheck direnvrc
  echo run black
  LC_ALL=en_US.utf-8 ${python3.pkgs.black}/bin/black --check .
  echo run flake8
  ${python3.pkgs.flake8}/bin/flake8 --ignore E501 tests
  echo run mypy
  ${mypy}/bin/mypy tests

  echo run unittest
  ${python3.pkgs.pytest}/bin/pytest .
''
