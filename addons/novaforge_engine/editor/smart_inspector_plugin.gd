@tool
extends EditorInspectorPlugin
class_name NovaSmartInspectorPlugin
## Hooks directly into Godot 4's native `Inspector` dock!
## Whenever the developer selects ANY `Node3D` in the Scene Tree, injects a clean
## collapsible "⚡ NovaForge Smart Module" section at the top of the standard Godot 4 Inspector
## so users can enable Interaction, Voronoi Destruction, Living NPC AI, or Blender Auto-PBR
## with 1 checkbox inside Godot 4's native workflow.


func _can_handle(object: Object) -> bool:
	return object is Node3D


func _parse_begin(object: Object) -> void:
	if not (object is Node3D):
		return
	var node3d := object as Node3D

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)

	var header := Button.new()
	header.text = "⚡ NovaForge Smart Module (" + node3d.get_class() + ")"
	header.disabled = true
	box.add_child(header)

	var chk_interact := CheckBox.new()
	chk_interact.text = "Interactable (Auto-Hinge Door / Chest / Pickup [E])"
	chk_interact.button_pressed = node3d.has_node("SmartObjectBehavior3D")
	chk_interact.toggled.connect(func(on: bool): _toggle_smart_object(node3d, on, false))
	box.add_child(chk_interact)

	var chk_destruct := CheckBox.new()
	chk_destruct.text = "Destructible with Weapon (Voronoi 3D Jolt Fracture)"
	chk_destruct.toggled.connect(func(on: bool): _toggle_smart_object(node3d, true, on))
	box.add_child(chk_destruct)

	var chk_npc := CheckBox.new()
	chk_npc.text = "Living NPC (Evolving Life & Nemesis AI)"
	chk_npc.button_pressed = node3d.has_node("LivingNPCBrain3D")
	chk_npc.toggled.connect(func(on: bool): _toggle_living_npc(node3d, on))
	box.add_child(chk_npc)

	var btn_pbr := Button.new()
	btn_pbr.text = "🎨 Auto-Bind Blender PBR Textures & Fix Normals"
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
		var comp := SmartObjectBehavior3D.new()
		comp.name = "SmartObjectBehavior3D"
		comp.is_interactable = interactable
		comp.is_destructible = destructible
		target.add_child(comp)
		if target.owner:
			comp.owner = target.owner
	else:
		existing.is_interactable = interactable
		existing.is_destructible = destructible


func _toggle_living_npc(target: Node3D, enabled: bool) -> void:
	var existing := target.get_node_or_null("LivingNPCBrain3D")
	if not enabled:
		if existing:
			existing.queue_free()
		return
	if existing == null:
		var brain := LivingNPCBrain3D.new()
		brain.name = "LivingNPCBrain3D"
		brain.enable_evolving_life = true
		target.add_child(brain)
		if target.owner:
			brain.owner = target.owner


func _autobind_node_materials(target: Node3D) -> void:
	if not target.scene_file_path.is_empty():
		var imp := NovaUniversal3DImporter.new()
		imp.import_and_autobind(target.scene_file_path)
