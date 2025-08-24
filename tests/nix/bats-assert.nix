{ fetchFromGitHub, stdenv }:
stdenv.mkDerivation {
  name = "bats-assert";
  version = "2.1.0+";
  src = fetchFromGitHub {
    owner = "bats-core";
    repo = "bats-assert";
    rev = "912a98804efd34f24d5eae1bf97ee622ca770e9"; # master 8/7/2025
    hash = "sha256-gp52V4mAiT+Lod2rvEMLhi0Y7AdQQTFCHcNgb8JEKXE=";
  };

  dontBuild = true;
  installPhase = ''

    # This looks funny
    # but they mean that you can use bats' built-in `bats_load_library` easily
    # when setting $BATS_LIB_PATH to the string of the derivation.

    mkdir -p $out/bats-assert;
    cp -r src $out/bats-assert/
    cp load.bash $out/bats-assert
  '';
}
