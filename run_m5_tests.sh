#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
export GODOT_SILENCE_ROOT_WARNING=1
GODOT_BIN="${GODOT_BIN:-godot}"
FAILED=0
# Never let regression tests touch a player's existing save data.
export XDG_DATA_HOME="$(mktemp -d)"
trap 'rm -rf "$XDG_DATA_HOME"' EXIT

run_test() {
  local path="$1" log
  log="$(mktemp)"
  echo "=== $path ==="
  if ! timeout 90 "$GODOT_BIN" --headless --script "$path" >"$log" 2>&1; then
    FAILED=1
  fi
  cat "$log"
  if grep -Eq 'SCRIPT ERROR|Parse Error' "$log"; then FAILED=1; fi
  rm -f "$log"
}

for path in tests/test_season_system.gd tests/test_event_system.gd tests/test_full_run.gd \
  tests/test_save_round_trip.gd tests/test_save_corrupt.gd tests/test_save_atomic.gd \
  tests/test_meta_persistence.gd tests/test_stat_row.gd tests/test_game_screen_signals.gd \
  tests/test_seed_library.gd tests/test_seed_starting_stats.gd tests/test_unlock_flow.gd \
  tests/test_audio_manager.gd tests/test_safe_area.gd tests/test_run_result.gd; do
  run_test "$path"
done
exit "$FAILED"
