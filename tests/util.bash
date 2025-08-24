function _common_setup {
  shopt -s globstar
  bats_require_minimum_version 1.5.0
  bats_load_library bats-support
  bats_load_library bats-assert

  TESTDIR=
  TESTDIR=$(mktemp -d -t nix-direnv.XXXXXX)
  export TESTDIR
  export DIRENV_LOG_FORMAT="direnv: %s"

  # Set up nix to be able to find your user's nix.conf if run locally
  export NIX_USER_CONF_FILES="$HOME/.config/nix/nix.conf"

  export HOME=$TESTDIR/home
  unset XDG_DATA_HOME
  unset XDG_CONFIG_HOME

  cp "$BATS_TEST_DIRNAME"/testenv/* "$TESTDIR/"
}

function _common_teardown {
  rm -rf "$TESTDIR"
}

function write_envrc {
  echo "source $DIRENVRC" >"$TESTDIR/.envrc"
  echo -e "\n$*" >>"$TESTDIR/.envrc"
  direnv allow "$TESTDIR"
}

function run_in_direnv {
  run --separate-stderr direnv exec "$TESTDIR" sh -c "$@"
  assert_success
  run direnv exec "$TESTDIR" sh -c "$@"
  assert_success
  assert_stderr -p "Renewed cache"
}
