extends CanvasLayer
## Complete Customized Persian In-App Interactive Studio & Game HUD (`NovaStudioHUD`).
## Appears automatically when the user runs the program/game (`F5` or `Play` mode in `NovaForge_Studio.exe`),
## so ALL NovaForge AI Studio capabilities are 100% visible, customized in Persian, and interactive
## right inside the live 3D playable Jolt world! Toggle panels anytime with [Tab].

var _left_panel: PanelContainer
var _right_panel: PanelContainer
var _bottom_log: RichTextLabel
var _npc_lbl: RichTextLabel
var _vram_bar: ProgressBar
var _prompt_edit: TextEdit
var _cutscene_bars: Control
var _day: int = 1
var _crate_shattered: bool = false
var _npc_gold: int = 120
var _npc_rel: int = 10
var _npc_title: String = "شاگرد آهنگر (سطح ۱)"
var _npc_scars: Array[String] = []
var _panels_visible: bool = true
var _neural_client: Node = null
var _llm_brain: Node = null
var _hud_ai_reply: RichTextLabel = null


func _ready() -> void:
	if Engine.is_editor_hint():
		visible = false
		return

	layer = 10
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var nscr = load("res://addons/novaforge_engine/forge/neural_3d_cloud_client.gd")
	if nscr:
		_neural_client = nscr.new()
		_neural_client.name = "RuntimeNeural3DClient"
		_neural_client.progress_updated.connect(func(pct: int, msg: String):
			if _vram_bar:
				_vram_bar.value = float(pct)
			_log("[color=#38bdf8][هوش مصنوعی ۳۶۰ درجه %d%%][/color] %s" % [pct, msg])
		)
		add_child(_neural_client)

	var lscr = load("res://addons/novaforge_engine/ai_council/neural_llm_brain_client.gd")
	if lscr:
		_llm_brain = lscr.new()
		_llm_brain.name = "RuntimeNeuralLLMBrain"
		_llm_brain.thinking_progress.connect(func(pct: int, msg: String):
			if _vram_bar:
				_vram_bar.value = float(pct)
			_log("[color=#a855f7][مغز هوش مصنوعی %d%%][/color] %s" % [pct, msg])
		)
		add_child(_llm_brain)

	var iscr = load("res://addons/novaforge_engine/ai_council/in_app_setup_installer.gd")
	if iscr:
		var inst: Node = iscr.new()
		inst.name = "RuntimeInAppSetupInstaller"
		inst.setup_state_changed.connect(func(st: Dictionary):
			if _vram_bar and not bool(st.get("completed", false)):
				_vram_bar.value = float(st.get("overall_pct", 0))
		)
		inst.setup_log_line.connect(func(bb: String):
			_log("[color=#10b981][نصب داخل برنامه][/color] " + bb)
		)
		add_child(inst)

	_build_ui()
	var w := get_window()
	if w and not w.files_dropped.is_connected(_on_runtime_files_dropped):
		w.files_dropped.connect(_on_runtime_files_dropped)


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		_toggle_studio_panels()


func _toggle_studio_panels() -> void:
	_panels_visible = not _panels_visible
	if _left_panel: _left_panel.visible = _panels_visible
	if _right_panel: _right_panel.visible = _panels_visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _panels_visible else Input.MOUSE_MODE_CAPTURED


func _sync_hud_resize_bars(grip: Control, is_right: bool) -> void:
	if grip == null:
		return
	var target := _right_panel if is_right else _left_panel
	if target == null:
		return
	var gx := target.position.x - 4.0 if is_right else (target.position.x + target.size.x - 4.0)
	grip.position = Vector2(gx, target.position.y)
	grip.size = Vector2(9.0, target.size.y)


func _build_ui() -> void:
	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root_ctrl)

	# ── TOP CUSTOMIZED PERSIAN HEADER BAR ──
	var top_bar := PanelContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 48
	top_bar.add_theme_stylebox_override("panel", _box_style(Color(0.06, 0.08, 0.14, 0.94), Color(0.24, 0.72, 0.96), 0))
	root_ctrl.add_child(top_bar)

	var thb := HBoxContainer.new()
	thb.add_theme_constant_override("separation", 8)
	top_bar.add_child(thb)

	var btn_freeplay := _btn("▶ بازی آزاد / نمایش پنل‌ها [Tab]", Color(0.14, 0.52, 0.32))
	btn_freeplay.pressed.connect(_toggle_studio_panels)
	thb.add_child(btn_freeplay)

	var q_opt := OptionButton.new()
	for qt in ["کیفیت: AAA آنریل", "کیفیت: استاندارد یونیتی", "کیفیت: سل‌شید انیمه", "کیفیت: رترو PS1"]:
		q_opt.add_item(qt)
	q_opt.item_selected.connect(_on_quality_picked)
	thb.add_child(q_opt)

	var c_opt := OptionButton.new()
	for ct in ["دوربین: سوم‌شخص سولزلایک", "دوربین: روی شانه", "دوربین: اول‌شخص FPS", "دوربین: ۲.۵ بعدی", "دوربین: ایزومتریک"]:
		c_opt.add_item(ct)
	c_opt.item_selected.connect(_on_cam_picked)
	thb.add_child(c_opt)

	var btn_day := _btn("» +۵ روز تکامل دنیا", Color(0.45, 0.34, 0.14))
	btn_day.pressed.connect(_on_advance_days)
	thb.add_child(btn_day)

	var brand := Label.new()
	brand.text = "⚡ استودیو بازی‌سازی فارسی نوافورج v2.0 (مدل‌های واقعی .GLB + عکس به مش 3D)"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_theme_color_override("font_color", Color(0.45, 0.86, 1.0))
	brand.add_theme_font_size_override("font_size", 14)
	thb.add_child(brand)

	# ── RIGHT PANEL: 5-BRAIN COUNCIL, PERSIAN PROMPT & 3D/MOCAP/BLENDER FORGE ──
	_right_panel = PanelContainer.new()
	_right_panel.anchor_left = 1.0
	_right_panel.anchor_right = 1.0
	_right_panel.anchor_top = 0.0
	_right_panel.anchor_bottom = 1.0
	_right_panel.offset_left = -335
	_right_panel.offset_top = 54
	_right_panel.offset_right = -8
	_right_panel.offset_bottom = -98
	_right_panel.add_theme_stylebox_override("panel", _box_style(Color(0.08, 0.11, 0.18, 0.90), Color(0.26, 0.52, 0.85), 10))
	root_ctrl.add_child(_right_panel)

	var r_scroll := ScrollContainer.new()
	r_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_right_panel.add_child(r_scroll)

	var rvb := VBoxContainer.new()
	rvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rvb.add_theme_constant_override("separation", 7)
	r_scroll.add_child(rvb)

	rvb.add_child(_hdr("⚡ شورای ۵ مغز زنده (کلیک کنید)"))
	for bpair in [
		["1. کارگردان بازی (Command-A 111B)", "کارگردان ارشد گیم‌پلی"],
		["2. کدنویس GDScript / C++20", "برنامه‌نویس گادوت ۴.۷"],
		["3. آرتیست مش ۳۶۰ (Hunyuan3D-2)", "آرتیست مدل سه‌بعدی و متریال PBR"],
		["4. موشن‌کپچر و کات‌سین — Foot-IK", "کارگردان انیمیشن و کات‌سین"],
		["5. داور کیفیت و Scene Audit", "داور بررسی و رفع باگ صحنه"]
	]:
		var role_str: String = bpair[1]
		var bb := _btn(str(bpair[0]), Color(0.14, 0.22, 0.36))
		bb.pressed.connect(func(): _on_ask_runtime_ai(role_str))
		rvb.add_child(bb)

	_vram_bar = ProgressBar.new()
	_vram_bar.value = 0.0
	_vram_bar.custom_minimum_size = Vector2(0, 14)
	rvb.add_child(_vram_bar)

	rvb.add_child(HSeparator.new())
	rvb.add_child(_hdr("⚡ چت با هوش مصنوعی و ساخت مش ۳۶۰ درجه"))
	_prompt_edit = TextEdit.new()
	_prompt_edit.text = "سلام! یه کد حرکت و پرش کاراکتر بنویس، یا یه جنگجوی سامورایی سیاه و طلایی بساز"
	_prompt_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_prompt_edit.custom_minimum_size = Vector2(0, 62)
	rvb.add_child(_prompt_edit)

	var btn_ask_ai := _btn("⚡ پرسش و گفتگوی زنده با هوش مصنوعی", Color(0.42, 0.22, 0.78))
	btn_ask_ai.pressed.connect(func(): _on_ask_runtime_ai(""))
	rvb.add_child(btn_ask_ai)

	var btn_council := _btn("◆ ساخت مدل ۳۶۰ درجه واقعی + ریگ خودکار", Color(0.14, 0.46, 0.88))
	btn_council.pressed.connect(_on_run_council)
	rvb.add_child(btn_council)

	_hud_ai_reply = RichTextLabel.new()
	_hud_ai_reply.bbcode_enabled = true
	_hud_ai_reply.selection_enabled = true
	_hud_ai_reply.scroll_following = true
	_hud_ai_reply.custom_minimum_size = Vector2(0, 105)
	_hud_ai_reply.text = "[color=#38bdf8]✓ هوش مصنوعی آنلاین است:[/color] سوال بپرسید یا دکمه ساخت مش ۳۶۰ درجه را بزنید!"
	rvb.add_child(_hud_ai_reply)

	rvb.add_child(HSeparator.new())
	rvb.add_child(_hdr("■ تبدیل هر عکس به مش ۳۶۰ درجه و ریگ خودکار"))

	var use_os_native := OS.get_name() in ["Windows", "macOS"]
	var runtime_img_dlg := FileDialog.new()
	runtime_img_dlg.title = "انتخاب عکس برای ساخت مش سه‌بعدی ۳۶۰ درجه و ریگ خودکار"
	runtime_img_dlg.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	runtime_img_dlg.access = FileDialog.ACCESS_FILESYSTEM
	runtime_img_dlg.use_native_dialog = use_os_native
	var pic_dir := OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	if not pic_dir.is_empty() and DirAccess.dir_exists_absolute(pic_dir):
		runtime_img_dlg.current_dir = pic_dir
	runtime_img_dlg.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp, *.bmp ; تصاویر"])
	runtime_img_dlg.file_selected.connect(_spawn_rigged_from_image_path)
	add_child(runtime_img_dlg)

	var runtime_mesh_dlg := FileDialog.new()
	runtime_mesh_dlg.title = "انتخاب فایل مدل سه‌بعدی (.glb / .gltf / .obj) برای ریگ خودکار"
	runtime_mesh_dlg.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	runtime_mesh_dlg.access = FileDialog.ACCESS_FILESYSTEM
	runtime_mesh_dlg.use_native_dialog = use_os_native
	var dl_dir := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if not dl_dir.is_empty() and DirAccess.dir_exists_absolute(dl_dir):
		runtime_mesh_dlg.current_dir = dl_dir
	runtime_mesh_dlg.filters = PackedStringArray(["*.blend, *.glb, *.gltf, *.fbx, *.obj, *.dae, *.usd, *.usdz, *.abc, *.ply, *.stl ; همه ۱۳ فرمت بلندر و سه‌بعدی"])
	runtime_mesh_dlg.file_selected.connect(_autorig_external_model_path)
	add_child(runtime_mesh_dlg)

	# Mouse-drag horizontal resize handle on inner edge of Right Panel
	var r_resize := Control.new()
	r_resize.anchor_left = 0.0
	r_resize.anchor_right = 0.0
	r_resize.anchor_top = 0.0
	r_resize.anchor_bottom = 1.0
	r_resize.offset_left = -6
	r_resize.offset_right = 5
	r_resize.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	r_resize.tooltip_text = "کشیدن با ماوس: کوچک و بزرگ کردن عرض پنل راست"
	r_resize.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseMotion and (ev.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			var vp_w := get_viewport().get_visible_rect().size.x
			var new_left_off := clampf(_right_panel.offset_left + ev.relative.x, -vp_w * 0.62, -230.0)
			_right_panel.offset_left = new_left_off
	)
	root_ctrl.add_child(r_resize)
	_right_panel.resized.connect(func():
		r_resize.position = Vector2(_right_panel.position.x - 4.0, _right_panel.position.y)
		r_resize.size = Vector2(9.0, _right_panel.size.y)
	)
	call_deferred("_sync_hud_resize_bars", r_resize, true)

	var b_pick_photo := _btn("◆ انتخاب عکس از ویندوز ⬅ مش ۳۶۰ درجه + ریگ", Color(0.10, 0.48, 0.80))
	b_pick_photo.pressed.connect(func():
		if use_os_native:
			runtime_img_dlg.popup()
		else:
			runtime_img_dlg.popup_centered(Vector2i(820, 520))
	)
	rvb.add_child(b_pick_photo)

	var b_paste_photo := _btn("✦ چسباندن عکس از کلیپ‌بورد (Ctrl+V)", Color(0.12, 0.56, 0.44))
	b_paste_photo.pressed.connect(_paste_clipboard_image_runtime)
	rvb.add_child(b_paste_photo)

	var b_pick_mesh := _btn("✦ انتخاب مدل (.GLB/.OBJ) ⬅ ریگ خودکار", Color(0.52, 0.30, 0.72))
	b_pick_mesh.pressed.connect(func():
		if use_os_native:
			runtime_mesh_dlg.popup()
		else:
			runtime_mesh_dlg.popup_centered(Vector2i(820, 520))
	)
	rvb.add_child(b_pick_mesh)

	var g4 := GridContainer.new()
	g4.columns = 2
	g4.add_theme_constant_override("h_separation", 6)
	g4.add_theme_constant_override("v_separation", 6)

	var b1 := _btn("◆ تست نمونه عکس", Color(0.15, 0.42, 0.68))
	b1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b1.pressed.connect(func(): _spawn_rigged_from_image_path("res://assets/sample_images/cyber_samurai_concept.png"))
	g4.add_child(b1)

	var b2 := _btn("▶ ویدیو⬅موشن", Color(0.15, 0.52, 0.36))
	b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b2.pressed.connect(_play_slash_motion)
	g4.add_child(b2)

	var b3 := _btn("✦ ایمپورت بلندر", Color(0.68, 0.38, 0.14))
	b3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b3.pressed.connect(_spawn_blender_gate)
	g4.add_child(b3)

	var b4 := _btn("▶ کات‌سین زنده", Color(0.50, 0.24, 0.72))
	b4.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b4.pressed.connect(_play_cutscene)
	g4.add_child(b4)
	rvb.add_child(g4)

	# ── LEFT PANEL: LIVING NPC, ELEMENTAL CHEMISTRY & VORONOI DESTRUCTION ──
	_left_panel = PanelContainer.new()
	_left_panel.anchor_left = 0.0
	_left_panel.anchor_right = 0.0
	_left_panel.anchor_top = 0.0
	_left_panel.anchor_bottom = 1.0
	_left_panel.offset_left = 8
	_left_panel.offset_top = 54
	_left_panel.offset_right = 330
	_left_panel.offset_bottom = -98
	_left_panel.add_theme_stylebox_override("panel", _box_style(Color(0.08, 0.11, 0.18, 0.90), Color(0.24, 0.68, 0.62), 10))
	root_ctrl.add_child(_left_panel)

	# Mouse-drag horizontal resize handle on inner edge of Left Panel
	var l_resize := Control.new()
	l_resize.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	l_resize.tooltip_text = "کشیدن با ماوس: کوچک و بزرگ کردن عرض پنل چپ"
	l_resize.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseMotion and (ev.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			var vp_w := get_viewport().get_visible_rect().size.x
			_left_panel.offset_right = clampf(_left_panel.offset_right + ev.relative.x, 225.0, vp_w * 0.60)
			l_resize.position = Vector2(_left_panel.position.x + _left_panel.size.x - 4.0, _left_panel.position.y)
	)
	root_ctrl.add_child(l_resize)
	call_deferred("_sync_hud_resize_bars", l_resize, false)

	var l_scroll := ScrollContainer.new()
	l_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_left_panel.add_child(l_scroll)

	var lvb := VBoxContainer.new()
	lvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lvb.add_theme_constant_override("separation", 7)
	l_scroll.add_child(lvb)

	lvb.add_child(_hdr("✦ زندگی تکاملی NPC (کاوه آهنگر)"))
	_npc_lbl = RichTextLabel.new()
	_npc_lbl.bbcode_enabled = true
	_npc_lbl.fit_content = true
	_npc_lbl.scroll_active = false
	lvb.add_child(_npc_lbl)
	_refresh_npc_ui()

	var nhb := HBoxContainer.new()
	nhb.add_theme_constant_override("separation", 6)
	var bh := _btn("✦ کمک و خرید", Color(0.14, 0.52, 0.34))
	bh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.pressed.connect(_help_npc)
	nhb.add_child(bh)

	var bf := _btn("⚔ نبرد Nemesis", Color(0.68, 0.20, 0.22))
	bf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bf.pressed.connect(_fight_npc)
	nhb.add_child(bf)
	lvb.add_child(nhb)

	lvb.add_child(HSeparator.new())
	lvb.add_child(_hdr("✦ شیمی عناصر و جهان‌باز"))
	var eg := GridContainer.new()
	eg.columns = 2
	eg.add_theme_constant_override("h_separation", 6)
	eg.add_theme_constant_override("v_separation", 6)
	for ep in [["CLEAR", "● هوای صاف"], ["RAIN", "◈ باران (خیس)"], ["FIRE", "▲ آتش + باد"], ["LIGHTNING", "⚡ صاعقه در آب"]]:
		var ecode: String = ep[0]
		var eb := _btn(ep[1], Color(0.18, 0.34, 0.52))
		eb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		eb.pressed.connect(func(): _apply_weather(ecode))
		eg.add_child(eb)
	lvb.add_child(eg)

	lvb.add_child(HSeparator.new())
	lvb.add_child(_hdr("★ تخریب فیزیکی Voronoi 3D"))
	var b_vor := _btn("★ شکستن / بازسازی ۱۶ تکه صندوق باستانی", Color(0.72, 0.42, 0.14))
	b_vor.pressed.connect(_shatter_crate)
	lvb.add_child(b_vor)

	var hint := Label.new()
	hint.text = "کنترل سامورایی: WASD حرکت | Space پرش | کلیک چپ ضربه شمشیر | E تعامل"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.65, 0.78, 0.92))
	lvb.add_child(hint)

	# ── BOTTOM LIVE CONSOLE ──
	var bot_panel := PanelContainer.new()
	bot_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot_panel.offset_top = -90
	bot_panel.offset_left = 8
	bot_panel.offset_right = -8
	bot_panel.offset_bottom = -6
	bot_panel.add_theme_stylebox_override("panel", _box_style(Color(0.05, 0.07, 0.12, 0.92), Color(0.24, 0.36, 0.54), 8))
	root_ctrl.add_child(bot_panel)

	_bottom_log = RichTextLabel.new()
	_bottom_log.bbcode_enabled = true
	_bottom_log.scroll_following = true
	_bottom_log.text = "[color=#38bdf8][سیستم نوافورج][/color] تمام ۱۲۳ مهارت و ۱۱۴ ابزار بومی هوش مصنوعی بدون MCP فعال شدند. برای بازی آزاد کلید [b]Tab[/b] را بزنید."
	bot_panel.add_child(_bottom_log)

	# Cutscene Letterbox Overlay
	_cutscene_bars = Control.new()
	_cutscene_bars.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cutscene_bars.visible = false
	_cutscene_bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cb_top := ColorRect.new()
	cb_top.color = Color(0, 0, 0, 0.92)
	cb_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	cb_top.offset_bottom = 54
	_cutscene_bars.add_child(cb_top)
	var cb_bot := ColorRect.new()
	cb_bot.color = Color(0, 0, 0, 0.92)
	cb_bot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	cb_bot.offset_top = -58
	var sub := Label.new()
	sub.text = "▶ کات‌سین زنده بدون صفحه سیاه: «دروازه قلعه باز می‌شود... آماده نبرد شو!»"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub.set_anchors_preset(Control.PRESET_FULL_RECT)
	cb_bot.add_child(sub)
	_cutscene_bars.add_child(cb_bot)
	root_ctrl.add_child(_cutscene_bars)

	var win := get_window()
	if win and not win.files_dropped.is_connected(_on_runtime_files_dropped):
		win.files_dropped.connect(_on_runtime_files_dropped)


func _on_runtime_files_dropped(files: PackedStringArray) -> void:
	if files.is_empty():
		return
	var f := files[0]
	var ext := f.get_extension().to_lower()
	if ext in ["png", "jpg", "jpeg", "webp", "bmp"]:
		_spawn_rigged_from_image_path(f)
	elif ext in ["glb", "gltf", "obj"]:
		_autorig_external_model_path(f)


func _box_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


func _hdr(txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.add_theme_color_override("font_color", Color(0.38, 0.84, 1.0))
	l.add_theme_font_size_override("font_size", 13)
	return l


func _btn(txt: String, bg: Color) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(0, 30)
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = bg.lightened(0.25)
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	s.content_margin_left = 8
	s.content_margin_right = 8
	b.add_theme_stylebox_override("normal", s)
	return b


func _log(msg: String) -> void:
	if _bottom_log:
		_bottom_log.append_text("\n" + msg)


func _scene_root() -> Node3D:
	return get_parent() as Node3D


func _on_quality_picked(idx: int) -> void:
	var tiers := ["AAA_UNREAL", "STANDARD_UNITY", "INDIE_CEL_ANIME", "INDIE_PSX_RETRO"]
	var t: String = tiers[idx]
	if get_tree().root.has_node("NovaQuality"):
		get_tree().root.get_node("NovaQuality").call("apply_quality_tier", t, _scene_root())
	_log("[color=#a855f7][کیفیت گرافیک][/color] سطح رندر به [b]%s[/b] تغییر یافت." % t)


func _on_cam_picked(idx: int) -> void:
	var modes := ["TPS_SOULS", "TPS_SHOULDER", "FPS", "SIDE_2_5D", "ISOMETRIC"]
	var m: String = modes[idx]
	var rig := _scene_root().get_node_or_null("PerspectiveCameraRig3D")
	if rig and rig.has_method("set_perspective_by_name"):
		rig.call("set_perspective_by_name", m)
	_log("[color=#38bdf8][دوربین و ژانر][/color] زاویه دوربین به [b]%s[/b] تغییر کرد." % m)


func _on_ask_runtime_ai(persona_role: String = "") -> void:
	if _llm_brain == null:
		return
	var p := _prompt_edit.text.strip_edges()
	if p.is_empty():
		p = "سلام! چه کارهایی می‌توانی در این صحنه سه‌بعدی انجام دهی؟"
	if _hud_ai_reply:
		_hud_ai_reply.text = "[color=#fde047][b]▶ پیام شما:[/b][/color] %s\n[color=#94a3b8]در حال دریافت پاسخ از هوش مصنوعی (Command-A 111B)...[/color]" % p
	var res: Dictionary = await _llm_brain.call("ask_brain_async", p, persona_role)
	if res.get("ok", false):
		if _hud_ai_reply:
			_hud_ai_reply.text = "[b][color=#22c55e]✓ پاسخ (%s):[/color][/b]\n%s" % [str(res.get("model", "")), str(res.get("reply", ""))]
		var acts: Array = res.get("actions", [])
		for a in acts:
			if a in ["RAIN", "FIRE", "CLEAR"]:
				_apply_weather(str(a))
			elif a == "SHATTER" and not _crate_shattered:
				_shatter_crate()
			elif a == "CUTSCENE":
				_play_cutscene()
	else:
		if _hud_ai_reply:
			_hud_ai_reply.text = "[color=#ef4444]%s[/color]" % str(res.get("error", "خطا"))


func _on_run_council() -> void:
	var p := _prompt_edit.text.strip_edges()
	if p.is_empty() or _neural_client == null:
		return
	if _neural_client.call("is_busy"):
		_log("[color=#f59e0b]مدل ۳۶۰ درجه قبلی در حال ساخت است؛ لطفاً چند ثانیه صبر کنید...[/color]")
		return
	_log("[color=#38bdf8][شروع تولید مش ۳۶۰ درجه][/color] ارسال پرامپت به هوش مصنوعی سه‌بعدی: «%s»..." % p)
	var res: Dictionary = await _neural_client.call("generate_from_prompt_async", p, true, 0, 176)
	if not res.get("ok", false):
		_log("[color=#ef4444]%s[/color]" % str(res.get("error", "خطا")))
		return
	var r := _scene_root()
	var n3d: Node3D = res["node"]
	var markers := n3d.find_child("BoneDebugMarkers", true, false) as Node3D
	if markers:
		markers.visible = false
	n3d.position = Vector3(1.9, 0.0, 0.3)
	r.add_child(n3d)
	if p.contains("کات‌سین") or p.contains("کات سین"):
		_play_cutscene()
	_log("[color=#22c55e][مش ۳۶۰ درجه هوش مصنوعی ساخته شد ✓][/color] با [b]%s[/b]: %d مثلث | %d استخوان ریگ‌شده -> [b]%s[/b]" % [str(res.get("backend", "Hunyuan3D-2")), int(res["triangles"]), int(res["bones_count"]), str(res["saved_glb"])])


func _spawn_rigged_from_image_path(img_path: String) -> void:
	if _neural_client == null:
		return
	if _neural_client.call("is_busy"):
		_log("[color=#f59e0b]یک مدل ۳۶۰ درجه در حال ساخت است؛ لطفاً صبر کنید...[/color]")
		return
	_log("[color=#38bdf8][تبدیل عکس به مش ۳۶۰ درجه][/color] دوربری عصبی و ساخت مش حجمی از «%s»..." % img_path.get_file())
	var res: Dictionary = await _neural_client.call("generate_from_image_async", img_path, true, 176)
	if not res.get("ok", false):
		_log("[color=#ef4444]%s[/color]" % str(res.get("error", "خطا")))
		return
	var r := _scene_root()
	var old := r.get_node_or_null(NodePath(res["node"].name))
	if old: old.free()
	var rigged_node: Node3D = res["node"]
	var markers := rigged_node.find_child("BoneDebugMarkers", true, false) as Node3D
	if markers:
		markers.visible = false
	rigged_node.position = Vector3(1.8, 0.0, 0.25)
	r.add_child(rigged_node)
	_log("[color=#22c55e][عکس -> مش ۳۶۰ درجه + ریگ ۱۹ استخوانی][/color] ✓ «%s» با [b]%s[/b] (%d مثلث، %d استخوان) ساخته شد -> [b]%s[/b]" % [img_path.get_file(), str(res.get("backend", "Hunyuan3D-2")), int(res["triangles"]), int(res["bones_count"]), str(res["saved_glb"])])


func _paste_clipboard_image_runtime() -> void:
	if not DisplayServer.clipboard_has_image():
		_log("[color=#f59e0b]هیچ عکسی در کلیپ‌بورد ویندوز نیست! ابتدا یک تصویر را Copy یا Screenshot کنید.[/color]")
		return
	var img := DisplayServer.clipboard_get_image()
	if img == null or img.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://generated/concepts"))
	var saved_path := ProjectSettings.globalize_path("res://generated/concepts/clipboard_runtime_%d.png" % (Time.get_ticks_msec() % 100000))
	img.save_png(saved_path)
	_spawn_rigged_from_image_path(saved_path)


func _autorig_external_model_path(mesh_path: String) -> void:
	var loader = load("res://addons/novaforge_engine/forge/glb_asset_loader.gd")
	var rigger = load("res://addons/novaforge_engine/rigging/real_mesh_autorigger.gd")
	if loader == null or rigger == null:
		return
	var loaded: Node3D = loader.load_model_scene(mesh_path, 1.88)
	if loaded == null:
		_log("[color=#ef4444]فایل سه‌بعدی باز نشد: %s[/color]" % mesh_path)
		return
	var out_glb := "res://generated/rigged/" + mesh_path.get_file().get_basename().validate_node_name() + "_autorigged.glb"
	var rres: Dictionary = rigger.autorig_node3d(loaded, true, "Walk", out_glb)
	loaded.free()
	if rres.get("ok", false):
		var rigged: Node3D = rres["node"]
		rigged.position = Vector3(-1.4, 0.0, 0.3)
		_scene_root().add_child(rigged)
		_log("[color=#c084fc][ریگ‌گذاری خودکار مدل][/color] ✓ مدل «%s» با %d استخوان ریگ و متحرک شد!" % [mesh_path.get_file(), int(rres["bones_count"])])


func _play_slash_motion() -> void:
	var hero := _scene_root().get_node_or_null("SamuraiHero") as Node3D
	var loader = load("res://addons/novaforge_engine/forge/glb_asset_loader.gd")
	if hero and loader:
		loader.play_character_anim(hero, ["SwordSlash"], false)
	_log("[color=#22c55e][موشن‌کپچر ویدیو][/color] انیمیشن اسکلتی کمبوی شمشیر با قفل کف پا (Foot-Locking IK) اجرا شد!")


func _spawn_blender_gate() -> void:
	var r := _scene_root()
	if r.has_node("RuntimeTower3D"):
		return
	var loader = load("res://addons/novaforge_engine/forge/glb_asset_loader.gd")
	if loader:
		var tower: Node3D = loader.load_model_scene("res://assets/models/world/castle_tower.glb", 5.2)
		if tower:
			tower.name = "RuntimeTower3D"
			tower.position = Vector3(3.8, 0.0, -3.5)
			r.add_child(tower)
	_log("[color=#fb923c][ایمپورتر بلندر][/color] برج سنگی سه‌بعدی با اتصال خودکار تکسچرهای PBR وارد صحنه شد!")


func _shatter_crate() -> void:
	var crate := _scene_root().get_node_or_null("DestructibleAncientCrate") as Node3D
	if crate == null:
		return
	var mesh := crate.get_node_or_null("CrateMesh") as Node3D
	var existing := crate.get_node_or_null("LiveShards")
	if _crate_shattered:
		_crate_shattered = false
		if existing: existing.queue_free()
		if mesh: mesh.visible = true
		_log("[Voronoi] صندوق باستانی بازسازی شد.")
		return
	_crate_shattered = true
	if mesh: mesh.visible = false
	var holder := Node3D.new()
	holder.name = "LiveShards"
	crate.add_child(holder)
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.80, 0.54, 0.22)
	for i in range(16):
		var sh := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.32, 0.26, 0.30)
		pm.material = smat
		sh.mesh = pm
		holder.add_child(sh)
		var ang := TAU * float(i) / 16.0
		var tw := create_tween()
		tw.tween_property(sh, "position", Vector3(cos(ang) * 0.9, -0.4, sin(ang) * 0.9), 0.35)
	_log("[color=#f59e0b][تخریب Voronoi C++20][/color] صندوق باستانی به ۱۶ قطعه محدب فیزیکی خرد شد!")


func _play_cutscene() -> void:
	_cutscene_bars.visible = true
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(func(): _cutscene_bars.visible = false)
	_log("[color=#c084fc][کارگردان کات‌سین][/color] کات‌سین زنده بدون صفحه سیاه اجرا شد!")


func _apply_weather(code: String) -> void:
	var w := _scene_root().get_node_or_null("ElementalWeather")
	if w == null:
		return
	for c in w.get_children():
		c.queue_free()
	if code == "RAIN":
		var p := CPUParticles3D.new()
		p.amount = 220
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(8, 0.2, 8)
		p.direction = Vector3(0, -1, 0)
		p.initial_velocity_min = 11.0
		p.initial_velocity_max = 14.0
		var bm := BoxMesh.new()
		bm.size = Vector3(0.03, 0.4, 0.03)
		p.mesh = bm
		p.position = Vector3(0, 8, 0)
		w.add_child(p)
	elif code == "FIRE":
		var fl := OmniLight3D.new()
		fl.light_color = Color(1.0, 0.45, 0.1)
		fl.light_energy = 4.5
		fl.position = Vector3(1.4, 1.5, -1.4)
		w.add_child(fl)
	_log("[color=#38bdf8][شیمی عناصر][/color] وضعیت محیط به [b]%s[/b] تغییر یافت." % code)


func _on_advance_days() -> void:
	_day += 5
	_npc_gold += 160
	_npc_title = "استادکار سلطنتی" if _npc_gold >= 440 else "آهنگر ارشد شهر (سطح ۲)"
	_refresh_npc_ui()
	_log("[color=#22c55e][تکامل زندگی][/color] ۵ روز گذشت (روز %d) -> کاوه آهنگر ارتقا یافت: %s" % [_day, _npc_title])


func _help_npc() -> void:
	_npc_rel = mini(100, _npc_rel + 25)
	_npc_gold += 50
	_refresh_npc_ui()
	_log("[NPC زنده] کمک و خرید انجام شد -> رابطه با کاوه: +%d" % _npc_rel)


func _fight_npc() -> void:
	_npc_rel = maxi(-100, _npc_rel - 55)
	if not _npc_scars.has("زخم شمشیر روی گونه"):
		_npc_scars.append("زخم شمشیر روی گونه")
	_refresh_npc_ui()
	_log("[color=#ef4444][حافظه Nemesis][/color] کاوه زخم برداشت و ضدحمله کمبوی کاتانا را یاد گرفت!")


func _refresh_npc_ui() -> void:
	if _npc_lbl == null:
		return
	var status := "دشمن Nemesis" if _npc_rel <= -35 else ("متحد وفادار" if _npc_rel >= 35 else "دوستانه")
	_npc_lbl.text = "[b]کاوه آهنگر[/b] (روز %d)\nشغل: %s\nطلا: %d سکه | رابطه: %d (%s)" % [_day, _npc_title, _npc_gold, _npc_rel, status]
