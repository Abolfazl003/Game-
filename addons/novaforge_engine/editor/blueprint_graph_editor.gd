@tool
extends VBoxContainer
class_name NovaBlueprintGraphEditor
## Native Godot 4 `GraphEdit` Visual Blueprint Editor (`Blueprint Graph` Bottom Panel Module).
## Pre-populated with the connected Samurai Combat + Voronoi Destruction Blueprint graph,
## and transpiles directly to C++20 (`GDExtension`) or `GDScript` into the NovaForge Console.

var _graph_edit: GraphEdit
var _target_selector: OptionButton
var _status_label: Label
var _node_counter: int = 0
var _spawned_nodes: Array[Dictionary] = []


func _ready() -> void:
	custom_minimum_size = Vector2(0, 250)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 6)

	var btn_ev := Button.new()
	btn_ev.text = "+ Event"
	btn_ev.pressed.connect(func(): _spawn_bp_node("Event_OnInteract", "EVENT_ENTRY", Color(0.78, 0.20, 0.24), Vector2(60 + _node_counter * 180, 140)))
	bar.add_child(btn_ev)

	var btn_br := Button.new()
	btn_br.text = "+ Branch"
	btn_br.pressed.connect(func(): _spawn_bp_node("Branch_StaminaCheck", "FLOW_BRANCH", Color(0.30, 0.38, 0.52), Vector2(60 + _node_counter * 180, 140)))
	bar.add_child(btn_br)

	var btn_combo := Button.new()
	btn_combo.text = "+ Melee Combo"
	btn_combo.pressed.connect(func(): _spawn_bp_node("PlayMeleeCombo3Hit", "GAMEPLAY_ACTION", Color(0.16, 0.48, 0.72), Vector2(60 + _node_counter * 180, 140)))
	bar.add_child(btn_combo)

	var btn_frac := Button.new()
	btn_frac.text = "+ Voronoi Fracture"
	btn_frac.pressed.connect(func(): _spawn_bp_node("VoronoiHitCheck", "GAMEPLAY_ACTION", Color(0.72, 0.44, 0.14), Vector2(60 + _node_counter * 180, 140)))
	bar.add_child(btn_frac)

	var btn_cut := Button.new()
	btn_cut.text = "+ Live Cutscene"
	btn_cut.pressed.connect(func(): _spawn_bp_node("TriggerLiveCutscene", "GAMEPLAY_ACTION", Color(0.52, 0.26, 0.72), Vector2(60 + _node_counter * 180, 140)))
	bar.add_child(btn_cut)

	bar.add_child(VSeparator.new())

	_target_selector = OptionButton.new()
	_target_selector.add_item("Compile -> Native C++20 (.hpp)")
	_target_selector.add_item("Compile -> GDScript (.gd)")
	bar.add_child(_target_selector)

	var btn_compile := Button.new()
	btn_compile.text = "⚡ کامپایل گراف Blueprint"
	btn_compile.pressed.connect(_on_compile_pressed)
	bar.add_child(btn_compile)

	_status_label = Label.new()
	_status_label.text = "۶ نود فعال و متصل آماده کامپایل"
	bar.add_child(_status_label)

	add_child(bar)

	_graph_edit = GraphEdit.new()
	_graph_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph_edit.right_disconnects = true
	_graph_edit.connection_request.connect(_on_connection_request)
	_graph_edit.disconnection_request.connect(_on_disconnection_request)
	add_child(_graph_edit)

	call_deferred("_seed_samurai_graph")


func _seed_samurai_graph() -> void:
	var n1 := _spawn_bp_node("Event_BeginPlay", "EVENT_ENTRY", Color(0.78, 0.20, 0.24), Vector2(30, 24))
	var n2 := _spawn_bp_node("SetupPerspective: TPS_SOULS", "GAMEPLAY_ACTION", Color(0.16, 0.48, 0.72), Vector2(260, 24))

	var n3 := _spawn_bp_node("Event_OnAttack", "EVENT_ENTRY", Color(0.78, 0.20, 0.24), Vector2(30, 130))
	var n4 := _spawn_bp_node("Branch: stamina >= 18", "FLOW_BRANCH", Color(0.32, 0.40, 0.56), Vector2(260, 130))
	var n5 := _spawn_bp_node("PlayMeleeCombo3Hit", "GAMEPLAY_ACTION", Color(0.16, 0.48, 0.72), Vector2(510, 130))
	var n6 := _spawn_bp_node("VoronoiHitCheck (16 Shards)", "GAMEPLAY_ACTION", Color(0.76, 0.46, 0.16), Vector2(760, 130))

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
	gn.custom_minimum_size = Vector2(205, 82)
	gn.self_modulate = header_tint.lightened(0.35)

	var pin_lbl := Label.new()
	pin_lbl.text = "Exec (" + kind + ")"
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
	var out_path := "res://generated/blueprints/samurai_combat_bp" + ext
	var compiler := NovaBlueprintCompiler.new()
	var res := compiler.compile_graph_dict({"name": "SamuraiCombatBP", "nodes": _spawned_nodes}, target, out_path)
	if res.get("ok", false):
		_status_label.text = "✅ Compiled -> " + out_path
		if get_tree() and get_tree().root.has_node("NovaEditorController"):
			var ctrl := get_tree().root.get_node("NovaEditorController") as NovaEditorSceneController
			ctrl.emit_log("[b][color=#22c55e][BlueprintCompiler][/color][/b] Compiled %d nodes -> [b]%s[/b] (%s)" % [_spawned_nodes.size(), out_path, target.to_upper()])
