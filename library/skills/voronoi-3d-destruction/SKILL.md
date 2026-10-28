---
name: voronoi-3d-destruction
description: "Real-time 3D Voronoi mesh fracturing with Jolt Physics rigid shards for glass, wood, stone, metal, and explosive barrels."
license: MIT
category: physics-destruction
execution: zero-mcp-native
---

# Real-Time 3D Voronoi Mesh Destruction

Enable destructibility on any prop via `nova_configure_smart_object(node_path, destructible=true, material="STONE"|"GLASS"|"WOOD"|"METAL"|"EXPLOSIVE_BARREL", shard_count=16)`:
- Uses the C++20 `VoronoiFracturer` kernel (`libnova_core`) or GDScript fallback to slice the mesh around the exact weapon/bullet impact point into watertight convex Jolt `RigidBody3D` shards with radial blast impulses, debris VFX, and acoustic SFX.
