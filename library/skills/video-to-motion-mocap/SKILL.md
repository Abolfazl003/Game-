---
name: video-to-motion-mocap
description: "Extract 3D world-space root motion, body joints, fingers, face, Foot-Locking IK, and automatic combat hitbox keyframes from any video."
license: MIT
category: animation-mocap
execution: zero-mcp-native
---

# AI Video-to-Motion & Physics Mocap Studio

When a user supplies a reference video (`.mp4`, `.mov`, `.webm`) of a specific run style, martial-arts combo, or gesture:
1. Run `nova_video_to_motion(video_path, target_skeleton_path, motion_kind)`.
2. The pipeline (`pipelines/mocap/video_to_motion.py`) extracts 52-bone 3D world-space trajectories + root motion + finger curl + facial blendshapes.
3. Physics cleanup removes jitter (Savitzky-Golay filter), enforces anatomical joint limits, and locks planted feet via **Foot-Locking IK** (zero moonwalking/sliding).
4. **Auto-Combat Tagging** detects peak limb angular/linear velocity frames and automatically inserts `Hitbox3D` active windows, `vfx-hit-spark` triggers, and impact SFX events onto the generated Godot `Animation` resource.
