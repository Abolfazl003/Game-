#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chmod +x "$ROOT_DIR/launcher/start_live_godot4_editor.sh" "$ROOT_DIR/launcher/novaforge_launcher.py" 2>/dev/null || true

if [ "${1:-}" = "--play" ]; then
  exec python3 "$ROOT_DIR/launcher/novaforge_launcher.py" --play
elif [ "${1:-}" = "--web-editor" ]; then
  exec "$ROOT_DIR/launcher/start_live_godot4_editor.sh" "${2:-8080}"
else
  # Zero questions: enter straight into the Persian NovaForge Studio inside Godot 4.7.2!
  exec python3 "$ROOT_DIR/launcher/novaforge_launcher.py" --editor
fi
