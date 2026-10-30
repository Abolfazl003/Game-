@tool
extends EditorPlugin
## Main Godot 4.7 EditorPlugin for NovaForge AI Game Engine (100% Customized Persian Edition & Cold-Boot Safe).
## Applies NovaForge's custom Midnight-Cyan theme, Vazirmatn Persian font, and Persian (`fa`) Editor UI,
## and mounts:
## - Main Center Workspace (`⚡ میزکار نوافورج`) alongside 2D / 3D / Script
## - Right Dock (`⚡ استودیو هوش مصنوعی`)
## - Left Dock (`✦ جهان زنده و شیمی`)
## - 3D Spatial Viewport Toolbar (`⚡ نوافورج`)
## - Native Inspector Plugin (`⚡ ماژول هوشمند نوافورج`)
## - 4 Persian Bottom Panels (`کنسول خروجی نوافورج`, `گراف دیداری بلوپرینت`, `کارگردان کات‌سین و IK`, `مدل‌های لوکال Colibrì`)

var _editor_controller: Node
var _main_workspace: Control
var _living_world_dock: Control
var _ai_council_dock: Control
var _spatial_toolbar: Control
var _console_panel: Control
var _image_rig_panel: Control
var _blueprint_panel: Control
var _cutscene_panel: Control
var _colibri_panel: Control
var _inspector_plugin: EditorInspectorPlugin
var _context_popup: PopupMenu


func _has_main_screen() -> bool:
	return true


func _get_plugin_name() -> String:
	return "⚡ میزکار نوافورج"


func _get_plugin_icon() -> Texture2D:
	if Engine.is_editor_hint():
		var base := EditorInterface.get_base_control()
		if base:
			return base.get_theme_icon("Node", "EditorIcons")
	return null


func _make_visible(visible: bool) -> void:
	if _main_workspace:
		_main_workspace.visible = visible


func _enter_tree() -> void:
	_apply_novaforge_persian_theme_and_fonts()

	# 0. Central Live Scene & Viewport Controller
	var ctrl_script = load("res://addons/novaforge_engine/editor/editor_scene_controller.gd")
	if ctrl_script:
		_editor_controller = ctrl_script.new()
		_editor_controller.name = "NovaEditorController"
		get_tree().root.call_deferred("add_child", _editor_controller)

	# 1. Center Full-Screen Main Workspace (`⚡ میزکار نوافورج`)
	var ws_script = load("res://addons/novaforge_engine/editor/novaforge_main_workspace.gd")
	if ws_script and Engine.is_editor_hint():
		_main_workspace = ws_script.new()
		_main_workspace.name = "NovaForgeMainWorkspace"
		EditorInterface.get_editor_main_screen().add_child(_main_workspace)
		_make_visible(false)

	# 2. Right-Bottom Unified NovaForge Studio Dock (`⚡ استودیو هوش مصنوعی`)
	var dock_script = load("res://addons/novaforge_engine/editor/novaforge_main_dock.gd")
	if dock_script:
		_ai_council_dock = dock_script.new()
		_ai_council_dock.name = "⚡ استودیو هوش مصنوعی"
		add_control_to_dock(DOCK_SLOT_RIGHT_BL, _ai_council_dock)

	# 3. Left-Bottom Living World & Chemistry Dock (`✦ جهان زنده و شیمی`)
	var lw_script = load("res://addons/novaforge_engine/editor/living_world_dock.gd")
	if lw_script:
		_living_world_dock = lw_script.new()
		_living_world_dock.name = "✦ جهان زنده و شیمی"
		add_control_to_dock(DOCK_SLOT_LEFT_BR, _living_world_dock)

	# 4. Native 3D Viewport Top Toolbar
	var tb_script = load("res://addons/novaforge_engine/editor/spatial_viewport_toolbar.gd")
	if tb_script:
		_spatial_toolbar = tb_script.new()
		add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, _spatial_toolbar)

	# 5. Native Godot 4 Inspector Extension
	var insp_script = load("res://addons/novaforge_engine/editor/smart_inspector_plugin.gd")
	if insp_script:
		_inspector_plugin = insp_script.new()
		add_inspector_plugin(_inspector_plugin)

	# 6. Native Bottom Panel Modules (100% Persian)
	var ir_script = load("res://addons/novaforge_engine/editor/image_to_mesh_rig_panel.gd")
	if ir_script:
		_image_rig_panel = ir_script.new()
		add_control_to_bottom_panel(_image_rig_panel, "◆ عکس به مش 3D و ریگ خودکار")

	var con_script = load("res://addons/novaforge_engine/editor/novaforge_console_panel.gd")
	if con_script:
		_console_panel = con_script.new()
		add_control_to_bottom_panel(_console_panel, "کنسول خروجی نوافورج")

	var bp_script = load("res://addons/novaforge_engine/editor/blueprint_graph_editor.gd")
	if bp_script:
		_blueprint_panel = bp_script.new()
		add_control_to_bottom_panel(_blueprint_panel, "گراف دیداری بلوپرینت")

	var cs_script = load("res://addons/novaforge_engine/editor/cutscene_sequencer_panel.gd")
	if cs_script:
		_cutscene_panel = cs_script.new()
		add_control_to_bottom_panel(_cutscene_panel, "کارگردان کات‌سین و IK")

	var col_script = load("res://addons/novaforge_engine/editor/colibri_model_manager_panel.gd")
	if col_script:
		_colibri_panel = col_script.new()
		add_control_to_bottom_panel(_colibri_panel, "مدل‌های لوکال (Colibrì)")

	# 7. Viewport Alt+Click Smart Context Popup
	_build_3d_context_popup()
	call_deferred("_focus_novaforge_panels")


func _apply_novaforge_persian_theme_and_fonts() -> void:
	OS.low_processor_usage_mode = false
	if not Engine.is_editor_hint():
		return
	var es := EditorInterface.get_editor_settings()
	if es == null:
		return

	es.set_setting("interface/editor/update_continuously", true)

	var reg_font := ProjectSettings.globalize_path("res://fonts/Vazirmatn-Regular.ttf")
	var bold_font := ProjectSettings.globalize_path("res://fonts/Vazirmatn-Bold.ttf")

	if FileAccess.file_exists("res://fonts/Vazirmatn-Regular.ttf"):
		es.set_setting("interface/editor/fonts/main_font", reg_font)
	if FileAccess.file_exists("res://fonts/Vazirmatn-Bold.ttf"):
		es.set_setting("interface/editor/fonts/main_font_bold", bold_font)

	es.set_setting("interface/editor/localization/editor_language", "fa")
	es.set_setting("interface/theme/color_preset", "Custom")
	es.set_setting("interface/theme/base_color", Color(0.085, 0.11, 0.175, 1.0))
	es.set_setting("interface/theme/accent_color", Color(0.22, 0.78, 0.98, 1.0))
	es.set_setting("interface/theme/contrast", 0.28)
	es.set_setting("interface/theme/corner_radius", 6)
	es.set_setting("interface/theme/border_size", 1)
	es.set_setting("interface/theme/draw_extra_borders", true)
	if Engine.is_editor_hint():
		Engine.max_fps = 30


func _focus_novaforge_panels() -> void:
	if _console_panel:
		make_bottom_panel_item_visible(_console_panel)
	if Engine.is_editor_hint():
		EditorInterface.set_main_screen_editor("⚡ میزکار نوافورج")


func _exit_tree() -> void:
	if _main_workspace:
		_main_workspace.queue_free()
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
	if _image_rig_panel:
		remove_control_from_bottom_panel(_image_rig_panel)
		_image_rig_panel.queue_free()
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
	_context_popup.add_item("★ تست ضربه شمشیر / تخریب یا بازسازی Voronoi", 1)
	_context_popup.add_item("✦ تعامل دوستانه و خرید از NPC (+رابطه)", 2)
	_context_popup.add_item("⚔ درگیری با NPC و فعال‌سازی حافظه Nemesis", 3)
	_context_popup.add_item("▶ اجرای کات‌سین زنده در همین نقطه (این تیکه کات‌سینه)", 4)
	_context_popup.add_item("◈ فعال‌سازی باران و شیمی سطح خیس", 5)
	_context_popup.id_pressed.connect(_on_context_menu_id_pressed)
	add_child(_context_popup)


func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and mb.alt_pressed:
			_context_popup.position = Vector2i(DisplayServer.mouse_get_position())
			_context_popup.popup()
			return EditorPlugin.AFTER_GUI_INPUT_STOP
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _on_context_menu_id_pressed(id: int) -> void:
	if _editor_controller == null or not is_instance_valid(_editor_controller):
		return
	match id:
		1: _editor_controller.call("shatter_or_reset_crate")
		2: _editor_controller.call("help_npc")
		3: _editor_controller.call("fight_npc")
		4: _editor_controller.call("trigger_live_cutscene")
		5: _editor_controller.call("apply_elemental_weather", "RAIN")
