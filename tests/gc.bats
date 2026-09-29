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
  paths=("$TESTDIR"/.direnv/**)
  chomped_paths=("${paths[@]#$TESTDIR/.direnv/}")
  assert_equal "${#chomped_paths[@]}" "6"
  readarray -td '' sorted_paths < <(printf '%s\0' "${chomped_paths[@]}" | sort -z)
  expected_patterns=(
    "^$"
    "^bin$"
    "^bin/nix-direnv-reload$"
    "^nix-output.log$"
    "^nix-profile-.+$"
    "^nix-profile-.+\.rc$"
  )
  for ((i = 0; i < ${#expected_patterns[@]}; i++)); do
    path="${sorted_paths[$i]}"
    pattern="${expected_patterns[$i]}"
    assert_regex "$path" "$pattern"
  done
}

function assert_use_flake_layout_dir_shape {
  paths=("$TESTDIR"/.direnv/**)
  chomped_paths=("${paths[@]#$TESTDIR/.direnv/}")
  assert_equal "${#chomped_paths[@]}" "11"
  readarray -td '' sorted_paths < <(printf '%s\0' "${chomped_paths[@]}" | sort -z)
  expected_patterns=(
    "^$"
    "^bin$"
    "^bin/nix-direnv-reload$"
    "^flake-inputs$"
    "^flake-inputs/.+-source$"
    "^flake-inputs/.+-source$"
    "^flake-inputs/.+-source$"
    "^flake-inputs/.+-source$"
    "^flake-profile-.+$"
    "^flake-profile-.+\.rc$"
    "^nix-output.log$"
  )
  for ((i = 0; i < ${#expected_patterns[@]}; i++)); do
    path="${sorted_paths[$i]}"
    pattern="${expected_patterns[$i]}"
    assert_regex "$path" "$pattern"
  done
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
