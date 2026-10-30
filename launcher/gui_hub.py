#!/usr/bin/env python3
"""
Zero-Question Direct Entry Wrapper:
Enters straight into the official Persian Godot 4.7.2 NovaForge Studio without asking any questions.
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

if __name__ == "__main__":
    extra = sys.argv[1:] if len(sys.argv) > 1 else ["--editor"]
    raise SystemExit(subprocess.call([sys.executable, str(ROOT / "launcher" / "novaforge_launcher.py"), *extra]))
