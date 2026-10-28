#!/usr/bin/env python3
"""
NovaForge AI Game Engine — Cross-Platform Graphical Studio Hub (Linux / macOS / Windows fallback)
Opens a clean graphical window with 1-click buttons to enter Real Godot 4.7.2 Editor or Play the 3D Game.
If Tkinter or a display server is unavailable, automatically launches Real Godot 4.7.2 Editor directly.
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "launcher"))
import novaforge_launcher as nf  # noqa: E402


def launch_mode(mode: str, root_win=None) -> None:
    if root_win is not None:
        root_win.destroy()
    nf.ensure_native_core()
    godot_bin = nf.find_or_download_godot(auto_download=True)
    if not godot_bin:
        sys.exit(1)
    if mode == "play":
        cmd = [str(godot_bin), "--path", str(ROOT), "res://scenes/showcase/novaforge_sandbox.tscn"]
    elif mode == "pm":
        cmd = [str(godot_bin), "--project-manager"]
    else:
        cmd = [str(godot_bin), "-e", "--path", str(ROOT), "scenes/showcase/novaforge_sandbox.tscn"]
    subprocess.Popen(cmd, cwd=str(ROOT))


def main() -> int:
    try:
        import tkinter as tk
    except Exception:
        launch_mode("editor")
        return 0

    if not os.environ.get("DISPLAY") and sys.platform.startswith("linux"):
        launch_mode("editor")
        return 0

    win = tk.Tk()
    win.title("NovaForge AI Game Engine — Studio Hub (Godot 4.7.2)")
    win.geometry("540x330")
    win.configure(bg="#181c26")
    win.resizable(False, False)

    tk.Label(
        win,
        text="NovaForge AI Game Engine (Godot 4.7.2)",
        fg="#f8fafc",
        bg="#181c26",
        font=("Sans", 15, "bold"),
    ).pack(pady=(22, 6))

    tk.Label(
        win,
        text="موتور رسمی گادوت ۴.۷ + هوش مصنوعی لوکال Colibrì و Blueprint/C++",
        fg="#94a3b8",
        bg="#181c26",
        font=("Sans", 10),
    ).pack(pady=(0, 18))

    tk.Button(
        win,
        text="🚀  ورود مستقیم به محیط ادیتور گادوت ۴.۷  (Open Editor)",
        bg="#2563eb",
        fg="#ffffff",
        activebackground="#1d4ed8",
        activeforeground="#ffffff",
        relief="flat",
        font=("Sans", 11, "bold"),
        width=46,
        height=2,
        command=lambda: launch_mode("editor", win),
    ).pack(pady=6)

    tk.Button(
        win,
        text="🎮  اجرای مستقیم بازی سه‌بعدی آماده  (Play 3D Showcase)",
        bg="#15803d",
        fg="#ffffff",
        activebackground="#166534",
        activeforeground="#ffffff",
        relief="flat",
        font=("Sans", 11, "bold"),
        width=46,
        height=2,
        command=lambda: launch_mode("play", win),
    ).pack(pady=6)

    tk.Button(
        win,
        text="📁  ساخت بازی جدید / مدیریت پروژه‌ها  (Project Manager)",
        bg="#334155",
        fg="#e2e8f0",
        activebackground="#475569",
        activeforeground="#ffffff",
        relief="flat",
        font=("Sans", 10),
        width=46,
        height=1,
        command=lambda: launch_mode("pm", win),
    ).pack(pady=6)

    win.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
