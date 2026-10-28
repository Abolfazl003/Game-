@tool
extends HBoxContainer
class_name NovaSpatialViewportToolbar
## Native Godot 4 3D Viewport Top-Bar Extension (`CONTAINER_SPATIAL_EDITOR_MENU`).
## Sits directly inside Godot 4's 3D Viewport toolbar (right next to Transform / Snap / View / Perspective)
## so the editor stays 100% standard Godot 4 with quick modular controls!

var _quality_btn: OptionButton
var _cam_btn: OptionButton


func _ready() -> void:
	add_theme_constant_override("separation", 6)

	var sep := VSeparator.new()
	add_child(sep)

	var badge := Label.new()
	badge.text = "⚡ NovaForge:"
	add_child(badge)

	_quality_btn = OptionButton.new()
	_quality_btn.tooltip_text = "Switch Visual Quality Tier (AAA Unreal / Unity / Indie)"
	for t in ["AAA_UNREAL", "STANDARD_UNITY", "INDIE_CEL_ANIME", "INDIE_LOWPOLY_COZY", "INDIE_HD2D", "INDIE_PSX_RETRO"]:
		_quality_btn.add_item(t)
	_quality_btn.item_selected.connect(_on_quality_changed)
	add_child(_quality_btn)

	_cam_btn = OptionButton.new()
	_cam_btn.tooltip_text = "Switch Camera & Genre Perspective"
	for c in ["TPS_SOULS", "TPS_SHOULDER", "FPS", "SIDE_2_5D", "HD_2D", "ISOMETRIC", "PURE_2D", "FIXED_CINEMATIC"]:
		_cam_btn.add_item(c)
	_cam_btn.item_selected.connect(_on_cam_changed)
	add_child(_cam_btn)

	var btn_cutscene := Button.new()
	btn_cutscene.text = "🎬 Cutscene Here"
	btn_cutscene.tooltip_text = "Mark current camera/zone as a Live In-Engine Cutscene"
	btn_cutscene.pressed.connect(_on_mark_cutscene)
	add_child(btn_cutscene)

	var btn_undo := Button.new()
	btn_undo.text = "⏪ Time-Machine"
	btn_undo.tooltip_text = "Create or rewind project snapshot"
	btn_undo.pressed.connect(_on_snapshot)
	add_child(btn_undo)


func _on_quality_changed(idx: int) -> void:
	var tier := _quality_btn.get_item_text(idx)
	if get_tree() and get_tree().root.has_node("NovaQuality"):
		get_tree().root.get_node("NovaQuality").apply_quality_tier(tier)


func _on_cam_changed(idx: int) -> void:
	var mode := _cam_btn.get_item_text(idx)
	if get_tree() and get_tree().root.has_node("NovaNativeBus"):
		get_tree().root.get_node("NovaNativeBus").invoke_tool("nova_set_camera_perspective", {"perspective": mode})


func _on_mark_cutscene() -> void:
	if get_tree() and get_tree().root.has_node("NovaNativeBus"):
		get_tree().root.get_node("NovaNativeBus").invoke_tool("nova_create_cutscene", {"prompt": "این تیکه کات‌سینه", "seamless_blend": true})


func _on_snapshot() -> void:
	if get_tree() and get_tree().root.has_node("NovaNativeBus"):
		get_tree().root.get_node("NovaNativeBus").invoke_tool("nova_time_machine_snapshot", {"op": "create", "label": "3D Toolbar Checkpoint"})
