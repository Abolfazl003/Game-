@tool
extends ScrollContainer
## Central Full-Screen Customized Persian Main Workspace (`⚡ میزکار نوافورج`).
## Features:
## 1. Real Semantic Persian/English Prompt-to-3D `.GLB` World Builder (39 rigged/textured CC0 3D models — ZERO capsules!)
## 2. Embedded Full Interactive Image-to-3D Mesh Reconstruction & Real Vertex-Skinning Auto-Rigger Studio (`FileDialog` + Drag & Drop)
## 3. Blender/3D File Picker Auto-PBR Importer, Voronoi 3D Destruction, Live Cutscene Sequencer, Elemental Chemistry & Evolving NPC AI.

var _prompt_box: TextEdit
var _status_banner: RichTextLabel
var _npc_summary: RichTextLabel
var _blender_file_dialog: FileDialog


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var outer_margin := MarginContainer.new()
	outer_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_margin.add_theme_constant_override("margin_left", 14)
	outer_margin.add_theme_constant_override("margin_right", 14)
	outer_margin.add_theme_constant_override("margin_top", 10)
	outer_margin.add_theme_constant_override("margin_bottom", 14)
	add_child(outer_margin)

	var root_vb := VBoxContainer.new()
	root_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vb.add_theme_constant_override("separation", 10)
	outer_margin.add_child(root_vb)

	# ── 1. TOP HERO HEADER ──
	var header_card := _styled_card(Color(0.08, 0.12, 0.21), Color(0.24, 0.78, 0.98))
	var header_hb := HBoxContainer.new()
	header_hb.add_theme_constant_override("separation", 10)

	var title_lbl := Label.new()
	title_lbl.text = "⚡ میزکار مرکزی نوافورج — ساخت مدل‌های سه‌بعدی واقعی (.GLB)، تبدیل عکس به مش 3D و ریگ‌گذاری خودکار اسکلت"
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.clip_text = true
	header_hb.add_child(title_lbl)

	var btn_goto_3d := _action_btn("▶ رفتن به نمای زنده صحنه سه‌بعدی (3D)", Color(0.10, 0.50, 0.80))
	btn_goto_3d.pressed.connect(_goto_3d_screen)
	header_hb.add_child(btn_goto_3d)
	header_card.add_child(header_hb)
	root_vb.add_child(header_card.get_parent())

	# ── 2. REAL IMAGE-TO-3D MESH & AUTO-RIGGER STUDIO (EMBEDDED FRONT-AND-CENTER!) ──
	var forge_scr = load("res://addons/novaforge_engine/editor/image_to_mesh_rig_panel.gd")
	if forge_scr:
		var forge_panel: Control = forge_scr.new()
		root_vb.add_child(forge_panel)

	# ── 3. SEMANTIC PROMPT-TO-REAL-3D WORLD BUILDER + 5-BRAIN COLIBRÌ COUNCIL ──
	var prompt_row := HBoxContainer.new()
	prompt_row.add_theme_constant_override("separation", 10)
	prompt_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var p_card := _styled_card(Color(0.09, 0.13, 0.22), Color(0.22, 0.78, 0.98))
	p_card.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p_card.add_child(_sec_title("⚡ ساخت مش سه‌بعدی ۳۶۰ درجه واقعی از هر پرامپت فارسی و انگلیسی با هوش مصنوعی (Flux + Hunyuan3D-2 + ریگ خودکار)"))

	_prompt_box = TextEdit.new()
	_prompt_box.custom_minimum_size = Vector2(0, 62)
	_prompt_box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_prompt_box.text = "یه ربات سامورایی سیاه و طلایی با زره سنگین بساز"
	p_card.add_child(_prompt_box)

	var preset_hb := HBoxContainer.new()
	preset_hb.add_theme_constant_override("separation", 6)
	for pr in [
		["ربات سامورایی طلایی", "یه ربات سامورایی سیاه و طلایی با زره سنگین بساز"],
		["اژدهای آتشین بال‌دار", "یه اژدهای آتشین قرمز و سیاه با بال‌های باز بساز"],
		["ماشین لامبورگینی آبی", "یه ماشین سوپراسپرت آینده‌نگر آبی متالیک بساز"],
		["شمشیر افسانه‌ای نوری", "یه شمشیر افسانه‌ای سلطنتی طلایی و یاقوتی بساز"],
	]:
		var p_txt: String = pr[1]
		var pb := Button.new()
		pb.text = "✦ " + str(pr[0])
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pb.pressed.connect(func():
			_prompt_box.text = p_txt
			_on_run_prompt()
		)
		preset_hb.add_child(pb)
	p_card.add_child(preset_hb)

	var act_hb := HBoxContainer.new()
	act_hb.add_theme_constant_override("separation", 8)
	var btn_build := _action_btn("⚡ ساخت مدل ۳۶۰ درجه واقعی با هوش مصنوعی + ریگ خودکار (.GLB)", Color(0.10, 0.48, 0.86))
	btn_build.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_build.pressed.connect(_on_run_prompt)
	act_hb.add_child(btn_build)

	var btn_env := _action_btn("✦ چیدمان سریع محیط صحنه", Color(0.14, 0.48, 0.36))
	btn_env.pressed.connect(func():
		var c := _get_ctrl()
		if c and c.has_method("run_library_world_layout"):
			c.call("run_library_world_layout", _prompt_box.text)
	)
	act_hb.add_child(btn_env)

	var btn_clear := _action_btn("↺ پاک کردن", Color(0.32, 0.36, 0.46))
	btn_clear.pressed.connect(func():
		var c := _get_ctrl()
		if c: c.call("clear_ai_spawned_world")
	)
	act_hb.add_child(btn_clear)
	p_card.add_child(act_hb)
	prompt_row.add_child(p_card.get_parent())
	root_vb.add_child(prompt_row)

	# ── 4. CAPABILITIES GRID (BLENDER FILE PICKER, VORONOI, CUTSCENE, WEATHER, NPC) ──
	var cap_grid := GridContainer.new()
	cap_grid.columns = 3
	cap_grid.add_theme_constant_override("h_separation", 10)
	cap_grid.add_theme_constant_override("v_separation", 10)
	cap_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vb.add_child(cap_grid)

	# Blender / 3D File Picker Auto-PBR
	var m_bl := _styled_card(Color(0.10, 0.14, 0.22), Color(0.95, 0.56, 0.22))
	m_bl.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m_bl.add_child(_sec_title("✦ ایمپورتر فایل سه‌بعدی بلندر و تکسچر خودکار"))
	m_bl.add_child(_desc_lbl("انتخاب هر فایل .glb / .gltf / .obj از سیستم و اتصال خودکار متریال PBR + اصلاح Normal Map."))
	var b_bl := _action_btn("■ انتخاب فایل مدل از سیستم و ایمپورت در صحنه", Color(0.68, 0.36, 0.12))
	b_bl.pressed.connect(func(): _blender_file_dialog.popup_centered(Vector2i(760, 500)))
	m_bl.add_child(b_bl)
	cap_grid.add_child(m_bl.get_parent())

	# Voronoi 3D Destruction
	var m_vor := _styled_card(Color(0.10, 0.14, 0.22), Color(0.92, 0.35, 0.35))
	m_vor.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m_vor.add_child(_sec_title("★ تخریب فیزیکی واقعی (Voronoi 3D + Jolt)"))
	m_vor.add_child(_desc_lbl("خرد شدن هم‌زمان مش سه‌بعدی صندوق چوبی به ۱۶ قطعه فیزیکی با انیمیشن ضربه شمشیر سامورایی."))
	var b_vor := _action_btn("★ تست ضربه شمشیر و متلاشی کردن صندوق", Color(0.68, 0.22, 0.24))
	b_vor.pressed.connect(func(): _call_ctrl_and_view3d("shatter_or_reset_crate"))
	m_vor.add_child(b_vor)
	cap_grid.add_child(m_vor.get_parent())

	# Cutscene + Elemental Chemistry
	var m_cut := _styled_card(Color(0.10, 0.14, 0.22), Color(0.72, 0.38, 0.95))
	m_cut.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m_cut.add_child(_sec_title("▶ کات‌سین زنده و شیمی عناصر محیط"))
	var hb_cw := HBoxContainer.new()
	hb_cw.add_theme_constant_override("separation", 5)
	var b_cut := _action_btn("▶ کات‌سین زنده", Color(0.48, 0.24, 0.72))
	b_cut.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_cut.pressed.connect(func(): _call_ctrl_and_view3d("trigger_live_cutscene"))
	hb_cw.add_child(b_cut)
	for pair in [["RAIN", "◈ باران"], ["FIRE", "▲ آتش"], ["LIGHTNING", "⚡ صاعقه"]]:
		var code: String = pair[0]
		var wb := _action_btn(pair[1], Color(0.16, 0.38, 0.54))
		wb.pressed.connect(func():
			var c := _get_ctrl()
			if c: c.call("apply_elemental_weather", code)
			if Engine.is_editor_hint(): EditorInterface.set_main_screen_editor("3D")
		)
		hb_cw.add_child(wb)
	m_cut.add_child(_desc_lbl("اجرای حرکت سینمایی دوربین بدون صفحه سیاه و شبیه‌سازی باران، آتش و صاعقه."))
	m_cut.add_child(hb_cw)
	cap_grid.add_child(m_cut.get_parent())

	# ── 5. LIVING NPC & STATUS FOOTER ──
	var bot_card := _styled_card(Color(0.10, 0.13, 0.20), Color(0.95, 0.76, 0.25))
	bot_card.add_child(_sec_title("✦ زندگی تکاملی و حافظه دشمن (Evolving Life & Nemesis AI — کاوه آهنگر)"))
	_npc_summary = RichTextLabel.new()
	_npc_summary.bbcode_enabled = true
	_npc_summary.fit_content = true
	_npc_summary.scroll_active = false
	_npc_summary.text = "[b]کاوه آهنگر:[/b] شاگرد آهنگر (سطح ۱) | طلا: ۱۲۰ سکه | رابطه: +۱۰ (دوستانه) | روز ۱"
	bot_card.add_child(_npc_summary)

	var npc_bar := HBoxContainer.new()
	npc_bar.add_theme_constant_override("separation", 8)
	var b_nh := _action_btn("✦ کمک و خرید (+رابطه)", Color(0.15, 0.52, 0.34))
	b_nh.pressed.connect(func():
		var c := _get_ctrl()
		if c: c.call("help_npc")
	)
	npc_bar.add_child(b_nh)

	var b_nf := _action_btn("⚔ درگیری و ثبت زخم/ضدحمله Nemesis", Color(0.68, 0.20, 0.22))
	b_nf.pressed.connect(func():
		var c := _get_ctrl()
		if c: c.call("fight_npc")
		if Engine.is_editor_hint(): EditorInterface.set_main_screen_editor("3D")
	)
	npc_bar.add_child(b_nf)

	var b_nd := _action_btn("» جلو بردن زمان دنیا (+۵ روز تکامل زندگی)", Color(0.55, 0.42, 0.14))
	b_nd.pressed.connect(func():
		var c := _get_ctrl()
		if c: c.call("advance_world_days", 5)
	)
	npc_bar.add_child(b_nd)
	bot_card.add_child(npc_bar)

	_status_banner = RichTextLabel.new()
	_status_banner.bbcode_enabled = true
	_status_banner.fit_content = true
	_status_banner.scroll_active = false
	_status_banner.text = "[color=#38bdf8]✓ استودیو آماده است — عکس دلخواه را انتخاب کنید تا به مش سه‌بعدی واقعی (.GLB) تبدیل و ریگ شود، یا در کادر بالا پرامپت بنویسید.[/color]"
	bot_card.add_child(_status_banner)
	root_vb.add_child(bot_card.get_parent())

	_blender_file_dialog = FileDialog.new()
	_blender_file_dialog.title = "انتخاب مدل سه‌بعدی برای ایمپورت خودکار در صحنه"
	_blender_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_blender_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_blender_file_dialog.use_native_dialog = OS.get_name() in ["Windows", "macOS"]
	_blender_file_dialog.filters = PackedStringArray(["*.glb, *.gltf, *.obj ; مدل‌های سه‌بعدی"])
	_blender_file_dialog.file_selected.connect(func(p: String):
		var c := _get_ctrl()
		if c: c.call("import_blender_auto_pbr_gate", p)
		_goto_3d_screen()
	)
	add_child(_blender_file_dialog)

	call_deferred("_bind_ctrl")


func _styled_card(bg: Color, border: Color) -> VBoxContainer:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	pc.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	pc.add_child(vb)
	return vb


func _sec_title(txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(0.45, 0.86, 1.0))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _desc_lbl(txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(0.80, 0.86, 0.94))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _action_btn(txt: String, bg: Color) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(0, 33)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = bg.lightened(0.32)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = bg.lightened(0.15)
	b.add_theme_stylebox_override("hover", sbh)
	return b


func _get_ctrl() -> Node:
	if get_tree() and get_tree().root.has_node("NovaEditorController"):
		return get_tree().root.get_node("NovaEditorController")
	return null


func _bind_ctrl() -> void:
	var ctrl := _get_ctrl()
	if ctrl:
		if ctrl.has_signal("state_updated") and not ctrl.is_connected("state_updated", _on_state_updated):
			ctrl.connect("state_updated", _on_state_updated)
		if ctrl.has_signal("log_emitted") and not ctrl.is_connected("log_emitted", _on_log_emitted):
			ctrl.connect("log_emitted", _on_log_emitted)


func _on_state_updated(st: Dictionary) -> void:
	if _npc_summary == null:
		return
	var n: Dictionary = st.get("npc", {})
	var rel: int = int(n.get("rel", 10))
	var tag := "دشمن خونی Nemesis" if rel <= -35 else ("متحد وفادار" if rel >= 35 else "معمولی")
	_npc_summary.text = "[b]کاوه آهنگر (روز %d):[/b] %s | طلا: %d سکه | رابطه: %d (%s)" % [
		int(st.get("day", 1)), str(n.get("title", "شاگرد آهنگر")), int(n.get("gold", 120)), rel, tag
	]


func _on_log_emitted(bbcode_line: String) -> void:
	if _status_banner:
		_status_banner.text = bbcode_line


func _goto_3d_screen() -> void:
	var ctrl := _get_ctrl()
	if ctrl and ctrl.has_method("switch_to_3d_viewport"):
		ctrl.call("switch_to_3d_viewport")
		return
	if Engine.is_editor_hint():
		var loc := TranslationServer.translate("3D")
		EditorInterface.set_main_screen_editor(loc if not loc.is_empty() else "3D")


func _call_ctrl_and_view3d(method_name: String) -> void:
	var ctrl := _get_ctrl()
	if ctrl and ctrl.has_method(method_name):
		ctrl.call(method_name)
	_goto_3d_screen()


func _on_run_prompt() -> void:
	var p := _prompt_box.text.strip_edges()
	if p.is_empty():
		return
	var ctrl := _get_ctrl()
	if ctrl and ctrl.has_method("run_prompt_council_build"):
		ctrl.call("run_prompt_council_build", p)
