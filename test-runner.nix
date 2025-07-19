{
  writeShellScriptBin,
  direnv,
  python3,
  lib,
  coreutils,
  gnugrep,
  bats,
  nixVersions,
  nixVersion,
  nix-direnv,
  fetchurl,
}:
let
  direnv-stdlib = fetchurl {
    url = "https://raw.githubusercontent.com/direnv/direnv/refs/tags/v2.37.0/stdlib.sh";
    hash = "sha256-MMM04OXhqS/rRSuv8uh7CD70Z7CaGT63EtL/3LC08qM=";
  };
in
writeShellScriptBin "test-runner-${nixVersion}" ''
  set -e
  export PATH=${
    lib.makeBinPath [
      direnv
      nixVersions.${nixVersion}
      coreutils
      gnugrep
    ]
  }
  export DIRENV_STDLIB=${direnv-stdlib}
  export DIRENVRC="${nix-direnv}/share/nix-direnv/direnvrc"

  echo run python unittest
  ${lib.getExe' python3.pkgs.pytest "pytest"} tests/python/

  echo run bash unittest
  ${lib.getExe' bats "bats"} -x --verbose-run tests/bash/
''
