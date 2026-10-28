@tool
extends VBoxContainer
class_name NovaBlueprintGraphEditor
## Native Godot 4 `GraphEdit` Visual Blueprint Editor (`Blueprint Graph` Bottom Panel Module).
## Integrates directly into Godot 4's Bottom Panel alongside Output, Debugger, Animation & Shader Editor.

var _graph_edit: GraphEdit
var _target_selector: OptionButton
var _status_label: Label
var _node_counter: int = 0
var _spawned_nodes: Array[Dictionary] = []


func _ready() -> void:
	custom_minimum_size = Vector2(0, 260)

	# Native Godot 4-style Top Toolbar inside Bottom Panel
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)

	var btn_ev := Button.new()
	btn_ev.text = "+ Event Node"
	btn_ev.pressed.connect(func(): _spawn_bp_node("Event_OnAttackInput", "EVENT_ENTRY", Color(0.75, 0.18, 0.22)))
	bar.add_child(btn_ev)

	var btn_br := Button.new()
	btn_br.text = "+ Branch (If/Else)"
	btn_br.pressed.connect(func(): _spawn_bp_node("Flow_Branch", "FLOW_BRANCH", Color(0.28, 0.34, 0.46)))
	bar.add_child(btn_br)

	var btn_combo := Button.new()
	btn_combo.text = "+ Melee Combo 3-Hit"
	btn_combo.pressed.connect(func(): _spawn_bp_node("PlayMeleeCombo3Hit", "GAMEPLAY_ACTION", Color(0.16, 0.45, 0.68)))
	bar.add_child(btn_combo)

	var btn_frac := Button.new()
	btn_frac.text = "+ Voronoi Fracture"
	btn_frac.pressed.connect(func(): _spawn_bp_node("FractureObject3D", "GAMEPLAY_ACTION", Color(0.68, 0.42, 0.14)))
	bar.add_child(btn_frac)

	var btn_cut := Button.new()
	btn_cut.text = "+ Trigger Cutscene"
	btn_cut.pressed.connect(func(): _spawn_bp_node("TriggerLiveCutscene", "GAMEPLAY_ACTION", Color(0.48, 0.24, 0.68)))
	bar.add_child(btn_cut)

	var sep := VSeparator.new()
	bar.add_child(sep)

	_target_selector = OptionButton.new()
	_target_selector.add_item("Compile -> GDScript (.gd)")
	_target_selector.add_item("Compile -> Native C++20 (GDExtension)")
	bar.add_child(_target_selector)

	var btn_compile := Button.new()
	btn_compile.text = "⚡ Compile Blueprint"
	btn_compile.pressed.connect(_on_compile_pressed)
	bar.add_child(btn_compile)

	_status_label = Label.new()
	_status_label.text = "Godot 4 GraphEdit Ready"
	bar.add_child(_status_label)

	add_child(bar)

	# Native Godot 4 `GraphEdit` Canvas
	_graph_edit = GraphEdit.new()
	_graph_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph_edit.right_disconnects = true
	_graph_edit.connection_request.connect(_on_connection_request)
	_graph_edit.disconnection_request.connect(_on_disconnection_request)
	add_child(_graph_edit)

	# Seed starter nodes
	_spawn_bp_node("Event_BeginPlay", "EVENT_ENTRY", Color(0.75, 0.18, 0.22))
	_spawn_bp_node("SetupPerspectiveRig", "GAMEPLAY_ACTION", Color(0.16, 0.45, 0.68))


func _spawn_bp_node(node_title: String, kind: String, header_tint: Color) -> void:
	_node_counter += 1
	var gn := GraphNode.new()
	gn.name = "BPNode_" + str(_node_counter)
	gn.title = node_title
	gn.position_offset = Vector2(60 + (_node_counter - 1) * 230, 50)
	gn.custom_minimum_size = Vector2(195, 86)
	gn.self_modulate = header_tint.lightened(0.35)

	var pin_lbl := Label.new()
	pin_lbl.text = "Exec Flow (" + kind + ")"
	gn.add_child(pin_lbl)

	var has_left := (kind != "EVENT_ENTRY")
	gn.set_slot(0, has_left, 0, Color.WHITE, true, 0, Color(0.28, 0.78, 1.0))

	_graph_edit.add_child(gn)
	_spawned_nodes.append({"type": node_title, "kind": kind})


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_graph_edit.connect_node(from_node, from_port, to_node, to_port)


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_graph_edit.disconnect_node(from_node, from_port, to_node, to_port)


func _on_compile_pressed() -> void:
	var target := "cpp" if _target_selector.selected == 1 else "gdscript"
	var ext := ".hpp" if target == "cpp" else ".gd"
	var out_path := "res://generated/blueprints/compiled_character_bp" + ext
	var compiler := NovaBlueprintCompiler.new()
	var res := compiler.compile_graph_dict({"name": "CompiledCharacterBP", "nodes": _spawned_nodes}, target, out_path)
	if res.get("ok", false):
		_status_label.text = "Compiled -> " + out_path
