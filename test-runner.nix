{ writeShellScriptBin
, direnv
, python3
, lib
, coreutils
, gnugrep
, nixVersions
, nixVersion
}:
writeShellScriptBin "test-runner-${nixVersion}" ''
  set -e
  export PATH=${lib.makeBinPath [ direnv nixVersions.${nixVersion} coreutils gnugrep ]}

  echo run unittest
  ${lib.getExe python3.pkgs.pytest} .
''
