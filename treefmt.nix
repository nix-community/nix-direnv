{ lib, inputs, ... }: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = { pkgs, ... }: {
    treefmt = {
      # Used to find the project root
      projectRootFile = "flake.lock";

      programs = {
        deadnix.enable = true;
        deno.enable = true;
        mypy.enable = true;
        nixpkgs-fmt.enable = true;
        shellcheck.enable = true;
        shfmt.enable = true;
        statix.enable = true;
      };

      settings.formatter =
        let
          sh-includes = [ "*.sh" "direnvrc" ];
        in
        {
          python = {
            command = "sh";
            options = [
              "-eucx"
              ''
                ${lib.getExe pkgs.ruff} --fix "$@"
                ${lib.getExe pkgs.ruff} format "$@"
              ''
              "--" # this argument is ignored by bash
            ];
            includes = [ "*.py" ];
          };

          shellcheck.includes = sh-includes;

          shfmt.includes = sh-includes;
        };
    };
  };
}
