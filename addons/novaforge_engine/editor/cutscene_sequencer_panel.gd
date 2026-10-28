@tool
extends VBoxContainer
class_name NovaCutsceneSequencerPanel
## Native Godot 4 Bottom-Panel Module: Blender-Grade Pose/IK, Bezier Curve, NLA Mixer & Live Cutscene Sequencer.
## Sits right beside Godot 4's native `Animation` bottom panel tab.

var _prompt_line: LineEdit
var _curve_preset: OptionButton
var _nla_blend_mode: OptionButton
var _shot_tree: Tree


func _ready() -> void:
	custom_minimum_size = Vector2(0, 240)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)

	var lbl := Label.new()
	lbl.text = "🎬 Cutscene & Pose/IK Sequencer:"
	bar.add_child(lbl)

	_prompt_line = LineEdit.new()
	_prompt_line.placeholder_text = "مثلاً: این تیکه کات‌سینه — دوربین زوم کنه روی دروازه، باس بپره زمین با اسلوموشن..."
	_prompt_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(_prompt_line)

	_curve_preset = OptionButton.new()
	for c in ["Bezier: Smooth Ease-In-Out", "Bezier: Martial-Arts Snap", "Bezier: Linear", "Pose Mode: Analytical 2-Bone IK"]:
		_curve_preset.add_item(c)
	bar.add_child(_curve_preset)

	_nla_blend_mode = OptionButton.new()
	for m in ["NLA: Replace", "NLA: Additive Upper-Body", "NLA: Multiply"]:
		_nla_blend_mode.add_item(m)
	bar.add_child(_nla_blend_mode)

	var btn_gen := Button.new()
	btn_gen.text = "+ Build Live Cutscene"
	btn_gen.pressed.connect(_on_build_cutscene)
	bar.add_child(btn_gen)

	add_child(bar)

	# Multi-Track Sequencer Tree (Camera Rail, Lens DOF, Time-Scale, Audio/Subtitle, Gameplay Blend)
	_shot_tree = Tree.new()
	_shot_tree.columns = 4
	_shot_tree.set_column_titles_visible(true)
	_shot_tree.set_column_title(0, "Sequencer Track / Shot")
	_shot_tree.set_column_title(1, "Timing (s)")
	_shot_tree.set_column_title(2, "Camera / IK / NLA")
	_shot_tree.set_column_title(3, "Transition")
	_shot_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_shot_tree)

	_populate_default_tracks()


func _populate_default_tracks() -> void:
	_shot_tree.clear()
	var root := _shot_tree.create_item()
	var tracks := [
		["Track 1: Camera3D Rail & Rack-Focus DOF", "0.00s -> 2.20s", "FOV 65 -> 38 | Focus: Boss", "Zero-Black-Screen Blend"],
		["Track 2: Character Pose/IK & NLA Action", "0.40s -> 3.60s", "Foot-Locking IK + UpperBody Additive", "Bezier Ease-In-Out"],
		["Track 3: Time-Dilation & VFX Impact", "2.20s -> 3.00s", "TimeScale = 0.45x + Dust/Sparks", "Hitstop Impulse"],
		["Track 4: Return to Player Shoulder", "3.60s -> 4.25s", "Restore Active Gameplay Rig", "Seamless Control Hand-off"]
	]
	for row in tracks:
		var it := _shot_tree.create_item(root)
		for col in range(4):
			it.set_text(col, row[col])


func _on_build_cutscene() -> void:
	var txt := _prompt_line.text.strip_edges()
	if txt.is_empty():
		txt = "این تیکه کات‌سینه"
	if get_tree() and get_tree().root.has_node("NovaNativeBus"):
		get_tree().root.get_node("NovaNativeBus").invoke_tool("nova_create_cutscene", {
			"prompt": txt,
			"seamless_blend": true
		})
	var root := _shot_tree.get_root()
	if root:
		var it := _shot_tree.create_item(root)
		it.set_text(0, "AI Generated Cutscene: " + txt.left(36))
		it.set_text(1, "0.00s -> 4.80s")
		it.set_text(2, _curve_preset.get_item_text(_curve_preset.selected))
		it.set_text(3, "Seamless In-Engine")
