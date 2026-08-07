# -*- mode: bash-ts -*-

function setup {
  load "util"

  _common_setup
}

function teardown {
  _common_teardown
}

function fallback_allowed() { # @test
  write_envrc "watch_file shell.nix\nuse flake"
  run_in_direnv 'hello'

  sed -i.bk 's|inherit shellHook|inherit doesntExist|' "$TESTDIR/shell.nix"

  run --separate-stderr direnv exec "$TESTDIR" "hello"
  assert_stderr -p "Falling back to previous environment"

}

function fallback_disallowed() { # @test
  write_envrc "watch_file shell.nix\nnix_direnv_disallow_fallback\nuse flake"
  run_in_direnv 'hello'

  sed -i.bk 's|inherit shellHook|inherit doesntExist|' "$TESTDIR/shell.nix"

  run --separate-stderr direnv exec "$TESTDIR" "hello"
  refute_stderr -p "Falling back to previous environment"
}
