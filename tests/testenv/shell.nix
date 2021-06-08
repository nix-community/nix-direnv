{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  nativeBuildInputs = [ pkgs.hello ];
  shellHook = ''
    echo "Executing shellHook."
  '';
}
