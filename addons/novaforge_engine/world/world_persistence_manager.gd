@tool
extends RefCounted
class_name WorldPersistenceManager
## Smart Living-World Persistence (`WorldPersistenceManager`).
## Saves & restores destroyed Voronoi object IDs, weather/time, player inventory,
## and every `LivingNPCBrain3D` evolving life biography, scars & Nemesis combat memory!


static func save_world_slot(
	slot_path: String,
	player_state: Dictionary,
	destroyed_object_ids: Array[String],
	npc_snapshots: Array[Dictionary],
	world_day: int = 1
) -> Dictionary:
	var payload := {
		"schema": "novaforge_living_world_v1",
		"saved_unix": Time.get_unix_time_from_system(),
		"world_day": world_day,
		"player": player_state,
		"destroyed_voronoi_objects": destroyed_object_ids,
		"living_npcs": npc_snapshots
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(slot_path.get_base_dir()))
	var f := FileAccess.open(slot_path, FileAccess.WRITE)
	if f == null:
		return {"ok": false, "error": "Cannot open save path: " + slot_path}
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()
	return {"ok": true, "slot_path": slot_path, "npc_count": npc_snapshots.size(), "destroyed_count": destroyed_object_ids.size()}


static func load_world_slot(slot_path: String) -> Dictionary:
	if not FileAccess.file_exists(slot_path):
		return {"ok": false, "error": "Save slot does not exist"}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(slot_path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "error": "Corrupted save file"}
	parsed["ok"] = true
	return parsed
