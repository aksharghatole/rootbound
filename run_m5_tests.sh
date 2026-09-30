#!/usr/bin/env bash
cd /workspaces/rootbound

run_test() {
  local name="$1"
  local path="$2"
  echo "=== $name ==="
  godot --headless --script "$path"
  echo "exit=$?"
  echo ""
}

echo "=== IMPORT ==="
godot --headless --import
echo ""

run_test "M3 REGRESSION: season"      tests/test_season_system.gd
run_test "M3 REGRESSION: events"      tests/test_event_system.gd
run_test "M3 REGRESSION: full run"    tests/test_full_run.gd
run_test "M4 REGRESSION: save rt"     tests/test_save_round_trip.gd
run_test "M4 REGRESSION: save corrupt" tests/test_save_corrupt.gd
run_test "M4 REGRESSION: save atomic" tests/test_save_atomic.gd
run_test "M4 REGRESSION: meta"        tests/test_meta_persistence.gd
run_test "M5 NEW: stat row"           tests/test_stat_row.gd
run_test "M5 NEW: game screen sigs"   tests/test_game_screen_signals.gd

echo "=== DONE ==="
