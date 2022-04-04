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
  echo -e "\x1b[32m## run shellcheck\x1b[0m"
  ${shellcheck}/bin/shellcheck direnvrc
  echo -e "\x1b[32m## run black\x1b[0m"
  LC_ALL=en_US.utf-8 ${python3.pkgs.black}/bin/black --check .
  echo -e "\x1b[32m## run flake8\x1b[0m"
  ${python3.pkgs.flake8}/bin/flake8 --ignore E501 tests
  echo -e "\x1b[32m## run mypy\x1b[0m"
  ${mypy}/bin/mypy tests

  echo -e "\x1b[32m## run unittest\x1b[0m"
  ${python3.interpreter} -m unittest discover tests
''
