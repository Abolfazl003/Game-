---
name: world-persistence-timemachine
description: "Save/Load full living-world state (fractured objects + evolved NPCs) & revert editor AI changes via Project Time-Machine snapshots."
license: MIT
category: persistence-tooling
execution: zero-mcp-native
---

# Smart Living-World Persistence & Editor Time-Machine

- **In-Game Save/Load (`WorldPersistenceManager`)**: Serializes player inventory, destroyed Voronoi prop IDs, quest flags, and every `LivingNPCBrain3D` biography/wealth/scar/memory delta into compact binary/JSON save slots.
- **Editor Time-Machine (`NovaTimeMachine`)**: Automatically records lightweight project snapshots before every Multi-Brain AI operation for instant 1-click rollback.
