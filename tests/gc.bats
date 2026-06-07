# -*- mode: bash-ts -*-

# test initialization ====================
function setup {
  load "util"

  _common_setup
}

function teardown {
  _common_teardown
}

# helpers =================================
function assert_run_output {
  run --separate-stderr direnv exec "$TESTDIR" sh -c hello
  assert_success
  assert_output "Hello, world!"
  assert_stderr "Executing shellHook."
}

function assert_gcroot {
  profile_path=$(find "$TESTDIR/.direnv" -type l | head -n 1)
  run bats_pipe find /nix/var/nix/gcroots/auto/ -type l -printf "%l\n" \| grep "$profile_path"
  assert_success
}

function assert_use_nix_layout_dir_shape {
  paths=("$TESTDIR"/.direnv/*)
  chomped_paths=("${paths[@]#$TESTDIR/.direnv/}")
  assert_equal "${#chomped_paths[@]}" "3"
  assert_regex "$(printf "%s " "${chomped_paths[@]}")" "bin nix-profile.+ nix-profile-.+\.rc"
}

function assert_use_flake_layout_dir_shape {
  paths=("$TESTDIR"/.direnv/flake-inputs/*)
  chomped_inputs_paths=("${paths[@]#$TESTDIR/.direnv/flake-inputs/}")
  # four inputs, so four "...-source" outputs
  assert_regex "$(printf "%s " "${chomped_inputs_paths[@]}")" "(.+-source[ ]?){4}"

  paths=("$TESTDIR"/.direnv/*)
  chomped_paths=("${paths[@]#$TESTDIR/.direnv/}")
  assert_equal "${#chomped_paths[@]}" "4"
  assert_regex "$(printf "%s " "${chomped_paths[@]}")" "bin flake-inputs flake-profile-.+ flake-profile-.+\.rc"
}

# tests ===================================
function use_nix { # @test
  silence_nix_direnv_logging
  write_envrc "use nix"
  assert_run_output
  assert_gcroot
  assert_use_nix_layout_dir_shape
}

function use_flake { # @test
  silence_nix_direnv_logging
  write_envrc "use flake"
  assert_run_output
  assert_gcroot
  assert_use_flake_layout_dir_shape
}
