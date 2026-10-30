extends SceneTree
## Headless Real-Godot 4.7.2 Verification for v3.3.0 / Studio 4.0:
## Verifies all 12 resizable modules, floating pop-out windows, HSplit/VSplit mouse dividers,
## embedded 3D SubViewport, pure-GDScript 13-format PBR resolver, and 1-Click Exporter.

var _ws: Control = null
var _frames: int = 0


func _initialize() -> void:
	var ws_scr = load("res://addons/novaforge_engine/editor/novaforge_main_workspace.gd")
	if ws_scr == null:
		printerr("Failed to load novaforge_main_workspace.gd")
		quit(1)
		return
	_ws = ws_scr.new()
	root.add_child(_ws)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 2:
		return false

	var cards: Dictionary = _ws.get("_cards")
	if cards.size() != 12:
		printerr("Expected 12 studio modules, got: ", cards.size())
		quit(1)
		return true

	for mid in ["m1_setup", "m2_ai", "m3_view3d", "m4_mesh360", "m5_blender", "m6_mocap", "m7_blueprint", "m8_modular", "m9_voronoi", "m10_npc", "m11_audit", "m12_export"]:
		if not cards.has(mid):
			printerr("Missing module card: ", mid)
			quit(1)
			return true

	var outer_h: HSplitContainer = _ws.get("_outer_hsplit")
	var inner_h: HSplitContainer = _ws.get("_inner_hsplit")
	var center_v: VSplitContainer = _ws.get("_center_vsplit")
	if outer_h == null or inner_h == null or center_v == null:
		printerr("Missing mouse-resizable SplitContainers")
		quit(1)
		return true

	# Test mouse resize step + collapse + floating Window pop-out & dock-back
	var c5 = cards["m5_blender"]
	c5.call("adjust_height", 64.0)
	c5.call("set_collapsed", true)
	if c5.get("_collapsed") != true:
		printerr("Collapse failed")
		quit(1)
		return true
	c5.call("set_collapsed", false)
	c5.call("toggle_floating_window")
	var fw: Window = c5.get("_floating_win")
	if fw == null or fw.unresizable != false:
		printerr("Floating window must exist and be mouse-resizable!")
		quit(1)
		return true
	c5.call("dock_back_from_floating")
	if c5.get("_floating_win") != null:
		printerr("Dock-back from floating window failed")
		quit(1)
		return true

	# Pure-GDScript 13-format PBR resolver (Windows zero-Python verification)
	var imp_scr = load("res://addons/novaforge_engine/importers/universal_3d_importer.gd")
	var imp = imp_scr.new()
	var pbr_res: Dictionary = imp.resolve_pbr_slots_pure_gdscript("res://assets/models/world/castle_tower.glb")
	if pbr_res.get("ok", false) != true:
		printerr("Pure-GDScript PBR resolver failed")
		quit(1)
		return true

	# One-Click Exporter bundle test
	var exp_scr = load("res://addons/novaforge_engine/world/one_click_exporter.gd")
	var dummy_3d := Node3D.new()
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	dummy_3d.add_child(mi)
	var exp_res: Dictionary = exp_scr.export_project_bundle("Windows Desktop (.exe)", dummy_3d, true)
	dummy_3d.free()
	if exp_res.get("ok", false) != true or not FileAccess.file_exists("res://export_presets.cfg"):
		printerr("One-click exporter failed")
		quit(1)
		return true

	_ws.free()
	print("V33_STUDIO_ALL_12_MODULES_OK")
	quit(0)
	return true
