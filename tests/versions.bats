# -*- mode: bash-ts -*-

function setup {
  bats_load_library bats-support
  bats_load_library bats-assert

  load "$DIRENV_STDLIB"
  load "$DIRENVRC"
}

function require_version_with_valid_versions { # @test
  # args: cmd version minimum_required
  run _require_version "test-cmd" "2.5" "2.4"
  assert_success
  run _require_version "test-cmd" "2.5" "2.4.1"
  assert_success
  run _require_version "test-cmd" "2.4.1" "2.4"
  assert_success
  run _require_version "test-cmd" "2.4" "2.4.1"
  assert_failure
  run _require_version "test-cmd" "2.31pre20250712_b1245123" "2.4"
  assert_success
}

function require_cmd_version_with_valid_versions { # @test
  run _require_cmd_version "bash" "1.0"
  assert_success
  run _require_cmd_version "bash" "100.0"
  assert_failure
  run _require_cmd_version "bash" "1.2.3"
  assert_success
}
