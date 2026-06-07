{
  bash,
  bats,
  callPackage,
  coreutils,
  direnv,
  fetchurl,
  findutils,
  gnugrep,
  gnused,
  lib,
  nix-direnv,
  nixVersions,
  writeShellScriptBin,
  writeText,
}:
let
  direnv-stdlib = fetchurl {
    url = "https://raw.githubusercontent.com/direnv/direnv/refs/tags/v2.37.1/stdlib.sh";
    hash = "sha256-MMM04OXhqS/rRSuv8uh7CD70Z7CaGT63EtL/3LC08qM=";
  };
  bats-support = callPackage ./nix/bats-support.nix { };
  bats-assert = callPackage ./nix/bats-assert.nix { };
  reload-helper-other-owner = writeText "nix-direnv-reload-other-owner" ''
    #!/usr/bin/env bash
    set -e
    if [[ ! -d "/nix/store" ]]; then
      echo "Cannot find source directory; Did you move it?"
      echo "(Looking for /nix/store)"
      echo 'Cannot force reload with this script - use "direnv reload" manually and then try again'
      exit 1
    fi

    # rebuild the cache forcefully
    _nix_direnv_force_reload=1 direnv exec "/nix/store" true
  '';
  mkTestRunner =
    nixVersion:
    writeShellScriptBin "test-runner-${nixVersion}" ''
      set -e
      export PATH=${
        lib.makeBinPath [
          bash
          direnv
          nixVersions.${nixVersion}
          coreutils
          findutils
          gnugrep
          gnused
        ]
      }
      export DIRENV_STDLIB=${direnv-stdlib}
      export DIRENVRC="${nix-direnv}/share/nix-direnv/direnvrc"
      export BATS_LIB_PATH="${bats-support}:${bats-assert}"
      export NIX_DIRENV_RELOAD_HELPER_OTHER_OWNER=${reload-helper-other-owner}
      echo run unittest
      ${lib.getExe' bats "bats"} tests/
    '';
  test-runner-stable = mkTestRunner "stable";
  test-runner-latest = mkTestRunner "latest";
in
{
  inherit
    bats-support
    bats-assert
    direnv-stdlib
    test-runner-stable
    test-runner-latest
    ;
}
