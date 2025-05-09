{
  resholve,
  lib,
  coreutils,
  nix,
  writeText,
}:

# resholve does not yet support `finalAttrs` call pattern hence `rec`
# https://github.com/abathur/resholve/issues/107
resholve.mkDerivation rec {
  pname = "nix-direnv";
  version = "3.0.7";

  src = builtins.path {
    path = ./.;
    name = pname;
  };

  installPhase = ''
    install -m400 -D direnvrc $out/share/${pname}/direnvrc
  '';

  solutions = {
    default = {
      scripts = [ "share/${pname}/direnvrc" ];
      interpreter = "none";
      inputs = [ coreutils ];
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
        external = [
          # We want to reference the ambient Nix when possible, and have custom logic
          # for the fallback
          "nix"
        ];
      };
      keep = {
        "$cmd" = true;
        "$direnv" = true;

        # Nix fallback implementation
        "$_nix_direnv_nix" = true;
        "$ambient_nix" = true;
        "$NIX_DIRENV_FALLBACK_NIX" = true;
      };
      prologue =
        (writeText "prologue.sh" ''
          NIX_DIRENV_SKIP_VERSION_CHECK=1
          NIX_DIRENV_FALLBACK_NIX=''${NIX_DIRENV_FALLBACK_NIX:-${lib.getExe nix}}
        '').outPath;
    };
  };

  meta = with lib; {
    description = "A fast, persistent use_nix implementation for direnv";
    homepage = "https://github.com/nix-community/nix-direnv";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
