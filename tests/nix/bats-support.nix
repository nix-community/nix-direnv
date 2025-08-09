{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  name = "bats-support";
  version = "3.0+";
  src = fetchFromGitHub {
    owner = "bats-core";
    repo = "bats-support";
    rev = "0ad082d4590108684c68975ca517a90459f05cd0";
    hash = "sha256-hkPAn12gQudboL9pDpQZhtaMhqyyj885tti4Gx/aun4=";
  };

  dontBuild = true;
  installPhase = ''

    # This looks funny
    # but they mean that you can use bats' built-in `bats_load_library` easily
    # when setting $BATS_LIB_PATH to the string of the derivation.

    mkdir -p $out/bats-support;
    cp -r src $out/bats-support/
    cp load.bash $out/bats-support/
  '';
}
