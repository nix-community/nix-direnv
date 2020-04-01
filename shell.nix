with import <nixpkgs> {};
mkShell {
  nativeBuildInputs = [
    python3
    shellcheck
    direnv
  ];
}
