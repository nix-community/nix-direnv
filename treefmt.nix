{ inputs, ... }: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = {
    treefmt = {
      # Used to find the project root
      projectRootFile = ".git/config";

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
        yamlfmt.enable = true;
      };

      settings.formatter = {
        shellcheck.includes = [ "direnvrc" ];
        shfmt.includes = [ "direnvrc" ];
      };
    };
  };
}
