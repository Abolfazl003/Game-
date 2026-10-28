@tool
extends EditorPlugin
## Main Godot 4 EditorPlugin for NovaForge AI Game Engine.
## Mounts the Multi-Brain AI Studio Dock AND hooks `_forward_3d_gui_input` so clicking
## any 3D object or NPC in the viewport opens the Smart Context Action Menu!

var _studio_dock: Control
var _context_popup: PopupMenu
var _last_clicked_3d_node: Node3D


func _enter_tree() -> void:
	var dock_script = load("res://addons/novaforge_engine/editor/novaforge_main_dock.gd")
	if dock_script:
		_studio_dock = dock_script.new()
		_studio_dock.name = "NovaForge AI Studio"
		add_control_to_dock(DOCK_SLOT_RIGHT_UL, _studio_dock)

	_build_3d_context_popup()


func _exit_tree() -> void:
	if _studio_dock:
		remove_control_from_docks(_studio_dock)
		_studio_dock.queue_free()
	if _context_popup:
		_context_popup.queue_free()


func _handles(object: Object) -> bool:
	return object is Node3D


func _build_3d_context_popup() -> void:
	_context_popup = PopupMenu.new()
	_context_popup.name = "NovaSmartObjectPopup"
	_context_popup.add_item("⚡ تبدیل به آبجکت قابل تعامل (در/صندوق/آیتم)", 1)
	_context_popup.add_item("💥 فعال‌سازی تخریب با سلاح (Voronoi 3D Fracture)", 2)
	_context_popup.add_item("🧠 تبدیل به NPC زنده با زندگی پیش‌رونده (Evolving Life AI)", 3)
	_context_popup.add_item("🎬 تعریف به عنوان نقطه شروع کات‌سین (این تیکه کات‌سینه)", 4)
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
