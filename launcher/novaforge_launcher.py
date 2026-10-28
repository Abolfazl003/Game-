#!/usr/bin/env python3
"""
NovaForge AI Game Engine — Real Godot 4.7.2 Auto-Launcher
=========================================================
1. Compiles/verifies the C11/C++20 native core (`libnova_core.so` / `.dll` / `.dylib`) if a compiler is installed.
2. Detects or automatically downloads the official MIT-licensed Godot Engine 4.7.2 binary
   for Windows (win64), Linux (x86_64), or macOS (universal) into `engine_bin/`.
3. Launches the REAL official Godot 4.7.2 Editor (`--editor`) with `addons/novaforge_engine` loaded,
   or plays `scenes/showcase/novaforge_sandbox.tscn` directly (`--play`).
"""

from __future__ import annotations

import argparse
import os
import platform
import shutil
import stat
import subprocess
import sys
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENGINE_BIN_DIR = ROOT / "engine_bin"
CACHE_BIN_DIR = Path.home() / ".cache" / "novaforge_godot"
GODOT_VERSION = "4.7.2-stable"

GODOT_URLS = {
    ("Linux", "x86_64"): (
        f"https://github.com/godotengine/godot/releases/download/{GODOT_VERSION}/Godot_v{GODOT_VERSION}_linux.x86_64.zip",
        f"Godot_v{GODOT_VERSION}_linux.x86_64",
    ),
    ("Windows", "AMD64"): (
        f"https://github.com/godotengine/godot/releases/download/{GODOT_VERSION}/Godot_v{GODOT_VERSION}_win64.exe.zip",
        f"Godot_v{GODOT_VERSION}_win64.exe",
    ),
    ("Darwin", "arm64"): (
        f"https://github.com/godotengine/godot/releases/download/{GODOT_VERSION}/Godot_v{GODOT_VERSION}_macos.universal.zip",
        "Godot.app/Contents/MacOS/Godot",
    ),
    ("Darwin", "x86_64"): (
        f"https://github.com/godotengine/godot/releases/download/{GODOT_VERSION}/Godot_v{GODOT_VERSION}_macos.universal.zip",
        "Godot.app/Contents/MacOS/Godot",
    ),
}


def ensure_native_core() -> Path | None:
    system = platform.system()
    ext = ".dll" if system == "Windows" else (".dylib" if system == "Darwin" else ".so")
    target = ROOT / "native" / "bin" / f"libnova_core{ext}"
    if target.exists():
        return target
    if shutil.which("make") and (shutil.which("g++") or shutil.which("clang++")):
        print("[NovaForge] Compiling C11/C++20 native engine core (Colibrì + Blueprint VM + Voronoi)...")
        subprocess.run(["make", "-C", str(ROOT / "native"), "all"], check=False)
    return target if target.exists() else None


def find_or_download_godot(auto_download: bool = True) -> Path | None:
    for candidate in ("godot4", "godot"):
        found = shutil.which(candidate)
        if found:
            return Path(found)

    key = (platform.system(), platform.machine())
    if key not in GODOT_URLS and platform.system() == "Windows":
        key = ("Windows", "AMD64")
    if key not in GODOT_URLS:
        return None

    url, rel_bin = GODOT_URLS[key]
    for base_dir in (ENGINE_BIN_DIR, CACHE_BIN_DIR):
        candidate_bin = base_dir / rel_bin
        if candidate_bin.exists():
            return candidate_bin

    if not auto_download:
        return None

    target_dir = ENGINE_BIN_DIR if platform.system() == "Windows" else CACHE_BIN_DIR
    target_dir.mkdir(parents=True, exist_ok=True)
    bin_path = target_dir / rel_bin
    zip_path = target_dir / f"godot_{GODOT_VERSION}.zip"
    print(f"[NovaForge] Downloading official Godot {GODOT_VERSION} binary from:\n  {url}")
    urllib.request.urlretrieve(url, zip_path)
    with zipfile.ZipFile(zip_path, "r") as zf:
        zf.extractall(target_dir)
    zip_path.unlink(missing_ok=True)

    if bin_path.exists() and platform.system() != "Windows":
        bin_path.chmod(bin_path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    return bin_path if bin_path.exists() else None


def main() -> int:
    parser = argparse.ArgumentParser(description="NovaForge AI Game Engine — Official Godot 4.7.2 Launcher")
    parser.add_argument("--editor", action="store_true", help="Open the real Godot 4.7.2 Editor with NovaForge modules")
    parser.add_argument("--play", action="store_true", help="Play the 3D Samurai Showcase game directly")
    parser.add_argument("--web-editor", action="store_true", help="Stream the real Godot 4.7.2 Editor over X11/noVNC")
    parser.add_argument("--download-only", action="store_true", help="Only download/verify the official Godot 4.7.2 binary")
    parser.add_argument("--port", type=int, default=8080, help="Port for --web-editor noVNC stream")
    args = parser.parse_args()

    ensure_native_core()
    godot_bin = find_or_download_godot(auto_download=True)
    if not godot_bin:
        print("[NovaForge] ERROR: Could not locate or download official Godot 4.7.2 binary.", file=sys.stderr)
        return 1

    print(f"[NovaForge] Official Godot binary ready: {godot_bin}")
    if args.download_only:
        return 0

    if args.web_editor:
        script = ROOT / "launcher" / "start_live_godot4_editor.sh"
        return subprocess.call(["bash", str(script), str(args.port)])

    if args.play:
        cmd = [str(godot_bin), "--path", str(ROOT), "res://scenes/showcase/novaforge_sandbox.tscn"]
    else:
        cmd = [str(godot_bin), "-e", "--path", str(ROOT), "scenes/showcase/novaforge_sandbox.tscn"]

    print(f"[NovaForge] Launching Real Godot 4.7.2: {' '.join(cmd)}")
    return subprocess.call(cmd)


if __name__ == "__main__":
    raise SystemExit(main())
