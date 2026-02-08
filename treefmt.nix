{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem = _: {
    treefmt = {
      # Used to find the project root
      projectRootFile = ".git/config";

      programs = {
        deadnix.enable = true;
        deno.enable = true;
        nixfmt.enable = true;
        shellcheck.enable = true;
        shfmt.enable = true;
        statix.enable = true;
        yamlfmt.enable = true;
      };

      settings.formatter = {
        shellcheck.includes = [
          "direnvrc"
          "tests/*.bash"
          "tests/*.bats"
        ];
        shfmt.includes = [
          "direnvrc"
          "tests/*.bash"
          "tests/*.bats"
        ];
      };
    };
  };
}
