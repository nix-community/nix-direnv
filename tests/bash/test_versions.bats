load "$DIRENV_STDLIB"
load "$DIRENVRC"

@test "test _require_version with valid versions" {
  # args: cmd version minimum_required
  run _require_version "test-cmd" "2.5" "2.4"
  [ "$status" -eq 0 ]
  run _require_version "test-cmd" "2.5" "2.4.1"
  [ "$status" -eq 0 ]
  run _require_version "test-cmd" "2.4.1" "2.4"
  [ "$status" -eq 0 ]
  run _require_version "test-cmd" "2.4" "2.4.1"
  [ "$status" -eq 1 ]
  run _require_version "test-cmd" "2.31pre20250712_b1245123" "2.4"
  [ "$status" -eq 0 ]
}


test_cmd1() {
    echo "1.2"
}

test_cmd2() {
    echo "1.2.3"
}

@test "test _require_cmd_version with valid versions" {
  run _require_cmd_version "test_cmd1" "1.1"
  [ "$status" -eq 0 ]
  run _require_cmd_version "test_cmd2" "1.1.1"
  [ "$status" -eq 0 ]
}
