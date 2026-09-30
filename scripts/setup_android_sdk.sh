#!/usr/bin/env bash
# scripts/setup_android_sdk.sh — install Android SDK + tools in Codespaces
# Idempotent: safe to run multiple times.
# Run: bash scripts/setup_android_sdk.sh
#
# Downloads ~100-150 MB (SDK + build-tools). No NDK by default — Godot 4.3
# with GDScript-only projects does not require it. If the export later
# complains about NDK, uncomment the ndk section below.

set -e

ANDROID_HOME="${ANDROID_HOME:-/usr/local/lib/android/sdk}"
CMDLINE_TOOLS_VERSION="11076708"   # commandlinetools-linux-11076708_latest.zip
SDK_PLATFORM="android-34"
BUILD_TOOLS="34.0.0"

echo "=== Android SDK setup ==="
echo "ANDROID_HOME: $ANDROID_HOME"
echo ""

# --- 1. Ensure Java is available (should already be via devcontainer) ---
if ! command -v java >/dev/null 2>&1; then
  echo "ERROR: java not found. Expected OpenJDK 17 from devcontainer."
  exit 1
fi
echo "java: $(java -version 2>&1 | head -1)"
echo ""

# --- 2. Download command-line tools ---
sudo mkdir -p "$ANDROID_HOME/cmdline-tools"
cd /tmp
if [ ! -f cmdline-tools.zip ]; then
  echo "Downloading command-line tools..."
  wget -q --show-progress \
    "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip" \
    -O cmdline-tools.zip
fi

if [ ! -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
  echo "Unpacking command-line tools..."
  rm -rf /tmp/cmdline-tools-unpack
  mkdir -p /tmp/cmdline-tools-unpack
  unzip -q cmdline-tools.zip -d /tmp/cmdline-tools-unpack
  sudo mv /tmp/cmdline-tools-unpack/cmdline-tools "$ANDROID_HOME/cmdline-tools/latest"
fi
echo ""

# --- 3. Accept licenses and install SDK components ---
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

echo "Accepting licenses..."
yes | sdkmanager --licenses >/dev/null 2>&1 || true

echo "Installing SDK components (platform-tools, platforms, build-tools)..."
sdkmanager --install \
  "platform-tools" \
  "platforms;${SDK_PLATFORM}" \
  "build-tools;${BUILD_TOOLS}" >/dev/null

# --- Optional: NDK. Uncomment if Godot export complains. ---
# echo "Installing NDK..."
# sdkmanager --install "ndk;25.2.9519653" >/dev/null

echo ""

# --- 4. Persist env vars to .bashrc ---
if ! grep -q "ANDROID_HOME" ~/.bashrc 2>/dev/null; then
  {
    echo ""
    echo "# Android SDK"
    echo "export ANDROID_HOME=\"$ANDROID_HOME\""
    echo "export PATH=\"\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$PATH\""
  } >> ~/.bashrc
fi

echo "=== Android SDK install complete ==="
echo "ANDROID_HOME=$ANDROID_HOME"
sdkmanager --list_installed 2>/dev/null | head -10
