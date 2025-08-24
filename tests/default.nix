{
  bash,
  bats,
  callPackage,
  coreutils,
  direnv,
  fetchurl,
  findutils,
  gnugrep,
  lib,
  nix-direnv,
  nixVersions,
  writeShellScriptBin,
}:
let
  direnv-stdlib = fetchurl {
    url = "https://raw.githubusercontent.com/direnv/direnv/refs/tags/v2.37.1/stdlib.sh";
    hash = "sha256-MMM04OXhqS/rRSuv8uh7CD70Z7CaGT63EtL/3LC08qM=";
  };
  bats-support = callPackage ./nix/bats-support.nix { };
  bats-assert = callPackage ./nix/bats-assert.nix { };
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
        ]
      }
      export DIRENV_STDLIB=${direnv-stdlib}
      export DIRENVRC="${nix-direnv}/share/nix-direnv/direnvrc"
      export BATS_LIB_PATH="${bats-support}:${bats-assert}"

      echo run unittest
      ${lib.getExe' bats "bats"} -x --verbose-run tests/
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
