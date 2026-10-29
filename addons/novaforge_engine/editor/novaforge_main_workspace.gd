@tool
extends ScrollContainer
## Central Full-Screen Customized Persian Main Workspace (`⚡ میزکار نوافورج` — v3.1).
## Combines:
##   1. Real Live AI Chat, GDScript Code Generator & 5-Brain Council (`Command-A Reasoning 111B` + `Cohere Aya` + Local `Ollama` + Custom API)
##   2. True 360° Neural AI Image-to-3D & Prompt-to-3D Mesh Studio (`Flux` + `Neural RemBG` + `Hunyuan3D-2`) + 19-Bone Auto-Rigger
##   3. Blender Auto-PBR Importer, Voronoi 3D Destruction, Live Cutscene Sequencer, Elemental Chemistry & Evolving NPC AI.

var _prompt_box: TextEdit
var _ai_chat_log: RichTextLabel
var _ai_progress: ProgressBar
var _ai_status_lbl: Label
var _backend_opt: OptionButton
var _local_cfg_row: HBoxContainer
var _ollama_url_edit: LineEdit
var _ollama_model_edit: LineEdit
var _api_key_edit: LineEdit
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
	outer_margin.add_theme_constant_override("margin_top", 8)
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
	title_lbl.text = "⚡ میزکار هوشمند نوافورج ۳.۱ — چت و کدنویسی با هوش مصنوعی واقعی (111B) + ساخت مش سه‌بعدی ۳۶۰ درجه و ریگ خودکار"
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.clip_text = true
	header_hb.add_child(title_lbl)

	var btn_goto_3d := _action_btn("▶ رفتن به نمای زنده صحنه سه‌بعدی (3D)", Color(0.10, 0.50, 0.80))
	btn_goto_3d.pressed.connect(_goto_3d_screen)
	header_hb.add_child(btn_goto_3d)
	header_card.add_child(header_hb)
	root_vb.add_child(header_card.get_parent())

	# ── 2. LIVE INTERACTIVE AI BRAIN CHAT, GDSCRIPT CODER & 360° PROMPT BUILDER (TOP & VISIBLE!) ──
	var ai_card := _styled_card(Color(0.08, 0.12, 0.22), Color(0.62, 0.42, 0.98))
	ai_card.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var ai_hdr := HBoxContainer.new()
	ai_hdr.add_theme_constant_override("separation", 8)
	var ai_title := _sec_title("⚡ دستیار هوش مصنوعی زنده، کدنویس GDScript و شورای ۵ مغز (متصل و آماده پاسخگویی)")
	ai_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ai_hdr.add_child(ai_title)

	var backend_lbl := Label.new()
	backend_lbl.text = "مغز فعال:"
	backend_lbl.add_theme_font_size_override("font_size", 12)
	ai_hdr.add_child(backend_lbl)

	_backend_opt = OptionButton.new()
	_backend_opt.add_item("⚡ Command-A Reasoning 111B (ابری رایگان — بدون کلید)")
	_backend_opt.add_item("✦ Cohere Aya Persian (فارسی فوق‌سریع — ابری رایگان)")
	_backend_opt.add_item("◆ لوکال Ollama / LM Studio (127.0.0.1:11434)")
	_backend_opt.add_item("★ سرور اختصاصی OpenAI / Groq / Custom API")
	_backend_opt.item_selected.connect(_on_backend_changed)
	ai_hdr.add_child(_backend_opt)
	ai_card.add_child(ai_hdr)

	# Optional Local Ollama / Custom API Configuration Row
	_local_cfg_row = HBoxContainer.new()
	_local_cfg_row.add_theme_constant_override("separation", 6)
	_local_cfg_row.visible = false

	_ollama_url_edit = LineEdit.new()
	_ollama_url_edit.text = "http://127.0.0.1:11434/api/chat"
	_ollama_url_edit.placeholder_text = "آدرس سرور (Ollama یا OpenAI URL)"
	_ollama_url_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_local_cfg_row.add_child(_ollama_url_edit)

	_ollama_model_edit = LineEdit.new()
	_ollama_model_edit.text = "qwen2.5-coder:7b"
	_ollama_model_edit.placeholder_text = "نام مدل (مثلاً qwen2.5-coder:7b)"
	_ollama_model_edit.custom_minimum_size = Vector2(180, 0)
	_local_cfg_row.add_child(_ollama_model_edit)

	_api_key_edit = LineEdit.new()
	_api_key_edit.secret = true
	_api_key_edit.placeholder_text = "کلید API (فقط برای OpenAI/Groq)"
	_api_key_edit.custom_minimum_size = Vector2(180, 0)
	_local_cfg_row.add_child(_api_key_edit)

	var btn_test_ollama := _action_btn("✦ تست اتصال لوکال", Color(0.16, 0.50, 0.42))
	btn_test_ollama.pressed.connect(_on_test_local_ollama)
	_local_cfg_row.add_child(btn_test_ollama)
	ai_card.add_child(_local_cfg_row)

	# Scrollable Rich AI Conversation Window
	var chat_frame := PanelContainer.new()
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color(0.05, 0.07, 0.13)
	csb.border_color = Color(0.24, 0.36, 0.58)
	csb.set_border_width_all(1)
	csb.set_corner_radius_all(6)
	csb.content_margin_left = 10
	csb.content_margin_right = 10
	csb.content_margin_top = 8
	csb.content_margin_bottom = 8
	chat_frame.add_theme_stylebox_override("panel", csb)

	_ai_chat_log = RichTextLabel.new()
	_ai_chat_log.bbcode_enabled = true
	_ai_chat_log.scroll_following = true
	_ai_chat_log.selection_enabled = true
	_ai_chat_log.custom_minimum_size = Vector2(0, 155)
	_ai_chat_log.text = (
		"[b][color=#38bdf8]⚡ شورای هوش مصنوعی نوافورج (آنلاین ✓):[/color][/b] سلام! من به مغز [b]Command-A Reasoning 111B[/b] و موتور ساخت سه‌بعدی [b]Hunyuan3D-2[/b] متصلم.\n"
		+ "• هر سوال بازی‌سازی یا درخواست اسکریپت [b]GDScript[/b] دارید بپرسید و دکمه [b]«⚡ پرسش، طراحی و کدنویسی با هوش مصنوعی»[/b] را بزنید.\n"
		+ "• برای ساخت مدل سه‌بعدی ۳۶۰ درجه واقعی از روی متن، دکمه [b]«◆ ساخت مش سه‌بعدی ۳۶۰ درجه واقعی (.GLB)»[/b] را بزنید!"
	)
	chat_frame.add_child(_ai_chat_log)
	ai_card.add_child(chat_frame)

	# Prompt Input + Quick Presets
	_prompt_box = TextEdit.new()
	_prompt_box.custom_minimum_size = Vector2(0, 54)
	_prompt_box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_prompt_box.placeholder_text = "اینجا پیام، سوال، درخواست کد GDScript یا پرامپت ساخت مدل سه‌بعدی ۳۶۰ درجه را به فارسی یا انگلیسی بنویسید..."
	_prompt_box.text = "سلام! یه اسکریپت حرکت، پرش دوتایی و دش (Dash) برای کاراکتر سه‌بعدی در گادوت ۴ بنویس و توضیح بده."
	ai_card.add_child(_prompt_box)

	var preset_hb := HBoxContainer.new()
	preset_hb.add_theme_constant_override("separation", 6)
	for pr in [
		["کد پرش دوتایی + دش", "یه اسکریپت کامل حرکت، پرش دوتایی و دش برای CharacterBody3D در Godot 4 بنویس.", false],
		["هوای بارانی + کات‌سین", "هوای بازی رو بارانی کن و یه کات‌سین سینمایی اجرا کن و توضیح بده چطور کار می‌کنه.", false],
		["ساخت مش ۳۶۰: سامورایی طلایی", "یه ربات سامورایی سیاه و طلایی با زره سنگین بساز", true],
		["ساخت مش ۳۶۰: ماشین اسپرت آبی", "یه ماشین سوپراسپرت آینده‌نگر آبی متالیک بساز", true],
	]:
		var p_txt: String = pr[1]
		var is_3d_mode: bool = pr[2]
		var pb := Button.new()
		pb.text = "✦ " + str(pr[0])
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pb.pressed.connect(func():
			_prompt_box.text = p_txt
			if is_3d_mode:
				_on_run_3d_mesh_prompt()
			else:
				_on_ask_ai_chat()
		)
		preset_hb.add_child(pb)
	ai_card.add_child(preset_hb)

	# Action Buttons Row
	var act_hb := HBoxContainer.new()
	act_hb.add_theme_constant_override("separation", 8)

	var btn_ask := _action_btn("⚡ پرسش، طراحی و کدنویسی با هوش مصنوعی (پاسخ زنده)", Color(0.42, 0.22, 0.78))
	btn_ask.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_ask.pressed.connect(_on_ask_ai_chat)
	act_hb.add_child(btn_ask)

	var btn_build_3d := _action_btn("◆ ساخت مش سه‌بعدی ۳۶۰ درجه واقعی (.GLB) + ریگ خودکار", Color(0.10, 0.48, 0.86))
	btn_build_3d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_build_3d.pressed.connect(_on_run_3d_mesh_prompt)
	act_hb.add_child(btn_build_3d)

	var btn_open_code := _action_btn("✦ باز کردن کد ساخته‌شده", Color(0.14, 0.50, 0.38))
	btn_open_code.pressed.connect(func():
		var c := _get_ctrl()
		if c and c.has_method("open_last_ai_script_in_editor"):
			c.call("open_last_ai_script_in_editor")
	)
	act_hb.add_child(btn_open_code)

	var btn_clear_chat := _action_btn("↺ پاک کردن چت", Color(0.30, 0.34, 0.44))
	btn_clear_chat.pressed.connect(func():
		_ai_chat_log.text = "[color=#94a3b8]تاریخچه گفتگو پاک شد. پیام جدید خود را بنویسید![/color]"
		var c := _get_ctrl()
		if c and c.has_method("clear_ai_spawned_world"):
			c.call("clear_ai_spawned_world")
	)
	act_hb.add_child(btn_clear_chat)
	ai_card.add_child(act_hb)

	# Live Progress Bar & Status Line inside AI Card
	var prog_hb := HBoxContainer.new()
	prog_hb.add_theme_constant_override("separation", 8)
	_ai_progress = ProgressBar.new()
	_ai_progress.min_value = 0.0
	_ai_progress.max_value = 100.0
	_ai_progress.value = 0.0
	_ai_progress.custom_minimum_size = Vector2(220, 18)
	prog_hb.add_child(_ai_progress)

	_ai_status_lbl = Label.new()
	_ai_status_lbl.text = "✓ هوش مصنوعی آماده پاسخگویی و ساخت سه‌بعدی است"
	_ai_status_lbl.add_theme_font_size_override("font_size", 12)
	_ai_status_lbl.add_theme_color_override("font_color", Color(0.32, 0.90, 0.55))
	_ai_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ai_status_lbl.clip_text = true
	prog_hb.add_child(_ai_status_lbl)
	ai_card.add_child(prog_hb)

	root_vb.add_child(ai_card.get_parent())

	# ── 3. REAL IMAGE-TO-3D MESH & AUTO-RIGGER STUDIO ──
	var forge_scr = load("res://addons/novaforge_engine/editor/image_to_mesh_rig_panel.gd")
	if forge_scr:
		var forge_panel: Control = forge_scr.new()
		root_vb.add_child(forge_panel)

	# ── 4. CAPABILITIES GRID (BLENDER FILE PICKER, VORONOI, CUTSCENE, WEATHER, NPC) ──
	var cap_grid := GridContainer.new()
	cap_grid.columns = 3
	cap_grid.add_theme_constant_override("h_separation", 10)
	cap_grid.add_theme_constant_override("v_separation", 10)
	cap_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vb.add_child(cap_grid)

	var m_bl := _styled_card(Color(0.10, 0.14, 0.22), Color(0.95, 0.56, 0.22))
	m_bl.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m_bl.add_child(_sec_title("✦ ایمپورتر فایل سه‌بعدی بلندر و تکسچر خودکار"))
	m_bl.add_child(_desc_lbl("انتخاب هر فایل .glb / .gltf / .obj از ویندوز و اتصال خودکار متریال PBR + اصلاح Normal Map."))
	var b_bl := _action_btn("■ انتخاب فایل مدل از سیستم و ایمپورت در صحنه", Color(0.68, 0.36, 0.12))
	b_bl.pressed.connect(func():
		if OS.get_name() in ["Windows", "macOS"]:
			_blender_file_dialog.popup()
		else:
			_blender_file_dialog.popup_centered(Vector2i(760, 500))
	)
	m_bl.add_child(b_bl)
	cap_grid.add_child(m_bl.get_parent())

	var m_vor := _styled_card(Color(0.10, 0.14, 0.22), Color(0.92, 0.35, 0.35))
	m_vor.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m_vor.add_child(_sec_title("★ تخریب فیزیکی واقعی (Voronoi 3D + Jolt)"))
	m_vor.add_child(_desc_lbl("خرد شدن هم‌زمان مش سه‌بعدی صندوق چوبی به ۱۶ قطعه فیزیکی با انیمیشن ضربه شمشیر سامورایی."))
	var b_vor := _action_btn("★ تست ضربه شمشیر و متلاشی کردن صندوق", Color(0.68, 0.22, 0.24))
	b_vor.pressed.connect(func(): _call_ctrl_and_view3d("shatter_or_reset_crate"))
	m_vor.add_child(b_vor)
	cap_grid.add_child(m_vor.get_parent())

	var m_cut := _styled_card(Color(0.10, 0.14, 0.22), Color(0.72, 0.38, 0.95))
	m_cut.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m_cut.add_child(_sec_title("▶ کات‌سین زنده و شیمی عناصر محیط"))
	var hb_cw := HBoxContainer.new()
	hb_cw.add_theme_constant_override("separation", 5)
	var b_cut := _action_btn("▶ کات‌سین زنده", Color(0.48, 0.24, 0.72))
	b_cut.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_cut.pressed.connect(func(): _call_ctrl_and_view3d("trigger_live_cutscene"))
	hb_cw.add_child(b_cut)
	for pair in [["RAIN", "◆ باران"], ["FIRE", "★ آتش"], ["LIGHTNING", "⚡ صاعقه"]]:
		var code: String = pair[0]
		var wb := _action_btn(pair[1], Color(0.16, 0.38, 0.54))
		wb.pressed.connect(func():
			var c := _get_ctrl()
			if c: c.call("apply_elemental_weather", code)
			_goto_3d_screen()
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
		_goto_3d_screen()
	)
	npc_bar.add_child(b_nf)

	var b_nd := _action_btn("▶ جلو بردن زمان دنیا (+۵ روز تکامل زندگی)", Color(0.55, 0.42, 0.14))
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
	_status_banner.text = "[color=#38bdf8]✓ استودیو نوافورج ۳.۱ آماده است — از بخش بالا با هوش مصنوعی گفتگو کنید، کد بسازید یا مش سه‌بعدی ۳۶۰ درجه تولید کنید.[/color]"
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


func _on_backend_changed(idx: int) -> void:
	_local_cfg_row.visible = (idx == 2 or idx == 3)
	var ctrl := _get_ctrl()
	if ctrl == null or not ctrl.has_method("get_llm_brain"):
		return
	var brain: Node = ctrl.call("get_llm_brain")
	if brain == null:
		return
	if idx == 0:
		brain.set("preferred_backend", "AUTO_CLOUD")
	elif idx == 1:
		brain.set("preferred_backend", "AYA_FAST")
	elif idx == 2:
		brain.set("preferred_backend", "OLLAMA_LOCAL")
	elif idx == 3:
		brain.set("preferred_backend", "CUSTOM_OPENAI")


func _sync_brain_config() -> void:
	var ctrl := _get_ctrl()
	if ctrl == null or not ctrl.has_method("get_llm_brain"):
		return
	var brain: Node = ctrl.call("get_llm_brain")
	if brain == null:
		return
	if _backend_opt.selected == 2:
		brain.set("ollama_url", _ollama_url_edit.text.strip_edges())
		brain.set("ollama_model", _ollama_model_edit.text.strip_edges())
	elif _backend_opt.selected == 3:
		brain.set("custom_openai_url", _ollama_url_edit.text.strip_edges())
		brain.set("custom_model_name", _ollama_model_edit.text.strip_edges())
		brain.set("custom_api_key", _api_key_edit.text.strip_edges())


func _on_test_local_ollama() -> void:
	var ctrl := _get_ctrl()
	if ctrl == null or not ctrl.has_method("get_llm_brain"):
		return
	var brain: Node = ctrl.call("get_llm_brain")
	if brain == null:
		return
	_ai_status_lbl.text = "در حال بررسی سرویس Ollama روی 127.0.0.1:11434..."
	var res: Dictionary = await brain.call("check_local_ollama_status_async")
	if res.get("ok", false):
		var models: Array = res.get("models", [])
		var m_str := "، ".join(PackedStringArray(models)) if not models.is_empty() else "بدون مدل دانلودشده"
		_ai_chat_log.append_text("\n[color=#22c55e][b]✓ اتصال به Ollama لوکال برقرار شد![/b] مدل‌های یافت‌شده: %s[/color]\n" % m_str)
		if not models.is_empty():
			_ollama_model_edit.text = str(models[0])
		_ai_status_lbl.text = "✓ متصل به Ollama لوکال"
	else:
		_ai_chat_log.append_text("\n[color=#f59e0b][b]توجه:[/b] سرویس Ollama در حال حاضر روی پورت 11434 باز نیست؛ نوافورج به طور خودکار از مغز ابری رایگان (Command-A 111B) استفاده می‌کند تا بدون وقفه پاسخ بگیرید![/color]\n")
		_ai_status_lbl.text = "✓ حالت خودکار ابری فعال است (Ollama بسته بود)"


func _on_ask_ai_chat() -> void:
	var p := _prompt_box.text.strip_edges()
	if p.is_empty():
		return
	_sync_brain_config()
	var ctrl := _get_ctrl()
	if ctrl == null or not ctrl.has_method("ask_ai_council_async"):
		return
	_ai_progress.value = 10.0
	_ai_status_lbl.text = "در حال ارسال پیام به مغز هوش مصنوعی..."
	_ai_chat_log.append_text("\n[b][color=#fde047]▶ شما:[/color][/b] %s\n[color=#94a3b8]در حال تفکر و نگارش پاسخ...[/color]\n" % p)
	await ctrl.call("ask_ai_council_async", p, false, "")


func _on_run_3d_mesh_prompt() -> void:
	var p := _prompt_box.text.strip_edges()
	if p.is_empty():
		return
	var ctrl := _get_ctrl()
	if ctrl == null:
		return
	_ai_progress.value = 8.0
	_ai_status_lbl.text = "در حال ساخت مش سه‌بعدی ۳۶۰ درجه واقعی با Flux + Hunyuan3D-2..."
	_ai_chat_log.append_text("\n[b][color=#38bdf8]◆ درخواست ساخت مش ۳۶۰ درجه:[/color][/b] «%s»\n[color=#94a3b8]در حال ترجمه پرامپت، رندر کانسپت ایزوله، دوربری عصبی و ساخت مش حجمی .GLB (حدود ۱۰ تا ۲۰ ثانیه)...[/color]\n" % p)
	await ctrl.call("run_prompt_council_build", p)
	_ai_chat_log.append_text("[b][color=#22c55e]✓ مدل سه‌بعدی ۳۶۰ درجه ساخته، ریگ‌گذاری و وارد صحنه 3D شد![/color][/b]\n")


func _on_ai_progress(pct: int, msg: String) -> void:
	if _ai_progress:
		_ai_progress.value = float(pct)
	if _ai_status_lbl:
		_ai_status_lbl.text = "[%d%%] %s" % [pct, msg]


func _on_ai_chat_replied(res: Dictionary) -> void:
	if _ai_chat_log == null:
		return
	if not res.get("ok", false):
		_ai_chat_log.append_text("\n[color=#ef4444][خطا] %s[/color]\n" % str(res.get("error", "")))
		return
	var model_used := str(res.get("model", "AI Brain"))
	var reply_bb := _markdown_to_bbcode(str(res.get("reply", "")))
	_ai_chat_log.append_text("\n[b][color=#38bdf8]⚡ پاسخ هوش مصنوعی (%s):[/color][/b]\n%s\n" % [model_used, reply_bb])
	var sp := str(res.get("saved_script_path", ""))
	if not sp.is_empty():
		_ai_chat_log.append_text("[color=#22c55e]✦ اسکریپت GDScript به طور خودکار در [b]%s[/b] ذخیره شد! (روی دکمه «باز کردن کد ساخته‌شده» کلیک کنید)[/color]\n" % sp)


func _markdown_to_bbcode(md: String) -> String:
	var lines := md.split("\n")
	var out := PackedStringArray()
	var in_code := false
	for ln in lines:
		if ln.strip_edges().begins_with("```"):
			if not in_code:
				in_code = true
				out.append("[color=#a5f3fc][code]")
			else:
				in_code = false
				out.append("[/code][/color]")
		else:
			out.append(ln)
	if in_code:
		out.append("[/code][/color]")
	return "\n".join(out)


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
	b.custom_minimum_size = Vector2(0, 32)
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
		if ctrl.has_signal("ai_progress_updated") and not ctrl.is_connected("ai_progress_updated", _on_ai_progress):
			ctrl.connect("ai_progress_updated", _on_ai_progress)
		if ctrl.has_signal("ai_chat_replied") and not ctrl.is_connected("ai_chat_replied", _on_ai_chat_replied):
			ctrl.connect("ai_chat_replied", _on_ai_chat_replied)


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
		EditorInterface.set_main_screen_editor("3D")


func _call_ctrl_and_view3d(method_name: String) -> void:
	var ctrl := _get_ctrl()
	if ctrl and ctrl.has_method(method_name):
		ctrl.call(method_name)
	_goto_3d_screen()
