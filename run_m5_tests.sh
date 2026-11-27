#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
export GODOT_SILENCE_ROOT_WARNING=1
GODOT_BIN="${GODOT_BIN:-godot}"
FAILED=0
# Never let regression tests touch a player's existing save data.
TEST_DATA="$(mktemp -d)"
trap 'rm -rf "$TEST_DATA"' EXIT

run_test() {
  local path="$1" log
  export XDG_DATA_HOME="$TEST_DATA/$(basename "$path" .gd)"
  mkdir -p "$XDG_DATA_HOME"
  log="$(mktemp)"
  echo "=== $path ==="
  if ! timeout 90 "$GODOT_BIN" --headless --script "$path" >"$log" 2>&1; then
    FAILED=1
  fi
  cat "$log"
  if grep -Eq 'SCRIPT ERROR|Parse Error' "$log"; then FAILED=1; fi
  rm -f "$log"
}

for path in tests/test_*.gd; do
  run_test "$path"
done
exit "$FAILED"
