@tool
extends EditorPlugin
## Main Godot 4 EditorPlugin for NovaForge AI Game Engine.
## Preserves 100% of Godot 4's native Editor UI while mounting all interactive NovaForge Studio panels:
## - `NovaEditorController` live scene & viewport orchestrator
## - Right-Upper Dock (`🧬 NPC و شیمی`): Living NPC Biography, Elemental Chemistry (Clear/Rain/Fire/Lightning), Smart Voronoi Object controls & Blueprint Summary
## - Right-Lower Dock (`🧠 شورا و ساخت`): 5-Brain Colibrì Council + VRAM Meter + Persian Prompt-to-Scene + 2x2 Image-to-3D/Auto-Rig/Video-Mocap/Blender/Cutscene Forge
## - 3D Spatial Viewport Toolbar: Quality Tier, Camera/Genre, +5 World Days, Voronoi Shatter, Live Cutscene & Time-Machine Undo
## - Bottom Panel Tabs: `NovaForge Console`, `Blueprint Graph`, `Cutscene & IK`, `Local AI (Colibrì)`
## - 3D Viewport `Alt + Left-Click` Smart Context PopupMenu

var _editor_controller: Node
var _living_world_dock: Control
var _ai_council_dock: Control
var _spatial_toolbar: Control
var _console_panel: Control
var _blueprint_panel: Control
var _cutscene_panel: Control
var _colibri_panel: Control
var _inspector_plugin: EditorInspectorPlugin
var _context_popup: PopupMenu
var _last_clicked_3d_node: Node3D


func _enter_tree() -> void:
	# 0. Central Live Scene & Viewport Controller
	var ctrl_script = load("res://addons/novaforge_engine/editor/editor_scene_controller.gd")
	if ctrl_script:
		_editor_controller = ctrl_script.new()
		_editor_controller.name = "NovaEditorController"
		get_tree().root.call_deferred("add_child", _editor_controller)

	# 1. Right-Bottom Unified NovaForge Studio Dock (`⚡ استودیو NovaForge`)
	var dock_script = load("res://addons/novaforge_engine/editor/novaforge_main_dock.gd")
	if dock_script:
		_ai_council_dock = dock_script.new()
		_ai_council_dock.name = "⚡ استودیو NovaForge"
		add_control_to_dock(DOCK_SLOT_RIGHT_BL, _ai_council_dock)

	# 2. Dedicated Living World & Chemistry Dock Tab beside FileSystem (`🧬 NPC و شیمی`)
	var lw_script = load("res://addons/novaforge_engine/editor/living_world_dock.gd")
	if lw_script:
		_living_world_dock = lw_script.new()
		_living_world_dock.name = "🧬 NPC و شیمی"
		add_control_to_dock(DOCK_SLOT_LEFT_BR, _living_world_dock)

	# 3. Native 3D Viewport Top Toolbar
	var tb_script = load("res://addons/novaforge_engine/editor/spatial_viewport_toolbar.gd")
	if tb_script:
		_spatial_toolbar = tb_script.new()
		add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, _spatial_toolbar)

	# 4. Native Godot 4 Inspector Extension
	var insp_script = load("res://addons/novaforge_engine/editor/smart_inspector_plugin.gd")
	if insp_script:
		_inspector_plugin = insp_script.new()
		add_inspector_plugin(_inspector_plugin)

	# 5. Native Bottom Panel Modules
	var con_script = load("res://addons/novaforge_engine/editor/novaforge_console_panel.gd")
	if con_script:
		_console_panel = con_script.new()
		add_control_to_bottom_panel(_console_panel, "NovaForge Console")

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

	# 6. Viewport Alt+Click Smart Context Popup
	_build_3d_context_popup()

	# Focus the Living World dock tab and open Hybrid Console cleanly after layout loads
	call_deferred("_focus_novaforge_panels")


func _focus_novaforge_panels() -> void:
	if _living_world_dock and _living_world_dock.get_parent() is TabContainer:
		var tc := _living_world_dock.get_parent() as TabContainer
		tc.current_tab = _living_world_dock.get_index()
	if _console_panel:
		make_bottom_panel_item_visible(_console_panel)


func _exit_tree() -> void:
	if _living_world_dock:
		remove_control_from_docks(_living_world_dock)
		_living_world_dock.queue_free()
	if _ai_council_dock:
		remove_control_from_docks(_ai_council_dock)
		_ai_council_dock.queue_free()
	if _spatial_toolbar:
		remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, _spatial_toolbar)
		_spatial_toolbar.queue_free()
	if _inspector_plugin:
		remove_inspector_plugin(_inspector_plugin)
	if _console_panel:
		remove_control_from_bottom_panel(_console_panel)
		_console_panel.queue_free()
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
	if _editor_controller and is_instance_valid(_editor_controller):
		_editor_controller.queue_free()


func _handles(object: Object) -> bool:
	return object is Node3D


func _build_3d_context_popup() -> void:
	_context_popup = PopupMenu.new()
	_context_popup.name = "NovaSmartObjectPopup"
	_context_popup.add_item("💥 تست ضربه شمشیر / تخریب یا بازسازی Voronoi", 1)
	_context_popup.add_item("🤝 تعامل دوستانه و خرید از NPC (+رابطه)", 2)
	_context_popup.add_item("⚔️ درگیری با NPC و فعال‌سازی حافظه Nemesis", 3)
	_context_popup.add_item("🎬 اجرای کات‌سین زنده در همین نقطه (این تیکه کات‌سینه)", 4)
	_context_popup.add_item("🌧️ فعال‌سازی باران و شیمی سطح خیس", 5)
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
	if _editor_controller == null or not is_instance_valid(_editor_controller):
		return
	var ctrl := _editor_controller as NovaEditorSceneController
	match id:
		1:
			ctrl.shatter_or_reset_crate()
		2:
			ctrl.help_npc()
		3:
			ctrl.fight_npc()
		4:
			ctrl.trigger_live_cutscene()
		5:
			ctrl.apply_elemental_weather("RAIN")
