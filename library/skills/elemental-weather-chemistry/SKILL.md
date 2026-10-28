---
name: elemental-weather-chemistry
description: "Dynamic weather, 24h day/night cycle, and systemic Fire/Water/Wind/Lightning chemistry reactions."
license: MIT
category: world-systems
execution: zero-mcp-native
---

# Dynamic Weather & Elemental Chemistry System

`ElementalWorldSystem` (`addons/novaforge_engine/world/elemental_weather_system.gd`) couples weather with systemic physics:
- Fire ignites dry grass/wood and spreads along Wind direction.
- Rain/Water extinguishes Fire, spawns steam VFX, and increases surface wetness/slipperiness.
- Lightning conducts through wet surfaces and water bodies to shock nearby Hurtboxes.
