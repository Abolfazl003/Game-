---
name: in-engine-cutscene-sequencer
description: "Author Blender-grade Pose/IK, Bezier Graph Editor, NLA layers, and seamless real-time cutscenes directly in-engine ('این تیکه کات‌سینه')."
license: MIT
category: cinematics
execution: zero-mcp-native
---

# In-Engine Blender-Grade Animation & Live Cutscene Director

Never require pre-rendered `.mp4` videos from Blender for story moments. When the user marks a moment as a cutscene (*"این تیکه کات‌سینه"*):
1. Spawn a `CutsceneTrigger3D` + `CutsceneDirector` timeline via `nova_create_cutscene(...)`.
2. Lock player input smoothly while blending the active gameplay `Camera3D` transform into the `CutsceneCameraRig` (zero black screen!).
3. Drive character poses via **In-Engine Pose/IK**, **Bezier Graph Curves**, **NLA Animation Layers**, focal rack-focus DOF, time-dilation slow-mo, and optional **QTE** prompts, then blend seamlessly back to gameplay!
