---
name: visual-quality-tiers
description: "Switch instantly between AAA Unreal-Grade (Vulkan SDFGI/SSR/Volumetric/ACES), Standard Unity-Style, and Indie Stylized (Cel-Shade, Low-Poly, HD-2D, PSX)."
license: MIT
category: rendering-quality
execution: zero-mcp-native
---

# One-Click Optional Visual Quality & Art-Style Tiers

Call `NovaQuality.apply_quality_tier(tier_name)` to reconfigure `WorldEnvironment`, directional shadow cascades, MSAA/FSR upscaling, shader overrides, and AI 3D polygon budgets simultaneously:
- `AAA_UNREAL`: Forward+, SDFGI, SSR, SSIL, Volumetric Fog, ACES Filmic tonemap, 4K PBR, High-Poly LOD0.
- `STANDARD_UNITY`: Balanced LightmapGI + crisp real-time shadows, clean PBR, 60+ FPS target.
- `INDIE_CEL_ANIME`: Toon shader (`shaders/cel_toon_outline.gdshader`) with crisp ink outlines.
- `INDIE_LOWPOLY_COZY`: Warm gradient sky, soft ambient occlusion, flat-shaded low-poly decimation.
- `INDIE_HD2D`: Sprite3D pixel characters in full 3D lit environments with tilt-shift depth-of-field.
- `INDIE_PSX_RETRO`: Vertex jitter snapping + affine UV + Bayer dithering (`shaders/psx_retro.gdshader`).
