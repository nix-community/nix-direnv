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

# Loads `use flake "$@"` for the test flake, checks that its inputs are rooted
# and nothing else is left in .direnv, and leaves in $status whether the flake
# itself, recognised by a marker file, is rooted as well.
function use_flake_and_find_its_root {
  silence_nix_direnv_logging
  touch "$TESTDIR/marker"
  write_envrc "use flake $*"
  assert_run_output
  assert_use_flake_layout_dir_shape
  run compgen -G "$TESTDIR/.direnv/flake-inputs/*/pkgs/top-level"
  assert_success
  run compgen -G "$TESTDIR/.direnv/flake-inputs/*/marker"
}

function use_flake_roots_inputs_but_not_the_flake { # @test
  use_flake_and_find_its_root
  assert_failure
}

# The remaining tests cover flakes that are archived as a whole, as before.

# The flake reference is a registry name, although a directory of that name
# holds a flake as well.
function use_flake_with_registry_name_roots_the_flake_too { # @test
  mkdir "$TESTDIR/myreg"
  cp "$TESTDIR"/flake.{nix,lock} "$TESTDIR/myreg"
  echo '{"version":2,"flakes":[{"from":{"type":"indirect","id":"myreg"},"to":{"type":"path","path":"'"$TESTDIR"'"}}]}' >"$TESTDIR/registry.json"
  export NIX_CONFIG="flake-registry = $TESTDIR/registry.json"
  use_flake_and_find_its_root myreg
  assert_success
}

# flake.nix and the lock file are not enough: the new input is not locked yet
# and its path is relative to the flake.
function use_flake_with_unlocked_relative_input_roots_the_flake_too { # @test
  mkdir "$TESTDIR/sub"
  echo "{ outputs = _: { }; }" >"$TESTDIR/sub/flake.nix"
  sed -i '1a inputs.sub.url = "path:./sub";' "$TESTDIR/flake.nix"
  use_flake_and_find_its_root . --no-write-lock-file
  assert_success
}

# A flake without inputs has no lock file. It borrows the test flake's shell.
function use_flake_without_lock_file_roots_the_flake { # @test
  silence_nix_direnv_logging
  mkdir "$TESTDIR/nolock"
  touch "$TESTDIR/nolock/marker"
  echo "{ outputs = _: { inherit (builtins.getFlake \"path:$TESTDIR\") devShell; }; }" >"$TESTDIR/nolock/flake.nix"
  write_envrc "use flake ./nolock --impure"
  assert_run_output
  run compgen -G "$TESTDIR/.direnv/flake-inputs/*/marker"
  assert_success
}
