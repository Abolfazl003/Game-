@tool
extends Node3D
class_name WorldChunkStreamer3D
## Open-World Spatial Chunk Streaming & Auto-LOD Coordinator.
## Partitions huge maps into `Chunk(gx, gz)` cells around the player camera:
## - Near ring (`<= active_radius`): Full detail + Jolt Physics + live NPCs
## - Mid ring (`<= lod_proxy_radius`): Lightweight LOD2 meshes
## - Far cells: Unloaded from GPU/RAM while `NovaWorldLife` ticks NPC lives in background!

@export var chunk_size_meters: float = 64.0
@export var active_radius_chunks: int = 2
@export var lod_proxy_radius_chunks: int = 4

var _registered_chunks: Dictionary = {} # Vector2i -> Dictionary
var _current_center_cell: Vector2i = Vector2i(999999, 999999)


func register_chunk(cell: Vector2i, scene_path: String, lod_proxy_path: String = "") -> void:
	_registered_chunks[cell] = {
		"scene_path": scene_path,
		"lod_proxy_path": lod_proxy_path,
		"state": "UNLOADED"
	}


func update_streaming_for_position(world_pos: Vector3) -> Dictionary:
	var gx := int(floor(world_pos.x / chunk_size_meters))
	var gz := int(floor(world_pos.z / chunk_size_meters))
	var center := Vector2i(gx, gz)
	_current_center_cell = center

	var active_count := 0
	var proxy_count := 0
	var unloaded_count := 0

	for cell: Vector2i in _registered_chunks.keys():
		var dist := maxi(absi(cell.x - center.x), absi(cell.y - center.y))
		if dist <= active_radius_chunks:
			_registered_chunks[cell]["state"] = "ACTIVE_FULL_LOD0"
			active_count += 1
		elif dist <= lod_proxy_radius_chunks:
			_registered_chunks[cell]["state"] = "STREAMED_LOD2_PROXY"
			proxy_count += 1
		else:
			_registered_chunks[cell]["state"] = "UNLOADED_BACKGROUND_NPC_TICK"
			unloaded_count += 1

	return {
		"center_cell": [center.x, center.y],
		"active_chunks": active_count,
		"lod_proxy_chunks": proxy_count,
		"unloaded_chunks": unloaded_count
	}
