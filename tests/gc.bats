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
  assert_equal "${#chomped_paths[@]}" "10"
  readarray -td '' sorted_paths < <(printf '%s\0' "${chomped_paths[@]}" | sort -z)
  expected_patterns=(
    "^$"
    "^bin$"
    "^bin/nix-direnv-reload$"
    "^flake-inputs$"
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

function use_flake_roots_remote_sources_without_materializing_checkout() { # @test
  local output
  git -C "$TESTDIR" init -q
  echo "$TESTDIR" >"$TESTDIR/marker"
  git -C "$TESTDIR" add flake.nix flake.lock shell.nix marker
  git -C "$TESTDIR" -c user.name=Test -c user.email=test@example.org -c commit.gpgsign=false commit -qm fixture
  write_envrc "direnv_layout_dir=.direnv\nuse flake"

  run nix print-dev-env "$TESTDIR"
  assert_success
  mkdir "$TESTDIR/snapshot"
  cp "$TESTDIR"/{flake.nix,flake.lock,shell.nix,marker} "$TESTDIR/snapshot/"
  run nix hash path --type sha256 --base32 "$TESTDIR/snapshot"
  assert_success
  run nix-store --print-fixed-path --recursive sha256 "$output" source
  assert_success
  checkout_path=$output
  checkout_was_present=0
  if [[ -e $checkout_path ]]; then
    checkout_was_present=1
  fi

  run --separate-stderr direnv exec "$TESTDIR" hello
  assert_success
  if [[ $checkout_was_present == 0 ]]; then
    refute test -e "$checkout_path"
  fi

  write_envrc "use flake git+file://$TESTDIR"
  run --separate-stderr direnv exec "$TESTDIR" hello
  assert_success
  assert test -e "$TESTDIR/.direnv/flake-inputs/${checkout_path##*/}"
}

function use_flake_retains_unused_recursive_inputs() { # @test
  local output
  mkdir "$TESTDIR/unused" "$TESTDIR/transitive" "$TESTDIR/raw"
  echo "$TESTDIR" >"$TESTDIR/raw/marker"
  cat >"$TESTDIR/transitive/flake.nix" <<EOF
{
  inputs.raw = { url = "path:$TESTDIR/raw"; flake = false; };
  outputs = _: throw "Unused outputs must not be evaluated";
}
EOF
  cat >"$TESTDIR/unused/flake.nix" <<EOF
{
  inputs.transitive.url = "path:$TESTDIR/transitive";
  outputs = _: throw "Unused outputs must not be evaluated";
}
EOF
  sed -i.bk "s|  description =|  inputs.unused.url = \"path:$TESTDIR/unused\";\n  description =|" "$TESTDIR/flake.nix"
  run nix flake lock "$TESTDIR"
  assert_success
  write_envrc "use flake . --offline"
  run --separate-stderr direnv exec "$TESTDIR" hello
  assert_success

  for input in unused transitive raw; do
    run nix hash path --type sha256 --base32 "$TESTDIR/$input"
    assert_success
    run nix-store --print-fixed-path --recursive sha256 "$output" source
    assert_success
    input_path=$output
    assert test -e "$TESTDIR/.direnv/flake-inputs/${input_path##*/}"
    run nix-store --delete "$input_path"
    assert_failure
    assert_output -p "Cannot delete path"
    mv "$TESTDIR/$input" "$TESTDIR/$input-unavailable"
  done

  rm "$TESTDIR"/.direnv/flake-profile-*.rc
  run --separate-stderr direnv exec "$TESTDIR" hello
  assert_success
  assert_output "Hello, world!"
}
