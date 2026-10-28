---
name: smart-interactive-objects
description: "Click any 3D prop in the viewport to open the Smart Context Menu: doors/chests with auto-hinge, pickups, weapons, physics traps, or custom AI prompts."
license: MIT
category: interactive-world
execution: zero-mcp-native
---

# Smart Context-Click Object Behaviors

Any `Node3D` / `MeshInstance3D` in the scene can be configured with one click via `SmartObjectBehavior3D`:
- **Interactable**: Auto-detects bounding-box hinge edge for doors/chests, adds `[E]` prompt + outline shader, supports Pickup/Inventory, Weapon Equip, Lever/Button, Ladder, and Seat.
- **Custom Prompt Box**: Synthesizes bespoke Blueprint/GDScript logic directly onto the clicked object.
