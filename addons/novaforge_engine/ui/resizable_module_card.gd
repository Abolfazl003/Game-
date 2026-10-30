@tool
extends PanelContainer
## NovaResizableModuleCard (v4.0) — Mouse-Resizable, Collapsible & Detachable Floating Window Container.
## Gives every NovaForge Studio module:
##   1. Bottom mouse-drag vertical resize grip (`CURSOR_VSIZE`) + corner diagonal grip (`CURSOR_FDIAGSIZE`)
##   2. Header quick controls: Collapse/Expand (`▾`/`▸`), Step Smaller/Larger (`−`/`+`), and
##      Pop-Out Floating Resizable Window (`❐ شناور`) that can be dragged & resized freely with the mouse!

signal collapsed_changed(is_collapsed: bool)
signal floated_changed(is_floating: bool)

var module_id: String = ""
var module_title: String = ""
var accent_color: Color = Color(0.24, 0.78, 0.98)

var _outer_vb: VBoxContainer
var _header_bar: PanelContainer
var _title_lbl: Label
var _badge_lbl: Label
var _btn_collapse: Button
var _btn_float: Button
var _body_holder: MarginContainer
var _content_box: VBoxContainer
var _resize_bar: PanelContainer

var _collapsed: bool = false
var _dragging_h: bool = false
var _dragging_diag: bool = false
var _drag_start_mouse: Vector2 = Vector2.ZERO
var _drag_start_min: Vector2 = Vector2.ZERO
var _target_body_height: float = 0.0
var _floating_win: Window = null
var _floating_dock_btn: Button = null


func setup(id_str: String, title_str: String, accent: Color = Color(0.24, 0.78, 0.98), initial_min_h: float = 0.0, start_collapsed: bool = false) -> VBoxContainer:
	module_id = id_str
	module_title = title_str
	accent_color = accent
	_target_body_height = initial_min_h

	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_sb := StyleBoxFlat.new()
	card_sb.bg_color = Color(0.075, 0.105, 0.175, 0.98)
	card_sb.border_color = accent.darkened(0.12)
	card_sb.set_border_width_all(1)
	card_sb.border_width_top = 2
	card_sb.set_corner_radius_all(7)
	card_sb.content_margin_left = 0
	card_sb.content_margin_right = 0
	card_sb.content_margin_top = 0
	card_sb.content_margin_bottom = 0
	add_theme_stylebox_override("panel", card_sb)

	_outer_vb = VBoxContainer.new()
	_outer_vb.add_theme_constant_override("separation", 0)
	_outer_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_outer_vb)

	# ── HEADER BAR ──
	_header_bar = PanelContainer.new()
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color(accent.r * 0.18 + 0.06, accent.g * 0.18 + 0.08, accent.b * 0.18 + 0.14, 1.0)
	hsb.corner_radius_top_left = 6
	hsb.corner_radius_top_right = 6
	hsb.content_margin_left = 8
	hsb.content_margin_right = 8
	hsb.content_margin_top = 5
	hsb.content_margin_bottom = 5
	_header_bar.add_theme_stylebox_override("panel", hsb)
	_outer_vb.add_child(_header_bar)

	var hhb := HBoxContainer.new()
	hhb.add_theme_constant_override("separation", 5)
	_header_bar.add_child(hhb)

	_btn_collapse = _mini_btn("▾", "جمع کردن / باز کردن این ماژول")
	_btn_collapse.pressed.connect(toggle_collapsed)
	hhb.add_child(_btn_collapse)

	_title_lbl = Label.new()
	_title_lbl.text = title_str
	_title_lbl.add_theme_font_size_override("font_size", 13)
	_title_lbl.add_theme_color_override("font_color", accent.lightened(0.28))
	_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_lbl.clip_text = true
	hhb.add_child(_title_lbl)

	_badge_lbl = Label.new()
	_badge_lbl.text = ""
	_badge_lbl.visible = false
	_badge_lbl.add_theme_font_size_override("font_size", 11)
	_badge_lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 0.65))
	hhb.add_child(_badge_lbl)

	var btn_smaller := _mini_btn("−", "کوچک‌تر کردن ارتفاع ماژول")
	btn_smaller.pressed.connect(func(): adjust_height(-65.0))
	hhb.add_child(btn_smaller)

	var btn_larger := _mini_btn("+", "بزرگ‌تر کردن ارتفاع ماژول")
	btn_larger.pressed.connect(func(): adjust_height(65.0))
	hhb.add_child(btn_larger)

	_btn_float = _mini_btn("✦ شناور", "جدا کردن ماژول در پنجره مستقل قابل تغییر سایز با ماوس")
	_btn_float.pressed.connect(toggle_floating_window)
	hhb.add_child(_btn_float)

	# ── BODY CONTAINER ──
	_body_holder = MarginContainer.new()
	_body_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_holder.add_theme_constant_override("margin_left", 10)
	_body_holder.add_theme_constant_override("margin_right", 10)
	_body_holder.add_theme_constant_override("margin_top", 8)
	_body_holder.add_theme_constant_override("margin_bottom", 6)
	if initial_min_h > 0.0:
		_body_holder.custom_minimum_size.y = initial_min_h
	_outer_vb.add_child(_body_holder)

	_content_box = VBoxContainer.new()
	_content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_box.add_theme_constant_override("separation", 6)
	_body_holder.add_child(_content_box)

	# ── BOTTOM MOUSE-DRAG RESIZE BAR ──
	_resize_bar = PanelContainer.new()
	_resize_bar.custom_minimum_size = Vector2(0, 12)
	_resize_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_resize_bar.mouse_default_cursor_shape = Control.CURSOR_VSIZE
	_resize_bar.tooltip_text = "با نگه داشتن کلیک چپ ماوس و کشیدن بالا/پایین، اندازه این ماژول را تغییر دهید"
	var rsb := StyleBoxFlat.new()
	rsb.bg_color = Color(0.11, 0.16, 0.25, 0.95)
	rsb.corner_radius_bottom_left = 6
	rsb.corner_radius_bottom_right = 6
	rsb.content_margin_top = 0
	rsb.content_margin_bottom = 0
	rsb.content_margin_left = 6
	rsb.content_margin_right = 6
	_resize_bar.add_theme_stylebox_override("panel", rsb)
	_resize_bar.gui_input.connect(_on_resize_bar_gui_input)

	var grip_hb := HBoxContainer.new()
	grip_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grip_center := Label.new()
	grip_center.text = "═══ کشیدن با ماوس برای تغییر سایز ═══"
	grip_center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grip_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grip_center.add_theme_font_size_override("font_size", 9)
	grip_center.add_theme_color_override("font_color", Color(0.45, 0.64, 0.85, 0.85))
	grip_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grip_hb.add_child(grip_center)

	var corner_lbl := Label.new()
	corner_lbl.text = "◆"
	corner_lbl.add_theme_font_size_override("font_size", 10)
	corner_lbl.add_theme_color_override("font_color", accent)
	corner_lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	corner_lbl.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	corner_lbl.gui_input.connect(_on_corner_gui_input)
	grip_hb.add_child(corner_lbl)

	_resize_bar.add_child(grip_hb)
	_outer_vb.add_child(_resize_bar)

	if start_collapsed:
		set_collapsed(true)

	return _content_box


func get_content_box() -> VBoxContainer:
	return _content_box


func set_badge(txt: String, col: Color = Color(0.35, 0.95, 0.65)) -> void:
	if _badge_lbl == null:
		return
	_badge_lbl.text = txt
	_badge_lbl.visible = not txt.is_empty()
	_badge_lbl.add_theme_color_override("font_color", col)


func set_collapsed(c: bool) -> void:
	if _floating_win != null:
		return
	_collapsed = c
	if _body_holder:
		_body_holder.visible = not _collapsed
	if _resize_bar:
		_resize_bar.visible = not _collapsed
	if _btn_collapse:
		_btn_collapse.text = "▸" if _collapsed else "▾"
	collapsed_changed.emit(_collapsed)


func toggle_collapsed() -> void:
	set_collapsed(not _collapsed)


func adjust_height(delta_y: float) -> void:
	if _collapsed:
		set_collapsed(false)
	var cur := _body_holder.size.y if _body_holder.custom_minimum_size.y <= 1.0 else _body_holder.custom_minimum_size.y
	_target_body_height = clampf(cur + delta_y, 70.0, 920.0)
	_body_holder.custom_minimum_size.y = _target_body_height


func _on_resize_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging_h = true
			_drag_start_mouse = get_global_mouse_position()
			var cur_h := _body_holder.size.y if _body_holder.custom_minimum_size.y <= 1.0 else _body_holder.custom_minimum_size.y
			_drag_start_min = Vector2(custom_minimum_size.x, cur_h)
		else:
			_dragging_h = false
	elif event is InputEventMouseMotion and _dragging_h:
		var dy := get_global_mouse_position().y - _drag_start_mouse.y
		_target_body_height = clampf(_drag_start_min.y + dy, 70.0, 950.0)
		_body_holder.custom_minimum_size.y = _target_body_height


func _on_corner_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging_diag = true
			_drag_start_mouse = get_global_mouse_position()
			var cur_h := _body_holder.size.y if _body_holder.custom_minimum_size.y <= 1.0 else _body_holder.custom_minimum_size.y
			var cur_w := size.x if custom_minimum_size.x <= 1.0 else custom_minimum_size.x
			_drag_start_min = Vector2(cur_w, cur_h)
		else:
			_dragging_diag = false
	elif event is InputEventMouseMotion and _dragging_diag:
		var dm := get_global_mouse_position() - _drag_start_mouse
		custom_minimum_size.x = clampf(_drag_start_min.x + dm.x, 220.0, 1400.0)
		_target_body_height = clampf(_drag_start_min.y + dm.y, 70.0, 950.0)
		_body_holder.custom_minimum_size.y = _target_body_height


func toggle_floating_window() -> void:
	if _floating_win != null and is_instance_valid(_floating_win):
		dock_back_from_floating()
		return

	if _collapsed:
		set_collapsed(false)

	_floating_win = Window.new()
	_floating_win.title = module_title + " — پنجره شناور نوافورج (قابل تغییر سایز با ماوس)"
	_floating_win.unresizable = false
	_floating_win.min_size = Vector2i(360, 220)
	_floating_win.size = Vector2i(760, 520)
	_floating_win.wrap_controls = false
	_floating_win.transient = true
	_floating_win.close_requested.connect(dock_back_from_floating)

	var win_bg := PanelContainer.new()
	win_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var wsb := StyleBoxFlat.new()
	wsb.bg_color = Color(0.07, 0.10, 0.17, 1.0)
	wsb.border_color = accent_color
	wsb.set_border_width_all(2)
	wsb.content_margin_left = 10
	wsb.content_margin_right = 10
	wsb.content_margin_top = 8
	wsb.content_margin_bottom = 10
	win_bg.add_theme_stylebox_override("panel", wsb)
	_floating_win.add_child(win_bg)

	var win_vb := VBoxContainer.new()
	win_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	win_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	win_vb.add_theme_constant_override("separation", 6)
	win_bg.add_child(win_vb)

	var top_bar := HBoxContainer.new()
	var info_lbl := Label.new()
	info_lbl.text = "✦ لبه‌ها و گوشه‌های این پنجره را با ماوس بکشید تا کوچک یا بزرگ شود"
	info_lbl.add_theme_font_size_override("font_size", 11)
	info_lbl.add_theme_color_override("font_color", Color(0.55, 0.86, 1.0))
	info_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(info_lbl)

	var btn_dock := Button.new()
	btn_dock.text = "« بازگرداندن ماژول به جای خود در میزکار"
	btn_dock.pressed.connect(dock_back_from_floating)
	top_bar.add_child(btn_dock)
	win_vb.add_child(top_bar)

	var win_scroll := ScrollContainer.new()
	win_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	win_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	win_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	win_vb.add_child(win_scroll)

	_body_holder.remove_child(_content_box)
	win_scroll.add_child(_content_box)

	var win_grip_bar := HBoxContainer.new()
	var win_hint := Label.new()
	win_hint.text = "═ لبه‌های پنجره یا گوشه سمت راست پایین را با ماوس بکشید ═"
	win_hint.add_theme_font_size_override("font_size", 10)
	win_hint.add_theme_color_override("font_color", Color(0.45, 0.72, 0.95))
	win_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	win_grip_bar.add_child(win_hint)

	var win_corner := Label.new()
	win_corner.text = " ◆ تغییر سایز پنجره "
	win_corner.add_theme_font_size_override("font_size", 11)
	win_corner.add_theme_color_override("font_color", Color(0.35, 0.90, 1.0))
	win_corner.mouse_filter = Control.MOUSE_FILTER_STOP
	win_corner.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	win_corner.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseMotion and (ev.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0 and _floating_win != null:
			var ns := Vector2i(
				maxi(360, _floating_win.size.x + int(ev.relative.x)),
				maxi(220, _floating_win.size.y + int(ev.relative.y))
			)
			_floating_win.size = ns
	)
	win_grip_bar.add_child(win_corner)
	win_vb.add_child(win_grip_bar)

	_floating_dock_btn = Button.new()
	_floating_dock_btn.text = "✦ این ماژول در پنجره شناور باز است — کلیک برای بازگرداندن به اینجا"
	_floating_dock_btn.pressed.connect(dock_back_from_floating)
	_body_holder.add_child(_floating_dock_btn)
	_resize_bar.visible = false
	_btn_float.text = "« اتصال"

	add_child(_floating_win)
	_floating_win.popup_centered(Vector2i(760, 520))
	floated_changed.emit(true)


func dock_back_from_floating() -> void:
	if _floating_win == null or not is_instance_valid(_floating_win):
		_floating_win = null
		return
	if _content_box and _content_box.get_parent():
		_content_box.get_parent().remove_child(_content_box)
	if _floating_dock_btn and is_instance_valid(_floating_dock_btn):
		_floating_dock_btn.queue_free()
		_floating_dock_btn = null
	_body_holder.add_child(_content_box)
	_floating_win.queue_free()
	_floating_win = null
	_resize_bar.visible = not _collapsed
	_btn_float.text = "✦ شناور"
	floated_changed.emit(false)


func _exit_tree() -> void:
	if _floating_win != null and is_instance_valid(_floating_win):
		_floating_win.queue_free()
		_floating_win = null


func _mini_btn(txt: String, tip: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(24, 22)
	b.add_theme_font_size_override("font_size", 11)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.20, 0.32, 0.95)
	sb.border_color = Color(0.28, 0.44, 0.68, 0.9)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 5
	sb.content_margin_right = 5
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	b.add_theme_stylebox_override("normal", sb)
	return b
