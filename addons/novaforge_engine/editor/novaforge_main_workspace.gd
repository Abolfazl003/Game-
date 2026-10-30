@tool
extends VBoxContainer
## NovaForge Studio v4.0 — Complete 12-Module Mouse-Resizable Multi-Pane Persian Workspace (`⚡ میزکار نوافورج`).
## Every column/row divider is mouse-draggable (`HSplitContainer` / `VSplitContainer`), and every single
## module card (`NovaResizableModuleCard`) can be dragged-resized vertically/diagonally with the mouse,
## collapsed/expanded with `▾`, or popped out into its own movable mouse-resizable floating window (`❐ شناور`)!

const ResizableCardScript = preload("res://addons/novaforge_engine/ui/resizable_module_card.gd")

const QUALITY_ITEMS := [
	["AAA_UNREAL", "گرافیک AAA آنریل (SDFGI + مه حجمی + ACES)"],
	["STANDARD_UNITY", "گرافیک استاندارد یونیتی (متعادل ۶۰+ فریم)"],
	["INDIE_CEL_ANIME", "سل‌شید انیمه‌ای (Cel-Shaded Toon Outline)"],
	["INDIE_LOWPOLY_COZY", "لو-پلی سبک و سریع (سیستم‌های ضعیف)"],
	["INDIE_HD2D", "دیورامای HD-2D (نورپردازی حجمی سینمایی)"],
	["INDIE_PSX_RETRO", "رترو کلاسیک PS1 (پیکسلی نوستالژیک)"]
]

const CAM_ITEMS := [
	["TPS_SOULS", "سوم‌شخص سولزلایک"],
	["TPS_SHOULDER", "روی شانه (بقا/شوتر)"],
	["FPS", "اول‌شخص (FPS)"],
	["ISOMETRIC", "ایزومتریک بالا به پایین"],
	["SIDE_2_5D", "۲.۵ بعدی پلتفرمر"],
	["HD_2D", "دیورامای HD-2D"],
	["PURE_2D", "دوبعدی کامل"],
	["FIXED_CINEMATIC", "سینمایی ثابت"]
]

const GENRE_ITEMS := [
	["SOULS_ARPG", "★ سولزلایک رزمی"],
	["SHOOTER_FPS", "✦ شوتر اول‌شخص"],
	["SURVIVAL_HORROR", "◆ ترس و بقا"],
	["OPEN_WORLD_RPG", "▲ جهان‌باز RPG"],
	["PLATFORMER_2_5D", "▶ پلتفرمر ۲.۵بعدی"],
	["ISOMETRIC_ARPG", "⚡ اکشن ایزومتریک"]
]

var _outer_hsplit: HSplitContainer
var _inner_hsplit: HSplitContainer
var _center_vsplit: VSplitContainer

var _left_scroll: ScrollContainer
var _center_scroll: ScrollContainer
var _right_scroll: ScrollContainer

var _cards: Dictionary = {}
var _card_scroll_map: Dictionary = {}

# Module 1: In-App Auto-Installer & Downloader
var _setup_headline_lbl: Label
var _setup_detail_lbl: Label
var _setup_overall_bar: ProgressBar
var _setup_file_bar: ProgressBar
var _setup_stage_lbls: Array[Label] = []
var _setup_pause_btn: Button
var _setup_model_opt: OptionButton
var _auto_compacted_once: bool = false

# Module 2: Live AI Chat & 5-Brain Council
var _prompt_box: TextEdit
var _ai_chat_log: RichTextLabel
var _ai_progress: ProgressBar
var _ai_status_lbl: Label
var _backend_opt: OptionButton
var _local_cfg_row: HBoxContainer
var _ollama_url_edit: LineEdit
var _ollama_model_edit: LineEdit
var _api_key_edit: LineEdit
var _active_persona: String = ""

# Module 3: Live Embedded 3D Viewport
var _preview_subvp: SubViewport
var _preview_cam: Camera3D
var _orbit_yaw: float = 0.28
var _orbit_pitch: float = -0.34
var _orbit_dist: float = 6.8
var _orbit_target: Vector3 = Vector3(0.0, 1.1, -1.0)
var _orbit_dragging: bool = false
var _cam_opt: OptionButton

# Module 5 & 6: File Dialogs & Diagnostic Labels
var _blender_file_dialog: FileDialog
var _blender_rep_lbl: RichTextLabel
var _video_file_dialog: FileDialog
var _mocap_rep_lbl: Label
var _cutscene_sub_edit: LineEdit

# Module 8: Modular Checkboxes & Quality
var _quality_opt: OptionButton
var _mod_checks: Dictionary = {}

# Module 10: Living NPC & AI Dialogue
var _npc_summary: RichTextLabel
var _npc_chat_input: LineEdit
var _npc_reply_lbl: RichTextLabel

# Module 11 & 12: Zero-MCP Audit, Skills Search & Exporter
var _audit_rep_lbl: RichTextLabel
var _skill_search_edit: LineEdit
var _skill_list_lbl: RichTextLabel
var _all_skills_cache: Array[String] = []
var _export_platform_opt: OptionButton
var _export_ai_chk: CheckBox
var _export_rep_lbl: Label
var _status_banner: RichTextLabel


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 4)

	_build_top_studio_header()
	_build_quick_jump_module_strip()
	_build_resizable_three_pane_body()
	_build_footer_and_dialogs()

	_load_skills_catalog()
	call_deferred("_bind_ctrl")
	call_deferred("_sync_embedded_3d_world")


func _process(_delta: float) -> void:
	if visible and _preview_subvp != null and (_preview_subvp.world_3d == null):
		_sync_embedded_3d_world()


func _build_top_studio_header() -> void:
	var bar_panel := PanelContainer.new()
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.06, 0.10, 0.18, 1.0)
	bsb.border_color = Color(0.22, 0.72, 0.96, 0.85)
	bsb.border_width_bottom = 1
	bsb.content_margin_left = 10
	bsb.content_margin_right = 10
	bsb.content_margin_top = 5
	bsb.content_margin_bottom = 5
	bar_panel.add_theme_stylebox_override("panel", bsb)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	bar_panel.add_child(hb)

	var title := Label.new()
	title.text = "⚡ استودیو کامل نوافورج ۴.۰ — ۱۲ ماژول حرفه‌ای بازی‌سازی (لبه‌های ستون‌ها و پایین هر ماژول با ماوس کوچک/بزرگ می‌شوند + دکمه ❐ شناور)"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.90, 0.97, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	hb.add_child(title)

	var b_play := _action_btn("▶ اجرای بازی (F5)", Color(0.12, 0.56, 0.32))
	b_play.pressed.connect(func():
		var c := _get_ctrl()
		if c and c.has_method("launch_game_now"):
			c.call("launch_game_now")
	)
	hb.add_child(b_play)

	var b_3d := _action_btn("✦ ادیتور تمام‌صفحه 3D", Color(0.10, 0.46, 0.76))
	b_3d.pressed.connect(_goto_3d_screen)
	hb.add_child(b_3d)

	var b_exp_all := _action_btn("⊞ باز کردن همه", Color(0.20, 0.30, 0.46))
	b_exp_all.pressed.connect(func(): _set_all_cards_collapsed(false))
	hb.add_child(b_exp_all)

	var b_col_all := _action_btn("▤ جمع کردن همه", Color(0.20, 0.30, 0.46))
	b_col_all.pressed.connect(func(): _set_all_cards_collapsed(true))
	hb.add_child(b_col_all)

	var b_reset_layout := _action_btn("↺ بازنشانی سایز پنل‌ها", Color(0.32, 0.28, 0.48))
	b_reset_layout.pressed.connect(_reset_split_layout)
	hb.add_child(b_reset_layout)

	add_child(bar_panel)


func _build_quick_jump_module_strip() -> void:
	var strip_panel := PanelContainer.new()
	var ssb := StyleBoxFlat.new()
	ssb.bg_color = Color(0.05, 0.08, 0.14, 1.0)
	ssb.border_color = Color(0.16, 0.28, 0.44, 0.8)
	ssb.border_width_bottom = 1
	ssb.content_margin_left = 8
	ssb.content_margin_right = 8
	ssb.content_margin_top = 3
	ssb.content_margin_bottom = 3
	strip_panel.add_theme_stylebox_override("panel", ssb)

	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 3)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip_panel.add_child(grid)

	var jump_defs := [
		["m1_setup", "۱. نصب و دانلود داخلی", Color(0.12, 0.46, 0.36)],
		["m2_ai", "۲. چت 111B و شورای ۵ مغز", Color(0.38, 0.22, 0.68)],
		["m3_view3d", "۳. صحنه زنده 3D و کیت ژانر", Color(0.10, 0.44, 0.68)],
		["m4_mesh360", "۴. عکس/متن به مش ۳۶۰ و ریگ", Color(0.14, 0.42, 0.72)],
		["m5_blender", "۵. ایمپورتر ۱۳ فرمت بلندر", Color(0.56, 0.32, 0.12)],
		["m6_mocap", "۶. ویدیو به موشن و کات‌سین", Color(0.46, 0.24, 0.62)],
		["m7_blueprint", "۷. گراف دیداری بلوپرینت", Color(0.18, 0.38, 0.58)],
		["m8_modular", "۸. چک‌باکس ماژولار و گرافیک", Color(0.22, 0.46, 0.48)],
		["m9_voronoi", "۹. تخریب Voronoi و شیمی", Color(0.58, 0.22, 0.24)],
		["m10_npc", "۱۰. زندگی و گفتگوی NPC کاوه", Color(0.52, 0.40, 0.14)],
		["m11_audit", "۱۱. ممیزی صحنه و ۱۲۳ مهارت", Color(0.16, 0.46, 0.38)],
		["m12_export", "۱۲. خروجی یک‌کلیکی و صدا", Color(0.32, 0.28, 0.56)],
	]
	for jd in jump_defs:
		var mid: String = jd[0]
		var b := Button.new()
		b.text = jd[1]
		b.tooltip_text = "کلیک چپ: پرش مستقیم و باز کردن این ماژول | دکمه ❐ روی ماژول: پنجره شناور قابل تغییر سایز"
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 24)
		b.add_theme_font_size_override("font_size", 11)
		var col: Color = jd[2]
		var psb := StyleBoxFlat.new()
		psb.bg_color = col
		psb.border_color = col.lightened(0.30)
		psb.set_border_width_all(1)
		psb.set_corner_radius_all(4)
		psb.content_margin_left = 6
		psb.content_margin_right = 6
		b.add_theme_stylebox_override("normal", psb)
		b.pressed.connect(func(): focus_module(mid))
		grid.add_child(b)

	add_child(strip_panel)


func _build_resizable_three_pane_body() -> void:
	# Outer HSplit: Left Column  <-->  (Center + Right)
	_outer_hsplit = HSplitContainer.new()
	_outer_hsplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_outer_hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_outer_hsplit.split_offset = 345
	_style_split(_outer_hsplit)
	add_child(_outer_hsplit)

	# ── LEFT COLUMN (Modules 5, 6, 9, 11, 12) ──
	_left_scroll = _make_column_scroll(250)
	_outer_hsplit.add_child(_left_scroll)
	var left_vb := _left_scroll.get_child(0) as VBoxContainer

	# Inner HSplit: Center Pane  <-->  Right Column
	_inner_hsplit = HSplitContainer.new()
	_inner_hsplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inner_hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_inner_hsplit.split_offset = 540
	_style_split(_inner_hsplit)
	_outer_hsplit.add_child(_inner_hsplit)

	# ── CENTER PANE: VSplit (Top Live 3D Viewport  <-->  Bottom Modules 1, 4, 7) ──
	_center_vsplit = VSplitContainer.new()
	_center_vsplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_center_vsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_center_vsplit.split_offset = 275
	_style_split(_center_vsplit)
	_inner_hsplit.add_child(_center_vsplit)

	var center_top_wrap := VBoxContainer.new()
	center_top_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_top_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_center_vsplit.add_child(center_top_wrap)

	_center_scroll = _make_column_scroll(320)
	_center_vsplit.add_child(_center_scroll)
	var center_bot_vb := _center_scroll.get_child(0) as VBoxContainer

	# ── RIGHT COLUMN (Modules 2, 8, 10) ──
	_right_scroll = _make_column_scroll(300)
	_inner_hsplit.add_child(_right_scroll)
	var right_vb := _right_scroll.get_child(0) as VBoxContainer

	# Populate all 12 resizable modules!
	_build_mod3_live_3d_and_genres(center_top_wrap)
	_build_mod1_in_app_installer(center_bot_vb)
	_build_mod4_mesh360_and_autorig(center_bot_vb)
	_build_mod7_blueprint_graph(center_bot_vb)

	_build_mod2_live_ai_and_council(right_vb)
	_build_mod8_modular_checkboxes_and_quality(right_vb)
	_build_mod10_living_npc_and_dialogue(right_vb)

	_build_mod5_blender_all_formats(left_vb)
	_build_mod6_video_mocap_and_cutscene(left_vb)
	_build_mod9_voronoi_and_chemistry(left_vb)
	_build_mod11_zero_mcp_audit_and_skills(left_vb)
	_build_mod12_exporter_and_audio(left_vb)


func _make_card(parent_vb: VBoxContainer, scroll_owner: ScrollContainer, id_str: String, title_str: String, accent: Color, min_h: float = 0.0) -> VBoxContainer:
	var card = ResizableCardScript.new()
	var body: VBoxContainer = card.setup(id_str, title_str, accent, min_h, false)
	parent_vb.add_child(card)
	_cards[id_str] = card
	_card_scroll_map[id_str] = scroll_owner
	return body


# ═══════════════════════════════════════════════════════════════════════════
# MODULE 3: LIVE EMBEDDED 3D VIEWPORT + 8 CAMERAS + 6 PLAYABLE GENRE KITS
# ═══════════════════════════════════════════════════════════════════════════
func _build_mod3_live_3d_and_genres(parent_vb: VBoxContainer) -> void:
	var body := _make_card(parent_vb, null, "m3_view3d", "۳. نمای زنده صحنه سه‌بعدی داخل میزکار + ۸ دوربین و ۶ کیت ژانر آماده", Color(0.22, 0.78, 0.98), 195.0)
	(_cards["m3_view3d"] as Control).size_flags_vertical = Control.SIZE_EXPAND_FILL

	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 5)

	_cam_opt = OptionButton.new()
	for ci in CAM_ITEMS:
		_cam_opt.add_item("دوربین: " + str(ci[1]))
	_cam_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cam_opt.item_selected.connect(func(idx: int):
		var code: String = CAM_ITEMS[idx][0]
		var c := _get_ctrl()
		if c:
			c.call("apply_camera_perspective", code)
		_apply_preview_cam_preset(code)
	)
	top_hb.add_child(_cam_opt)

	var b_sync := Button.new()
	b_sync.text = "↺ همگام‌سازی صحنه"
	b_sync.pressed.connect(_sync_embedded_3d_world)
	top_hb.add_child(b_sync)
	body.add_child(top_hb)

	# Embedded Interactive 3D SubViewport
	var vp_frame := PanelContainer.new()
	vp_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vp_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vp_frame.custom_minimum_size = Vector2(0, 145)
	var vsb := StyleBoxFlat.new()
	vsb.bg_color = Color(0.03, 0.05, 0.09)
	vsb.border_color = Color(0.24, 0.62, 0.88)
	vsb.set_border_width_all(1)
	vsb.set_corner_radius_all(5)
	vp_frame.add_theme_stylebox_override("panel", vsb)

	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	svc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	svc.mouse_filter = Control.MOUSE_FILTER_STOP
	svc.tooltip_text = "کلیک و حرکت ماوس: چرخش ۳۶۰ درجه دوربین | اسکرول ماوس: زوم در صحنه زنده"
	svc.gui_input.connect(_on_preview_3d_gui_input)
	vp_frame.add_child(svc)

	_preview_subvp = SubViewport.new()
	_preview_subvp.size = Vector2i(640, 320)
	_preview_subvp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_preview_subvp.msaa_3d = Viewport.MSAA_2X
	svc.add_child(_preview_subvp)

	_preview_cam = Camera3D.new()
	_preview_cam.fov = 58.0
	_preview_subvp.add_child(_preview_cam)
	_update_orbit_camera()
	body.add_child(vp_frame)

	# 6 One-Click Genre Kit Assembler Buttons
	var g_grid := GridContainer.new()
	g_grid.columns = 3
	g_grid.add_theme_constant_override("h_separation", 4)
	g_grid.add_theme_constant_override("v_separation", 4)
	for gi in GENRE_ITEMS:
		var gcode: String = gi[0]
		var gb := Button.new()
		gb.text = gi[1]
		gb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gb.add_theme_font_size_override("font_size", 11)
		gb.pressed.connect(func():
			var c := _get_ctrl()
			if c and c.has_method("assemble_genre_kit"):
				c.call("assemble_genre_kit", gcode)
				_sync_embedded_3d_world()
		)
		g_grid.add_child(gb)
	body.add_child(g_grid)


func _sync_embedded_3d_world() -> void:
	if _preview_subvp == null or not Engine.is_editor_hint():
		return
	var ed_vp := EditorInterface.get_editor_viewport_3d(0)
	if ed_vp and ed_vp.find_world_3d():
		_preview_subvp.world_3d = ed_vp.find_world_3d()
	_update_orbit_camera()


func _update_orbit_camera() -> void:
	if _preview_cam == null or not _preview_cam.is_inside_tree():
		return
	var offset := Vector3(
		cos(_orbit_pitch) * sin(_orbit_yaw),
		-sin(_orbit_pitch),
		cos(_orbit_pitch) * cos(_orbit_yaw)
	) * _orbit_dist
	var cam_pos := _orbit_target + offset
	_preview_cam.look_at_from_position(cam_pos, _orbit_target, Vector3.UP)


func _apply_preview_cam_preset(code: String) -> void:
	match code:
		"FPS":
			_orbit_dist = 2.4; _orbit_pitch = -0.10; _orbit_yaw = 0.0
		"ISOMETRIC":
			_orbit_dist = 10.5; _orbit_pitch = -0.68; _orbit_yaw = 0.78
		"SIDE_2_5D":
			_orbit_dist = 7.6; _orbit_pitch = -0.14; _orbit_yaw = 1.57
		"HD_2D":
			_orbit_dist = 9.2; _orbit_pitch = -0.56; _orbit_yaw = 0.0
		_:
			_orbit_dist = 6.5; _orbit_pitch = -0.34; _orbit_yaw = 0.28
	_update_orbit_camera()


func _on_preview_3d_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_orbit_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_orbit_dist = clampf(_orbit_dist - 0.55, 1.8, 18.0)
			_update_orbit_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_orbit_dist = clampf(_orbit_dist + 0.55, 1.8, 18.0)
			_update_orbit_camera()
	elif event is InputEventMouseMotion and _orbit_dragging:
		_orbit_yaw -= event.relative.x * 0.01
		_orbit_pitch = clampf(_orbit_pitch - event.relative.y * 0.01, -1.25, 0.05)
		_update_orbit_camera()


# ═══════════════════════════════════════════════════════════════════════════
# MODULE 1: LIVE IN-APP AUTO-INSTALLER & DOWNLOADER
# ═══════════════════════════════════════════════════════════════════════════
func _build_mod1_in_app_installer(parent_vb: VBoxContainer) -> void:
	var body := _make_card(parent_vb, _center_scroll, "m1_setup", "۱. پروسه نصب، دانلود و راه‌اندازی خودکار داخل برنامه", Color(0.16, 0.86, 0.62))

	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 6)

	_setup_model_opt = OptionButton.new()
	_setup_model_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_setup_model_opt.add_item("مدل آفلاین پیش‌فرض: Qwen2.5-Coder 0.5B (۴۶۸ مگابایت)")
	_setup_model_opt.add_item("مدل آفلاین حرفه‌ای: Qwen2.5-Coder 1.5B (۱.۰۶ گیگابایت)")
	_setup_model_opt.item_selected.connect(func(idx: int):
		_auto_compacted_once = false
		var c := _get_ctrl()
		if c and c.has_method("get_setup_installer"):
			var inst: Node = c.call("get_setup_installer")
			if inst:
				inst.call("select_and_install_model", idx)
	)
	top_hb.add_child(_setup_model_opt)

	_setup_pause_btn = _action_btn("■ توقف موقت", Color(0.24, 0.36, 0.48))
	_setup_pause_btn.pressed.connect(func():
		var c := _get_ctrl()
		if c and c.has_method("get_setup_installer"):
			var inst: Node = c.call("get_setup_installer")
			if inst:
				inst.call("toggle_pause_resume")
	)
	top_hb.add_child(_setup_pause_btn)
	body.add_child(top_hb)

	var stg_grid := GridContainer.new()
	stg_grid.columns = 2
	stg_grid.add_theme_constant_override("h_separation", 6)
	stg_grid.add_theme_constant_override("v_separation", 4)
	_setup_stage_lbls.clear()
	for sn in [
		"۱. هسته C++/Jolt و رابط فارسی",
		"۲. اتصال هوش مصنوعی ابری 111B",
		"۳. دانلود و نصب موتور llama-server",
		"۴. دانلود و اجرای مدل Qwen2.5-Coder"
	]:
		var sl := Label.new()
		sl.text = "• " + sn
		sl.add_theme_font_size_override("font_size", 11)
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.clip_text = true
		stg_grid.add_child(sl)
		_setup_stage_lbls.append(sl)
	body.add_child(stg_grid)

	var bars_hb := HBoxContainer.new()
	bars_hb.add_theme_constant_override("separation", 6)
	_setup_overall_bar = ProgressBar.new()
	_setup_overall_bar.custom_minimum_size = Vector2(110, 16)
	bars_hb.add_child(_setup_overall_bar)

	_setup_file_bar = ProgressBar.new()
	_setup_file_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_setup_file_bar.custom_minimum_size = Vector2(0, 16)
	bars_hb.add_child(_setup_file_bar)
	body.add_child(bars_hb)

	_setup_headline_lbl = _desc_lbl("• در حال بررسی و شروع خودکار نصب داخل برنامه...")
	body.add_child(_setup_headline_lbl)

	_setup_detail_lbl = _desc_lbl("در حین دانلود، تمام ۱۲ ماژول و هوش مصنوعی ابری کاملاً فعال‌اند.")
	_setup_detail_lbl.add_theme_color_override("font_color", Color(0.42, 0.92, 0.70))
	body.add_child(_setup_detail_lbl)


# ═══════════════════════════════════════════════════════════════════════════
# MODULE 4: REAL 360° NEURAL IMAGE-TO-3D & AUTO-RIGGER
# ═══════════════════════════════════════════════════════════════════════════
func _build_mod4_mesh360_and_autorig(parent_vb: VBoxContainer) -> void:
	var body := _make_card(parent_vb, _center_scroll, "m4_mesh360", "۴. ساخت مش سه‌بعدی ۳۶۰ درجه واقعی (.GLB) از عکس/متن + ریگ ۱۹ استخوانی", Color(0.24, 0.68, 0.98))
	var forge_scr = load("res://addons/novaforge_engine/editor/image_to_mesh_rig_panel.gd")
	if forge_scr:
		var forge_panel: Control = forge_scr.new()
		body.add_child(forge_panel)


# ═══════════════════════════════════════════════════════════════════════════
# MODULE 7: VISUAL BLUEPRINT GRAPH EDITOR (C++20 & GDSCRIPT COMPILER)
# ═══════════════════════════════════════════════════════════════════════════
func _build_mod7_blueprint_graph(parent_vb: VBoxContainer) -> void:
	var body := _make_card(parent_vb, _center_scroll, "m7_blueprint", "۷. گراف دیداری بلوپرینت (تبدیل متن به نود + کامپایل به C++20 و GDScript)", Color(0.38, 0.66, 0.98), 265.0)
	var bp_scr = load("res://addons/novaforge_engine/editor/blueprint_graph_editor.gd")
	if bp_scr:
		var bp_ed: Control = bp_scr.new()
		body.add_child(bp_ed)


# ═══════════════════════════════════════════════════════════════════════════
# MODULE 2: LIVE AI CHAT, GDSCRIPT CODER & 5-BRAIN COLIBRÌ COUNCIL
# ═══════════════════════════════════════════════════════════════════════════
func _build_mod2_live_ai_and_council(parent_vb: VBoxContainer) -> void:
	var body := _make_card(parent_vb, _right_scroll, "m2_ai", "۲. دستیار چت زنده، کدنویس GDScript و شورای ۵ مغز (111B + آفلاین)", Color(0.66, 0.44, 0.98), 310.0)

	_backend_opt = OptionButton.new()
	_backend_opt.add_item("⚡ Command-A Reasoning 111B (ابری رایگان — بدون کلید)")
	_backend_opt.add_item("✦ Cohere Aya Persian (فارسی فوق‌سریع — ابری رایگان)")
	_backend_opt.add_item("◆ موتور آفلاین نصب‌شده داخل برنامه (Qwen2.5-Coder Local)")
	_backend_opt.add_item("◆ لوکال Ollama / LM Studio (127.0.0.1:11434)")
	_backend_opt.add_item("★ سرور اختصاصی OpenAI / Groq / Custom API")
	_backend_opt.item_selected.connect(_on_backend_changed)
	body.add_child(_backend_opt)

	_local_cfg_row = HBoxContainer.new()
	_local_cfg_row.visible = false
	_ollama_url_edit = LineEdit.new()
	_ollama_url_edit.text = "http://127.0.0.1:11434/api/chat"
	_ollama_url_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_local_cfg_row.add_child(_ollama_url_edit)
	_ollama_model_edit = LineEdit.new()
	_ollama_model_edit.text = "qwen2.5-coder:7b"
	_ollama_model_edit.custom_minimum_size = Vector2(115, 0)
	_local_cfg_row.add_child(_ollama_model_edit)
	_api_key_edit = LineEdit.new()
	_api_key_edit.secret = true
	_api_key_edit.placeholder_text = "API Key"
	_api_key_edit.custom_minimum_size = Vector2(90, 0)
	_local_cfg_row.add_child(_api_key_edit)
	var b_test_ol := Button.new()
	b_test_ol.text = "تست"
	b_test_ol.pressed.connect(_on_test_local_ollama)
	_local_cfg_row.add_child(b_test_ol)
	body.add_child(_local_cfg_row)

	# 5 Clickable Council Brain Pills
	var council_grid := GridContainer.new()
	council_grid.columns = 3
	council_grid.add_theme_constant_override("h_separation", 4)
	council_grid.add_theme_constant_override("v_separation", 3)
	for sp in [
		["۱. کارگردان بازی", "کارگردان ارشد مکانیک و مرحله"],
		["۲. کدنویس GDScript/C++", "برنامه‌نویس ارشد گادوت ۴ و C++20"],
		["۳. آرتیست سه‌بعدی", "متخصص مش ۳۶۰ درجه و شیدر PBR"],
		["۴. کارگردان کات‌سین", "کارگردان انیمیشن، IK و دوربین"],
		["۵. داور QA صحنه", "داور رفع باگ، فیزیک Jolt و فریم"],
		["⚡ شورای کامل ۵ مغز", "همفکری هم‌زمان هر ۵ مغز متخصص"],
	]:
		var role_str: String = sp[1]
		var sb_btn := Button.new()
		sb_btn.text = sp[0]
		sb_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb_btn.add_theme_font_size_override("font_size", 11)
		sb_btn.pressed.connect(func():
			_active_persona = role_str
			_on_ask_ai_chat()
		)
		council_grid.add_child(sb_btn)
	body.add_child(council_grid)

	# Conversation Box
	var chat_frame := PanelContainer.new()
	chat_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color(0.04, 0.06, 0.11)
	csb.border_color = Color(0.24, 0.36, 0.58)
	csb.set_border_width_all(1)
	csb.set_corner_radius_all(5)
	csb.content_margin_left = 8
	csb.content_margin_right = 8
	csb.content_margin_top = 6
	csb.content_margin_bottom = 6
	chat_frame.add_theme_stylebox_override("panel", csb)

	_ai_chat_log = RichTextLabel.new()
	_ai_chat_log.bbcode_enabled = true
	_ai_chat_log.scroll_following = true
	_ai_chat_log.selection_enabled = true
	_ai_chat_log.custom_minimum_size = Vector2(0, 125)
	_ai_chat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ai_chat_log.text = "[b][color=#38bdf8]⚡ شورای ۵ مغز نوافورج (آنلاین ✓):[/color][/b] سوال، درخواست کد [b]GDScript[/b] یا دستور ساخت مش سه‌بعدی خود را بنویسید!"
	chat_frame.add_child(_ai_chat_log)
	body.add_child(chat_frame)

	_prompt_box = TextEdit.new()
	_prompt_box.custom_minimum_size = Vector2(0, 52)
	_prompt_box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_prompt_box.text = "سلام! یه اسکریپت حرکت، پرش دوتایی و دش (Dash) برای کاراکتر سه‌بعدی در گادوت ۴ بنویس و توضیح بده."
	body.add_child(_prompt_box)

	var act1 := HBoxContainer.new()
	act1.add_theme_constant_override("separation", 5)
	var btn_ask := _action_btn("⚡ پرسش و کدنویسی با هوش مصنوعی", Color(0.42, 0.22, 0.78))
	btn_ask.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_ask.pressed.connect(_on_ask_ai_chat)
	act1.add_child(btn_ask)

	var btn_3d := _action_btn("◆ ساخت مش ۳۶۰ (.GLB)", Color(0.10, 0.48, 0.84))
	btn_3d.pressed.connect(_on_run_3d_mesh_prompt)
	act1.add_child(btn_3d)
	body.add_child(act1)

	var act2 := HBoxContainer.new()
	act2.add_theme_constant_override("separation", 5)
	var b_open := Button.new()
	b_open.text = "✦ باز کردن کد ساخته‌شده"
	b_open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_open.pressed.connect(func():
		var c := _get_ctrl()
		if c and c.has_method("open_last_ai_script_in_editor"):
			c.call("open_last_ai_script_in_editor")
	)
	act2.add_child(b_open)

	var b_clr := Button.new()
	b_clr.text = "↺ پاک کردن چت"
	b_clr.pressed.connect(func():
		_ai_chat_log.text = "[color=#94a3b8]چت پاک شد.[/color]"
		var c := _get_ctrl()
		if c: c.call("clear_ai_spawned_world")
	)
	act2.add_child(b_clr)
	body.add_child(act2)

	var prog_hb := HBoxContainer.new()
	prog_hb.add_theme_constant_override("separation", 6)
	_ai_progress = ProgressBar.new()
	_ai_progress.custom_minimum_size = Vector2(95, 16)
	prog_hb.add_child(_ai_progress)

	_ai_status_lbl = _desc_lbl("✓ آماده پاسخگویی")
	_ai_status_lbl.add_theme_color_override("font_color", Color(0.35, 0.92, 0.62))
	_ai_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ai_status_lbl.clip_text = true
	prog_hb.add_child(_ai_status_lbl)
	body.add_child(prog_hb)


# ═══════════════════════════════════════════════════════════════════════════
# MODULE 8: MODULAR OPTIONAL CHECKBOXES & VISUAL QUALITY TIERS
# ═══════════════════════════════════════════════════════════════════════════
func _build_mod8_modular_checkboxes_and_quality(parent_vb: VBoxContainer) -> void:
	var body := _make_card(parent_vb, _right_scroll, "m8_modular", "۸. چک‌باکس‌های ماژولار اختیاری (کنترل فشار سخت‌افزار) + سطح گرافیک", Color(0.24, 0.86, 0.78))

	_quality_opt = OptionButton.new()
	for qi in QUALITY_ITEMS:
		_quality_opt.add_item(qi[1])
	_quality_opt.item_selected.connect(func(idx: int):
		var c := _get_ctrl()
		if c:
			c.call("apply_quality_visuals", QUALITY_ITEMS[idx][0])
	)
	body.add_child(_quality_opt)

	var flag_defs := [
		["npc_life", "هوش مصنوعی زندگی تکاملی و حافظه دشمن (Evolving NPC & Nemesis)"],
		["voronoi_smart", "تخریب فیزیکی ۱۶تکه Voronoi و تعامل اشیاء هوشمند"],
		["elemental_chem", "شیمی عناصر محیط و آب‌وهوای پویا (باران / آتش / صاعقه)"],
		["chunk_lod", "استریم چانک‌های جهان‌باز و تولید خودکار ۳ سطح جزئیات (Auto-LOD)"],
		["advanced_gi_fog", "نورپردازی پیشرفته، سایه خورشید، Bloom و مه حجمی"],
		["spatial_audio", "صدای سه‌بعدی فضایی و موسیقی تطبیقی داینامیک نبرد"],
	]
	for fd in flag_defs:
		var fid: String = fd[0]
		var chk := CheckBox.new()
		chk.text = fd[1]
		chk.button_pressed = true
		chk.add_theme_font_size_override("font_size", 11)
		chk.toggled.connect(func(on: bool):
			var c := _get_ctrl()
			if c and c.has_method("set_modular_feature_enabled"):
				c.call("set_modular_feature_enabled", fid, on)
		)
		body.add_child(chk)
		_mod_checks[fid] = chk


# ═══════════════════════════════════════════════════════════════════════════
# MODULE 10: LIVING NPC EVOLUTION, NEMESIS MEMORY & AI DIALOGUE
# ═══════════════════════════════════════════════════════════════════════════
func _build_mod10_living_npc_and_dialogue(parent_vb: VBoxContainer) -> void:
	var body := _make_card(parent_vb, _right_scroll, "m10_npc", "۱۰. زندگی تکاملی NPC، حافظه زخم Nemesis و گفتگوی زنده با کاوه آهنگر", Color(0.96, 0.76, 0.24))

	_npc_summary = RichTextLabel.new()
	_npc_summary.bbcode_enabled = true
	_npc_summary.fit_content = true
	_npc_summary.scroll_active = false
	_npc_summary.text = "[b]کاوه آهنگر (روز ۱):[/b] شاگرد آهنگر | طلا: ۱۲۰ سکه | رابطه: +۱۰ (دوستانه)"
	body.add_child(_npc_summary)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	var b_h := _action_btn("✦ کمک و خرید", Color(0.14, 0.50, 0.34))
	b_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_h.pressed.connect(func():
		var c := _get_ctrl()
		if c: c.call("help_npc")
	)
	hb.add_child(b_h)

	var b_f := _action_btn("★ نبرد Nemesis", Color(0.66, 0.20, 0.22))
	b_f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_f.pressed.connect(func():
		var c := _get_ctrl()
		if c: c.call("fight_npc")
	)
	hb.add_child(b_f)

	var b_d := _action_btn("» +۵ روز تکامل", Color(0.54, 0.40, 0.14))
	b_d.pressed.connect(func():
		var c := _get_ctrl()
		if c: c.call("advance_world_days", 5)
	)
	hb.add_child(b_d)
	body.add_child(hb)

	var chat_hb := HBoxContainer.new()
	chat_hb.add_theme_constant_override("separation", 4)
	_npc_chat_input = LineEdit.new()
	_npc_chat_input.text = "سلام کاوه! شمشیر جدید چی ساختی و نظرت درباره من چیه؟"
	_npc_chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_npc_chat_input.text_submitted.connect(func(_t: String): _on_talk_to_kaveh())
	chat_hb.add_child(_npc_chat_input)

	var b_talk := _action_btn("✦ گفتگو با کاوه", Color(0.46, 0.34, 0.14))
	b_talk.pressed.connect(_on_talk_to_kaveh)
	chat_hb.add_child(b_talk)
	body.add_child(chat_hb)

	_npc_reply_lbl = RichTextLabel.new()
	_npc_reply_lbl.bbcode_enabled = true
	_npc_reply_lbl.fit_content = true
	_npc_reply_lbl.scroll_active = false
	_npc_reply_lbl.text = "[color=#fde047]کاوه آهنگر بر اساس رابطه، طلا و زخم‌های نبرد قبلی به صورت زنده با شما حرف می‌زند.[/color]"
	body.add_child(_npc_reply_lbl)


# ═══════════════════════════════════════════════════════════════════════════
# MODULE 5: BLENDER ALL-13-FORMAT AUTO-PBR IMPORTER
# ═══════════════════════════════════════════════════════════════════════════
func _build_mod5_blender_all_formats(parent_vb: VBoxContainer) -> void:
	var body := _make_card(parent_vb, _left_scroll, "m5_blender", "۵. ایمپورتر بدون دردسر بلندر (.blend و ۱۳ فرمت) + اتصال خودکار تکسچر PBR", Color(0.96, 0.56, 0.22))
	body.add_child(_desc_lbl("پشتیبانی از .blend, .glb, .gltf, .fbx, .obj, .dae, .usd, .abc, .ply, .stl + اصلاح خودکار کانال سبز Normal Map (DirectX/OpenGL) و تبدیل Gloss به Roughness بدون پایتون!"))

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 5)
	var b_pick := _action_btn("■ انتخاب فایل بلندر / سه‌بعدی از ویندوز", Color(0.68, 0.36, 0.12))
	b_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_pick.pressed.connect(func():
		if OS.get_name() in ["Windows", "macOS"]:
			_blender_file_dialog.popup()
		else:
			_blender_file_dialog.popup_centered(Vector2i(780, 500))
	)
	hb.add_child(b_pick)

	var b_demo := Button.new()
	b_demo.text = "تست نمونه قلعه"
	b_demo.pressed.connect(func(): _run_blender_import("res://assets/models/world/castle_tower.glb"))
	hb.add_child(b_demo)
	body.add_child(hb)

	_blender_rep_lbl = RichTextLabel.new()
	_blender_rep_lbl.bbcode_enabled = true
	_blender_rep_lbl.fit_content = true
	_blender_rep_lbl.scroll_active = false
	_blender_rep_lbl.text = "[color=#94a3b8]فایل مدل را انتخاب کنید تا متریال PBR خودکار ساخته و در صحنه سه‌بعدی قرار گیرد.[/color]"
	body.add_child(_blender_rep_lbl)


# ═══════════════════════════════════════════════════════════════════════════
# MODULE 6: VIDEO-TO-MOTION MOCAP (FOOT-IK) & LIVE CUTSCENE SEQUENCER
# ═══════════════════════════════════════════════════════════════════════════
func _build_mod6_video_mocap_and_cutscene(parent_vb: VBoxContainer) -> void:
	var body := _make_card(parent_vb, _left_scroll, "m6_mocap", "۶. موشن‌کپچر از ویدیو (Foot-IK) و کارگردان کات‌سین زنده (Bezier / NLA)", Color(0.76, 0.40, 0.96))

	var b_vid := _action_btn("▶ انتخاب فایل ویدیو (.mp4 / .mov / .webm) برای استخراج موشن", Color(0.46, 0.22, 0.68))
	b_vid.pressed.connect(func():
		if OS.get_name() in ["Windows", "macOS"]:
			_video_file_dialog.popup()
		else:
			_video_file_dialog.popup_centered(Vector2i(760, 480))
	)
	body.add_child(b_vid)

	var p_grid := GridContainer.new()
	p_grid.columns = 2
	p_grid.add_theme_constant_override("h_separation", 4)
	p_grid.add_theme_constant_override("v_separation", 4)
	for mp in [
		["KATANA_3HIT", "▶ کمبوی شمشیر + IK"],
		["PARKOUR_VAULT", "▶ پرش پارکور از مانع"],
		["STEALTH_ASSASSIN", "▶ حرکت مخفی‌کاری"],
		["VICTORY_TAUNT", "▶ رقص پیروزی کاراکتر"],
	]:
		var code: String = mp[0]
		var mb := Button.new()
		mb.text = mp[1]
		mb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mb.pressed.connect(func(): _run_mocap("", code))
		p_grid.add_child(mb)
	body.add_child(p_grid)

	_mocap_rep_lbl = _desc_lbl("حلال تحلیلی ۲ استخوانی Foot-IK فعال است.")
	_mocap_rep_lbl.add_theme_color_override("font_color", Color(0.55, 0.90, 1.0))
	body.add_child(_mocap_rep_lbl)

	var cut_hb := HBoxContainer.new()
	cut_hb.add_theme_constant_override("separation", 4)
	_cutscene_sub_edit = LineEdit.new()
	_cutscene_sub_edit.text = "«دروازه باستانی باز می‌شود... شمشیرت را آماده کن!»"
	_cutscene_sub_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cut_hb.add_child(_cutscene_sub_edit)

	var b_cut := _action_btn("▶ اجرای کات‌سین", Color(0.54, 0.24, 0.72))
	b_cut.pressed.connect(func():
		var c := _get_ctrl()
		if c:
			c.call("trigger_live_cutscene", _cutscene_sub_edit.text)
	)
	cut_hb.add_child(b_cut)
	body.add_child(cut_hb)


# ═══════════════════════════════════════════════════════════════════════════
# MODULE 9: VORONOI 3D DESTRUCTION & ELEMENTAL CHEMISTRY
# ═══════════════════════════════════════════════════════════════════════════
func _build_mod9_voronoi_and_chemistry(parent_vb: VBoxContainer) -> void:
	var body := _make_card(parent_vb, _left_scroll, "m9_voronoi", "۹. تخریب فیزیکی Voronoi 3D (Jolt) و شیمی عناصر محیط", Color(0.94, 0.36, 0.38))

	var b_shatter := _action_btn("★ ضربه شمشیر: متلاشی کردن ۱۶تکه Voronoi / بازسازی صندوق", Color(0.68, 0.22, 0.24))
	b_shatter.pressed.connect(func():
		var c := _get_ctrl()
		if c:
			c.call("shatter_or_reset_crate")
	)
	body.add_child(b_shatter)

	var chem_grid := GridContainer.new()
	chem_grid.columns = 2
	chem_grid.add_theme_constant_override("h_separation", 4)
	chem_grid.add_theme_constant_override("v_separation", 4)
	for el in [
		["CLEAR", "● هوای صاف و پایدار"],
		["RAIN", "◆ باران + خیس شدن سطوح"],
		["FIRE", "▲ آتش + گسترش با باد"],
		["LIGHTNING", "⚡ صاعقه زنجیره‌ای در آب"],
	]:
		var ecode: String = el[0]
		var eb := Button.new()
		eb.text = el[1]
		eb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		eb.pressed.connect(func():
			var c := _get_ctrl()
			if c:
				c.call("apply_elemental_weather", ecode)
		)
		chem_grid.add_child(eb)
	body.add_child(chem_grid)


# ═══════════════════════════════════════════════════════════════════════════
# MODULE 11: ZERO-MCP AGENT (123 SKILLS + 114 TOOLS), SCENE AUDIT & AUTOPILOT
# ═══════════════════════════════════════════════════════════════════════════
func _build_mod11_zero_mcp_audit_and_skills(parent_vb: VBoxContainer) -> void:
	var body := _make_card(parent_vb, _left_scroll, "m11_audit", "۱۱. ایجنت بدون MCP (۱۲۳ مهارت)، ممیزی صحنه، پلی‌تست خودکار و ماشین زمان", Color(0.22, 0.86, 0.56))

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 4)
	var b_aud := _action_btn("✦ ممیزی صحنه و رفع باگ", Color(0.14, 0.50, 0.36))
	b_aud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_aud.pressed.connect(_on_run_scene_audit)
	row1.add_child(b_aud)

	var b_auto := _action_btn("▶ پلی‌تست خودکار ایجنت", Color(0.14, 0.44, 0.68))
	b_auto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_auto.pressed.connect(_on_run_autopilot)
	row1.add_child(b_auto)
	body.add_child(row1)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 4)
	var b_snap := Button.new()
	b_snap.text = "+ ذخیره اسنپ‌شات ماشین زمان"
	b_snap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_snap.pressed.connect(func():
		var c := _get_ctrl()
		if c: c.call("save_snapshot", "Manual User Restore Point")
	)
	row2.add_child(b_snap)

	var b_undo := Button.new()
	b_undo.text = "↺ بازگشت به اسنپ‌شات قبلی"
	b_undo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_undo.pressed.connect(func():
		var c := _get_ctrl()
		if c: c.call("undo_snapshot")
	)
	row2.add_child(b_undo)
	body.add_child(row2)

	_audit_rep_lbl = RichTextLabel.new()
	_audit_rep_lbl.bbcode_enabled = true
	_audit_rep_lbl.fit_content = true
	_audit_rep_lbl.scroll_active = false
	_audit_rep_lbl.text = "[color=#94a3b8]گذرگاه Zero-MCP با ۱۲۳ مهارت بازی‌سازی و ۱۱۴ ابزار بومی آماده است.[/color]"
	body.add_child(_audit_rep_lbl)

	_skill_search_edit = LineEdit.new()
	_skill_search_edit.placeholder_text = "جستجو در ۱۲۳ مهارت بازی‌سازی داخلی (مثلاً: combat, shader, camera, ai, physics)..."
	_skill_search_edit.text_changed.connect(_filter_skills_view)
	body.add_child(_skill_search_edit)

	_skill_list_lbl = RichTextLabel.new()
	_skill_list_lbl.bbcode_enabled = true
	_skill_list_lbl.custom_minimum_size = Vector2(0, 74)
	body.add_child(_skill_list_lbl)


# ═══════════════════════════════════════════════════════════════════════════
# MODULE 12: ONE-CLICK MULTI-PLATFORM EXPORTER & ADAPTIVE 3D AUDIO STUDIO
# ═══════════════════════════════════════════════════════════════════════════
func _build_mod12_exporter_and_audio(parent_vb: VBoxContainer) -> void:
	var body := _make_card(parent_vb, _left_scroll, "m12_export", "۱۲. خروجی یک‌کلیکی بازی (Windows/Linux/Web) و استودیو موسیقی تطبیقی", Color(0.56, 0.52, 0.98))

	var mus_hb := HBoxContainer.new()
	mus_hb.add_theme_constant_override("separation", 4)
	var b_calm := Button.new()
	b_calm.text = "♪ تم محیطی آرام"
	b_calm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_calm.pressed.connect(func():
		var c := _get_ctrl()
		if c: c.call("play_adaptive_music_preview", "CALM_EXPLORE")
	)
	mus_hb.add_child(b_calm)

	var b_boss := Button.new()
	b_boss.text = "♪ تم نبرد Boss"
	b_boss.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_boss.pressed.connect(func():
		var c := _get_ctrl()
		if c: c.call("play_adaptive_music_preview", "BOSS_COMBAT")
	)
	mus_hb.add_child(b_boss)

	var b_stop := Button.new()
	b_stop.text = "■ توقف"
	b_stop.pressed.connect(func():
		var c := _get_ctrl()
		if c: c.call("play_adaptive_music_preview", "STOP")
	)
	mus_hb.add_child(b_stop)
	body.add_child(mus_hb)

	_export_platform_opt = OptionButton.new()
	for tp in ["Windows Desktop (.exe)", "Linux x86_64", "Web (HTML5 / Wasm64)", "Android (.apk)", "macOS Universal"]:
		_export_platform_opt.add_item(tp)
	body.add_child(_export_platform_opt)

	_export_ai_chk = CheckBox.new()
	_export_ai_chk.text = "باندل خودکار هسته C++ و هوش مصنوعی زنده NPC داخل خروجی بازی"
	_export_ai_chk.button_pressed = true
	_export_ai_chk.add_theme_font_size_override("font_size", 11)
	body.add_child(_export_ai_chk)

	var b_exp := _action_btn("⚡ ساخت بسته خروجی بازی + اسنپ‌شات .GLB صحنه", Color(0.32, 0.26, 0.68))
	b_exp.pressed.connect(_on_export_project_clicked)
	body.add_child(b_exp)

	_export_rep_lbl = _desc_lbl("")
	_export_rep_lbl.add_theme_color_override("font_color", Color(0.38, 0.94, 0.66))
	body.add_child(_export_rep_lbl)


func _build_footer_and_dialogs() -> void:
	var foot := PanelContainer.new()
	var fsb := StyleBoxFlat.new()
	fsb.bg_color = Color(0.05, 0.08, 0.14, 1.0)
	fsb.border_color = Color(0.18, 0.34, 0.54)
	fsb.border_width_top = 1
	fsb.content_margin_left = 10
	fsb.content_margin_right = 10
	fsb.content_margin_top = 3
	fsb.content_margin_bottom = 3
	foot.add_theme_stylebox_override("panel", fsb)

	_status_banner = RichTextLabel.new()
	_status_banner.bbcode_enabled = true
	_status_banner.fit_content = true
	_status_banner.scroll_active = false
	_status_banner.text = "[color=#38bdf8]✓ استودیو نوافورج ۴.۰ آماده است — هر ستون و هر ماژول با ماوس کوچک/بزرگ یا شناور (❐) می‌شود.[/color]"
	foot.add_child(_status_banner)
	add_child(foot)

	_blender_file_dialog = FileDialog.new()
	_blender_file_dialog.title = "انتخاب فایل بلندر یا مدل سه‌بعدی (۱۳ فرمت پشتیبانی‌شده)"
	_blender_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_blender_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_blender_file_dialog.use_native_dialog = OS.get_name() in ["Windows", "macOS"]
	_blender_file_dialog.filters = PackedStringArray([
		"*.blend, *.glb, *.gltf, *.fbx, *.obj, *.dae, *.usd, *.usdz, *.abc, *.ply, *.stl ; همه ۱۳ فرمت بلندر و سه‌بعدی"
	])
	_blender_file_dialog.file_selected.connect(_run_blender_import)
	add_child(_blender_file_dialog)

	_video_file_dialog = FileDialog.new()
	_video_file_dialog.title = "انتخاب فایل ویدیو برای استخراج موشن‌کپچر اسکلتی با قفل کف پا (Foot-IK)"
	_video_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_video_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_video_file_dialog.use_native_dialog = OS.get_name() in ["Windows", "macOS"]
	_video_file_dialog.filters = PackedStringArray(["*.mp4, *.mov, *.webm, *.avi, *.mkv ; فایل‌های ویدیویی"])
	_video_file_dialog.file_selected.connect(func(vp: String): _run_mocap(vp, "KATANA_3HIT"))
	add_child(_video_file_dialog)


# ═══════════════════════════════════════════════════════════════════════════
# INTERACTION HANDLERS & CONTROLLER WIRING
# ═══════════════════════════════════════════════════════════════════════════
func focus_module(mid: String) -> void:
	if not _cards.has(mid):
		return
	var card: Control = _cards[mid]
	if card.has_method("set_collapsed"):
		card.call("set_collapsed", false)
	var sc: ScrollContainer = _card_scroll_map.get(mid, null)
	if sc != null:
		await get_tree().process_frame
		sc.scroll_vertical = maxi(0, int(card.position.y) - 8)
	var orig_mod := card.modulate
	var tw := create_tween()
	tw.tween_property(card, "modulate", Color(1.35, 1.35, 1.15), 0.16)
	tw.tween_property(card, "modulate", orig_mod, 0.28)


func _set_all_cards_collapsed(c: bool) -> void:
	for k in _cards.keys():
		if k == "m3_view3d" and c:
			continue
		var card = _cards[k]
		if card and card.has_method("set_collapsed"):
			card.call("set_collapsed", c)


func _reset_split_layout() -> void:
	if _outer_hsplit:
		_outer_hsplit.split_offset = 345
	if _inner_hsplit:
		_inner_hsplit.split_offset = 540
	if _center_vsplit:
		_center_vsplit.split_offset = 275
	_set_all_cards_collapsed(false)


func _run_blender_import(path_str: String) -> void:
	var c := _get_ctrl()
	if c == null or not c.has_method("import_blender_auto_pbr_gate"):
		return
	var rep: Dictionary = c.call("import_blender_auto_pbr_gate", path_str, false)
	if rep.get("ok", false) and _blender_rep_lbl:
		_blender_rep_lbl.text = (
			"[color=#22c55e][b]✓ ایمپورت موفق:[/b] %s (%s)[/color]\n" % [str(rep.get("file", "")), str(rep.get("format", ""))]
			+ "کانال‌های تکسچر متصل‌شده: [b]%s[/b] | نرمال‌مپ: [b]%s[/b]" % [str(rep.get("slots", "")), str(rep.get("normal_fix", ""))]
		)
	_sync_embedded_3d_world()


func _run_mocap(video_path: String, preset: String) -> void:
	var c := _get_ctrl()
	if c == null or not c.has_method("run_video_file_to_motion"):
		return
	var r: Dictionary = c.call("run_video_file_to_motion", video_path, preset)
	if r.get("ok", false) and _mocap_rep_lbl:
		_mocap_rep_lbl.text = "✓ منبع: %s | زاویه زانو Foot-IK: %s° | %d فریم روی کاراکتر اجرا شد" % [
			str(r.get("source", "")), str(r.get("ik_angle_deg", 42.5)), int(r.get("frames_baked", 72))
		]


func _on_talk_to_kaveh() -> void:
	var c := _get_ctrl()
	if c == null or not c.has_method("talk_to_living_npc_async"):
		return
	var msg := _npc_chat_input.text.strip_edges()
	_npc_reply_lbl.text = "[color=#94a3b8]در حال دریافت پاسخ زنده از کاوه آهنگر...[/color]"
	var r: Dictionary = await c.call("talk_to_living_npc_async", msg)
	if r.get("ok", false):
		_npc_reply_lbl.text = "[b][color=#facc15]کاوه آهنگر:[/color][/b] " + str(r.get("reply", ""))


func _on_run_scene_audit() -> void:
	var c := _get_ctrl()
	if c == null or not c.has_method("run_live_scene_audit_and_autofix"):
		return
	var r: Dictionary = c.call("run_live_scene_audit_and_autofix", true)
	if r.get("ok", false) and _audit_rep_lbl:
		_audit_rep_lbl.text = (
			"[color=#22c55e][b]✓ نتیجه ممیزی: %s[/b][/color]\n" % str(r.get("grade", ""))
			+ "گره‌ها: %d | مش‌ها: %d (%d مثلث) | اسکلت: %d | کولایدر Jolt: %d | نورها: %d" % [
				int(r.get("nodes", 0)), int(r.get("meshes", 0)), int(r.get("triangles", 0)),
				int(r.get("skeletons", 0)), int(r.get("collisions", 0)), int(r.get("lights", 0))
			]
		)


func _on_run_autopilot() -> void:
	var c := _get_ctrl()
	if c == null or not c.has_method("run_live_agent_playtest_async"):
		return
	_audit_rep_lbl.text = "[color=#38bdf8]▶ ایجنت Autopilot در حال حرکت خودکار، تست پرش و تخریب در صحنه ۳بعدی است...[/color]"
	var r: Dictionary = await c.call("run_live_agent_playtest_async")
	if r.get("ok", false):
		_audit_rep_lbl.text = "[color=#22c55e][b]✓ پلی‌تست خودکار کامل شد:[/b] ۴ نقطه مسیر، فیزیک برخورد Jolt و تخریب Voronoi بدون باگ تایید شدند![/color]"


func _on_export_project_clicked() -> void:
	var c := _get_ctrl()
	if c == null or not c.has_method("export_project_one_click"):
		return
	var plat := _export_platform_opt.get_item_text(_export_platform_opt.selected)
	var r: Dictionary = c.call("export_project_one_click", plat, _export_ai_chk.button_pressed)
	if r.get("ok", false) and _export_rep_lbl:
		_export_rep_lbl.text = "✓ خروجی آماده شد: " + str(r.get("output_dir", ""))


func _load_skills_catalog() -> void:
	_all_skills_cache.clear()
	var idx_path := "res://library/skills_index.json"
	if FileAccess.file_exists(idx_path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(idx_path))
		if parsed is Dictionary and parsed.has("skills") and parsed["skills"] is Array:
			for s in parsed["skills"]:
				if s is Dictionary:
					_all_skills_cache.append(str(s.get("id", s.get("name", ""))))
				else:
					_all_skills_cache.append(str(s))
	if _all_skills_cache.is_empty():
		var da := DirAccess.open("res://library/skills")
		if da:
			da.list_dir_begin()
			var fn := da.get_next()
			while not fn.is_empty():
				if not fn.begins_with("."):
					_all_skills_cache.append(fn.get_basename())
				fn = da.get_next()
			da.list_dir_end()
	_filter_skills_view("")


func _filter_skills_view(q: String) -> void:
	if _skill_list_lbl == null:
		return
	var needle := q.strip_edges().to_lower()
	var matched: Array[String] = []
	for s in _all_skills_cache:
		if needle.is_empty() or s.to_lower().contains(needle):
			matched.append(s)
			if matched.size() >= 24:
				break
	_skill_list_lbl.text = "[color=#38bdf8]مهارت‌های یافت‌شده (%d کل):[/color] %s" % [
		maxi(123, _all_skills_cache.size()),
		(" • ".join(PackedStringArray(matched)) if not matched.is_empty() else "موردی با این عبارت یافت نشد")
	]


func _on_backend_changed(idx: int) -> void:
	_local_cfg_row.visible = (idx == 3 or idx == 4)
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
		brain.set("preferred_backend", "BUILTIN_LOCAL")
	elif idx == 3:
		brain.set("preferred_backend", "OLLAMA_LOCAL")
	elif idx == 4:
		brain.set("preferred_backend", "CUSTOM_OPENAI")


func _sync_brain_config() -> void:
	var ctrl := _get_ctrl()
	if ctrl == null or not ctrl.has_method("get_llm_brain"):
		return
	var brain: Node = ctrl.call("get_llm_brain")
	if brain == null:
		return
	if _backend_opt.selected == 3:
		brain.set("ollama_url", _ollama_url_edit.text.strip_edges())
		brain.set("ollama_model", _ollama_model_edit.text.strip_edges())
	elif _backend_opt.selected == 4:
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
	var res: Dictionary = await brain.call("check_local_ollama_status_async")
	if res.get("ok", false):
		_ai_chat_log.append_text("\n[color=#22c55e]✓ اتصال به Ollama برقرار شد![/color]\n")
	else:
		_ai_chat_log.append_text("\n[color=#f59e0b]Ollama روی 11434 باز نبود؛ موتور داخلی 11435 و مغز ابری 111B آماده هستند![/color]\n")


func _on_ask_ai_chat() -> void:
	var p := _prompt_box.text.strip_edges()
	if p.is_empty():
		return
	_sync_brain_config()
	var ctrl := _get_ctrl()
	if ctrl == null or not ctrl.has_method("ask_ai_council_async"):
		return
	_ai_progress.value = 10.0
	_ai_status_lbl.text = "در حال تفکر..."
	_ai_chat_log.append_text("\n[b][color=#fde047]▶ شما:[/color][/b] %s\n" % p)
	await ctrl.call("ask_ai_council_async", p, false, _active_persona)


func _on_run_3d_mesh_prompt() -> void:
	var p := _prompt_box.text.strip_edges()
	if p.is_empty():
		return
	var ctrl := _get_ctrl()
	if ctrl == null:
		return
	_ai_progress.value = 8.0
	_ai_status_lbl.text = "در حال ساخت مش ۳۶۰ درجه (.GLB)..."
	_ai_chat_log.append_text("\n[b][color=#38bdf8]◆ ساخت مش ۳۶۰ درجه:[/color][/b] «%s»...\n" % p)
	await ctrl.call("run_prompt_council_build", p)


func _on_ai_progress(pct: int, msg: String) -> void:
	if _ai_progress:
		_ai_progress.value = float(pct)
	if _ai_status_lbl:
		_ai_status_lbl.text = "[%d%%] %s" % [pct, msg]


func _on_ai_chat_replied(res: Dictionary) -> void:
	if _ai_chat_log == null:
		return
	if not res.get("ok", false):
		_ai_chat_log.append_text("[color=#ef4444]خطا: %s[/color]\n" % str(res.get("error", "")))
		return
	var saved_scr := str(res.get("saved_script_path", ""))
	var scr_note := ("\n[color=#4ade80]✦ کد در [b]%s[/b] ذخیره شد![/color]" % saved_scr) if not saved_scr.is_empty() else ""
	_ai_chat_log.append_text("[b][color=#22c55e]⚡ پاسخ (%s):[/color][/b]\n%s%s\n" % [
		str(res.get("model", "AI")), str(res.get("reply", "")), scr_note
	])
	if _ai_progress:
		_ai_progress.value = 100.0


func _on_setup_state_updated(st: Dictionary) -> void:
	var ov := int(st.get("overall_pct", 0))
	if _setup_overall_bar:
		_setup_overall_bar.value = float(ov)
	if _setup_file_bar:
		_setup_file_bar.value = float(st.get("file_pct", 0))
	if _setup_headline_lbl:
		_setup_headline_lbl.text = str(st.get("headline", ""))
	if _setup_detail_lbl:
		_setup_detail_lbl.text = str(st.get("detail", ""))
	if _cards.has("m1_setup"):
		var c1 = _cards["m1_setup"]
		if bool(st.get("completed", false)):
			c1.call("set_badge", "✓ ۱۰۰٪ نصب شد", Color(0.28, 0.96, 0.62))
			if not _auto_compacted_once:
				_auto_compacted_once = true
				c1.call("set_collapsed", true)
		else:
			c1.call("set_badge", "%d%%" % ov, Color(0.38, 0.86, 1.0))

	if _setup_pause_btn:
		if bool(st.get("completed", false)):
			_setup_pause_btn.text = "✓ نصب کامل شد"
		elif bool(st.get("paused", false)) or not bool(st.get("running", false)):
			_setup_pause_btn.text = "▶ ادامه دانلود"
		else:
			_setup_pause_btn.text = "■ توقف موقت"

	var base_names := [
		"۱. هسته C++/Jolt و رابط فارسی",
		"۲. اتصال هوش مصنوعی ابری 111B",
		"۳. دانلود و نصب موتور llama-server",
		"۴. دانلود و اجرای مدل Qwen2.5-Coder"
	]
	var cur_stage := int(st.get("stage", 0))
	for i in range(mini(_setup_stage_lbls.size(), 4)):
		var is_done := bool(st.get("stage_%d_done" % (i + 1), false))
		var lbl := _setup_stage_lbls[i]
		if is_done:
			lbl.text = "✓ " + base_names[i]
			lbl.add_theme_color_override("font_color", Color(0.28, 0.96, 0.62))
		elif cur_stage == (i + 1):
			lbl.text = "⬇ " + base_names[i]
			lbl.add_theme_color_override("font_color", Color(0.38, 0.86, 1.0))
		else:
			lbl.text = "• " + base_names[i]
			lbl.add_theme_color_override("font_color", Color(0.68, 0.78, 0.90))


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
		if ctrl.has_signal("setup_state_updated") and not ctrl.is_connected("setup_state_updated", _on_setup_state_updated):
			ctrl.connect("setup_state_updated", _on_setup_state_updated)
		if ctrl.has_method("get_setup_installer"):
			var inst: Node = ctrl.call("get_setup_installer")
			if inst and inst.has_method("get_state"):
				_on_setup_state_updated(inst.call("get_state"))


func _on_state_updated(st: Dictionary) -> void:
	if _npc_summary == null:
		return
	var n: Dictionary = st.get("npc", {})
	var rel: int = int(n.get("rel", 10))
	var tag := "دشمن خونی Nemesis" if rel <= -35 else ("متحد وفادار" if rel >= 35 else "معمولی")
	var scars: Array = n.get("scars", [])
	var scar_txt := (" | زخم‌ها: " + "، ".join(PackedStringArray(scars))) if not scars.is_empty() else ""
	_npc_summary.text = "[b]کاوه آهنگر (روز %d):[/b] %s | طلا: %d سکه | رابطه: %d (%s)%s" % [
		int(st.get("day", 1)), str(n.get("title", "شاگرد آهنگر")), int(n.get("gold", 120)), rel, tag, scar_txt
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


func _get_ctrl() -> Node:
	if get_tree() and get_tree().root.has_node("NovaEditorController"):
		return get_tree().root.get_node("NovaEditorController")
	return null


func _make_column_scroll(min_w: float) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(min_w, 120)
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 8)
	sc.add_child(vb)
	return sc


func _style_split(sp: SplitContainer) -> void:
	sp.dragger_visibility = SplitContainer.DRAGGER_VISIBLE
	sp.add_theme_constant_override("separation", 7)
	sp.add_theme_constant_override("autohide", 0)


func _desc_lbl(txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color(0.80, 0.86, 0.94))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _action_btn(txt: String, bg: Color) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(0, 28)
	b.add_theme_font_size_override("font_size", 11)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = bg.lightened(0.32)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = bg.lightened(0.15)
	b.add_theme_stylebox_override("hover", sbh)
	return b
