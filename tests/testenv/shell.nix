{ pkgs ? import <nixpkgs> { }, someArg ? null, shellHook ? ''
  echo "Executing shellHook."
'' }:
pkgs.mkShellNoCC {
  inherit shellHook;

  nativeBuildInputs = [ pkgs.hello ];
  SHOULD_BE_SET = someArg;

  passthru = { subshell = pkgs.mkShellNoCC { THIS_IS_A_SUBSHELL = "OK"; }; };
}
