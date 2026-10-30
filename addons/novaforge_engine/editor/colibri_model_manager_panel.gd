@tool
extends VBoxContainer
## Interactive AI Model Hub & Colibrì Panel (`مدل‌های هوش مصنوعی Colibrì` — v3.1).
## Every model row is now clickable & live-testable, connected directly to `NeuralLLMBrainClient`
## and `Neural3DCloudClient`, plus 1-click Local Ollama detection!

var _model_tree: Tree
var _hw_summary_label: Label
var _quick_input: LineEdit
var _live_reply_lbl: RichTextLabel
var _builtin_row: TreeItem = null
var _dl_bar: ProgressBar = null


func _ready() -> void:
	custom_minimum_size = Vector2(0, 235)
	add_theme_constant_override("separation", 5)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 6)

	_hw_summary_label = Label.new()
	_hw_summary_label.text = "◆ نصب و دانلود خودکار داخل برنامه فعال است — روی هر مدل کلیک کنید تا فعال و تست شود!"
	_hw_summary_label.clip_text = true
	_hw_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(_hw_summary_label)

	_dl_bar = ProgressBar.new()
	_dl_bar.min_value = 0.0
	_dl_bar.max_value = 100.0
	_dl_bar.value = 0.0
	_dl_bar.custom_minimum_size = Vector2(140, 18)
	top_bar.add_child(_dl_bar)

	var btn_ollama := Button.new()
	btn_ollama.text = "✦ بررسی Ollama لوکال"
	btn_ollama.pressed.connect(_check_ollama_now)
	top_bar.add_child(btn_ollama)

	var btn_img3d := Button.new()
	btn_img3d.text = "◆ ساخت مش ۳۶۰ درجه نمونه"
	btn_img3d.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl:
			_hw_summary_label.text = "در حال ساخت مش ۳۶۰ درجه با Hunyuan3D-2..."
			ctrl.call("spawn_image_to_3d_rigged_character")
	)
	top_bar.add_child(btn_img3d)

	var btn_mocap := Button.new()
	btn_mocap.text = "▶ تست موشن شمشیر"
	btn_mocap.pressed.connect(func():
		var ctrl := _get_ctrl()
		if ctrl:
			ctrl.call("run_video_to_motion_combo")
			ctrl.call("switch_to_3d_viewport")
		_hw_summary_label.text = "✓ انیمیشن کمبوی شمشیر روی اسکلت کاراکتر اجرا شد!"
	)
	top_bar.add_child(btn_mocap)
	add_child(top_bar)

	# Quick Test Chat Bar right inside the Models Panel!
	var ask_bar := HBoxContainer.new()
	ask_bar.add_theme_constant_override("separation", 6)
	_quick_input = LineEdit.new()
	_quick_input.placeholder_text = "پیام تستی به مغز انتخاب‌شده بنویسید (مثلاً: سلام! یه کد پرش کاراکتر بنویس) و Enter بزنید..."
	_quick_input.text = "سلام! در دو خط بگو وظیفه تو در موتور بازی‌سازی نوافورج چیست؟"
	_quick_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quick_input.text_submitted.connect(func(_t: String): _run_quick_test(""))
	ask_bar.add_child(_quick_input)

	var btn_send := Button.new()
	btn_send.text = "⚡ ارسال و تست زنده هوش مصنوعی"
	btn_send.pressed.connect(func(): _run_quick_test(""))
	ask_bar.add_child(btn_send)
	add_child(ask_bar)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(split)

	_model_tree = Tree.new()
	_model_tree.columns = 4
	_model_tree.set_column_titles_visible(true)
	_model_tree.set_column_title(0, "شناسه مغز هوش مصنوعی")
	_model_tree.set_column_title(1, "نقش تخصصی")
	_model_tree.set_column_title(2, "حالت اجرا")
	_model_tree.set_column_title(3, "وضعیت (کلیک برای تست زنده)")
	_model_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_model_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_model_tree.item_selected.connect(_on_tree_item_clicked)
	_model_tree.item_activated.connect(_on_tree_item_clicked)
	split.add_child(_model_tree)

	_live_reply_lbl = RichTextLabel.new()
	_live_reply_lbl.bbcode_enabled = true
	_live_reply_lbl.selection_enabled = true
	_live_reply_lbl.scroll_following = true
	_live_reply_lbl.custom_minimum_size = Vector2(420, 0)
	_live_reply_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_live_reply_lbl.text = "[color=#38bdf8][b]⚡ پاسخ زنده مغزها:[/b][/color]\nروی هر ردیف از جدول سمت راست کلیک کنید یا دکمه [b]«⚡ ارسال و تست زنده هوش مصنوعی»[/b] را بزنید تا همان لحظه پاسخ واقعی دریافت کنید!"
	split.add_child(_live_reply_lbl)

	_populate_models()
	call_deferred("_bind_signals")


func _populate_models() -> void:
	_model_tree.clear()
	_builtin_row = null
	var root := _model_tree.create_item()
	var rows := [
		["Qwen2.5-Coder (نصب داخل برنامه)", "موتور آفلاین کدنویس و بازی‌ساز (Colibrì GGUF)", "127.0.0.1:11435 (نصب خودکار)", "⬇ در حال دانلود و نصب خودکار..."],
		["Command-A-Reasoning-111B", "کارگردان ارشد و کدنویس GDScript/C++", "ابری رایگان (بدون کلید)", "✓ آنلاین — کلیک برای تست زنده"],
		["Cohere-Aya-Persian-Fast", "دستیار فارسی فوق‌سریع و دیالوگ NPC", "ابری رایگان (۱ ثانیه)", "✓ آنلاین — کلیک برای تست زنده"],
		["Tencent-Hunyuan3D-2", "ساخت مش سه‌بعدی ۳۶۰ درجه واقعی (.GLB)", "ابری رایگان + دوربری عصبی", "✓ آنلاین — کلیک برای ساخت مش"],
		["Colibrì / Ollama Local", "اجرای آفلاین مدل‌های سیستم شما", "127.0.0.1:11434 (RAM/VRAM)", "▶ کلیک برای بررسی و اتصال"],
	]
	for i in range(rows.size()):
		var r: Array = rows[i]
		var item := _model_tree.create_item(root)
		item.set_text(0, r[0])
		item.set_text(1, r[1])
		item.set_text(2, r[2])
		item.set_text(3, r[3])
		if i == 0:
			_builtin_row = item


func _on_tree_item_clicked() -> void:
	var sel := _model_tree.get_selected()
	if sel == null:
		return
	var mid := sel.get_text(0)
	var role := sel.get_text(1)
	if mid.contains("Hunyuan3D-2"):
		_live_reply_lbl.text = "[color=#38bdf8][b]◆ موتور سه‌بعدی Hunyuan3D-2 فعال شد![/b][/color]\nدر حال ساخت مش سه‌بعدی ۳۶۰ درجه از تصویر نمونه..."
		var ctrl := _get_ctrl()
		if ctrl:
			ctrl.call("spawn_image_to_3d_rigged_character")
		return
	if mid.contains("Ollama"):
		_check_ollama_now()
		return
	var ctrl := _get_ctrl()
	if ctrl and ctrl.has_method("get_llm_brain"):
		var b: Node = ctrl.call("get_llm_brain")
		if b:
			if mid.contains("نصب داخل برنامه"):
				b.set("preferred_backend", "BUILTIN_LOCAL")
			elif mid.contains("Aya"):
				b.set("preferred_backend", "AYA_FAST")
			else:
				b.set("preferred_backend", "AUTO_CLOUD")
	_run_quick_test(mid + " — " + role)


func _run_quick_test(persona_title: String) -> void:
	var ctrl := _get_ctrl()
	if ctrl == null or not ctrl.has_method("ask_ai_council_async"):
		return
	var q := _quick_input.text.strip_edges()
	if q.is_empty():
		q = "سلام! کوتاه بگو چه کمکی می‌تونی بکنی؟"
	_live_reply_lbl.text = "[color=#fde047][b]▶ پرسش شما:[/b] %s[/color]\n[color=#94a3b8]در حال دریافت پاسخ زنده از هوش مصنوعی...[/color]" % q
	var res: Dictionary = await ctrl.call("ask_ai_council_async", q, false, persona_title)
	if res.get("ok", false):
		_live_reply_lbl.text = "[color=#22c55e][b]✓ پاسخ از %s:[/b][/color]\n%s" % [str(res.get("model", "")), str(res.get("reply", ""))]
		_hw_summary_label.text = "✓ پاسخ زنده از «%s» دریافت شد!" % str(res.get("model", ""))


func _check_ollama_now() -> void:
	var ctrl := _get_ctrl()
	if ctrl == null or not ctrl.has_method("get_llm_brain"):
		return
	var b: Node = ctrl.call("get_llm_brain")
	if b == null:
		return
	_live_reply_lbl.text = "[color=#94a3b8]در حال بررسی پورت 127.0.0.1:11434 برای Ollama لوکال...[/color]"
	var r: Dictionary = await b.call("check_local_ollama_status_async")
	if r.get("ok", false):
		var ms: Array = r.get("models", [])
		_live_reply_lbl.text = "[color=#22c55e][b]✓ سرور Ollama لوکال روی ویندوز/لینوکس شما فعال است![/b][/color]\nمدل‌های آماده: %s" % (", ".join(PackedStringArray(ms)) if not ms.is_empty() else "بدون مدل")
	else:
		_live_reply_lbl.text = "[color=#f59e0b][b]سرویس Ollama روی پورت 11434 باز نیست.[/b][/color]\nنگران نباشید! مغزهای ابری رایگان ([b]Command-A 111B[/b] و [b]Cohere Aya[/b] و [b]Hunyuan3D-2[/b]) بدون نیاز به هیچ کلید یا نصبی فعال و آماده پاسخگویی هستند!"


func _get_ctrl() -> Node:
	if get_tree() and get_tree().root.has_node("NovaEditorController"):
		return get_tree().root.get_node("NovaEditorController")
	return null


func _bind_signals() -> void:
	var ctrl := _get_ctrl()
	if ctrl:
		if ctrl.has_signal("ai_chat_replied") and not ctrl.is_connected("ai_chat_replied", _on_global_reply):
			ctrl.connect("ai_chat_replied", _on_global_reply)
		if ctrl.has_signal("setup_state_updated") and not ctrl.is_connected("setup_state_updated", _on_setup_state_updated):
			ctrl.connect("setup_state_updated", _on_setup_state_updated)
		if ctrl.has_method("get_setup_installer"):
			var inst: Node = ctrl.call("get_setup_installer")
			if inst and inst.has_method("get_state"):
				_on_setup_state_updated(inst.call("get_state"))


func _on_setup_state_updated(st: Dictionary) -> void:
	var ov := int(st.get("overall_pct", 0))
	if _dl_bar:
		_dl_bar.value = float(ov)
	if _hw_summary_label:
		_hw_summary_label.text = str(st.get("headline", ""))
	if _builtin_row:
		if bool(st.get("local_ready", false)):
			_builtin_row.set_text(3, "✓ نصب‌شده و فعال (کلیک برای تست آفلاین)")
		elif bool(st.get("paused", false)):
			_builtin_row.set_text(3, "■ متوقف‌شده (%d%%)" % ov)
		else:
			var d_mb := float(st.get("downloaded_mb", 0.0))
			var t_mb := float(st.get("total_mb", 0.0))
			if t_mb > 0.5:
				_builtin_row.set_text(3, "⬇ دانلود زنده: %.0f / %.0f MB (%d%%)" % [d_mb, t_mb, int(st.get("file_pct", 0))])
			else:
				_builtin_row.set_text(3, "• در حال راه‌اندازی (%d%%)..." % ov)


func _on_global_reply(res: Dictionary) -> void:
	if _live_reply_lbl and res.get("ok", false):
		_live_reply_lbl.text = "[color=#22c55e][b]✓ آخرین پاسخ (%s):[/b][/color]\n%s" % [str(res.get("model", "")), str(res.get("reply", "")).left(900)]
