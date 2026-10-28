@tool
extends VBoxContainer
## Persian Cutscene, Pose/IK, Bezier & NLA Sequencer Bottom Panel (`کارگردان کات‌سین و IK`).

var _prompt_line: LineEdit
var _curve_preset: OptionButton
var _nla_blend_mode: OptionButton
var _shot_tree: Tree


func _ready() -> void:
	custom_minimum_size = Vector2(0, 230)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)

	var lbl := Label.new()
	lbl.text = "▶ کارگردان کات‌سین و ریگ FK/IK:"
	bar.add_child(lbl)

	_prompt_line = LineEdit.new()
	_prompt_line.placeholder_text = "مثلاً: این تیکه کات‌سینه — دوربین زوم کنه روی دروازه، سامورایی با اسلوموشن فرود بیاد..."
	_prompt_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(_prompt_line)

	_curve_preset = OptionButton.new()
	for c in ["منحنی Bezier: نرم و سینمایی", "منحنی Bezier: ضربتی رزمی", "حالت Pose: حل‌کننده ۲ استخوانی IK"]:
		_curve_preset.add_item(c)
	bar.add_child(_curve_preset)

	_nla_blend_mode = OptionButton.new()
	for m in ["ترکیب NLA: جایگزینی کامل", "ترکیب NLA: لایه بالاتنه (Additive)"]:
		_nla_blend_mode.add_item(m)
	bar.add_child(_nla_blend_mode)

	var btn_gen := Button.new()
	btn_gen.text = "▶ ساخت و اجرای کات‌سین زنده"
	btn_gen.pressed.connect(_on_build_cutscene)
	bar.add_child(btn_gen)

	add_child(bar)

	_shot_tree = Tree.new()
	_shot_tree.columns = 4
	_shot_tree.set_column_titles_visible(true)
	_shot_tree.set_column_title(0, "ردیف تایم‌لاین / شات")
	_shot_tree.set_column_title(1, "بازه زمانی")
	_shot_tree.set_column_title(2, "تنظیمات دوربین / IK / NLA")
	_shot_tree.set_column_title(3, "نوع گذار به گیم‌پلی")
	_shot_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_shot_tree)

	_populate_default_tracks()


func _populate_default_tracks() -> void:
	_shot_tree.clear()
	var root := _shot_tree.create_item()
	var tracks := [
		["ردیف ۱: ریل دوربین سه‌بعدی و فوکوس لنز", "0.00s -> 2.20s", "لنز ۳۲ میلی‌متری | فوکوس روی قهرمان", "بدون صفحه سیاه (Zero Black Screen)"],
		["ردیف ۲: اسکلت FK/IK و لایه NLA", "0.40s -> 3.60s", "قفل کف پا (Foot-IK) + کمبوی بالاتنه", "منحنی نرم Bezier"],
		["ردیف ۳: اسلوموشن و ذرات جرقه", "2.20s -> 3.00s", "سرعت زمان 0.45x + لرزش ضربه", "ضربه لحظه‌ای (Hitstop)"],
		["ردیف ۴: بازگشت نرم پشت شانه بازیکن", "3.60s -> 4.25s", "تحویل کنترل بدون مکث", "ادغام زنده در موتور"]
	]
	for row in tracks:
		var it := _shot_tree.create_item(root)
		for col in range(4):
			it.set_text(col, row[col])


func _on_build_cutscene() -> void:
	var txt := _prompt_line.text.strip_edges()
	if txt.is_empty():
		txt = "«دروازه قلعه باز می‌شود... آماده نبرد شو!»"
	if get_tree() and get_tree().root.has_node("NovaEditorController"):
		get_tree().root.get_node("NovaEditorController").call("trigger_live_cutscene", txt)
	var root := _shot_tree.get_root()
	if root:
		var it := _shot_tree.create_item(root)
		it.set_text(0, "کات‌سین هوش مصنوعی: " + txt.left(36))
		it.set_text(1, "0.00s -> 3.30s")
		it.set_text(2, _curve_preset.get_item_text(_curve_preset.selected))
		it.set_text(3, "اجرای زنده در صحنه")
