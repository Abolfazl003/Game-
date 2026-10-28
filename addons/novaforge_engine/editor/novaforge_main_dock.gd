@tool
extends VBoxContainer
class_name NovaForgeMainDock
## In-Editor NovaForge Studio Control Dock (Zero-MCP Prompt Console, Multi-Brain Status,
## One-Click Visual Quality Switcher, Camera Perspective Selector & Time-Machine Undo).

var _prompt_input: TextEdit
var _quality_select: OptionButton
var _perspective_select: OptionButton
var _log_view: RichTextLabel


func _ready() -> void:
	custom_minimum_size = Vector2(340, 520)

	var header := Label.new()
	header.text = "🚀 NovaForge AI Studio (Zero-MCP | Colibrì Council)"
	add_child(header)

	# Visual Quality Switcher
	var q_row := HBoxContainer.new()
	var q_lbl := Label.new()
	q_lbl.text = "Quality Tier:"
	q_row.add_child(q_lbl)
	_quality_select = OptionButton.new()
	for t in ["AAA_UNREAL", "STANDARD_UNITY", "INDIE_CEL_ANIME", "INDIE_LOWPOLY_COZY", "INDIE_HD2D", "INDIE_PSX_RETRO"]:
		_quality_select.add_item(t)
	_quality_select.item_selected.connect(_on_quality_selected)
	q_row.add_child(_quality_select)
	add_child(q_row)

	# Perspective Switcher
	var p_row := HBoxContainer.new()
	var p_lbl := Label.new()
	p_lbl.text = "Camera / Genre:"
	p_row.add_child(p_lbl)
	_perspective_select = OptionButton.new()
	for m in ["TPS_SOULS", "TPS_SHOULDER", "FPS", "SIDE_2_5D", "HD_2D", "ISOMETRIC", "PURE_2D", "FIXED_CINEMATIC"]:
		_perspective_select.add_item(m)
	p_row.add_child(_perspective_select)
	add_child(p_row)

	# Prompt Input (Persian & English)
	_prompt_input = TextEdit.new()
	_prompt_input.placeholder_text = "پرامپت بازی، سیستم فایت، کات‌سین، تبدیل عکس/ویدیو به کاراکتر و انیمیشن را اینجا بنویسید..."
	_prompt_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_prompt_input.custom_minimum_size = Vector2(0, 110)
	add_child(_prompt_input)

	var btn_run := Button.new()
	btn_run.text = "⚡ اجرای همفکری شورا (Run AI Council)"
	btn_run.pressed.connect(_on_run_council_pressed)
	add_child(btn_run)

	_log_view = RichTextLabel.new()
	_log_view.bbcode_enabled = true
	_log_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_view.text = "[b]Ready.[/b] 123 Skills & 114 Native Tools active (Zero-MCP).\nAlt + Left-Click any 3D object/NPC in viewport for Smart Menu."
	add_child(_log_view)


func _on_quality_selected(idx: int) -> void:
	var tier := _quality_select.get_item_text(idx)
	if get_tree() and get_tree().root.has_node("NovaQuality"):
		get_tree().root.get_node("NovaQuality").apply_quality_tier(tier)
	_log_view.append_text("\n[color=cyan]Visual Tier switched -> " + tier + "[/color]")


func _on_run_council_pressed() -> void:
	var txt := _prompt_input.text.strip_edges()
	if txt.is_empty():
		return
	if get_tree() and get_tree().root.has_node("NovaBrainCouncil"):
		var res: Dictionary = get_tree().root.get_node("NovaBrainCouncil").execute_prompt_with_council(txt)
		_log_view.append_text("\n[color=lime]Council Unified Consensus:[/color] " + JSON.stringify(res.get("matched_skills", [])))
