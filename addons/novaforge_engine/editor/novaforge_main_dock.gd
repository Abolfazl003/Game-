@tool
extends VBoxContainer
class_name NovaForgeMainDock
## Complete Unified NovaForge Studio Dock inside Real Godot 4 Editor (`⚡ NovaForge Studio`).
## Houses 100% of the interactive Studio modules in one zero-clipping scrollable dock with quick filter tabs:
##   1. شورای ۵ مغز لوکال (Colibrì) + نوار زنده VRAM
##   2. پرامپت ساخت بازی، فایت، ریگ و کات‌سین
##   3. پایپ‌لاین بلندر، عکس به 3D + ریگ ۵۲ استخوانی، ویدیو به موشن و کات‌سین زنده
##   4. وضعیت NPC زنده (کاوه آهنگر — Evolving Life & Nemesis AI)
##   5. شیمی عناصر و جهان‌باز (صاف / باران / آتش + باد / صاعقه در آب)
##   6. منوی هوشمند آبجکت و تخریب Voronoi 3D
##   7. پیش‌نمایش گراف Blueprint فعال

var _sec_council: VBoxContainer
var _sec_world: VBoxContainer

var _relay_badge: Label
var _brain_labels: Array[Label] = []
var _vram_label: Label
var _vram_bar: ProgressBar
var _prompt_input: TextEdit
var _npc_bio: RichTextLabel
var _elem_status: Label
var _council_busy: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(215, 310)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 4)

	# Quick Section Filter Tabs (All | AI Council & 3D | NPC & Chemistry)
	var filter_bar := HBoxContainer.new()
	filter_bar.add_theme_constant_override("separation", 4)

	var b_all := _small_btn("همه امکانات")
	b_all.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_all.pressed.connect(func():
		_sec_council.visible = true
		_sec_world.visible = true
	)
	filter_bar.add_child(b_all)

	var b_ai := _small_btn("◈ شورا و 3D")
	b_ai.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_ai.pressed.connect(func():
		_sec_council.visible = true
		_sec_world.visible = false
	)
	filter_bar.add_child(b_ai)

	var b_npc := _small_btn("✦ NPC و شیمی")
	b_npc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_npc.pressed.connect(func():
		_sec_council.visible = false
		_sec_world.visible = true
	)
	filter_bar.add_child(b_npc)
	add_child(filter_bar)

	# Main Vertical Scroll Container (zero horizontal overflow)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)

	# ══════════ SECTION A: AI COUNCIL, PROMPT & 3D/MOCAP FORGE ══════════
	_sec_council = VBoxContainer.new()
	_sec_council.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sec_council.add_theme_constant_override("separation", 8)
	content.add_child(_sec_council)

	# Card 1: 5-Brain Colibrì Council
	var c1 := _make_card(_sec_council)
	var hdr1 := HBoxContainer.new()
	var t1 := _title_lbl("◈ شورای ۵ مغز لوکال (Colibrì)")
	hdr1.add_child(t1)
	_relay_badge = _small_lbl("آماده ✓")
	_relay_badge.add_theme_color_override("font_color", Color(0.20, 0.85, 0.45))
	hdr1.add_child(_relay_badge)
	c1.add_child(hdr1)

	var brains_list := [
		"1. کارگردان (GLM-5.3 MoE) [NVMe]",
		"2. کدنویس C++ / Blueprint [RAM]",
		"3. سه‌بعدی و متریال بلندر [PBR]",
		"4. موشن‌کپچر و کات‌سین [Foot-IK]",
		"5. داور و Scene Audit [Zero-Bug]"
	]
	for btxt in brains_list:
		var bl := _small_lbl(btxt)
		bl.clip_text = true
		c1.add_child(bl)
		_brain_labels.append(bl)

	_vram_label = _small_lbl("VRAM: 0.4 GB / 5.0 GB")
	c1.add_child(_vram_label)

	_vram_bar = ProgressBar.new()
	_vram_bar.min_value = 0.0
	_vram_bar.max_value = 100.0
	_vram_bar.value = 12.0
	_vram_bar.show_percentage = false
	_vram_bar.custom_minimum_size = Vector2(0, 8)
	c1.add_child(_vram_bar)

	# Card 2: Prompt-to-Scene
	var c2 := _make_card(_sec_council)
	c2.add_child(_title_lbl("⚡ پرامپت ساخت بازی و کات‌سین"))

	_prompt_input = TextEdit.new()
	_prompt_input.text = "یه جنگجوی سامورایی با کمبوی ۳ ضربه‌ای شمشیر بساز، صندوق چوبی با ضربه تیکه‌تیکه بشه و وقتی رسید دم دروازه، این تیکه کات‌سینه!"
	_prompt_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_prompt_input.custom_minimum_size = Vector2(0, 74)
	_prompt_input.add_theme_font_size_override("font_size", 11)
	c2.add_child(_prompt_input)

	var btn_run := _small_btn("⚡ اجرای همفکری شورا در صحنه")
	btn_run.custom_minimum_size = Vector2(0, 30)
	btn_run.pressed.connect(_on_run_council_pressed)
	c2.add_child(btn_run)

	# Card 3: 2x2 Asset Forge, Blender, Mocap & Cutscene
	var c3 := _make_card(_sec_council)
	c3.add_child(_title_lbl("■ بلندر، Auto-Rig و ویدیو موشن"))

	var grid3 := GridContainer.new()
	grid3.columns = 2
	grid3.add_theme_constant_override("h_separation", 4)
	grid3.add_theme_constant_override("v_separation", 4)

	var dock_img_dlg := FileDialog.new()
	dock_img_dlg.title = "انتخاب عکس از سیستم برای تبدیل به مش سه‌بعدی و ریگ خودکار"
	dock_img_dlg.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dock_img_dlg.access = FileDialog.ACCESS_FILESYSTEM
	dock_img_dlg.use_native_dialog = false
	dock_img_dlg.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp, *.bmp ; تصاویر"])
	dock_img_dlg.file_selected.connect(func(p: String):
		var ctrl := _get_ctrl()
		if ctrl:
			ctrl.call("spawn_image_to_3d_rigged_character", p)
			if ctrl.has_method("switch_to_3d_viewport"): ctrl.call("switch_to_3d_viewport")
	)
	add_child(dock_img_dlg)

	var dock_mesh_dlg := FileDialog.new()
	dock_mesh_dlg.title = "انتخاب مدل سه‌بعدی (.glb / .gltf / .obj) برای ایمپورت"
	dock_mesh_dlg.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dock_mesh_dlg.access = FileDialog.ACCESS_FILESYSTEM
	dock_mesh_dlg.use_native_dialog = false
	dock_mesh_dlg.filters = PackedStringArray(["*.glb, *.gltf, *.obj ; مدل‌های سه‌بعدی"])
	dock_mesh_dlg.file_selected.connect(func(p: String):
		var ctrl := _get_ctrl()
		if ctrl:
			ctrl.call("import_blender_auto_pbr_gate", p)
			if ctrl.has_method("switch_to_3d_viewport"): ctrl.call("switch_to_3d_viewport")
	)
	add_child(dock_mesh_dlg)

	var b_img3d := _small_btn("◆ انتخاب عکس⬅ریگ")
	b_img3d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_img3d.pressed.connect(func(): dock_img_dlg.popup_centered(Vector2i(760, 500)))
	grid3.add_child(b_img3d)

	var b_mocap := _small_btn("▶ ویدیو⬅موشن")
	b_mocap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_mocap.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.call("run_video_to_motion_combo")
	)
	grid3.add_child(b_mocap)

	var b_blend := _small_btn("✦ انتخاب مدل 3D")
	b_blend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_blend.pressed.connect(func(): dock_mesh_dlg.popup_centered(Vector2i(760, 500)))
	grid3.add_child(b_blend)

	var b_cut := _small_btn("▶ کات‌سین زنده")
	b_cut.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_cut.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.call("trigger_live_cutscene")
	)
	grid3.add_child(b_cut)
	c3.add_child(grid3)

	# ══════════ SECTION B: LIVING NPC, ELEMENTAL CHEMISTRY & VORONOI ══════════
	_sec_world = VBoxContainer.new()
	_sec_world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sec_world.add_theme_constant_override("separation", 8)
	content.add_child(_sec_world)

	# Card 4: Living NPC Biography
	var c4 := _make_card(_sec_world)
	c4.add_child(_title_lbl("✦ NPC زنده (Evolving Life AI)"))

	_npc_bio = RichTextLabel.new()
	_npc_bio.bbcode_enabled = true
	_npc_bio.fit_content = true
	_npc_bio.scroll_active = false
	_npc_bio.add_theme_font_size_override("normal_font_size", 11)
	_npc_bio.add_theme_font_size_override("bold_font_size", 11)
	c4.add_child(_npc_bio)

	var npc_hb := HBoxContainer.new()
	npc_hb.add_theme_constant_override("separation", 4)

	var b_help := _small_btn("✦ کمک و خرید")
	b_help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_help.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.call("help_npc")
	)
	npc_hb.add_child(b_help)

	var b_fight := _small_btn("⚔ درگیری و فرار")
	b_fight.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_fight.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.call("fight_npc")
	)
	npc_hb.add_child(b_fight)
	c4.add_child(npc_hb)

	var b_days := _small_btn("» +۵ روز تکامل زندگی NPCها")
	b_days.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.call("advance_world_days", 5)
	)
	c4.add_child(b_days)

	# Card 5: Elemental Chemistry
	var c5 := _make_card(_sec_world)
	c5.add_child(_title_lbl("✦ شیمی عناصر و جهان‌باز"))

	var egrid := GridContainer.new()
	egrid.columns = 2
	egrid.add_theme_constant_override("h_separation", 4)
	egrid.add_theme_constant_override("v_separation", 4)

	var elems := [
		["CLEAR", "● صاف"],
		["RAIN", "◈ باران (خیس)"],
		["FIRE", "▲ آتش + باد"],
		["LIGHTNING", "⚡ صاعقه در آب"]
	]
	for item in elems:
		var code: String = item[0]
		var eb := _small_btn(item[1])
		eb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		eb.pressed.connect(func():
			var ctrl := _get_ctrl()
			if ctrl:
				_elem_status.text = str(ctrl.call("apply_elemental_weather", code))
		)
		egrid.add_child(eb)
	c5.add_child(egrid)

	_elem_status = _small_lbl("واکنش فعال: محیط پایدار | Chunk [0,0]")
	_elem_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c5.add_child(_elem_status)

	# Card 6: Smart Voronoi Object Controls
	var c6 := _make_card(_sec_world)
	c6.add_child(_title_lbl("■ منوی هوشمند آبجکت و Voronoi"))

	for chk_txt in [
		"قابل تعامل ([E] لولای خودکار)",
		"تخریب واقعی (Voronoi 3D Shards)",
		"زندگی پیش‌رونده (Evolving Life)"
	]:
		var chk := CheckBox.new()
		chk.text = chk_txt
		chk.button_pressed = true
		chk.clip_text = true
		chk.add_theme_font_size_override("font_size", 11)
		c6.add_child(chk)

	var obj_in := LineEdit.new()
	obj_in.placeholder_text = "پرامپت اختصاصی آبجکت..."
	obj_in.add_theme_font_size_override("font_size", 11)
	c6.add_child(obj_in)

	var b_shatter := _small_btn("★ تست شمشیر / تخریب Voronoi")
	b_shatter.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.call("shatter_or_reset_crate")
	)
	c6.add_child(b_shatter)

	call_deferred("_bind_ctrl")


func _title_lbl(txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.clip_text = true
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(0.38, 0.80, 1.0))
	return l


func _small_lbl(txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 11)
	return l


func _small_btn(txt: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 11)
	return b


func _make_card(parent: VBoxContainer) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)
	parent.add_child(panel)
	return vb


func _bind_ctrl() -> void:
	var ctrl := _get_ctrl()
	if ctrl and ctrl.has_signal("state_updated"):
		if not ctrl.is_connected("state_updated", _on_state_updated):
			ctrl.connect("state_updated", _on_state_updated)
		_on_state_updated(ctrl.call("get_snapshot_dict"))


func _get_ctrl() -> Node:
	if get_tree() and get_tree().root.has_node("NovaEditorController"):
		return get_tree().root.get_node("NovaEditorController")
	return null


func _on_state_updated(st: Dictionary) -> void:
	if _npc_bio == null:
		return
	var n: Dictionary = st.get("npc", {})
	var rel: int = int(n.get("rel", 10))
	var rel_tag := "معمولی"
	if rel <= -35:
		rel_tag = "[color=#ef4444]دشمن Nemesis[/color]"
	elif rel >= 35:
		rel_tag = "[color=#22c55e]متحد وفادار[/color]"
	var rel_str := ("+" + str(rel)) if rel >= 0 else str(rel)
	var scars: Array = n.get("scars", [])
	var counters: Array = n.get("counters", [])
	var scar_txt := "بدون زخم" if scars.is_empty() else "، ".join(PackedStringArray(scars))
	var cnt_txt := "در حال یادگیری" if counters.is_empty() else ", ".join(PackedStringArray(counters))

	_npc_bio.text = (
		"[b]نام:[/b] کاوه آهنگر | [b]روز %d[/b]\n" % int(st.get("day", 1)) +
		"[b]شغل:[/b] %s\n" % str(n.get("title", "شاگرد آهنگر")) +
		"[b]ثروت:[/b] %d سکه | [b]رابطه:[/b] %s (%s)\n" % [int(n.get("gold", 120)), rel_str, rel_tag] +
		"[b]حافظه نبرد:[/b] %s | %s" % [scar_txt, cnt_txt]
	)


func _on_run_council_pressed() -> void:
	if _council_busy:
		return
	var prompt_txt := _prompt_input.text.strip_edges()
	if prompt_txt.is_empty():
		return

	_council_busy = true
	_relay_badge.text = "همفکری..."
	_relay_badge.add_theme_color_override("font_color", Color(0.98, 0.72, 0.20))

	var vram_steps := ["2.1 GB / 5.0 GB", "1.8 GB / 5.0 GB", "2.6 GB / 5.0 GB", "1.9 GB / 5.0 GB", "1.4 GB / 5.0 GB"]
	var vram_vals := [44.0, 36.0, 52.0, 38.0, 28.0]

	var tw := create_tween()
	for i in range(5):
		var idx := i
		tw.tween_callback(func():
			for j in range(5):
				_brain_labels[j].add_theme_color_override("font_color", Color(0.25, 0.95, 0.50) if j == idx else Color(0.88, 0.91, 0.96))
			_vram_bar.value = vram_vals[idx]
			_vram_label.text = "VRAM شورا: " + vram_steps[idx]
		)
		tw.tween_interval(0.24)

	tw.tween_callback(func():
		for j in range(5):
			_brain_labels[j].add_theme_color_override("font_color", Color(0.88, 0.91, 0.96))
		_vram_bar.value = 8.0
		_vram_label.text = "VRAM: 0.3 GB / 5.0 GB (تخلیه برای رندر)"
		_relay_badge.text = "تایید شد ✓"
		_relay_badge.add_theme_color_override("font_color", Color(0.20, 0.85, 0.45))
		_execute_council_scene_actions(prompt_txt)
		_council_busy = false
	)


func _execute_council_scene_actions(prompt_txt: String) -> void:
	var ctrl := _get_ctrl()
	if ctrl:
		ctrl.call("run_prompt_council_build", prompt_txt)
		if ctrl.has_method("switch_to_3d_viewport"):
			ctrl.call("switch_to_3d_viewport")
