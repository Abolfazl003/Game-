@tool
extends EditorInspectorPlugin
## Persian Inspector Extension (`⚡ ماژول هوشمند نوافورج` — Cold-Boot Safe).


func _can_handle(object: Object) -> bool:
	return object is Node3D


func _parse_begin(object: Object) -> void:
	if not (object is Node3D):
		return
	var node3d := object as Node3D

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)

	var header := Button.new()
	header.text = "⚡ ماژول هوشمند نوافورج (" + node3d.name + ")"
	header.disabled = true
	box.add_child(header)

	var chk_interact := CheckBox.new()
	chk_interact.text = "قابل تعامل ([E] در / صندوق با لولای خودکار)"
	chk_interact.button_pressed = node3d.has_node("SmartObjectBehavior3D")
	chk_interact.toggled.connect(func(on: bool): _toggle_smart_object(node3d, on, false))
	box.add_child(chk_interact)

	var chk_destruct := CheckBox.new()
	chk_destruct.text = "تخریب‌پذیر با ضربه سلاح (Voronoi 3D Jolt)"
	chk_destruct.toggled.connect(func(on: bool): _toggle_smart_object(node3d, true, on))
	box.add_child(chk_destruct)

	var chk_npc := CheckBox.new()
	chk_npc.text = "NPC زنده (تکامل زندگی و حافظه Nemesis)"
	chk_npc.button_pressed = node3d.has_node("LivingNPCBrain3D")
	chk_npc.toggled.connect(func(on: bool): _toggle_living_npc(node3d, on))
	box.add_child(chk_npc)

	var btn_pbr := Button.new()
	btn_pbr.text = "✦ اتصال خودکار تکسچرهای بلندر و اصلاح Normal"
	btn_pbr.pressed.connect(func(): _autobind_node_materials(node3d))
	box.add_child(btn_pbr)

	add_custom_control(box)


func _toggle_smart_object(target: Node3D, interactable: bool, destructible: bool) -> void:
	var existing := target.get_node_or_null("SmartObjectBehavior3D")
	if not interactable and not destructible:
		if existing:
			existing.queue_free()
		return
	if existing == null:
		var scr = load("res://addons/novaforge_engine/smart_objects/smart_object_behavior_3d.gd")
		if scr:
			var comp: Node = scr.new()
			comp.name = "SmartObjectBehavior3D"
			comp.set("is_interactable", interactable)
			comp.set("is_destructible", destructible)
			target.add_child(comp)
			if target.owner:
				comp.owner = target.owner
	else:
		existing.set("is_interactable", interactable)
		existing.set("is_destructible", destructible)


func _toggle_living_npc(target: Node3D, enabled: bool) -> void:
	var existing := target.get_node_or_null("LivingNPCBrain3D")
	if not enabled:
		if existing:
			existing.queue_free()
		return
	if existing == null:
		var scr = load("res://addons/novaforge_engine/living_npcs/living_npc_brain_3d.gd")
		if scr:
			var brain: Node = scr.new()
			brain.name = "LivingNPCBrain3D"
			brain.set("enable_evolving_life", true)
			target.add_child(brain)
			if target.owner:
				brain.owner = target.owner


func _autobind_node_materials(target: Node3D) -> void:
	if not target.scene_file_path.is_empty():
		var scr = load("res://addons/novaforge_engine/importers/universal_3d_importer.gd")
		if scr:
			var imp = scr.new()
			imp.import_and_autobind(target.scene_file_path)
