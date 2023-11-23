{ stdenv, nix, gnugrep, gzip, jq, lib }:

stdenv.mkDerivation {
  name = "nix-direnv";

  src = ./.;

  postPatch = ''
    sed -i "2iNIX_BIN_PREFIX=${nix}/bin/" direnvrc
    substituteInPlace direnvrc \
      --replace "grep" "${gnugrep}/bin/grep" \
      --replace gzip "${gzip}/bin/gzip" \
      --replace JQ= "JQ=${jq}/bin/jq"
  '';

  installPhase = ''
    install -m400 -D direnvrc $out/share/nix-direnv/direnvrc
  '';

  meta = with lib; {
    description = "A fast, persistent use_nix implementation for direnv";
    homepage = "https://github.com/nix-community/nix-direnv";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
