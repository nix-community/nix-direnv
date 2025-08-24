# -*- mode: bash-ts -*-

function setup {
  load "util"

  _common_setup
}

function teardown {
  _common_teardown
}

function use_nix_attrs_strict { # @test
  write_envrc "strict_env\nuse nix -A subshell"
  # shellcheck disable=SC2016
  run_in_direnv 'echo "subshell: $THIS_IS_A_SUBSHELL"'
  assert_output -e "subshell: OK$"
}

function use_nix_attrs_no_strict { # @test
  write_envrc "use nix -A subshell"
  # shellcheck disable=SC2016
  run_in_direnv 'echo "subshell: $THIS_IS_A_SUBSHELL"'
  assert_output -e "subshell: OK$"
}

function use_nix_no_nix_path_strict { # @test
  unset NIX_PATH
  write_envrc "strict_env\nuse nix --argstr someArg OK"
  # shellcheck disable=SC2016
  run_in_direnv 'echo "someArg: $SHOULD_BE_SET"'
  assert_output -e "someArg: OK$"
}

function use_nix_no_nix_path_no_strict { # @test
  unset NIX_PATH
  write_envrc "use nix --argstr someArg OK"
  # shellcheck disable=SC2016
  run_in_direnv 'echo "someArg: $SHOULD_BE_SET"'
  assert_output -e "someArg: OK$"
}

function use_nix_no_files { # @test
  write_envrc "use nix -p hello"
  (
    cd "$TESTDIR" || exit 1
    run --separate-stderr direnv status
    assert_success
    refute_output -p 'Loaded watch: "."'
  )
}
