{ resholve, lib, coreutils, direnv, nix }:

# resholve does not yet support `finalAttrs` call pattern hence `rec`
# https://github.com/abathur/resholve/issues/107
resholve.mkDerivation rec {
  pname = "nix-direnv";
  version = "3.0.1";

  src = builtins.path {
    path = ./.;
    name = pname;
  };

  # drop min version checks which are redundant when built with nix
  postPatch = ''
    sed -i "/_require_version bash/,+2d" direnvrc
  '';

  installPhase = ''
    install -m400 -D direnvrc $out/share/${pname}/direnvrc
  '';

  solutions = {
    default = {
      scripts = [ "share/${pname}/direnvrc" ];
      interpreter = "none";
      inputs = [ coreutils direnv nix ];
      fake = {
        builtin = [
          "PATH_add"
          "direnv_layout_dir"
          "has"
          "log_error"
          "log_status"
          "watch_file"
        ];
        function = [
          # not really a function - this is in an else branch for macOS/homebrew that
          # cannot be reached when built with nix
          "shasum"
        ];
      };
      keep."$cmd" = true;
      execer = [
        "cannot:${direnv}/bin/direnv"
        "cannot:${nix}/bin/nix"
      ];
    };
  };

  meta = with lib; {
    description = "A fast, persistent use_nix implementation for direnv";
    homepage = "https://github.com/nix-community/nix-direnv";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
