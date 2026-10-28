@tool
extends EditorPlugin
## Main Godot 4 EditorPlugin for NovaForge AI Game Engine.
## Preserves 100% of Godot 4's native Editor UI (Scene, FileSystem, 2D/3D/Script/AssetLib, Inspector, Output/Debugger/Animation)
## while cleanly mounting modular NovaForge extensions into Godot 4's official extension slots:
## 1. 3D Viewport Toolbar (`CONTAINER_SPATIAL_EDITOR_MENU`): Quality Tier, Camera/Genre, Cutscene & Time-Machine buttons
## 2. Native Inspector (`EditorInspectorPlugin`): Smart Object, Voronoi Fracture, Living NPC & Auto-PBR checkboxes on any Node3D
## 3. Right Dock Tab (`DOCK_SLOT_RIGHT_BL` beside Inspector/Node/History): Multi-Brain AI Council Prompt Assistant
## 4. Bottom Panel Tabs (beside Output/Debugger/Animation/Shader Editor):
##    - `Blueprint Graph` (Visual `GraphEdit` + C++20/GDScript compiler)
##    - `Cutscene & IK` (Pose/IK, Bezier Curves, NLA & Live Cutscene Sequencer)
##    - `Local AI (Colibrì)` (Tiered VRAM/RAM/SSD Model Hub + 3D/Rig/Mocap Forge)
## 5. 3D Viewport Alt+Left-Click Raycast Context Popup Menu

var _ai_council_dock: Control
var _spatial_toolbar: Control
var _blueprint_panel: Control
var _cutscene_panel: Control
var _colibri_panel: Control
var _inspector_plugin: EditorInspectorPlugin
var _context_popup: PopupMenu
var _last_clicked_3d_node: Node3D


func _enter_tree() -> void:
	# 1. Right Dock Tab (next to Inspector / Node / History)
	var dock_script = load("res://addons/novaforge_engine/editor/novaforge_main_dock.gd")
	if dock_script:
		_ai_council_dock = dock_script.new()
		_ai_council_dock.name = "AI Council"
		add_control_to_dock(DOCK_SLOT_RIGHT_BL, _ai_council_dock)

	# 2. Native 3D Viewport Top Toolbar
	var tb_script = load("res://addons/novaforge_engine/editor/spatial_viewport_toolbar.gd")
	if tb_script:
		_spatial_toolbar = tb_script.new()
		add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, _spatial_toolbar)

	# 3. Native Godot 4 Inspector Extension
	var insp_script = load("res://addons/novaforge_engine/editor/smart_inspector_plugin.gd")
	if insp_script:
		_inspector_plugin = insp_script.new()
		add_inspector_plugin(_inspector_plugin)

	# 4. Native Bottom Panel Modules (alongside Output / Debugger / Animation / Shader Editor)
	var bp_script = load("res://addons/novaforge_engine/editor/blueprint_graph_editor.gd")
	if bp_script:
		_blueprint_panel = bp_script.new()
		add_control_to_bottom_panel(_blueprint_panel, "Blueprint Graph")

	var cs_script = load("res://addons/novaforge_engine/editor/cutscene_sequencer_panel.gd")
	if cs_script:
		_cutscene_panel = cs_script.new()
		add_control_to_bottom_panel(_cutscene_panel, "Cutscene & IK")

	var col_script = load("res://addons/novaforge_engine/editor/colibri_model_manager_panel.gd")
	if col_script:
		_colibri_panel = col_script.new()
		add_control_to_bottom_panel(_colibri_panel, "Local AI (Colibrì)")

	# 5. Viewport Alt+Click Smart Context Popup
	_build_3d_context_popup()


func _exit_tree() -> void:
	if _ai_council_dock:
		remove_control_from_docks(_ai_council_dock)
		_ai_council_dock.queue_free()
	if _spatial_toolbar:
		remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, _spatial_toolbar)
		_spatial_toolbar.queue_free()
	if _inspector_plugin:
		remove_inspector_plugin(_inspector_plugin)
	if _blueprint_panel:
		remove_control_from_bottom_panel(_blueprint_panel)
		_blueprint_panel.queue_free()
	if _cutscene_panel:
		remove_control_from_bottom_panel(_cutscene_panel)
		_cutscene_panel.queue_free()
	if _colibri_panel:
		remove_control_from_bottom_panel(_colibri_panel)
		_colibri_panel.queue_free()
	if _context_popup:
		_context_popup.queue_free()


func _handles(object: Object) -> bool:
	return object is Node3D


func _build_3d_context_popup() -> void:
	_context_popup = PopupMenu.new()
	_context_popup.name = "NovaSmartObjectPopup"
	_context_popup.add_item("⚡ Interactable (Auto-Hinge Door / Chest / Pickup)", 1)
	_context_popup.add_item("💥 Destructible with Weapon (Voronoi 3D Fracture)", 2)
	_context_popup.add_item("🧠 Living NPC (Evolving Life & Nemesis AI)", 3)
	_context_popup.add_item("🎬 Mark Live Cutscene Zone (این تیکه کات‌سینه)", 4)
	_context_popup.id_pressed.connect(_on_context_menu_id_pressed)
	add_child(_context_popup)


func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and mb.alt_pressed:
			var from := viewport_camera.project_ray_origin(mb.position)
			var to := from + viewport_camera.project_ray_normal(mb.position) * 500.0
			var hit := viewport_camera.get_world_3d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters3D.create(from, to)
			)
			if not hit.is_empty() and hit.get("collider") is Node3D:
				_last_clicked_3d_node = hit["collider"]
				_context_popup.position = Vector2i(DisplayServer.mouse_get_position())
				_context_popup.popup()
				return EditorPlugin.AFTER_GUI_INPUT_STOP
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _on_context_menu_id_pressed(id: int) -> void:
	if _last_clicked_3d_node == null or not is_instance_valid(_last_clicked_3d_node):
		return
	var bus = get_tree().root.get_node_or_null("NovaNativeBus")
	if bus == null:
		return
	var rel_path := str(bus.get_active_scene_root().get_path_to(_last_clicked_3d_node))
	match id:
		1:
			bus.invoke_tool("nova_configure_smart_object", {"path": rel_path, "interactable": true, "destructible": false})
		2:
			bus.invoke_tool("nova_configure_smart_object", {"path": rel_path, "destructible": true, "shard_count": 16, "material": "STONE"})
		3:
			bus.invoke_tool("nova_configure_living_npc", {"path": rel_path, "enable_evolving_life": true})
		4:
			bus.invoke_tool("nova_create_cutscene", {"prompt": "این تیکه کات‌سینه", "seamless_blend": true})
