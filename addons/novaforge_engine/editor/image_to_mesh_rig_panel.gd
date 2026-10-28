@tool
extends PanelContainer
## Interactive Persian Studio for Real Image-to-3D Mesh Reconstruction & Real Vertex-Skinning Auto-Rigging.
## Works identically inside Godot 4 Editor (Main Workspace & Bottom Panel) AND inside Runtime Play Mode (`F5`)!
## Supports:
## - Native FileDialog (`انتخاب عکس از کامپیوتر`) + Window Drag-and-Drop (`files_dropped`)
## - Live Original Image & Segmented Foreground Silhouette Preview
## - Real Smooth Poisson-Inflation Watertight 3D Mesh Generation + Sobel Normal Map + `.GLB` Export
## - Real 19-Bone Vertex-Skinning Auto-Rigger for BOTH Image-Generated Meshes AND External `.glb/.gltf/.obj` Models
## - Live Animation Switcher (`Idle`, `Walk`, `Run`, `SwordSlash`, `Wave`) + 1-Click `Make Playable Hero (WASD)`!

const ConvScript := preload("res://addons/novaforge_engine/forge/real_image_to_3d_converter.gd")
const RiggerScript := preload("res://addons/novaforge_engine/rigging/real_mesh_autorigger.gd")
const LoaderScript := preload("res://addons/novaforge_engine/forge/glb_asset_loader.gd")

signal status_logged(bbcode_msg: String)
signal mesh_or_rig_spawned(node3d: Node3D)

var target_scene_provider: Callable = Callable()

var _current_image_path: String = "res://assets/sample_images/cyber_samurai_concept.png"
var _last_spawned_node: Node3D = null
var _orig_preview: TextureRect
var _mask_preview: TextureRect
var _path_label: Label
var _depth_slider: HSlider
var _res_slider: HSlider
var _show_bones_chk: CheckBox
var _info_rtl: RichTextLabel
var _img_dialog: FileDialog
var _mesh_dialog: FileDialog


func _ready() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.11, 0.18, 0.98)
	sb.border_color = Color(0.22, 0.78, 0.98, 0.95)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	add_theme_stylebox_override("panel", sb)

	var main_hb := HBoxContainer.new()
	main_hb.add_theme_constant_override("separation", 14)
	main_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(main_hb)

	# ── LEFT COLUMN: IMAGE PICKER + PREVIEWS ──
	var left_vb := VBoxContainer.new()
	left_vb.custom_minimum_size = Vector2(275, 0)
	left_vb.add_theme_constant_override("separation", 6)

	var lbl_t1 := Label.new()
	lbl_t1.text = "◆ ۱. ورودی تصویر (عکس -> مش سه‌بعدی .GLB)"
	lbl_t1.add_theme_color_override("font_color", Color(0.38, 0.86, 1.0))
	left_vb.add_child(lbl_t1)

	var btn_pick_img := _styled_btn("✦ انتخاب عکس از کامپیوتر (.png / .jpg / .webp)", Color(0.10, 0.46, 0.78))
	btn_pick_img.pressed.connect(func(): _img_dialog.popup_centered(Vector2i(760, 500)))
	left_vb.add_child(btn_pick_img)

	var sample_hb := HBoxContainer.new()
	sample_hb.add_theme_constant_override("separation", 4)
	for pair in [
		["res://assets/sample_images/cyber_samurai_concept.png", "نمونه سامورایی"],
		["res://assets/sample_images/emerald_guardian_concept.png", "نمونه هیولا"],
		["res://assets/sample_images/royal_greatsword_concept.png", "نمونه شمشیر"],
	]:
		var sp_path: String = pair[0]
		var sb_btn := Button.new()
		sb_btn.text = pair[1]
		sb_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb_btn.pressed.connect(func(): load_image_for_preview(sp_path))
		sample_hb.add_child(sb_btn)
	left_vb.add_child(sample_hb)

	var prev_hb := HBoxContainer.new()
	prev_hb.add_theme_constant_override("separation", 8)
	prev_hb.alignment = BoxContainer.ALIGNMENT_CENTER

	_orig_preview = _make_preview_box(prev_hb, "تصویر اصلی")
	_mask_preview = _make_preview_box(prev_hb, "ماسک دوربری 3D")
	left_vb.add_child(prev_hb)

	_path_label = Label.new()
	_path_label.text = "فایل فعلی: cyber_samurai_concept.png (یا عکس را Drag & Drop کنید)"
	_path_label.clip_text = true
	_path_label.add_theme_color_override("font_color", Color(0.70, 0.80, 0.92))
	left_vb.add_child(_path_label)

	main_hb.add_child(left_vb)

	# ── CENTER COLUMN: MESH GENERATION SETTINGS & BUILD ──
	var mid_vb := VBoxContainer.new()
	mid_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_vb.add_theme_constant_override("separation", 7)

	var lbl_t2 := Label.new()
	lbl_t2.text = "⚙ ۲. تنظیمات حجم‌دهی سه‌بعدی و ساخت مش واقعی"
	lbl_t2.add_theme_color_override("font_color", Color(0.38, 0.86, 1.0))
	mid_vb.add_child(lbl_t2)

	var d_hb := HBoxContainer.new()
	var d_lbl := Label.new()
	d_lbl.text = "ضخامت و برجستگی حجم سه‌بعدی:"
	d_hb.add_child(d_lbl)
	_depth_slider = HSlider.new()
	_depth_slider.min_value = 0.20
	_depth_slider.max_value = 1.10
	_depth_slider.step = 0.05
	_depth_slider.value = 0.55
	_depth_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	d_hb.add_child(_depth_slider)
	mid_vb.add_child(d_hb)

	var r_hb := HBoxContainer.new()
	var r_lbl := Label.new()
	r_lbl.text = "ظرافت شبکه مثلث‌ها (پلی‌گان):"
	r_hb.add_child(r_lbl)
	_res_slider = HSlider.new()
	_res_slider.min_value = 48
	_res_slider.max_value = 112
	_res_slider.step = 8
	_res_slider.value = 84
	_res_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r_hb.add_child(_res_slider)
	mid_vb.add_child(r_hb)

	var btn_build_mesh := _styled_btn("◆ ساخت مش سه‌بعدی از این عکس + خروجی .GLB در صحنه", Color(0.08, 0.54, 0.42))
	btn_build_mesh.pressed.connect(_on_build_mesh_only)
	mid_vb.add_child(btn_build_mesh)

	var btn_build_and_rig := _styled_btn("⚡ ساخت مش سه‌بعدی + ریگ‌گذاری ۱۹ استخوانی + انیمیشن خودکار!", Color(0.14, 0.46, 0.86))
	btn_build_and_rig.pressed.connect(_on_build_mesh_and_rig)
	mid_vb.add_child(btn_build_and_rig)

	_info_rtl = RichTextLabel.new()
	_info_rtl.bbcode_enabled = true
	_info_rtl.fit_content = true
	_info_rtl.scroll_active = false
	_info_rtl.text = "[color=#94a3b8]هر عکس دلخواه (.png/.jpg) یا فایل مش (.glb/.obj) را انتخاب کنید یا مستقیم بکشید و داخل پنجره رها کنید.[/color]"
	mid_vb.add_child(_info_rtl)

	main_hb.add_child(mid_vb)

	# ── RIGHT COLUMN: AUTO-RIGGER FOR ANY MESH + LIVE ANIMATIONS ──
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 6)

	var lbl_t3 := Label.new()
	lbl_t3.text = "✦ ۳. ریگ‌گذاری خودکار هر مدل (.GLB / .OBJ) و تست حرکت"
	lbl_t3.add_theme_color_override("font_color", Color(0.38, 0.86, 1.0))
	right_vb.add_child(lbl_t3)

	var btn_pick_mesh := _styled_btn("■ انتخاب فایل مدل سه‌بعدی (.glb / .gltf / .obj) برای ریگ خودکار", Color(0.54, 0.34, 0.12))
	btn_pick_mesh.pressed.connect(func(): _mesh_dialog.popup_centered(Vector2i(760, 500)))
	right_vb.add_child(btn_pick_mesh)

	var btn_rig_last := _styled_btn("✦ ریگ‌گذاری خودکار روی آخرین مش ساخته‌شده / انتخابی", Color(0.46, 0.24, 0.72))
	btn_rig_last.pressed.connect(_on_rig_existing_mesh)
	right_vb.add_child(btn_rig_last)

	_show_bones_chk = CheckBox.new()
	_show_bones_chk.text = "نمایش مفاصل اسکلت سه‌بعدی روی مدل"
	_show_bones_chk.button_pressed = true
	_show_bones_chk.toggled.connect(_on_toggle_bone_markers)
	right_vb.add_child(_show_bones_chk)

	var anim_lbl := Label.new()
	anim_lbl.text = "تست انیمیشن زنده روی اسکلت ریگ‌شده:"
	right_vb.add_child(anim_lbl)

	var anim_hb := HBoxContainer.new()
	anim_hb.add_theme_constant_override("separation", 4)
	for apair in [["Idle", "ایستادن"], ["Walk", "راه رفتن"], ["Run", "دویدن"], ["SwordSlash", "ضربه شمشیر"], ["Wave", "سلام"]]:
		var acode: String = apair[0]
		var ab := Button.new()
		ab.text = apair[1]
		ab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ab.pressed.connect(func(): _play_anim_on_last(acode))
		anim_hb.add_child(ab)
	right_vb.add_child(anim_hb)

	var btn_make_hero := _styled_btn("▶ جایگزینی به‌عنوان قهرمان قابل‌بازی با کلیدهای WASD!", Color(0.14, 0.56, 0.32))
	btn_make_hero.pressed.connect(_on_make_playable_hero)
	right_vb.add_child(btn_make_hero)

	main_hb.add_child(right_vb)

	# Native FileDialogs
	_img_dialog = FileDialog.new()
	_img_dialog.title = "انتخاب تصویر برای تبدیل به مش سه‌بعدی"
	_img_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_img_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_img_dialog.use_native_dialog = false
	_img_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp, *.bmp ; فایل‌های تصویری"])
	_img_dialog.file_selected.connect(load_image_for_preview)
	add_child(_img_dialog)

	_mesh_dialog = FileDialog.new()
	_mesh_dialog.title = "انتخاب فایل مدل سه‌بعدی برای ریگ‌گذاری خودکار"
	_mesh_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_mesh_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_mesh_dialog.use_native_dialog = false
	_mesh_dialog.filters = PackedStringArray(["*.glb, *.gltf, *.obj ; مدل‌های سه‌بعدی"])
	_mesh_dialog.file_selected.connect(_on_external_mesh_selected)
	add_child(_mesh_dialog)

	call_deferred("_setup_drag_drop_and_default")


func _setup_drag_drop_and_default() -> void:
	var win := get_window()
	if win and not win.files_dropped.is_connected(_on_window_files_dropped):
		win.files_dropped.connect(_on_window_files_dropped)
	load_image_for_preview(_current_image_path)


func _on_window_files_dropped(files: PackedStringArray) -> void:
	if files.is_empty():
		return
	var fpath := files[0]
	var ext := fpath.get_extension().to_lower()
	if ext in ["png", "jpg", "jpeg", "webp", "bmp"]:
		load_image_for_preview(fpath)
		_log("[color=#38bdf8][Drag & Drop][/color] تصویر دریافت شد: [b]%s[/b] — در حال ساخت مش سه‌بعدی..." % fpath.get_file())
		_on_build_mesh_and_rig()
	elif ext in ["glb", "gltf", "obj"]:
		_on_external_mesh_selected(fpath)


func _make_preview_box(parent: HBoxContainer, caption: String) -> TextureRect:
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.12)
	sb.border_color = Color(0.24, 0.42, 0.65)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	frame.add_theme_stylebox_override("panel", sb)
	frame.custom_minimum_size = Vector2(96, 96)

	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(92, 92)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.add_child(tr)
	vb.add_child(frame)

	var lbl := Label.new()
	lbl.text = caption
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	vb.add_child(lbl)
	parent.add_child(vb)
	return tr


func _styled_btn(txt: String, bg: Color) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(0, 32)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = bg.lightened(0.32)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = bg.lightened(0.14)
	b.add_theme_stylebox_override("hover", sbh)
	return b


func load_image_for_preview(path: String) -> void:
	var img := ConvScript.load_any_image(path)
	if img == null:
		_log("[color=#ef4444]خطا در خواندن فایل تصویر: %s[/color]" % path)
		return
	_current_image_path = path
	_orig_preview.texture = ImageTexture.create_from_image(img)
	var seg := ConvScript.build_foreground_preview_and_mask(img, 72, 0.20)
	_mask_preview.texture = ImageTexture.create_from_image(seg["preview_img"] as Image)
	_path_label.text = "تصویر فعال: " + path.get_file()


func _resolve_scene_root() -> Node3D:
	if target_scene_provider.is_valid():
		var r = target_scene_provider.call()
		if r is Node3D:
			return r as Node3D
	if Engine.is_editor_hint():
		var er := EditorInterface.get_edited_scene_root()
		if er is Node3D:
			return er as Node3D
	if get_tree() and get_tree().current_scene is Node3D:
		return get_tree().current_scene as Node3D
	return null


func _place_in_scene(node: Node3D, pos: Vector3) -> void:
	var root := _resolve_scene_root()
	if root == null:
		return
	var old := root.get_node_or_null(NodePath(node.name))
	if old:
		old.free()
	node.position = pos
	root.add_child(node)
	node.owner = root
	_last_spawned_node = node
	mesh_or_rig_spawned.emit(node)
	if Engine.is_editor_hint():
		EditorInterface.set_main_screen_editor("3D")


func _on_build_mesh_only() -> void:
	var res := ConvScript.reconstruct_3d_mesh_from_image(
		_current_image_path,
		int(_res_slider.value),
		float(_depth_slider.value),
		1.88
	)
	if not res.get("ok", false):
		_log("[color=#ef4444]%s[/color]" % str(res.get("error", "خطا")))
		return
	var node: Node3D = res["node"]
	_place_in_scene(node, Vector3(1.5, 0.0, 0.4))
	_log(
		"[b][color=#22c55e][تبدیل عکس به مش 3D][/color][/b] مش یکپارچه از «%s» ساخته شد: [b]%d مثلث[/b] | فایل GLB: [b]%s[/b]" %
		[_current_image_path.get_file(), int(res["triangles"]), str(res["saved_glb"])]
	)


func _on_build_mesh_and_rig() -> void:
	var res := ConvScript.reconstruct_3d_mesh_from_image(
		_current_image_path,
		int(_res_slider.value),
		float(_depth_slider.value),
		1.88
	)
	if not res.get("ok", false):
		_log("[color=#ef4444]%s[/color]" % str(res.get("error", "خطا")))
		return
	var mesh_node: Node3D = res["node"]
	var out_glb := "res://generated/rigged/" + str(res["name"]) + "_rigged.glb"
	var rig_res := RiggerScript.autorig_node3d(mesh_node, _show_bones_chk.button_pressed, "Walk", out_glb)
	mesh_node.free()
	if not rig_res.get("ok", false):
		_log("[color=#ef4444]%s[/color]" % str(rig_res.get("error", "خطا در ریگ")))
		return

	var rigged_node: Node3D = rig_res["node"]
	_place_in_scene(rigged_node, Vector3(1.5, 0.0, 0.4))
	_log(
		"[b][color=#38bdf8][عکس -> مش 3D + ریگ خودکار][/color][/b] ✓ [b]%d ورتکس[/b] به [b]%d استخوان[/b] متصل شد + ۵ انیمیشن زنده | ذخیره شد: [b]%s[/b]" %
		[int(rig_res["skinned_vertices"]), int(rig_res["bones_count"]), str(rig_res["saved_glb"])]
	)


func _on_external_mesh_selected(mesh_path: String) -> void:
	var loaded := LoaderScript.load_model_scene(mesh_path, 1.88)
	if loaded == null:
		_log("[color=#ef4444]فایل مدل سه‌بعدی قابل خواندن نبود: %s[/color]" % mesh_path)
		return
	var bname := mesh_path.get_file().get_basename().validate_node_name()
	var out_glb := "res://generated/rigged/" + bname + "_autorigged.glb"
	var rig_res := RiggerScript.autorig_node3d(loaded, _show_bones_chk.button_pressed, "Walk", out_glb)
	loaded.free()
	if not rig_res.get("ok", false):
		_log("[color=#ef4444]%s[/color]" % str(rig_res.get("error", "خطا در ریگ‌گذاری")))
		return
	var rigged_node: Node3D = rig_res["node"]
	_place_in_scene(rigged_node, Vector3(0.0, 0.0, 0.2))
	_log(
		"[b][color=#c084fc][ریگ‌گذاری خودکار مدل خارجی][/color][/b] مدل «%s» با [b]%d استخوان[/b] و وزن‌دهی ورتکس ریگ شد -> [b]%s[/b]" %
		[mesh_path.get_file(), int(rig_res["bones_count"]), str(rig_res["saved_glb"])]
	)


func _on_rig_existing_mesh() -> void:
	var target: Node3D = _last_spawned_node
	if target == null or not is_instance_valid(target):
		_on_build_mesh_and_rig()
		return
	if target.find_children("*", "Skeleton3D", true, false).size() > 0:
		_play_anim_on_last("SwordSlash")
		_log("[color=#22c55e]این مدل از قبل ریگ شده است — انیمیشن ضربه شمشیر فعال شد![/color]")
		return
	var out_glb := "res://generated/rigged/" + target.name + "_rigged.glb"
	var pos := target.position
	var rig_res := RiggerScript.autorig_node3d(target, _show_bones_chk.button_pressed, "Walk", out_glb)
	if rig_res.get("ok", false):
		target.queue_free()
		_place_in_scene(rig_res["node"] as Node3D, pos)
		_log("[b][color=#22c55e]✓ مش انتخابی با موفقیت ریگ‌گذاری شد (%d استخوان)![/color][/b]" % int(rig_res["bones_count"]))


func _on_toggle_bone_markers(on: bool) -> void:
	if _last_spawned_node and is_instance_valid(_last_spawned_node):
		for n in _last_spawned_node.find_children("BoneDebugMarkers", "Node3D", true, false):
			(n as Node3D).visible = on


func _play_anim_on_last(anim_name: String) -> void:
	if _last_spawned_node == null or not is_instance_valid(_last_spawned_node):
		_on_build_mesh_and_rig()
	if _last_spawned_node and is_instance_valid(_last_spawned_node):
		var played := LoaderScript.play_character_anim(_last_spawned_node, [anim_name], true)
		_log("[color=#38bdf8]▶ اجرای انیمیشن اسکلت: [b]%s[/b][/color]" % (played if not played.is_empty() else anim_name))


func _on_make_playable_hero() -> void:
	if _last_spawned_node == null or not is_instance_valid(_last_spawned_node):
		_on_build_mesh_and_rig()
	var root := _resolve_scene_root()
	if root == null or _last_spawned_node == null or not is_instance_valid(_last_spawned_node):
		return
	var hero := root.get_node_or_null("SamuraiHero") as Node3D
	if hero == null:
		return

	for ch in hero.get_children():
		if ch is Node3D and not (ch is CollisionShape3D) and not (ch is Label3D):
			ch.queue_free()

	var dup := _last_spawned_node.duplicate() as Node3D
	dup.name = "CustomRiggedHero3D"
	dup.position = Vector3.ZERO
	hero.add_child(dup)
	var lbl := hero.get_node_or_null("HeroLabel3D") as Label3D
	if lbl:
		lbl.text = "⚔ کاراکتر ساخته‌شده شما (WASD)"
	LoaderScript.play_character_anim(dup, ["Idle"], true)
	_log("[b][color=#22c55e]✓ کاراکتر ریگ‌شده شما جایگزین قهرمان بازی شد! با F5 یا WASD با کاراکتر خودتان بازی کنید![/color][/b]")


func _log(msg: String) -> void:
	if _info_rtl:
		_info_rtl.text = msg
	status_logged.emit(msg)
	if get_tree() and get_tree().root.has_node("NovaEditorController"):
		get_tree().root.get_node("NovaEditorController").call("emit_log", msg)
