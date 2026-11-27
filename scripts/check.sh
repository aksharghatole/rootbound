#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export GODOT_SILENCE_ROOT_WARNING=1
export GODOT_BIN="${GODOT_BIN:-godot}"
if ! command -v "$GODOT_BIN" >/dev/null; then
  echo "Godot not found: $GODOT_BIN" >&2
  exit 1
fi

echo "=== Headless project import ==="
log="$(mktemp)"
trap 'rm -f "$log"' EXIT
if ! timeout 120 "$GODOT_BIN" --headless --import >"$log" 2>&1; then
  cat "$log"
  exit 1
fi
cat "$log"
if grep -Eq 'SCRIPT ERROR|Parse Error|^ERROR:' "$log"; then exit 1; fi

echo "=== Test suite ==="
bash run_m5_tests.sh
echo "=== ALL CHECKS PASSED ==="
