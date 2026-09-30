#!/usr/bin/env bash
cd /workspaces/rootbound

FAILED=0

run_test() {
  local name="$1"
  local path="$2"
  echo "=== $name ==="
  godot --headless --script "$path"
  local code=$?
  echo "exit=$code"
  echo ""
  if [ "$code" -ne 0 ]; then
    FAILED=1
  fi
}

echo "=== IMPORT ==="
godot --headless --import
echo ""

run_test "M3 REGRESSION: season"       tests/test_season_system.gd
run_test "M3 REGRESSION: events"       tests/test_event_system.gd
run_test "M3 REGRESSION: full run"     tests/test_full_run.gd
run_test "M4 REGRESSION: save rt"      tests/test_save_round_trip.gd
run_test "M4 REGRESSION: save corrupt" tests/test_save_corrupt.gd
run_test "M4 REGRESSION: save atomic"  tests/test_save_atomic.gd
run_test "M4 REGRESSION: meta"         tests/test_meta_persistence.gd
run_test "M5 REGRESSION: stat row"     tests/test_stat_row.gd
run_test "M5 REGRESSION: game sigs"    tests/test_game_screen_signals.gd
run_test "M6 REGRESSION: seed library" tests/test_seed_library.gd
run_test "M6 REGRESSION: seed stats"   tests/test_seed_starting_stats.gd
run_test "M6 REGRESSION: unlock flow"  tests/test_unlock_flow.gd
run_test "M7 NEW: audio manager"       tests/test_audio_manager.gd

echo "=== DONE ==="
if [ "$FAILED" -ne 0 ]; then
  echo "=== RESULT: FAILED ==="
  exit 1
fi
echo "=== RESULT: ALL PASSED ==="
exit 0
