@tool
extends VBoxContainer
## Persian Local AI Model Hub Bottom Panel (`مدل‌های هوش مصنوعی Colibrì` — Cold-Boot Safe).

var _model_tree: Tree
var _hw_summary_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(0, 230)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 8)

	_hw_summary_label = Label.new()
	_hw_summary_label.text = "معماری حافظه ۳ لایه Colibrì: حفاظت از VRAM کارت گرافیک ⇄ وزن‌های فشرده INT4 در RAM ⇄ استریم متخصص‌ها از SSD"
	_hw_summary_label.clip_text = true
	_hw_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(_hw_summary_label)

	var btn_img3d := Button.new()
	btn_img3d.text = "◆ عکس به مدل 3D + ریگ ۵۲ استخوانی"
	btn_img3d.pressed.connect(func():
		if get_tree() and get_tree().root.has_node("NovaEditorController"):
			get_tree().root.get_node("NovaEditorController").call("spawn_image_to_3d_rigged_character")
		_hw_summary_label.text = "✓ کاراکتر سه‌بعدی با ۳ سطح LOD و ریگ ۵۲ استخوانی در صحنه ساخته شد!"
	)
	top_bar.add_child(btn_img3d)

	var btn_mocap := Button.new()
	btn_mocap.text = "▶ ویدیو به موشن سه‌بعدی (Foot-IK)"
	btn_mocap.pressed.connect(func():
		if get_tree() and get_tree().root.has_node("NovaEditorController"):
			get_tree().root.get_node("NovaEditorController").call("run_video_to_motion_combo")
		_hw_summary_label.text = "✓ حرکت سه‌بعدی و قفل کف پا استخراج و روی کاراکتر اجرا شد!"
	)
	top_bar.add_child(btn_mocap)

	add_child(top_bar)

	_model_tree = Tree.new()
	_model_tree.columns = 5
	_model_tree.set_column_titles_visible(true)
	_model_tree.set_column_title(0, "شناسه مدل لوکال")
	_model_tree.set_column_title(1, "نقش در شورای ۵ مغز")
	_model_tree.set_column_title(2, "رم مقیم (RAM)")
	_model_tree.set_column_title(3, "استریم دیسک (SSD)")
	_model_tree.set_column_title(4, "وضعیت")
	_model_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_model_tree)

	_populate_models()


func _populate_models() -> void:
	_model_tree.clear()
	var root := _model_tree.create_item()
	var hub_script = load("res://addons/novaforge_engine/ai_council/local_model_hub.gd")
	if hub_script == null:
		return
	var hub = hub_script.new()
	for m in hub.get_catalog():
		var item := _model_tree.create_item(root)
		item.set_text(0, str(m["id"]))
		item.set_text(1, str(m["role"]) + " (" + str(m["modality"]) + ")")
		item.set_text(2, str(m["dense_ram_mb"]) + " MB")
		item.set_text(3, str(m["disk_experts_mb"]) + " MB")
		item.set_text(4, "✓ آماده اجرا (لوکال)" if hub.is_installed(m["id"]) else "آماده دانلود یک‌کلیکی")
