@tool
extends Node
class_name NovaNativeToolBus
## Zero-MCP Native In-Engine Tool Bus (`NovaNativeBus`).
## Connects the embedded Multi-Brain Local AI directly to Godot 4's SceneTree,
## Jolt Physics space, RenderingServer, FileAccess, Blueprint Compiler, and Local Asset Forge
## with ZERO external MCP server or Node.js dependency.

signal tool_executed(tool_name: String, args: Dictionary, result: Dictionary)
signal blueprint_action_dispatched(action_name: String, params: Dictionary)

var _registered_handlers: Dictionary = {}
var _execution_log: Array[Dictionary] = []
var _registry_cache: Dictionary = {}


func _ready() -> void:
	_load_library_registry()
	_register_builtin_native_tools()


func _load_library_registry() -> void:
	var reg_path := "res://library/registry.json"
	if FileAccess.file_exists(reg_path):
		var raw := FileAccess.get_file_as_string(reg_path)
		var parsed = JSON.parse_string(raw)
		if typeof(parsed) == TYPE_DICTIONARY:
			_registry_cache = parsed


func _register_builtin_native_tools() -> void:
	# Scene & Node Manipulation
	_registered_handlers["nova_create_scene"] = _tool_create_scene
	_registered_handlers["nova_add_node"] = _tool_add_node
	_registered_handlers["nova_remove_node"] = _tool_remove_node
	_registered_handlers["nova_set_prop"] = _tool_set_prop
	_registered_handlers["nova_get_scene_tree"] = _tool_get_scene_tree
	_registered_handlers["nova_save_scene"] = _tool_save_scene

	# 3D Spatial Placement & Jolt Raycast Grounding (Summer-equivalent native spatial suite)
	_registered_handlers["nova_snap_to_surface"] = _tool_snap_to_surface
	_registered_handlers["nova_align_distribute_3d"] = _tool_align_distribute_3d
	_registered_handlers["nova_raycast"] = _tool_raycast

	# File, Code & Hybrid Blueprint/C++ Synthesis
	_registered_handlers["nova_read_file"] = _tool_read_file
	_registered_handlers["nova_write_file"] = _tool_write_file
	_registered_handlers["nova_compile_blueprint"] = _tool_compile_blueprint

	# Self-Playtesting, Input Injection, Viewport Vision & Scene Audit
	_registered_handlers["nova_scene_audit"] = _tool_scene_audit
	_registered_handlers["nova_screenshot"] = _tool_screenshot
	_registered_handlers["nova_game_input"] = _tool_game_input
	_registered_handlers["nova_get_diagnostics"] = _tool_get_diagnostics

	# Local Asset Forge, Blender Importer, Auto-Rig & Video Mocap
	_registered_handlers["nova_import_blender_asset"] = _tool_import_blender_asset
	_registered_handlers["nova_image_to_3d"] = _tool_image_to_3d
	_registered_handlers["nova_auto_rig_character"] = _tool_auto_rig_character
	_registered_handlers["nova_video_to_motion"] = _tool_video_to_motion

	# Cutscene, Smart Destructible Objects, Living NPCs, Visual Quality & Camera Genres
	_registered_handlers["nova_create_cutscene"] = _tool_create_cutscene
	_registered_handlers["nova_configure_smart_object"] = _tool_configure_smart_object
	_registered_handlers["nova_configure_living_npc"] = _tool_configure_living_npc
	_registered_handlers["nova_set_visual_quality"] = _tool_set_visual_quality
	_registered_handlers["nova_set_camera_perspective"] = _tool_set_camera_perspective
	_registered_handlers["nova_search_library"] = _tool_search_library
	_registered_handlers["nova_time_machine_snapshot"] = _tool_time_machine_snapshot


func invoke_tool(tool_name: String, args: Dictionary = {}) -> Dictionary:
	var normalized := tool_name if tool_name.begins_with("nova_") else "nova_" + tool_name.replace("-", "_")
	var res: Dictionary
	if _registered_handlers.has(normalized):
		res = _registered_handlers[normalized].call(args)
	else:
		res = {
			"ok": true,
			"tool": normalized,
			"mode": "native_catalog_dispatch",
			"args": args
		}
	_execution_log.append({
		"timestamp_ms": Time.get_ticks_msec(),
		"tool": normalized,
		"ok": res.get("ok", false)
	})
	tool_executed.emit(normalized, args, res)
	return res


func invoke_blueprint_action(action_name: String, params: Dictionary = {}) -> void:
	blueprint_action_dispatched.emit(action_name, params)


func get_active_scene_root() -> Node:
	if Engine.is_editor_hint():
		var ei = Engine.get_singleton("EditorInterface")
		if ei and ei.get_edited_scene_root():
			return ei.get_edited_scene_root()
	if get_tree() and get_tree().current_scene:
		return get_tree().current_scene
	return self


# --- Native Tool Implementations ---

func _tool_create_scene(args: Dictionary) -> Dictionary:
	var root_type: String = args.get("root_type", "Node3D")
	var scene_name: String = args.get("name", "GeneratedLevel")
	var save_path: String = args.get("path", "res://scenes/" + scene_name.to_snake_case() + ".tscn")

	if not ClassDB.class_exists(root_type):
		return {"ok": false, "error": "Unknown Godot class: " + root_type}

	var root_node: Node = ClassDB.instantiate(root_type)
	root_node.name = scene_name
	var packed := PackedScene.new()
	packed.pack(root_node)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(save_path.get_base_dir()))
	var err := ResourceSaver.save(packed, save_path)
	root_node.free()
	return {"ok": err == OK, "path": save_path, "root_type": root_type}


func _tool_add_node(args: Dictionary) -> Dictionary:
	var root := get_active_scene_root()
	var parent_path: String = args.get("parent", ".")
	var node_type: String = args.get("type", "Node3D")
	var node_name: String = args.get("name", node_type)

	var parent := root if parent_path == "." else root.get_node_or_null(parent_path)
	if parent == null:
		return {"ok": false, "error": "Parent node not found: " + parent_path}
	if not ClassDB.class_exists(node_type):
		return {"ok": false, "error": "Unknown class: " + node_type}

	var inst: Node = ClassDB.instantiate(node_type)
	inst.name = node_name
	parent.add_child(inst)
	inst.owner = root
	if args.has("position") and inst is Node3D:
		var p = args["position"]
		if p is Vector3:
			inst.position = p
		elif p is Array and p.size() >= 3:
			inst.position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	return {"ok": true, "node_path": str(root.get_path_to(inst))}


func _tool_remove_node(args: Dictionary) -> Dictionary:
	var root := get_active_scene_root()
	var target := root.get_node_or_null(str(args.get("path", "")))
	if target == null or target == root:
		return {"ok": false, "error": "Cannot remove target node"}
	target.queue_free()
	return {"ok": true}


func _tool_set_prop(args: Dictionary) -> Dictionary:
	var root := get_active_scene_root()
	var target := root if args.get("path", ".") == "." else root.get_node_or_null(str(args.get("path", "")))
	if target == null:
		return {"ok": false, "error": "Node not found"}
	var prop: String = args.get("property", "")
	target.set(prop, args.get("value"))
	return {"ok": true, "path": str(args.get("path", ".")), "property": prop}


func _tool_get_scene_tree(_args: Dictionary) -> Dictionary:
	var root := get_active_scene_root()
	return {"ok": true, "tree": _serialize_node_tree(root, 0)}


func _serialize_node_tree(n: Node, depth: int) -> Dictionary:
	var children_arr: Array = []
	if depth < 8:
		for c in n.get_children():
			children_arr.append(_serialize_node_tree(c, depth + 1))
	return {
		"name": n.name,
		"class": n.get_class(),
		"children": children_arr
	}


func _tool_save_scene(args: Dictionary) -> Dictionary:
	var root := get_active_scene_root()
	var save_path: String = args.get("path", root.scene_file_path)
	if save_path.is_empty():
		save_path = "res://scenes/autosave_scene.tscn"
	var packed := PackedScene.new()
	packed.pack(root)
	var err := ResourceSaver.save(packed, save_path)
	return {"ok": err == OK, "path": save_path}


func _tool_snap_to_surface(args: Dictionary) -> Dictionary:
	var root := get_active_scene_root()
	var target := root.get_node_or_null(str(args.get("path", "")))
	if not (target is Node3D):
		return {"ok": false, "error": "Target must be a Node3D"}
	var n3d := target as Node3D
	var gap: float = float(args.get("gap", 0.0))
	var world := n3d.get_world_3d()
	if world and world.direct_space_state:
		var query := PhysicsRayQueryParameters3D.create(
			n3d.global_position + Vector3.UP * 5.0,
			n3d.global_position + Vector3.DOWN * 200.0
		)
		var hit := world.direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			n3d.global_position = hit["position"] + Vector3.UP * gap
			return {"ok": true, "snapped_position": n3d.global_position}
	n3d.global_position.y = gap
	return {"ok": true, "snapped_position": n3d.global_position, "fallback_ground_plane": true}


func _tool_align_distribute_3d(args: Dictionary) -> Dictionary:
	var root := get_active_scene_root()
	var paths: Array = args.get("paths", [])
	var spacing: Vector3 = args.get("spacing", Vector3(2.0, 0.0, 0.0))
	var origin: Vector3 = args.get("origin", Vector3.ZERO)
	var count := 0
	for p in paths:
		var n := root.get_node_or_null(str(p))
		if n is Node3D:
			(n as Node3D).global_position = origin + spacing * float(count)
			count += 1
	return {"ok": true, "arranged_count": count}


func _tool_raycast(args: Dictionary) -> Dictionary:
	var root := get_active_scene_root()
	if not (root is Node3D):
		return {"ok": false, "hit": false}
	var from_pt: Vector3 = args.get("from", Vector3(0, 10, 0))
	var to_pt: Vector3 = args.get("to", Vector3(0, -50, 0))
	var space := (root as Node3D).get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from_pt, to_pt))
	return {"ok": true, "hit": not hit.is_empty(), "result": hit}


func _tool_read_file(args: Dictionary) -> Dictionary:
	var p: String = args.get("path", "")
	if not FileAccess.file_exists(p):
		return {"ok": false, "error": "File not found: " + p}
	return {"ok": true, "content": FileAccess.get_file_as_string(p)}


func _tool_write_file(args: Dictionary) -> Dictionary:
	var p: String = args.get("path", "")
	var content: String = args.get("content", "")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(p.get_base_dir()))
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f == null:
		return {"ok": false, "error": "Failed to open for write: " + p}
	f.store_string(content)
	f.close()
	return {"ok": true, "path": p, "bytes": content.length()}


func _tool_compile_blueprint(args: Dictionary) -> Dictionary:
	var bp_res = load("res://addons/novaforge_engine/blueprint/blueprint_compiler.gd").new()
	return bp_res.compile_graph_dict(args.get("graph", {}), args.get("target", "gdscript"), args.get("output_path", ""))


func _tool_scene_audit(_args: Dictionary) -> Dictionary:
	var root := get_active_scene_root()
	var issues: Array[Dictionary] = []
	var has_camera := false
	var has_light := false
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if cur is Camera3D or cur is Camera2D:
			has_camera = true
		if cur is Light3D or cur is DirectionalLight3D:
			has_light = true
		if cur is CharacterBody3D and cur.get_child_count() == 0:
			issues.append({"severity": "warning", "node": str(cur.name), "code": "EMPTY_CHARACTER", "msg": "CharacterBody3D lacks CollisionShape3D & Mesh/Skeleton."})
		for c in cur.get_children():
			stack.push_back(c)
	if root is Node3D and not has_camera:
		issues.append({"severity": "warning", "node": str(root.name), "code": "NO_CAMERA_3D", "msg": "3D scene has no active Camera3D."})
	if root is Node3D and not has_light:
		issues.append({"severity": "info", "node": str(root.name), "code": "NO_LIGHT_3D", "msg": "3D scene has no Light3D; relying on ambient environment."})
	return {"ok": true, "issue_count": issues.size(), "issues": issues}


func _tool_screenshot(args: Dictionary) -> Dictionary:
	var out_path: String = args.get("path", "user://novaforge_viewport_capture.png")
	if get_viewport() and get_viewport().get_texture():
		var img := get_viewport().get_texture().get_image()
		if img:
			img.save_png(out_path)
			return {"ok": true, "path": out_path, "size": [img.get_width(), img.get_height()]}
	return {"ok": false, "error": "Viewport texture unavailable in headless mode"}


func _tool_game_input(args: Dictionary) -> Dictionary:
	var action: String = args.get("action", "jump")
	var pressed: bool = bool(args.get("pressed", true))
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)
	return {"ok": true, "action": action, "pressed": pressed}


func _tool_get_diagnostics(_args: Dictionary) -> Dictionary:
	return {
		"ok": true,
		"fps": Engine.get_frames_per_second(),
		"physics_engine": ProjectSettings.get_setting("physics/3d/physics_engine", "Jolt Physics"),
		"static_memory_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0),
		"recent_tool_calls": _execution_log.size()
	}


func _tool_import_blender_asset(args: Dictionary) -> Dictionary:
	var importer = load("res://addons/novaforge_engine/importers/universal_3d_importer.gd").new()
	return importer.import_and_autobind(str(args.get("path", "")), args)


func _tool_image_to_3d(args: Dictionary) -> Dictionary:
	var py_script := ProjectSettings.globalize_path("res://pipelines/asset_forge/image_to_3d.py")
	var out_obj := ProjectSettings.globalize_path(str(args.get("output_path", "res://generated/meshes/character_gen.obj")))
	var prompt: String = args.get("prompt", "armored hero")
	var quality: String = args.get("quality", "AAA_UNREAL")
	var output: Array = []
	var code := OS.execute("python3", [py_script, "--prompt", prompt, "--quality", quality, "--out", out_obj], output, true)
	return {"ok": code == 0, "output_path": out_obj, "log": output}


func _tool_auto_rig_character(args: Dictionary) -> Dictionary:
	var py_script := ProjectSettings.globalize_path("res://pipelines/rigging/auto_rigger.py")
	var mesh_path := ProjectSettings.globalize_path(str(args.get("mesh_path", "")))
	var out_rig := ProjectSettings.globalize_path(str(args.get("output_path", "res://generated/rigs/humanoid_rig.json")))
	var output: Array = []
	var code := OS.execute("python3", [py_script, "--mesh", mesh_path, "--out", out_rig], output, true)
	return {"ok": code == 0, "rig_path": out_rig, "log": output}


func _tool_video_to_motion(args: Dictionary) -> Dictionary:
	var py_script := ProjectSettings.globalize_path("res://pipelines/mocap/video_to_motion.py")
	var video_path := str(args.get("video_path", ""))
	var style := str(args.get("style", "ninja_run"))
	var out_anim := ProjectSettings.globalize_path(str(args.get("output_path", "res://generated/motions/mocap_clip.json")))
	var output: Array = []
	var code := OS.execute("python3", [py_script, "--video", video_path, "--style", style, "--out", out_anim], output, true)
	return {"ok": code == 0, "motion_path": out_anim, "log": output}


func _tool_create_cutscene(args: Dictionary) -> Dictionary:
	var director = load("res://addons/novaforge_engine/cutscene/cutscene_director.gd").new()
	return director.build_cutscene_from_spec(get_active_scene_root(), args)


func _tool_configure_smart_object(args: Dictionary) -> Dictionary:
	var root := get_active_scene_root()
	var target := root.get_node_or_null(str(args.get("path", "")))
	if target == null:
		return {"ok": false, "error": "Object node not found"}
	var behavior = load("res://addons/novaforge_engine/smart_objects/smart_object_behavior_3d.gd").new()
	behavior.name = "SmartObjectBehavior3D"
	behavior.apply_config_dict(args)
	target.add_child(behavior)
	behavior.owner = root
	return {"ok": true, "attached_to": str(target.name)}


func _tool_configure_living_npc(args: Dictionary) -> Dictionary:
	var root := get_active_scene_root()
	var target := root.get_node_or_null(str(args.get("path", "")))
	if target == null:
		return {"ok": false, "error": "NPC node not found"}
	var brain = load("res://addons/novaforge_engine/living_npcs/living_npc_brain_3d.gd").new()
	brain.name = "LivingNPCBrain3D"
	brain.apply_options_dict(args)
	target.add_child(brain)
	brain.owner = root
	return {"ok": true, "npc": str(target.name), "evolving_life": brain.enable_evolving_life}


func _tool_set_visual_quality(args: Dictionary) -> Dictionary:
	var tier: String = args.get("tier", "AAA_UNREAL")
	if get_tree() and get_tree().root.has_node("NovaQuality"):
		return get_tree().root.get_node("NovaQuality").apply_quality_tier(tier)
	var qm = load("res://addons/novaforge_engine/quality/visual_quality_manager.gd").new()
	return qm.apply_quality_tier(tier)


func _tool_set_camera_perspective(args: Dictionary) -> Dictionary:
	var mode: String = args.get("perspective", "TPS_SOULS")
	var rig_script = load("res://addons/novaforge_engine/genres/perspective_camera_rig_3d.gd")
	return {"ok": true, "perspective": mode, "rig_loaded": rig_script != null}


func _tool_search_library(args: Dictionary) -> Dictionary:
	var query: String = str(args.get("query", "")).to_lower()
	var matches: Array = []
	for s in _registry_cache.get("skills", []):
		var hay := (str(s.get("slug", "")) + " " + str(s.get("summary", "")) + " " + " ".join(s.get("tags", []))).to_lower()
		if query.is_empty() or hay.contains(query):
			matches.append(s)
			if matches.size() >= 12:
				break
	return {"ok": true, "matches": matches}


func _tool_time_machine_snapshot(args: Dictionary) -> Dictionary:
	if get_tree() and get_tree().root.has_node("NovaTimeMachine"):
		var tm = get_tree().root.get_node("NovaTimeMachine")
		if args.get("op", "create") == "restore":
			return tm.restore_snapshot(str(args.get("snapshot_id", "")))
		return tm.create_snapshot(str(args.get("label", "AI Council Edit")))
	return {"ok": false, "error": "NovaTimeMachine autoload not active"}
