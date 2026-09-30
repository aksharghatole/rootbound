#!/usr/bin/env bash
# scripts/build_android.sh — build a debug APK of Rootbound.
# Requires scripts/setup_android_sdk.sh to have been run.
# Run: bash scripts/build_android.sh
# Output: build/rootbound.apk

set -e

cd "$(dirname "$0")/.."   # repo root

# Make sure env is loaded (Codespaces fresh shell may not have it yet)
if [ -z "${ANDROID_HOME:-}" ]; then
  if [ -f "$HOME/.bashrc" ]; then
    # shellcheck disable=SC1090
    source "$HOME/.bashrc" || true
  fi
fi

if [ -z "${ANDROID_HOME:-}" ]; then
  echo "ERROR: ANDROID_HOME not set. Run scripts/setup_android_sdk.sh first."
  exit 1
fi

# Locate godot binary (workspace-local first, then system)
GODOT_BIN=""
if [ -x ".tools/godot" ]; then
  GODOT_BIN=".tools/godot"
elif command -v godot >/dev/null 2>&1; then
  GODOT_BIN="$(command -v godot)"
else
  echo "ERROR: godot binary not found (checked .tools/godot and PATH)."
  exit 1
fi

echo "=== Rootbound Android build ==="
echo "GODOT_BIN:   $GODOT_BIN"
echo "ANDROID_HOME: $ANDROID_HOME"
echo ""

mkdir -p build

echo "Importing project (headless)..."
"$GODOT_BIN" --headless --import >/dev/null 2>&1 || true

echo "Exporting Android APK (debug)..."
"$GODOT_BIN" --headless \
  --export-debug "Android" \
  "build/rootbound.apk"

if [ ! -f build/rootbound.apk ]; then
  echo "ERROR: build/rootbound.apk was not created."
  exit 1
fi

echo ""
echo "=== Build complete ==="
ls -lh build/rootbound.apk
echo ""
echo "Size in MB:"
du -m build/rootbound.apk | cut -f1
