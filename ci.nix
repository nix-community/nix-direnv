with import <nixpkgs> {};
mkShell {
  nativeBuildInputs = [
    shellcheck direnv mypy python3.pkgs.black python3.pkgs.flake8
  ];

  shellHook = ''
    set -e
    echo -e "\x1b[32m## run shellcheck\x1b[0m"
    LC_ALL=en_US.utf-8 black --check .
    echo -e "\x1b[32m## run black\x1b[0m"
    LC_ALL=en_US.utf-8 black --check .
    echo -e "\x1b[32m## run flake8\x1b[0m"
    flake8 --ignore E501 tests
    echo -e "\x1b[32m## run mypy\x1b[0m"
    mypy tests

    echo -e "\x1b[32m## run unittest\x1b[0m"
    ${pkgs.python3.interpreter} -m unittest discover tests
  '';
}
