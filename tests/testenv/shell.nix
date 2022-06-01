{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShellNoCC {
  nativeBuildInputs = [ pkgs.hello ];
  shellHook = ''
    echo "Executing shellHook."
  '';
}
