{ pkgs ? import <nixpkgs> {}, someArg ? null }:
pkgs.mkShellNoCC {
  nativeBuildInputs = [ pkgs.hello ];
  shellHook = ''
    echo "Executing shellHook."
  '';
  SHOULD_BE_SET = someArg;

  passthru = {
    subshell = pkgs.mkShellNoCC {
      THIS_IS_A_SUBSHELL = "OK";
    };
  };
}
