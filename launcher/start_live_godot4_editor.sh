#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${1:-8080}"
DISPLAY_NUM="${DISPLAY_NUM:-:99}"
RESOLUTION="${RESOLUTION:-1440x860}"

# Ensure native C/C++ GDExtension is compiled
if [ ! -f "$ROOT_DIR/native/bin/libnova_core.so" ] && command -v make >/dev/null 2>&1; then
  make -C "$ROOT_DIR/native" all
fi

# Ensure official Godot 4.7.2 binary exists (portable engine_bin/ or ~/.cache/novaforge_godot/)
GODOT_BIN="$ROOT_DIR/engine_bin/Godot_v4.7.2-stable_linux.x86_64"
if [ ! -x "$GODOT_BIN" ]; then
  GODOT_BIN="$HOME/.cache/novaforge_godot/Godot_v4.7.2-stable_linux.x86_64"
fi
if [ ! -x "$GODOT_BIN" ]; then
  python3 "$ROOT_DIR/launcher/novaforge_launcher.py" --download-only
  GODOT_BIN="$HOME/.cache/novaforge_godot/Godot_v4.7.2-stable_linux.x86_64"
fi

# Clean up stale processes from earlier runs
pkill -f "Xvfb ${DISPLAY_NUM}" 2>/dev/null || true
pkill -f "x11vnc -display ${DISPLAY_NUM}" 2>/dev/null || true
pkill -f "websockify.*:${PORT}" 2>/dev/null || true
rm -f "/tmp/.X${DISPLAY_NUM#:}-lock" "/tmp/.X11-unix/X${DISPLAY_NUM#:}" 2>/dev/null || true

# Prepare persistent web root combining noVNC core + NovaForge 1-Click Studio Hub
WEB_ROOT="/tmp/novaforge_web_vnc"
rm -rf "$WEB_ROOT"
mkdir -p "$WEB_ROOT"
cp -r /usr/share/novnc/* "$WEB_ROOT/"
cp "$ROOT_DIR/launcher/web_hub_index.html" "$WEB_ROOT/index.html"

# Write borderless maximized Openbox config so Godot 4 fills 100% of the screen
mkdir -p /tmp/novaforge_ob
cat > /tmp/novaforge_ob/rc.xml << 'OBEOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <applications>
    <application class="*">
      <decor>no</decor>
      <maximized>true</maximized>
    </application>
  </applications>
</openbox_config>
OBEOF

echo "[NovaForge] Starting Xvfb (${RESOLUTION}x24) on ${DISPLAY_NUM}..."
Xvfb "${DISPLAY_NUM}" -screen 0 "${RESOLUTION}x24" +extension GLX +render -noreset >/tmp/novaforge_xvfb.log 2>&1 &
XVFB_PID=$!
sleep 1

export DISPLAY="${DISPLAY_NUM}"
openbox --config-file /tmp/novaforge_ob/rc.xml >/tmp/novaforge_openbox.log 2>&1 &
OB_PID=$!
sleep 0.5

echo "[NovaForge] Launching official Godot Engine 4.7.2 Editor with NovaForge GDExtension & EditorPlugin..."
"${GODOT_BIN}" \
  --editor \
  --rendering-driver opengl3 \
  --audio-driver Dummy \
  --windowed \
  --resolution "${RESOLUTION}" \
  --position 0,0 \
  --path "${ROOT_DIR}" \
  scenes/showcase/novaforge_sandbox.tscn >/tmp/novaforge_godot4.log 2>&1 &
GODOT_PID=$!
sleep 2

echo "[NovaForge] Starting x11vnc on ${DISPLAY_NUM} (127.0.0.1:5900)..."
x11vnc -display "${DISPLAY_NUM}" -localhost -forever -shared -nopw -rfbport 5900 -noxdamage -wait 10 -defer 10 >/tmp/novaforge_vnc.log 2>&1 &
VNC_PID=$!
sleep 1

cleanup() {
  kill "${GODOT_PID}" "${VNC_PID}" "${OB_PID}" "${XVFB_PID}" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "[NovaForge] Real Godot 4.7.2 Editor + 1-Click Studio Hub streaming live on 0.0.0.0:${PORT}"
exec websockify --web="${WEB_ROOT}" "0.0.0.0:${PORT}" 127.0.0.1:5900
