# -*- mode: bash-ts -*-

function setup {
  load "util"

  _common_setup
}

function teardown {
  _common_teardown
}

function custom_logging_format { # @test
  export DIRENV_LOG_FORMAT="TEST:%s"
  write_envrc "use_flake"
  run_in_direnv hello
  assert_stderr -p "TEST:loading"
}

function custom_logging_filter { # @test
  echo -e "[global]\nlog_filter=\"^$\"\n" >"${DIRENV_CONFIG}/direnv.toml"
  write_envrc "use_flake"
  run --separate-stderr direnv exec "$TESTDIR" sh -c "$@" hello
  assert_output "Hello, world!"
  assert_stderr "Executing shellHook."
}
