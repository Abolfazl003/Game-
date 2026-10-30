#!/usr/bin/env python3
"""
Generates customized Persian (`fa`) + Cyber-Royal Midnight-Cyan NovaForge `editor_settings-4.7.tres`
for both local Godot config (`~/.config/godot/`) and Portable Self-Contained bundles (`engine_bin/editor_data/`).
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def write_editor_settings(target_file: Path, font_regular: str = "", font_bold: str = "") -> None:
    target_file.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        '[gd_resource type="EditorSettings" format=3]',
        "",
        "[resource]",
        'interface/editor/localization/editor_language = "fa"',
        "interface/editor/localization/localize_settings = true",
        "interface/editor/fonts/main_font_size = 14",
        f'interface/editor/fonts/main_font = "{font_regular}"',
        f'interface/editor/fonts/main_font_bold = "{font_bold}"',
        'interface/theme/style = "Modern"',
        'interface/theme/color_preset = "Custom"',
        "interface/theme/follow_system_theme = false",
        "interface/theme/use_system_accent_color = false",
        "interface/theme/base_color = Color(0.085, 0.11, 0.175, 1)",
        "interface/theme/accent_color = Color(0.22, 0.78, 0.98, 1)",
        "interface/theme/contrast = 0.28",
        "interface/theme/corner_radius = 6",
        "interface/theme/border_size = 1",
        "interface/theme/draw_extra_borders = true",
        "interface/editor/single_window_mode = false",
        "interface/editor/update_continuously = true",
        "interface/editor/behavior/show_internal_errors_in_toast_notifications = 0",
        "",
    ]
    target_file.write_text("\n".join(lines), encoding="utf-8")


if __name__ == "__main__":
    dest = Path(sys.argv[1]) if len(sys.argv) > 1 else (Path.home() / ".config" / "godot" / "editor_settings-4.7.tres")
    use_portable = "--portable" in sys.argv
    reg = "" if use_portable else str((ROOT / "fonts" / "Vazirmatn-Regular.ttf").resolve())
    bold = "" if use_portable else str((ROOT / "fonts" / "Vazirmatn-Bold.ttf").resolve())
    write_editor_settings(dest, reg, bold)
    print(f"[NovaForge] Wrote Persian Customized EditorSettings -> {dest}")
