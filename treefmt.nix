{ inputs, ... }: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = _: {
    treefmt = {
      # Used to find the project root
      projectRootFile = "flake.lock";

      programs = {
        deadnix.enable = true;
        deno.enable = true;
        mypy.enable = true;
        ruff.check = true;
        ruff.format = true;
        nixpkgs-fmt.enable = true;
        shellcheck.enable = true;
        shfmt.enable = true;
        statix.enable = true;
      };

      settings.formatter = {
        shellcheck.includes = [ "*.sh" "direnvrc" ];
        shfmt.includes = [ "*.sh" "direnvrc" ];
      };
    };
  };
}
