{
  pkgs ? import <nixpkgs> { },
  treefmt ? null,
  nix-direnv ? (pkgs.callPackage ./default.nix { }),
  test_pkgs ? (pkgs.lib.callPackagesWith pkgs ./tests { inherit nix-direnv; }),
}:
let
  inherit (pkgs) lib;
in
pkgs.mkShell {
  DIRENV_STDLIB = "${test_pkgs.direnv-stdlib}";
  BATS_LIB_PATH = lib.strings.makeSearchPath "" (
    with test_pkgs;
    [
      bats-support
      bats-assert
    ]
  );
  packages =
    (builtins.attrValues {
      inherit (pkgs)
        bats
        direnv
        shellcheck
        ;
    })
    ++ (builtins.attrValues (lib.attrsets.filterAttrs (name: _val: name != "direnv-stdlib") test_pkgs))
    ++ lib.optionals (treefmt != null) [ treefmt ];
}
