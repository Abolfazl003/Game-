---
name: colibri-multi-brain-council
description: "Orchestrate multiple local AI brains (Director, C++/Blueprint Coder, 3D Artist, Mocap Animator, QA Critic) via Colibrì VRAM/RAM/NVMe streaming."
license: MIT
category: ai-architecture
execution: zero-mcp-native
---

# Colibrì Multi-Brain Council (Zero-MCP Local Orchestration)

NovaForge runs a **5-Brain Specialist Council** directly inside the engine without MCP:
1. **DirectorBrain (`NOVA_BRAIN_DIRECTOR`)**: Breaks the user's Persian/English prompt into mechanics, camera mode, scene tree, and asset requirements.
2. **CoderBrain (`NOVA_BRAIN_CODER_CPP_BP`)**: Synthesizes hybrid `BlueprintGraph` nodes, `GDExtension` C++20 modules, and `GDScript` controllers.
3. **Artist3DBrain (`NOVA_BRAIN_ARTIST_3D_TEX`)**: Drives local Image-to-3D, Blender material auto-binding, lighting, and Visual Quality Tier presets.
4. **AnimatorCinematicsBrain (`NOVA_BRAIN_ANIMATOR_MOCAP`)**: Runs Auto-Rigging, Video-to-Motion IK cleanup, and the In-Engine Cutscene Sequencer.
5. **CriticQABrain (`NOVA_BRAIN_CRITIC_QA`)**: Executes `nova_scene_audit`, headless/viewport playtesting, and merges all specialist outputs into **one verified result**.

## Memory Rule
Always invoke `NovaBrainCouncil.run_council_task(prompt, active_modalities)` so `libnova_core` streams MoE experts from NVMe SSD and flushes GPU VRAM (`colibri_flush_vram_for_renderer`) before returning control to Godot's Vulkan renderer.
