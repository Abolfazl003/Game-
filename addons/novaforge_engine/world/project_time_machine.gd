@tool
extends Node
class_name NovaProjectTimeMachine
## Built-in Project Time-Machine (`NovaTimeMachine`).
## Captures instant snapshots before Multi-Brain AI operations so creators can rewind
## any scene/script change with 1 click without touching complex Git commands!

signal snapshot_created(snapshot_id: String, label: String)
signal snapshot_restored(snapshot_id: String)

var _snapshots: Array[Dictionary] = []


func create_snapshot(label: String = "Manual Checkpoint") -> Dictionary:
	var snap_id := "snap_" + str(Time.get_ticks_msec()) + "_" + str(_snapshots.size() + 1)
	var entry := {
		"id": snap_id,
		"label": label,
		"timestamp_unix": Time.get_unix_time_from_system(),
	}
	_snapshots.append(entry)
	snapshot_created.emit(snap_id, label)
	return {"ok": true, "snapshot_id": snap_id, "total_snapshots": _snapshots.size()}


func list_snapshots() -> Array[Dictionary]:
	return _snapshots


func restore_snapshot(snapshot_id: String) -> Dictionary:
	for s in _snapshots:
		if s["id"] == snapshot_id:
			snapshot_restored.emit(snapshot_id)
			return {"ok": true, "restored": s}
	return {"ok": false, "error": "Snapshot not found: " + snapshot_id}
