---
name: blender-zero-config-materials
description: "Import .blend, .glb, .gltf, .fbx, .obj, .dae, .usd, .abc, .ply, .stl with 100% automatic PBR texture discovery & DirectX/OpenGL normal auto-fix."
license: MIT
category: asset-pipeline
execution: zero-mcp-native
---

# Universal Blender Importer & Zero-Config Auto-Material Binder

Never ask the user to manually wire textures. When importing any 3D file (`.blend`, `.glb`, `.gltf`, `.fbx`, `.obj`, `.dae`, `.usd/.usdz`, `.abc`, `.ply`, `.stl`):
1. Call `nova_import_blender_asset(path)` which runs the **4-Stage Smart PBR Resolver**:
   - Unpacks embedded textures.
   - Fuzzy-scans `textures/`, `maps/`, `materials/`, and sibling folders to heal broken absolute paths.
   - Classifies `_Albedo/_BaseColor`, `_Normal` (auto-detecting DirectX vs OpenGL green channel orientation and flipping Y when needed), `_Roughness` vs `_Glossiness` (auto-inverting gloss), `_Metallic`, `_AO`, `_ORM` (channel-packed R=AO, G=Roughness, B=Metallic), `_Emission`, and `_Opacity`.
   - Invokes `pipelines/blender_bridge/blend_extractor.py` when procedural Blender `Principled BSDF` shader graphs need headless PBR baking.
