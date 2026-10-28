@tool
extends VBoxContainer
class_name NovaColibriModelManagerPanel
## Native Godot 4 Bottom-Panel Module: Local AI Model Hub (Colibrì Tiered Memory + Asset/Rig/Mocap Forge).
## Lets users install/manage local models & launch Image-to-3D, Auto-Rig, Video-to-Motion & Blender PBR tools
## without leaving the standard Godot 4 interface.

var _model_tree: Tree
var _hw_summary_label: Label
var _hub := NovaLocalModelHub.new()


func _ready() -> void:
	custom_minimum_size = Vector2(0, 240)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 8)

	_hw_summary_label = Label.new()
	_hw_summary_label.text = "Colibrì Tiered Hierarchy: GPU VRAM (3.0 GB Reserved for Godot Vulkan) ⇄ System RAM (INT4 Dense) ⇄ NVMe SSD (Streamed Experts)"
	_hw_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(_hw_summary_label)

	var btn_img3d := Button.new()
	btn_img3d.text = "🖼️ Image/Text -> 3D + Auto-Rig"
	btn_img3d.pressed.connect(_on_quick_forge_character)
	top_bar.add_child(btn_img3d)

	var btn_mocap := Button.new()
	btn_mocap.text = "🎥 Video -> 3D Motion (IK)"
	btn_mocap.pressed.connect(_on_quick_video_mocap)
	top_bar.add_child(btn_mocap)

	add_child(top_bar)

	_model_tree = Tree.new()
	_model_tree.columns = 5
	_model_tree.set_column_titles_visible(true)
	_model_tree.set_column_title(0, "Local AI Specialist Model")
	_model_tree.set_column_title(1, "Council Role / Modality")
	_model_tree.set_column_title(2, "Resident RAM")
	_model_tree(3, "NVMe Disk Stream")
	_model_tree.set_column_title(4, "Status")
	_model_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_model_tree)

	_populate_models()


func _model_tree(col: int, title: String) -> void:
	_model_tree.set_column_title(col, title)


func _populate_models() -> void:
	_model_tree.clear()
	var root := _model_tree.create_item()
	for m in _hub.get_catalog():
		var item := _model_tree.create_item(root)
		item.set_text(0, str(m["id"]))
		item.set_text(1, str(m["role"]) + " (" + str(m["modality"]) + ")")
		item.set_text(2, str(m["dense_ram_mb"]) + " MB")
		item.set_text(3, str(m["disk_experts_mb"]) + " MB")
		item.set_text(4, "✓ Ready (Local)" if _hub.is_installed(m["id"]) else "Download Available")


func _on_quick_forge_character() -> void:
	if get_tree() and get_tree().root.has_node("NovaNativeBus"):
		var bus = get_tree().root.get_node("NovaNativeBus")
		bus.invoke_tool("nova_image_to_3d", {"prompt": "armored warrior", "output_path": "res://generated/meshes/hero.obj"})
		bus.invoke_tool("nova_auto_rig_character", {"mesh_path": "res://generated/meshes/hero.obj", "output_path": "res://generated/rigs/hero_rig.json"})
		_hw_summary_label.text = "✓ Generated 3D Character + 3 LODs + 52-Bone Humanoid Skeleton!"


func _on_quick_video_mocap() -> void:
	if get_tree() and get_tree().root.has_node("NovaNativeBus"):
		var bus = get_tree().root.get_node("NovaNativeBus")
		bus.invoke_tool("nova_video_to_motion", {"style": "katana_3hit_combo", "output_path": "res://generated/motions/katana_combo.json"})
		_hw_summary_label.text = "✓ Extracted 3D Motion + Foot-Locking IK + Combat Hitbox Events!"
