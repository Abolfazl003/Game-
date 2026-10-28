@tool
extends ScrollContainer
class_name NovaLivingWorldDock
## Living NPC Biography, Elemental Chemistry, Smart Voronoi Object Menu & Blueprint Summary Dock
## (`Living World` tab mounted in Godot 4 right dock alongside Inspector).

var _npc_bio: RichTextLabel
var _elem_status: Label
var _chk_interact: CheckBox
var _chk_destruct: CheckBox
var _chk_evolve: CheckBox
var _obj_prompt: LineEdit


func _ready() -> void:
	custom_minimum_size = Vector2(315, 320)
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var root_vbox := VBoxContainer.new()
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", 8)
	add_child(root_vbox)

	# ── CARD 1: Evolving Life NPC (کاوه آهنگر) ──
	var c1 := _make_card(root_vbox)
	var t1 := Label.new()
	t1.text = "🧬 وضعیت NPC زنده (Evolving Life AI)"
	t1.add_theme_color_override("font_color", Color(0.35, 0.78, 1.0))
	c1.add_child(t1)

	_npc_bio = RichTextLabel.new()
	_npc_bio.bbcode_enabled = true
	_npc_bio.fit_content = true
	_npc_bio.scroll_active = false
	_npc_bio.custom_minimum_size = Vector2(0, 96)
	c1.add_child(_npc_bio)

	var npc_btns := HBoxContainer.new()
	npc_btns.add_theme_constant_override("separation", 6)

	var btn_help := Button.new()
	btn_help.text = "🤝 کمک و خرید"
	btn_help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_help.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.help_npc()
	)
	npc_btns.add_child(btn_help)

	var btn_fight := Button.new()
	btn_fight.text = "⚔️ درگیری و فرار"
	btn_fight.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_fight.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.fight_npc()
	)
	npc_btns.add_child(btn_fight)
	c1.add_child(npc_btns)

	var btn_days := Button.new()
	btn_days.text = "⏩ جلو بردن زمان بازی (+۵ روز تکامل زندگی NPCها)"
	btn_days.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.advance_world_days(5)
	)
	c1.add_child(btn_days)

	# ── CARD 2: Elemental Chemistry & Open-World ──
	var c2 := _make_card(root_vbox)
	var t2 := Label.new()
	t2.text = "🌦️ شیمی عناصر و جهان‌باز"
	t2.add_theme_color_override("font_color", Color(0.35, 0.78, 1.0))
	c2.add_child(t2)

	var egrid := GridContainer.new()
	egrid.columns = 2
	egrid.add_theme_constant_override("h_separation", 6)
	egrid.add_theme_constant_override("v_separation", 6)

	var elems := [
		["CLEAR", "☀️ صاف"],
		["RAIN", "🌧️ باران (خیس)"],
		["FIRE", "🔥 آتش + باد"],
		["LIGHTNING", "⚡ صاعقه در آب"]
	]
	for item in elems:
		var code: String = item[0]
		var b := Button.new()
		b.text = item[1]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func():
			var ctrl := _get_ctrl()
			if ctrl:
				_elem_status.text = ctrl.apply_elemental_weather(code)
		)
		egrid.add_child(b)
	c2.add_child(egrid)

	_elem_status = Label.new()
	_elem_status.text = "واکنش فعال: محیط پایدار | Chunk [0,0] LOD0"
	_elem_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c2.add_child(_elem_status)

	# ── CARD 3: Smart Object & Voronoi Destruction Controls ──
	var c3 := _make_card(root_vbox)
	var t3 := Label.new()
	t3.text = "📦 منوی هوشمند آبجکت و تخریب Voronoi"
	t3.add_theme_color_override("font_color", Color(0.35, 0.78, 1.0))
	c3.add_child(t3)

	_chk_interact = CheckBox.new()
	_chk_interact.text = "قابل تعامل ([E] تشخیص خودکار لولا)"
	_chk_interact.button_pressed = true
	c3.add_child(_chk_interact)

	_chk_destruct = CheckBox.new()
	_chk_destruct.text = "تخریب واقعی با سلاح (Voronoi 3D Shards)"
	_chk_destruct.button_pressed = true
	c3.add_child(_chk_destruct)

	_chk_evolve = CheckBox.new()
	_chk_evolve.text = "هوش مصنوعی زندگی پیش‌رونده (Evolving Life)"
	_chk_evolve.button_pressed = true
	c3.add_child(_chk_evolve)

	_obj_prompt = LineEdit.new()
	_obj_prompt.placeholder_text = "پرامپت اختصاصی برای آبجکت/NPC انتخابی..."
	c3.add_child(_obj_prompt)

	var btn_shatter := Button.new()
	btn_shatter.text = "💥 تست ضربه شمشیر / تخریب یا بازسازی صندوق"
	btn_shatter.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.shatter_or_reset_crate()
	)
	c3.add_child(btn_shatter)

	# ── CARD 4: Active Blueprint Graph Summary ──
	var c4 := _make_card(root_vbox)
	var t4 := Label.new()
	t4.text = "🔗 پیش‌نمایش گراف Blueprint فعال"
	t4.add_theme_color_override("font_color", Color(0.35, 0.78, 1.0))
	c4.add_child(t4)

	var bp_lbl := Label.new()
	bp_lbl.text = "[Event_BeginPlay] ──▶ [SetupPerspective: TPS_SOULS]\n[Event_OnAttack] ──▶ [Branch: stamina >= 18]\n   ├─True─▶ [PlayMeleeCombo3Hit] ──▶ [VoronoiHitCheck]\n   └─False▶ [StaminaWarningHUD]"
	bp_lbl.add_theme_color_override("font_color", Color(0.58, 0.78, 0.98))
	c4.add_child(bp_lbl)

	call_deferred("_bind_ctrl")


func _make_card(parent: VBoxContainer) -> VBoxContainer:
	var panel := PanelContainer.new()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	panel.add_child(vb)
	parent.add_child(panel)
	return vb


func _bind_ctrl() -> void:
	var ctrl := _get_ctrl()
	if ctrl:
		if not ctrl.state_updated.is_connected(_on_state_updated):
			ctrl.state_updated.connect(_on_state_updated)
		_on_state_updated(ctrl.get_snapshot_dict())


func _get_ctrl() -> NovaEditorSceneController:
	if get_tree() and get_tree().root.has_node("NovaEditorController"):
		return get_tree().root.get_node("NovaEditorController") as NovaEditorSceneController
	return null


func _on_state_updated(st: Dictionary) -> void:
	if _npc_bio == null:
		return
	var n: Dictionary = st.get("npc", {})
	var rel: int = int(n.get("rel", 10))
	var rel_tag := "معمولی"
	if rel <= -35:
		rel_tag = "[color=#ef4444]دشمن خونی / Nemesis[/color]"
	elif rel >= 35:
		rel_tag = "[color=#22c55e]متحد وفادار[/color]"
	var rel_str := ("+" + str(rel)) if rel >= 0 else str(rel)
	var scars: Array = n.get("scars", [])
	var counters: Array = n.get("counters", [])
	var scar_txt := "بدون زخم" if scars.is_empty() else "، ".join(PackedStringArray(scars))
	var cnt_txt := "در حال یادگیری" if counters.is_empty() else ("ضدحمله: " + ", ".join(PackedStringArray(counters)))

	_npc_bio.text = (
		"[b]نام:[/b] کاوه آهنگر (Kaveh) | [b]روز دنیا:[/b] روز %d\n" % int(st.get("day", 1)) +
		"[b]مرتبه شغلی:[/b] %s\n" % str(n.get("title", "شاگرد آهنگر")) +
		"[b]ثروت:[/b] %d سکه طلا\n" % int(n.get("gold", 120)) +
		"[b]رابطه با بازیکن:[/b] %s (%s)\n" % [rel_str, rel_tag] +
		"[b]زخم‌ها / حافظه نبرد:[/b] %s | %s" % [scar_txt, cnt_txt]
	)
