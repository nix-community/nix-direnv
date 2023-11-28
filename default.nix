{ stdenv, lib, nix, gnugrep, runCommand, shellcheck, direnv, ruff, mypy, python3 }:

stdenv.mkDerivation (finalAttrs: {
  name = "nix-direnv";

  src = builtins.path {
    inherit (finalAttrs) name;
    path = ./.;
  };

  postPatch = ''
    sed -i "2iNIX_BIN_PREFIX=${nix}/bin/" direnvrc
  '';

  installPhase = ''
    install -m400 -D direnvrc $out/share/nix-direnv/direnvrc
  '';

  passthru.tests = {
    lint = runCommand "lint-${finalAttrs.name}" {
      nativeBuildInputs = [shellcheck ruff mypy];
    } ''
      set -eu
      cd ${finalAttrs.src}
      export RUFF_CACHE_DIR=$TMP/ruff
      echo run shellcheck
      shellcheck direnvrc
      echo run ruff format
      ruff format --check tests
      echo run ruff check
      ruff check tests
      echo run mypy
      mypy tests
      touch $out
    '';
    test = finalAttrs.overrideAttrs {
      name = "test-${finalAttrs.name}-${nix.name}";
      nativeBuildInputs = [
        direnv
        nix
      ] ++ (with python3.pkgs; [
        pytestCheckHook
        pytest-cov
        pytest-randomly
        pytest-sugar
      ]);
    };
  };

  meta = with lib; {
    description = "A fast, persistent use_nix implementation for direnv";
    homepage = "https://github.com/nix-community/nix-direnv";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
