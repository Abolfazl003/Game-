@tool
extends Node
class_name NovaWorldLifeSimulator
## Ultra-Lightweight Background Living-World Simulator (`NovaWorldLife`).
## Advances off-screen Living NPCs' careers, economies, alliances, and Nemesis grudges
## when chapters/days advance without rendering off-screen 3D meshes or physics!

signal world_day_advanced(current_day: int, updated_npc_count: int)

var current_world_day: int = 1
var world_prosperity_index: float = 1.0
var _registered_npcs: Array[LivingNPCBrain3D] = []


func register_living_npc(npc: LivingNPCBrain3D) -> void:
	if npc and not _registered_npcs.has(npc):
		_registered_npcs.append(npc)


func advance_world_time(days: int = 1) -> Array[Dictionary]:
	current_world_day += maxi(1, days)
	var summaries: Array[Dictionary] = []
	for npc in _registered_npcs:
		if is_instance_valid(npc) and npc.enable_evolving_life:
			summaries.append(npc.advance_life_chapter(days, world_prosperity_index))
	world_day_advanced.emit(current_world_day, summaries.size())
	return summaries


func serialize_all_npcs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for npc in _registered_npcs:
		if is_instance_valid(npc):
			out.append(npc.get_biography_snapshot())
	return out
