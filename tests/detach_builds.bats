# -*- mode: bash-ts -*-

function setup {
  load "util"

  _common_setup
}

function teardown {
  _common_teardown
}

# Detached or inline (no user manager), the environment must load and cache.
function detach_builds_renews_and_caches() { # @test
  write_envrc "nix_direnv_detach_builds\nuse flake"
  run_in_direnv 'hello'
  assert_output -e "Hello, world!"

  run --separate-stderr direnv exec "$TESTDIR" "hello"
  assert_stderr -p "Using cached dev shell"
}
