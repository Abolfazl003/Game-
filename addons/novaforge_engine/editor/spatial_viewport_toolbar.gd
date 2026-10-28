@tool
extends HBoxContainer
## Native Godot 4 3D Viewport Top-Bar Extension (100% Persian & Cold-Boot Safe).

const QUALITY_CODES: Array[String] = ["AAA_UNREAL", "STANDARD_UNITY", "INDIE_CEL_ANIME", "INDIE_LOWPOLY_COZY", "INDIE_HD2D", "INDIE_PSX_RETRO"]
const QUALITY_LABELS: Array[String] = ["گرافیک: AAA آنریل", "گرافیک: استاندارد یونیتی", "گرافیک: سل‌شید انیمه", "گرافیک: لو-پلی سبک", "گرافیک: دیورامای HD-2D", "گرافیک: رترو PS1"]

const CAM_CODES: Array[String] = ["TPS_SOULS", "TPS_SHOULDER", "FPS", "SIDE_2_5D", "HD_2D", "ISOMETRIC", "PURE_2D", "FIXED_CINEMATIC"]
const CAM_LABELS: Array[String] = ["دوربین: سوم‌شخص سولز", "دوربین: روی شانه", "دوربین: اول‌شخص FPS", "دوربین: ۲.۵ بعدی", "دوربین: نمای HD-2D", "دوربین: ایزومتریک", "دوربین: دوبعدی کامل", "دوربین: سینمایی ثابت"]

var _quality_btn: OptionButton
var _cam_btn: OptionButton
var _day_btn: Button


func _ready() -> void:
	add_theme_constant_override("separation", 5)

	add_child(VSeparator.new())

	var badge := Label.new()
	badge.text = "⚡ نوافورج:"
	badge.add_theme_color_override("font_color", Color(0.35, 0.85, 1.0))
	add_child(badge)

	var btn_ws := Button.new()
	btn_ws.text = "✦ میزکار کامل"
	btn_ws.pressed.connect(func():
		if Engine.is_editor_hint():
			EditorInterface.set_main_screen_editor("⚡ میزکار نوافورج")
	)
	add_child(btn_ws)

	_quality_btn = OptionButton.new()
	for lbl in QUALITY_LABELS:
		_quality_btn.add_item(lbl)
	_quality_btn.item_selected.connect(_on_quality_changed)
	add_child(_quality_btn)

	_cam_btn = OptionButton.new()
	for lbl in CAM_LABELS:
		_cam_btn.add_item(lbl)
	_cam_btn.item_selected.connect(_on_cam_changed)
	add_child(_cam_btn)

	_day_btn = Button.new()
	_day_btn.text = "» +۵ روز (روز ۱)"
	_day_btn.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.call("advance_world_days", 5)
	)
	add_child(_day_btn)

	var btn_voronoi := Button.new()
	btn_voronoi.text = "★ تخریب Voronoi"
	btn_voronoi.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.call("shatter_or_reset_crate")
	)
	add_child(btn_voronoi)

	var btn_cutscene := Button.new()
	btn_cutscene.text = "▶ کات‌سین زنده"
	btn_cutscene.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.call("trigger_live_cutscene")
	)
	add_child(btn_cutscene)

	var btn_undo := Button.new()
	btn_undo.text = "↺ بازگشت"
	btn_undo.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.call("undo_snapshot")
	)
	add_child(btn_undo)

	call_deferred("_bind_ctrl")


func _bind_ctrl() -> void:
	var ctrl := _get_ctrl()
	if ctrl and ctrl.has_signal("state_updated") and not ctrl.is_connected("state_updated", _on_state_updated):
		ctrl.connect("state_updated", _on_state_updated)


func _on_state_updated(st: Dictionary) -> void:
	if _day_btn:
		_day_btn.text = "» +۵ روز (روز %d)" % int(st.get("day", 1))


func _get_ctrl() -> Node:
	if get_tree() and get_tree().root.has_node("NovaEditorController"):
		return get_tree().root.get_node("NovaEditorController")
	return null


func _on_quality_changed(idx: int) -> void:
	var ctrl := _get_ctrl()
	if ctrl and idx >= 0 and idx < QUALITY_CODES.size():
		ctrl.call("apply_quality_visuals", QUALITY_CODES[idx])


func _on_cam_changed(idx: int) -> void:
	var ctrl := _get_ctrl()
	if ctrl and idx >= 0 and idx < CAM_CODES.size():
		ctrl.call("apply_camera_perspective", CAM_CODES[idx])
