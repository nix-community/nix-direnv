{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        # Used to find the project root
        projectRootFile = ".git/config";

        programs = {
          deadnix.enable = true;
          deno.enable = true;
          nixfmt.enable = true;
          nixfmt.package = pkgs.nixfmt-rfc-style;
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
