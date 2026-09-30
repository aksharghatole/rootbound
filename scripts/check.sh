#!/usr/bin/env bash
# scripts/check.sh — Rootbound pre-flight check
# Fails fast on the classes of GDScript error we keep hitting.
#
# Run: bash scripts/check.sh
# Exit: 0 = clean, 1 = problem found

set -u
cd "$(dirname "$0")/.."   # repo root

FAIL=0

echo "=== 1/3: reserved-method scan ==="
# Godot's Object base class reserves these. Naming our methods this way
# causes "overrides a method from native class" parse errors.
RESERVED=(
  '\.get_meta\('
  '\.set_meta\('
  '\.has_meta\('
  '\.remove_meta\('
  '\.add_user_signal\('
  '\.emit_signal\('
  '\.get_class\('
  '\.queue_free\('
  '\.connect\('
  '\.disconnect\('
)
SCAN_DIRS=(autoload scripts tests)
HITS=0
for pattern in "${RESERVED[@]}"; do
  matches=$(grep -rn "$pattern" "${SCAN_DIRS[@]}" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    echo "HIT: pattern '$pattern'"
    echo "$matches"
    HITS=$((HITS + 1))
    FAIL=1
  fi
done
if [ "$HITS" -eq 0 ]; then
  echo "clean — no reserved-method calls"
fi
echo ""

echo "=== 2/3: headless import (parse errors) ==="
IMPORT_LOG=$(mktemp)
godot --headless --import > "$IMPORT_LOG" 2>&1
if grep -q "SCRIPT ERROR" "$IMPORT_LOG"; then
  echo "parse errors during import:"
  grep -A2 "SCRIPT ERROR" "$IMPORT_LOG"
  FAIL=1
else
  echo "clean — no parse errors"
fi
rm -f "$IMPORT_LOG"
echo ""

echo "=== 3/3: test suite ==="
if [ -x run_m5_tests.sh ]; then
  # Will rename to run_all_tests.sh in M6; prefer the general one if present.
  if [ -x scripts/run_all_tests.sh ]; then
    bash scripts/run_all_tests.sh
  else
    bash run_m5_tests.sh
  fi
  SUITE_EXIT=$?
  if [ "$SUITE_EXIT" -ne 0 ]; then
    FAIL=1
  fi
else
  echo "no test runner found — skipping"
fi
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "=== check.sh: ALL CLEAN ==="
  exit 0
else
  echo "=== check.sh: FAILURES ABOVE ==="
  exit 1
fi
