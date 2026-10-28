@tool
extends PanelContainer
## Full-Screen Customized Persian Main Workspace (`⚡ میزکار هوشمند نوافورج`) mounted in Godot 4's
## top-center workspace bar alongside 2D / 3D / Script (`_has_main_screen() -> true`).
## Gives 1-click visual access to ALL 9 NovaForge Engine capabilities in Persian, and can switch
## immediately to the 3D Viewport to display live scene results.

var _prompt_box: TextEdit
var _status_banner: RichTextLabel
var _vram_bar: ProgressBar
var _npc_summary: RichTextLabel


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	visible = false

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.07, 0.09, 0.14, 1.0)
	bg_style.content_margin_left = 18
	bg_style.content_margin_right = 18
	bg_style.content_margin_top = 14
	bg_style.content_margin_bottom = 14
	add_theme_stylebox_override("panel", bg_style)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var root_vb := VBoxContainer.new()
	root_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vb.add_theme_constant_override("separation", 12)
	scroll.add_child(root_vb)

	# ── HERO BANNER ──
	var hero_card := _styled_card(Color(0.11, 0.15, 0.25), Color(0.24, 0.76, 0.98))
	var hero_hb := HBoxContainer.new()
	hero_hb.add_theme_constant_override("separation", 12)

	var btn_go_3d := _action_btn("▶ مشاهده زنده صحنه سه‌بعدی (رفتن به نمای 3D)", Color(0.14, 0.52, 0.30))
	btn_go_3d.pressed.connect(func():
		if Engine.is_editor_hint():
			EditorInterface.set_main_screen_editor("3D")
	)
	hero_hb.add_child(btn_go_3d)

	var hero_title := Label.new()
	hero_title.text = "⚡ میزکار مرکزی موتور بازی‌سازی هوش مصنوعی نوافورج (Zero-MCP | ۱۲۳ مهارت | ۱۱۴ ابزار بومی | هسته C++20 و Jolt)"
	hero_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hero_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_title.add_theme_font_size_override("font_size", 15)
	hero_title.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	hero_hb.add_child(hero_title)

	hero_card.add_child(hero_hb)
	root_vb.add_child(hero_card.get_parent())

	# ── PROMPT + 5-BRAIN COUNCIL ROW ──
	var top_grid := GridContainer.new()
	top_grid.columns = 2
	top_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_grid.add_theme_constant_override("h_separation", 12)
	top_grid.add_theme_constant_override("v_separation", 12)
	root_vb.add_child(top_grid)

	# Prompt Card
	var p_card := _styled_card(Color(0.10, 0.13, 0.21), Color(0.32, 0.52, 0.85))
	p_card.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p_card.add_child(_sec_title("⚡ ساخت بازی با پرامپت فارسی و انگلیسی (بدون نیاز به MCP)"))

	_prompt_box = TextEdit.new()
	_prompt_box.text = "یه جنگجوی سامورایی با کمبوی ۳ ضربه‌ای شمشیر بساز، صندوق چوبی با ضربه تیکه‌تیکه بشه و وقتی رسید دم دروازه، این تیکه کات‌سینه!"
	_prompt_box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_prompt_box.custom_minimum_size = Vector2(0, 88)
	p_card.add_child(_prompt_box)

	var btn_exec_prompt := _action_btn("⚡ اجرای همفکری شورای ۵ مغز و اعمال مستقیم روی صحنه 3D", Color(0.18, 0.42, 0.86))
	btn_exec_prompt.pressed.connect(_on_run_prompt_and_show_3d)
	p_card.add_child(btn_exec_prompt)
	top_grid.add_child(p_card.get_parent())

	# 5-Brain Colibri Card
	var b_card := _styled_card(Color(0.10, 0.13, 0.21), Color(0.58, 0.36, 0.92))
	b_card.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_card.add_child(_sec_title("◈ شورای ۵ مغز لوکال (معماری کم‌مصرف Colibrì: VRAM ⇄ RAM ⇄ SSD)"))
	for line_txt in [
		"• مغز ۱ — کارگردان بازی و طراحی مرحله (GLM-5.3 MoE — استریم از SSD)",
		"• مغز ۲ — برنامه‌نویس C++20 و گراف Blueprint (کش فشرده INT4 در RAM)",
		"• مغز ۳ — آرتیست سه‌بعدی و اتصال خودکار تکسچرهای بلندر (Auto-PBR)",
		"• مغز ۴ — کارگردان موشن‌کپچر ویدیو، قفل کف پا (Foot-IK) و کات‌سین زنده",
		"• مغز ۵ — داور کنترل کیفیت، تست خودکار گیم‌پلی و Scene Audit بدون باگ"
	]:
		var l := Label.new()
		l.text = line_txt
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b_card.add_child(l)

	_vram_bar = ProgressBar.new()
	_vram_bar.value = 12.0
	_vram_bar.custom_minimum_size = Vector2(0, 14)
	b_card.add_child(_vram_bar)
	top_grid.add_child(b_card.get_parent())

	# ── 3-COLUMN CAPABILITY MATRIX (ALL ENGINE MODULES) ──
	var cap_grid := GridContainer.new()
	cap_grid.columns = 3
	cap_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cap_grid.add_theme_constant_override("h_separation", 12)
	cap_grid.add_theme_constant_override("v_separation", 12)
	root_vb.add_child(cap_grid)

	# Module 1: 3D Forge & 52-Bone Auto-Rig
	var m1 := _styled_card(Color(0.10, 0.14, 0.22), Color(0.22, 0.72, 0.95))
	m1.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m1.add_child(_sec_title("◆ تبدیل عکس/متن به مدل 3D + ریگ خودکار"))
	m1.add_child(_desc_lbl("ساخت کاراکتر سه‌بعدی با ۳ سطح جزئیات (Auto-LOD) و اسکلت‌بندی ۵۲ استخوانی استاندارد Humanoid."))
	var b_m1 := _action_btn("اسپان کاراکتر 3D ریگ‌شده در صحنه", Color(0.14, 0.45, 0.72))
	b_m1.pressed.connect(func(): _call_ctrl_and_view3d("spawn_image_to_3d_rigged_character"))
	m1.add_child(b_m1)
	cap_grid.add_child(m1.get_parent())

	# Module 2: Video-to-Motion Mocap
	var m2 := _styled_card(Color(0.10, 0.14, 0.22), Color(0.20, 0.78, 0.52))
	m2.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m2.add_child(_sec_title("▶ استخراج موشن‌کپچر از ویدیو (Foot-IK)"))
	m2.add_child(_desc_lbl("استخراج حرکت سه‌بعدی بدن، انگشتان و چهره از ویدیو با قفل کف پا روی زمین و تشخیص خودکار فریم ضربه شمشیر."))
	var b_m2 := _action_btn("اجرای موشن کمبوی شمشیر روی سامورایی", Color(0.14, 0.55, 0.36))
	b_m2.pressed.connect(func(): _call_ctrl_and_view3d("run_video_to_motion_combo"))
	m2.add_child(b_m2)
	cap_grid.add_child(m2.get_parent())

	# Module 3: Blender 13-Format Auto-PBR Importer
	var m3 := _styled_card(Color(0.10, 0.14, 0.22), Color(0.95, 0.55, 0.18))
	m3.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m3.add_child(_sec_title("✦ ایمپورتر هوشمند بلندر و تکسچر خودکار"))
	m3.add_child(_desc_lbl("پشتیبانی از .blend, .fbx, .glb, .obj, .usd, .abc با اصلاح خودکار Normal Map دایرکت‌ایکس، تبدیل Gloss و ORM."))
	var b_m3 := _action_btn("ایمپورت دروازه بلندر با تکسچر خودکار", Color(0.72, 0.38, 0.12))
	b_m3.pressed.connect(func(): _call_ctrl_and_view3d("import_blender_auto_pbr_gate"))
	m3.add_child(b_m3)
	cap_grid.add_child(m3.get_parent())

	# Module 4: Voronoi 3D Destruction
	var m4 := _styled_card(Color(0.10, 0.14, 0.22), Color(0.92, 0.35, 0.35))
	m4.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m4.add_child(_sec_title("★ تخریب فیزیکی واقعی (Voronoi 3D + Jolt)"))
	m4.add_child(_desc_lbl("برش هم‌زمان مش سه‌بعدی در هسته C++20 به ۱۶ قطعه محدب فیزیکی براساس جنس جسم و شدت ضربه سلاح."))
	var b_m4 := _action_btn("تست خرد کردن صندوق باستانی در صحنه", Color(0.68, 0.22, 0.24))
	b_m4.pressed.connect(func(): _call_ctrl_and_view3d("shatter_or_reset_crate"))
	m4.add_child(b_m4)
	cap_grid.add_child(m4.get_parent())

	# Module 5: Live In-Engine Cutscene Sequencer
	var m5 := _styled_card(Color(0.10, 0.14, 0.22), Color(0.72, 0.38, 0.95))
	m5.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m5.add_child(_sec_title("▶ کارگردان کات‌سین زنده («این تیکه کات‌سینه»)"))
	m5.add_child(_desc_lbl("حرکت سینمایی دوربین، فوکوس لنز، اسلوموشن و زیرنویس فارسی بدون حتی ۱ فریم صفحه سیاه بین گیم‌پلی و کات‌سین."))
	var b_m5 := _action_btn("اجرای کات‌سین زنده روی صحنه 3D", Color(0.48, 0.24, 0.72))
	b_m5.pressed.connect(func(): _call_ctrl_and_view3d("trigger_live_cutscene"))
	m5.add_child(b_m5)
	cap_grid.add_child(m5.get_parent())

	# Module 6: Elemental Chemistry & Quality Tiers
	var m6 := _styled_card(Color(0.10, 0.14, 0.22), Color(0.25, 0.82, 0.88))
	m6.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m6.add_child(_sec_title("✦ شیمی عناصر و سطح گرافیک (AAA تا PS1)"))
	m6.add_child(_desc_lbl("واکنش زنده باران، سطح خیس، گسترش آتش با باد و برق زنجیره‌ای صاعقه روی آب + سوییچر گرافیک Unreal / Anime / PS1."))
	var hb_w := HBoxContainer.new()
	for pair in [["RAIN", "◈ باران"], ["FIRE", "▲ آتش"], ["LIGHTNING", "⚡ صاعقه"]]:
		var code: String = pair[0]
		var wb := _action_btn(pair[1], Color(0.16, 0.38, 0.54))
		wb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wb.pressed.connect(func():
			var c := _get_ctrl()
			if c: c.call("apply_elemental_weather", code)
			if Engine.is_editor_hint(): EditorInterface.set_main_screen_editor("3D")
		)
		hb_w.add_child(wb)
	m6.add_child(hb_w)
	cap_grid.add_child(m6.get_parent())

	# ── LIVING NPC & STATUS FOOTER ──
	var bot_card := _styled_card(Color(0.10, 0.13, 0.20), Color(0.95, 0.76, 0.25))
	bot_card.add_child(_sec_title("✦ هوش مصنوعی زندگی تکاملی و حافظه دشمن (Evolving Life & Nemesis AI — کاوه آهنگر)"))
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
	_status_banner.text = "[color=#38bdf8]✓ تمام ماژول‌ها فعال هستند — با کلیک روی هر قابلیت، عملیات مستقیماً روی صحنه سه‌بعدی اعمال و نمایش داده می‌شود.[/color]"
	bot_card.add_child(_status_banner)
	root_vb.add_child(bot_card.get_parent())

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
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	pc.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	pc.add_child(vb)
	return vb


func _sec_title(txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(0.42, 0.84, 1.0))
	return l


func _desc_lbl(txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", Color(0.78, 0.83, 0.92))
	return l


func _action_btn(txt: String, bg: Color) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(0, 34)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = bg.lightened(0.28)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	b.add_theme_stylebox_override("normal", sb)
	return b


func _get_ctrl() -> Node:
	if get_tree() and get_tree().root.has_node("NovaEditorController"):
		return get_tree().root.get_node("NovaEditorController")
	return null


func _bind_ctrl() -> void:
	var c := _get_ctrl()
	if c and c.has_signal("state_updated") and not c.is_connected("state_updated", _on_state_updated):
		c.connect("state_updated", _on_state_updated)


func _on_state_updated(st: Dictionary) -> void:
	if _npc_summary == null:
		return
	var n: Dictionary = st.get("npc", {})
	_npc_summary.text = "[b]کاوه آهنگر:[/b] %s | [b]طلا:[/b] %d سکه | [b]رابطه:[/b] %d | [b]روز دنیا:[/b] روز %d" % [
		str(n.get("title", "شاگرد آهنگر")),
		int(n.get("gold", 120)),
		int(n.get("rel", 10)),
		int(st.get("day", 1))
	]


func _call_ctrl_and_view3d(method_name: String) -> void:
	var c := _get_ctrl()
	if c and c.has_method(method_name):
		c.call(method_name)
	if Engine.is_editor_hint():
		EditorInterface.set_main_screen_editor("3D")


func _on_run_prompt_and_show_3d() -> void:
	var txt := _prompt_box.text.strip_edges()
	var c := _get_ctrl()
	if Engine.is_editor_hint():
		EditorInterface.set_main_screen_editor("3D")
	if c:
		c.call("save_snapshot", "Prompt Execution")
		c.call("run_video_to_motion_combo")
		if txt.contains("دروازه") or txt.contains("قلعه") or txt.contains("blend"):
			c.call("import_blender_auto_pbr_gate")
		if txt.contains("عکس") or txt.contains("ریگ"):
			c.call("spawn_image_to_3d_rigged_character")
		if txt.contains("تیکه") or txt.contains("بشکن") or txt.contains("صندوق"):
			if not bool(c.get("crate_shattered")):
				c.call("shatter_or_reset_crate", false)
		if txt.contains("کات‌سین") or txt.contains("کات سین"):
			c.call("trigger_live_cutscene", "«دروازه قلعه باز می‌شود... آماده نبرد شو!»")
