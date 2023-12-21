{ self, withSystem, ... }: {
  flake.packages.x86_64-linux = withSystem "x86_64-linux"
    ({ pkgs, ... }: {
      bash4 = pkgs.callPackage ./. { };
      direnv-bash4 = pkgs.direnv.override {
        bash = self.packages.x86_64-linux.bash4;
      };
      test-runner-bash4 = pkgs.callPackage ../../test-runner.nix {
        nixVersion = "stable";
        direnv = self.packages.x86_64-linux.direnv-bash4;
      };
    });
}
