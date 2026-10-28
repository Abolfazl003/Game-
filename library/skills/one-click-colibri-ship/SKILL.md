---
name: one-click-colibri-ship
description: "One-click multi-platform game export (Windows, Linux, macOS, Android, iOS, Web) bundling the lightweight Colibrì C runtime for living-NPC games."
license: MIT
category: export-release
execution: zero-mcp-native
---

# One-Click Game Packager & Embedded Colibrì Ship Pipeline

`OneClickExporter` (`addons/novaforge_engine/world/one_click_exporter.gd`) runs `nova_scene_audit`, strips editor-only caches, compiles active Blueprints to native C++/GDScript, and—if any `LivingNPCBrain3D` uses runtime AI dialogue—bundles `libnova_core` + quantized micro-weights directly alongside the exported executable.
