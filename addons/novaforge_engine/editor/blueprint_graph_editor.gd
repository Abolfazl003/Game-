@tool
extends VBoxContainer
## Persian Visual Blueprint Graph Editor (`گراف دیداری بلوپرینت` — v4.0 Prompt-to-Graph + C++20/GDScript Compiler).

var _graph_edit: GraphEdit
var _target_selector: OptionButton
var _status_label: Label
var _prompt_line: LineEdit
var _node_counter: int = 0
var _spawned_nodes: Array[Dictionary] = []
var _last_compiled_path: String = ""


func _ready() -> void:
	custom_minimum_size = Vector2(0, 250)
	add_theme_constant_override("separation", 5)

	# Prompt-to-Blueprint AI Row
	var ai_bar := HBoxContainer.new()
	ai_bar.add_theme_constant_override("separation", 6)
	_prompt_line = LineEdit.new()
	_prompt_line.text = "وقتی بازیکن کلید تعامل E را زد، اگر استامینا کافی بود کمبوی شمشیر و تخریب Voronoi و کات‌سین اجرا شود"
	_prompt_line.placeholder_text = "منطق بازی را به فارسی بنویسید تا خودکار به گره‌های متصل بلوپرینت تبدیل شود..."
	_prompt_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prompt_line.text_submitted.connect(func(_t: String): build_graph_from_prompt(_prompt_line.text))
	ai_bar.add_child(_prompt_line)

	var btn_ai_bp := Button.new()
	btn_ai_bp.text = "⚡ تبدیل متن به گراف بلوپرینت"
	btn_ai_bp.pressed.connect(func(): build_graph_from_prompt(_prompt_line.text))
	ai_bar.add_child(btn_ai_bp)
	add_child(ai_bar)

	# Node Toolbar + Compiler Row
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 5)

	var btn_ev := Button.new()
	btn_ev.text = "+ رویداد (Event)"
	btn_ev.pressed.connect(func(): _spawn_bp_node("رویداد_ورودی_بازیکن", "EVENT_ENTRY", Color(0.78, 0.20, 0.24), Vector2(40 + (_node_counter % 4) * 225, 135)))
	bar.add_child(btn_ev)

	var btn_br := Button.new()
	btn_br.text = "+ شرط (Branch)"
	btn_br.pressed.connect(func(): _spawn_bp_node("بررسی_شرط_گیم‌پلی", "FLOW_BRANCH", Color(0.30, 0.38, 0.52), Vector2(40 + (_node_counter % 4) * 225, 135)))
	bar.add_child(btn_br)

	var btn_combo := Button.new()
	btn_combo.text = "+ کمبوی شمشیر"
	btn_combo.pressed.connect(func(): _spawn_bp_node("اجرای_کمبو_۳ضربه‌ای", "GAMEPLAY_ACTION", Color(0.16, 0.48, 0.72), Vector2(40 + (_node_counter % 4) * 225, 135)))
	bar.add_child(btn_combo)

	var btn_frac := Button.new()
	btn_frac.text = "+ تخریب Voronoi"
	btn_frac.pressed.connect(func(): _spawn_bp_node("تخریب_۱۶تکه_Voronoi", "GAMEPLAY_ACTION", Color(0.72, 0.44, 0.14), Vector2(40 + (_node_counter % 4) * 225, 135)))
	bar.add_child(btn_frac)

	var btn_cut := Button.new()
	btn_cut.text = "+ کات‌سین"
	btn_cut.pressed.connect(func(): _spawn_bp_node("شروع_کات‌سین_زنده", "GAMEPLAY_ACTION", Color(0.52, 0.26, 0.72), Vector2(40 + (_node_counter % 4) * 225, 135)))
	bar.add_child(btn_cut)

	bar.add_child(VSeparator.new())

	_target_selector = OptionButton.new()
	_target_selector.add_item("خروجی -> کد C++20 (.hpp)")
	_target_selector.add_item("خروجی -> کد GDScript (.gd)")
	bar.add_child(_target_selector)

	var btn_compile := Button.new()
	btn_compile.text = "⚡ کامپایل گراف"
	btn_compile.pressed.connect(_on_compile_pressed)
	bar.add_child(btn_compile)

	var btn_open := Button.new()
	btn_open.text = "✦ باز کردن کد"
	btn_open.pressed.connect(_open_compiled_code)
	bar.add_child(btn_open)

	_status_label = Label.new()
	_status_label.text = "آماده کامپایل"
	_status_label.clip_text = true
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(_status_label)

	add_child(bar)

	_graph_edit = GraphEdit.new()
	_graph_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph_edit.custom_minimum_size = Vector2(0, 175)
	_graph_edit.right_disconnects = true
	_graph_edit.connection_request.connect(_on_connection_request)
	_graph_edit.disconnection_request.connect(_on_disconnection_request)
	add_child(_graph_edit)

	call_deferred("_seed_samurai_graph")


func _clear_graph() -> void:
	_graph_edit.clear_connections()
	for ch in _graph_edit.get_children():
		if ch is GraphNode:
			ch.queue_free()
	_spawned_nodes.clear()
	_node_counter = 0


func build_graph_from_prompt(txt: String) -> void:
	var p := txt.strip_edges()
	if p.is_empty():
		return
	_clear_graph()
	var chain: Array[StringName] = []
	var x_pos := 24.0

	var ev_title := "رویداد_تعامل (Input E)" if (p.contains("کلید") or p.contains("تعامل") or p.contains("E")) else "رویداد_شروع_مکانیک (OnTrigger)"
	chain.append(_spawn_bp_node(ev_title, "EVENT_ENTRY", Color(0.78, 0.20, 0.24), Vector2(x_pos, 42)))
	x_pos += 235.0

	if p.contains("اگر") or p.contains("شرط") or p.contains("استامینا") or p.contains("طلا"):
		chain.append(_spawn_bp_node("شرط_گیم‌پلی (Branch)", "FLOW_BRANCH", Color(0.32, 0.42, 0.62), Vector2(x_pos, 42)))
		x_pos += 235.0

	if p.contains("شمشیر") or p.contains("کمبو") or p.contains("ضربه") or p.contains("حمله"):
		chain.append(_spawn_bp_node("اکشن: کمبوی_شمشیر", "GAMEPLAY_ACTION", Color(0.16, 0.50, 0.76), Vector2(x_pos, 42)))
		x_pos += 235.0

	if p.contains("تخریب") or p.contains("Voronoi") or p.contains("جعبه") or p.contains("شکستن"):
		chain.append(_spawn_bp_node("اکشن: تخریب_Voronoi_3D", "GAMEPLAY_ACTION", Color(0.76, 0.46, 0.16), Vector2(x_pos, 42)))
		x_pos += 235.0

	if p.contains("کات‌سین") or p.contains("کات سین") or p.contains("دوربین"):
		chain.append(_spawn_bp_node("اکشن: کات‌سین_سینمایی", "GAMEPLAY_ACTION", Color(0.56, 0.28, 0.78), Vector2(x_pos, 42)))
		x_pos += 235.0

	if chain.size() == 1:
		chain.append(_spawn_bp_node("اکشن: اجرای_منطق_پرامپت", "GAMEPLAY_ACTION", Color(0.16, 0.54, 0.44), Vector2(x_pos, 42)))

	for i in range(chain.size() - 1):
		_graph_edit.connect_node(chain[i], 0, chain[i + 1], 0)

	_status_label.text = "✓ %d گره از پرامپت ساخته و متصل شد" % chain.size()
	_on_compile_pressed()


func _seed_samurai_graph() -> void:
	var n1 := _spawn_bp_node("شروع_بازی (BeginPlay)", "EVENT_ENTRY", Color(0.78, 0.20, 0.24), Vector2(24, 18))
	var n2 := _spawn_bp_node("دوربین: سوم‌شخص سولز", "GAMEPLAY_ACTION", Color(0.16, 0.48, 0.72), Vector2(250, 18))

	var n3 := _spawn_bp_node("ورودی_ضربه (OnAttack)", "EVENT_ENTRY", Color(0.78, 0.20, 0.24), Vector2(24, 112))
	var n4 := _spawn_bp_node("شرط: استامینا >= ۱۸", "FLOW_BRANCH", Color(0.32, 0.40, 0.56), Vector2(250, 112))
	var n5 := _spawn_bp_node("کمبوی_۳ضربه‌ای_کاتانا", "GAMEPLAY_ACTION", Color(0.16, 0.48, 0.72), Vector2(485, 112))
	var n6 := _spawn_bp_node("برش_Voronoi (۱۶ قطعه)", "GAMEPLAY_ACTION", Color(0.76, 0.46, 0.16), Vector2(720, 112))

	_graph_edit.connect_node(n1, 0, n2, 0)
	_graph_edit.connect_node(n3, 0, n4, 0)
	_graph_edit.connect_node(n4, 0, n5, 0)
	_graph_edit.connect_node(n5, 0, n6, 0)


func _spawn_bp_node(node_title: String, kind: String, header_tint: Color, pos: Vector2) -> StringName:
	_node_counter += 1
	var gn := GraphNode.new()
	gn.name = "BPNode_" + str(_node_counter)
	gn.title = node_title
	gn.position_offset = pos
	gn.custom_minimum_size = Vector2(205, 76)
	gn.self_modulate = header_tint.lightened(0.35)

	var pin_lbl := Label.new()
	pin_lbl.text = "جریان اجرا (" + kind + ")"
	gn.add_child(pin_lbl)

	var has_left := (kind != "EVENT_ENTRY")
	gn.set_slot(0, has_left, 0, Color.WHITE, true, 0, Color(0.28, 0.78, 1.0))

	_graph_edit.add_child(gn)
	_spawned_nodes.append({"type": node_title, "kind": kind})
	return gn.name


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_graph_edit.connect_node(from_node, from_port, to_node, to_port)


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_graph_edit.disconnect_node(from_node, from_port, to_node, to_port)


func _on_compile_pressed() -> void:
	var target := "cpp" if _target_selector.selected == 0 else "gdscript"
	var ext := ".hpp" if target == "cpp" else ".gd"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://generated/blueprints"))
	var out_path := "res://generated/blueprints/samurai_combat_bp" + ext
	var comp_script = load("res://addons/novaforge_engine/blueprint/blueprint_compiler.gd")
	if comp_script:
		var compiler = comp_script.new()
		var res: Dictionary = compiler.compile_graph_dict({"name": "SamuraiCombatBP", "nodes": _spawned_nodes}, target, out_path)
		if res.get("ok", false):
			_last_compiled_path = out_path
			_status_label.text = "✓ کامپایل شد -> " + out_path
			if get_tree() and get_tree().root.has_node("NovaEditorController"):
				var ctrl := get_tree().root.get_node("NovaEditorController")
				if ext == ".gd":
					ctrl.set("last_generated_script_path", out_path)
				ctrl.call(
					"emit_log",
					"[b][color=#22c55e][کامپایلر بلوپرینت][/color][/b] %d گره کامپایل شد -> [b]%s[/b]" % [_spawned_nodes.size(), out_path]
				)


func _open_compiled_code() -> void:
	if _last_compiled_path.is_empty():
		_on_compile_pressed()
	if _last_compiled_path.ends_with(".gd") and Engine.is_editor_hint() and FileAccess.file_exists(_last_compiled_path):
		var s := load(_last_compiled_path) as Script
		if s:
			EditorInterface.edit_script(s)
	elif FileAccess.file_exists(ProjectSettings.globalize_path(_last_compiled_path)):
		OS.shell_open(ProjectSettings.globalize_path(_last_compiled_path))
