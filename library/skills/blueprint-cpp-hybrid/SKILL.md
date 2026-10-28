---
name: blueprint-cpp-hybrid
description: "Build gameplay simultaneously with Visual Blueprint Node Graphs, Native C++20 GDExtension, and GDScript."
license: MIT
category: scripting-architecture
execution: zero-mcp-native
---

# Hybrid Blueprint + C++20 + GDScript Workflow

Every gameplay mechanic in NovaForge can be authored or AI-generated as a **Visual Blueprint Graph** (`res://addons/novaforge_engine/blueprint/blueprint_resource.gd`) and compiled cleanly to either **GDScript** or **Native C++20 (`GDExtension`)**.

## Core Nodes
- `Event_BeginPlay`, `Event_Tick`, `Event_OnAttackInput`, `Event_OnInteract`, `Event_OnCutsceneTrigger`
- `Flow_Branch`, `Flow_Sequence`
- `MoveCharacter`, `PlayMeleeCombo`, `ApplyDamage`, `DodgeRoll`, `SpawnVFX`, `FractureObject`, `TriggerCutscene`

Use `nova_compile_blueprint(graph_path, target="cpp"|"gdscript")` to hot-compile any Blueprint graph.
