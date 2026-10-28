@tool
extends HBoxContainer
class_name NovaSpatialViewportToolbar
## Native Godot 4 3D Viewport Top-Bar Extension (`CONTAINER_SPATIAL_EDITOR_MENU`).
## Provides instant 1-click access inside Godot 4's 3D Viewport toolbar to:
## Quality Tier, Camera/Genre Perspective, +5 World Days, Voronoi Shatter Test, Live Cutscene, and Time-Machine Undo.

var _quality_btn: OptionButton
var _cam_btn: OptionButton
var _day_btn: Button


func _ready() -> void:
	add_theme_constant_override("separation", 5)

	var sep := VSeparator.new()
	add_child(sep)

	var badge := Label.new()
	badge.text = "⚡ NovaForge:"
	add_child(badge)

	_quality_btn = OptionButton.new()
	_quality_btn.tooltip_text = "کیفیت گرافیک (AAA Unreal / Unity / Indie)"
	for t in ["AAA_UNREAL", "STANDARD_UNITY", "INDIE_CEL_ANIME", "INDIE_LOWPOLY_COZY", "INDIE_HD2D", "INDIE_PSX_RETRO"]:
		_quality_btn.add_item(t)
	_quality_btn.item_selected.connect(_on_quality_changed)
	add_child(_quality_btn)

	_cam_btn = OptionButton.new()
	_cam_btn.tooltip_text = "دوربین و ژانر بازی"
	for c in ["TPS_SOULS", "TPS_SHOULDER", "FPS", "SIDE_2_5D", "HD_2D", "ISOMETRIC", "PURE_2D", "FIXED_CINEMATIC"]:
		_cam_btn.add_item(c)
	_cam_btn.item_selected.connect(_on_cam_changed)
	add_child(_cam_btn)

	_day_btn = Button.new()
	_day_btn.text = "⏩ +۵ روز (روز ۱)"
	_day_btn.tooltip_text = "جلو بردن زمان بازی و تکامل زندگی NPCها"
	_day_btn.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.advance_world_days(5)
	)
	add_child(_day_btn)

	var btn_voronoi := Button.new()
	btn_voronoi.text = "💥 تخریب Voronoi"
	btn_voronoi.tooltip_text = "تست شکستن صندوق باستانی به ۱۶ قطعه Voronoi در صحنه"
	btn_voronoi.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.shatter_or_reset_crate()
	)
	add_child(btn_voronoi)

	var btn_cutscene := Button.new()
	btn_cutscene.text = "🎬 کات‌سین زنده"
	btn_cutscene.tooltip_text = "اجرای کات‌سین زنده بدون صفحه سیاه روی دوربین صحنه"
	btn_cutscene.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.trigger_live_cutscene()
	)
	add_child(btn_cutscene)

	var btn_undo := Button.new()
	btn_undo.text = "⏪ Undo"
	btn_undo.tooltip_text = "بازگشت به وضعیت قبلی با Time-Machine"
	btn_undo.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.undo_snapshot()
	)
	add_child(btn_undo)

	call_deferred("_bind_ctrl")


func _bind_ctrl() -> void:
	var ctrl := _get_ctrl()
	if ctrl and not ctrl.state_updated.is_connected(_on_state_updated):
		ctrl.state_updated.connect(_on_state_updated)


func _on_state_updated(st: Dictionary) -> void:
	if _day_btn:
		_day_btn.text = "⏩ +۵ روز (روز %d)" % int(st.get("day", 1))


func _get_ctrl() -> NovaEditorSceneController:
	if get_tree() and get_tree().root.has_node("NovaEditorController"):
		return get_tree().root.get_node("NovaEditorController") as NovaEditorSceneController
	return null


func _on_quality_changed(idx: int) -> void:
	var tier := _quality_btn.get_item_text(idx)
	var ctrl := _get_ctrl()
	if ctrl:
		ctrl.apply_quality_visuals(tier)


func _on_cam_changed(idx: int) -> void:
	var mode := _cam_btn.get_item_text(idx)
	var ctrl := _get_ctrl()
	if ctrl:
		ctrl.apply_camera_perspective(mode)
