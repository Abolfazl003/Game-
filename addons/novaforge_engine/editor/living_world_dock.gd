@tool
extends ScrollContainer
## Living NPC Biography, Elemental Chemistry, Smart Voronoi Object Menu & Blueprint Summary Dock (100% Persian & Cold-Boot Safe).

var _npc_bio: RichTextLabel
var _elem_status: Label


func _ready() -> void:
	custom_minimum_size = Vector2(215, 290)
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var root_vbox := VBoxContainer.new()
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", 8)
	add_child(root_vbox)

	var c1 := _make_card(root_vbox)
	var t1 := Label.new()
	t1.text = "✦ وضعیت NPC زنده (کاوه آهنگر)"
	t1.add_theme_color_override("font_color", Color(0.35, 0.78, 1.0))
	c1.add_child(t1)

	_npc_bio = RichTextLabel.new()
	_npc_bio.bbcode_enabled = true
	_npc_bio.fit_content = true
	_npc_bio.scroll_active = false
	c1.add_child(_npc_bio)

	var npc_btns := HBoxContainer.new()
	npc_btns.add_theme_constant_override("separation", 5)

	var btn_help := Button.new()
	btn_help.text = "✦ کمک و خرید"
	btn_help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_help.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.call("help_npc")
	)
	npc_btns.add_child(btn_help)

	var btn_fight := Button.new()
	btn_fight.text = "⚔ درگیری Nemesis"
	btn_fight.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_fight.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.call("fight_npc")
	)
	npc_btns.add_child(btn_fight)
	c1.add_child(npc_btns)

	var btn_days := Button.new()
	btn_days.text = "» +۵ روز تکامل زندگی NPCها"
	btn_days.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.call("advance_world_days", 5)
	)
	c1.add_child(btn_days)

	var c2 := _make_card(root_vbox)
	var t2 := Label.new()
	t2.text = "✦ شیمی عناصر و جهان‌باز"
	t2.add_theme_color_override("font_color", Color(0.35, 0.78, 1.0))
	c2.add_child(t2)

	var egrid := GridContainer.new()
	egrid.columns = 2
	egrid.add_theme_constant_override("h_separation", 5)
	egrid.add_theme_constant_override("v_separation", 5)

	for item in [["CLEAR", "● صاف"], ["RAIN", "◈ باران (خیس)"], ["FIRE", "▲ آتش + باد"], ["LIGHTNING", "⚡ صاعقه در آب"]]:
		var code: String = item[0]
		var b := Button.new()
		b.text = item[1]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func():
			var ctrl := _get_ctrl()
			if ctrl: _elem_status.text = str(ctrl.call("apply_elemental_weather", code))
		)
		egrid.add_child(b)
	c2.add_child(egrid)

	_elem_status = Label.new()
	_elem_status.text = "واکنش فعال: محیط پایدار | چانک [0,0]"
	_elem_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c2.add_child(_elem_status)

	var c3 := _make_card(root_vbox)
	var t3 := Label.new()
	t3.text = "■ تخریب فیزیکی Voronoi 3D"
	t3.add_theme_color_override("font_color", Color(0.35, 0.78, 1.0))
	c3.add_child(t3)

	var btn_shatter := Button.new()
	btn_shatter.text = "★ تست شمشیر / تخریب یا بازسازی صندوق"
	btn_shatter.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl: ctrl.call("shatter_or_reset_crate")
	)
	c3.add_child(btn_shatter)

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
	_npc_bio.text = (
		"[b]نام:[/b] کاوه آهنگر | [b]روز %d[/b]\n" % int(st.get("day", 1)) +
		"[b]شغل:[/b] %s\n" % str(n.get("title", "شاگرد آهنگر")) +
		"[b]ثروت:[/b] %d سکه | [b]رابطه:[/b] %s (%s)" % [int(n.get("gold", 120)), rel_str, rel_tag]
	)
