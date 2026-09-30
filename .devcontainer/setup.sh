#!/usr/bin/env bash
set -e

GODOT_VERSION="4.3-stable"
GODOT_DIR="/usr/local/bin"
TMP="/tmp/godot"

mkdir -p "$TMP"
cd "$TMP"

# Godot headless/editor binary
wget -q "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
unzip -q "Godot_v${GODOT_VERSION}_linux.x86_64.zip"
mv "Godot_v${GODOT_VERSION}_linux.x86_64" "$GODOT_DIR/godot"
chmod +x "$GODOT_DIR/godot"

# Android export templates
mkdir -p ~/.local/share/godot/export_templates/${GODOT_VERSION}
wget -q "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_export_templates.tpz"
unzip -q "Godot_v${GODOT_VERSION}_export_templates.tpz" -d ~/.local/share/godot/export_templates/
mv ~/.local/share/godot/export_templates/templates/* ~/.local/share/godot/export_templates/${GODOT_VERSION}/ || true
rm -rf ~/.local/share/godot/export_templates/templates

echo "Godot installed: $(godot --version 2>/dev/null || echo 'not on PATH yet')"
