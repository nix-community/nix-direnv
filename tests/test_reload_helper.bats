# -*- mode: bash-ts -*-

function setup {
  load "util"

  _common_setup
}

function teardown {
  _common_teardown
}

function reload_helper_reuses_existing_script_when_bin_dir_is_read_only { # @test
  local layout_dir="$TESTDIR/layout"
  mkdir -p "$layout_dir/bin"

  PWD="$TESTDIR" bash -c 'source "$DIRENVRC"; _nix_direnv_install_reload "$1"' -- "$layout_dir"
  chmod a-w "$layout_dir/bin"

  run bash -c 'source "$DIRENVRC"; _nix_direnv_install_reload "$1"' -- "$layout_dir"
  chmod u+w "$layout_dir/bin"
  assert_success
}

function reload_helper_replaces_script_owned_by_different_user { # @test
  local layout_dir="$TESTDIR/layout"
  local reload="$layout_dir/bin/nix-direnv-reload"
  mkdir -p "$layout_dir/bin"
  ln -s "$NIX_DIRENV_RELOAD_HELPER_OTHER_OWNER" "$reload"

  run bash -c 'PWD=/nix/store; source "$DIRENVRC"; _nix_direnv_install_reload "$1"' -- "$layout_dir"
  assert_success
  [[ -f $reload && -O $reload ]]
}
