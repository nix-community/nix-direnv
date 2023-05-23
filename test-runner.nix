{ writeScript
, direnv
, python3
, lib
, nix
, coreutils
, gnugrep
}:
writeScript "test-runner" ''
  set -e
  export PATH=${lib.makeBinPath [ direnv nix coreutils gnugrep ]}

  echo run unittest
  ${lib.getExe python3.pkgs.pytest} .
''
