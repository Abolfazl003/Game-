@tool
extends PanelContainer
## Interactive Persian 360° Neural AI Studio (`v3.0`):
## - Real Image-to-3D 360° Neural Mesh Reconstruction (`Tencent Hunyuan3D-2` + `Neural RemBG` + `Shap-E` failover)
## - Native Windows File Explorer (`use_native_dialog = true` on Windows/macOS) + Clipboard Image Paste + Window Drag & Drop
## - Pose-Adaptive 19-Bone 3D Auto-Rigger for BOTH AI-Generated 360° Meshes AND External `.glb/.gltf/.obj` Models
## - Live Skeletal Animation Tester (`Idle`, `Walk`, `Run`, `SwordSlash`, `Wave`) + 1-Click `Make Playable Hero (WASD)`!

const NeuralClientScript := preload("res://addons/novaforge_engine/forge/neural_3d_cloud_client.gd")
const OfflineConvScript := preload("res://addons/novaforge_engine/forge/real_image_to_3d_converter.gd")
const RiggerScript := preload("res://addons/novaforge_engine/rigging/real_mesh_autorigger.gd")
const LoaderScript := preload("res://addons/novaforge_engine/forge/glb_asset_loader.gd")

signal status_logged(bbcode_msg: String)
signal mesh_or_rig_spawned(node3d: Node3D)

var target_scene_provider: Callable = Callable()

var _neural_client: Node = null
var _current_image_path: String = "res://assets/sample_images/cyber_samurai_concept.png"
var _last_spawned_node: Node3D = null
var _orig_preview: TextureRect
var _mask_preview: TextureRect
var _path_label: Label
var _res_slider: HSlider
var _progress_bar: ProgressBar
var _progress_lbl: Label
var _hf_token_edit: LineEdit
var _show_bones_chk: CheckBox
var _info_rtl: RichTextLabel
var _img_dialog: FileDialog
var _mesh_dialog: FileDialog
var _btn_mesh_only: Button
var _btn_mesh_rig: Button


func _ready() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.075, 0.105, 0.175, 0.98)
	sb.border_color = Color(0.22, 0.78, 0.98, 0.95)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	add_theme_stylebox_override("panel", sb)

	_neural_client = NeuralClientScript.new()
	_neural_client.name = "Neural3DCloudClient"
	_neural_client.progress_updated.connect(_on_neural_progress)
	_neural_client.concept_image_ready.connect(_on_neural_concept_ready)
	add_child(_neural_client)

	var main_hb := HFlowContainer.new()
	main_hb.add_theme_constant_override("h_separation", 12)
	main_hb.add_theme_constant_override("v_separation", 10)
	main_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(main_hb)

	# ── COLUMN 1: NATIVE WINDOWS IMAGE PICKER + CLIPBOARD PASTE + PREVIEWS ──
	var left_vb := VBoxContainer.new()
	left_vb.custom_minimum_size = Vector2(230, 0)
	left_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vb.add_theme_constant_override("separation", 5)

	var lbl_t1 := Label.new()
	lbl_t1.text = "◆ ۱. ورودی عکس (فایل ویندوز / کلیپ‌بورد / Drag & Drop)"
	lbl_t1.clip_text = true
	lbl_t1.add_theme_color_override("font_color", Color(0.38, 0.86, 1.0))
	left_vb.add_child(lbl_t1)

	var btn_pick_img := _styled_btn("✦ انتخاب عکس از کامپیوتر (.png / .jpg / .webp)", Color(0.10, 0.48, 0.82))
	btn_pick_img.pressed.connect(_open_native_image_picker)
	left_vb.add_child(btn_pick_img)

	var btn_paste_img := _styled_btn("✦ چسباندن عکس کپی‌شده از کلیپ‌بورد (Ctrl+V)", Color(0.16, 0.38, 0.62))
	btn_paste_img.pressed.connect(_on_paste_clipboard_image)
	left_vb.add_child(btn_paste_img)

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
	_orig_preview = _make_preview_box(prev_hb, "تصویر ورودی")
	_mask_preview = _make_preview_box(prev_hb, "دوربری سوژه 3D")
	left_vb.add_child(prev_hb)

	_path_label = Label.new()
	_path_label.text = "تصویر فعال: cyber_samurai_concept.png"
	_path_label.clip_text = true
	_path_label.add_theme_color_override("font_color", Color(0.72, 0.84, 0.96))
	left_vb.add_child(_path_label)

	main_hb.add_child(left_vb)

	# ── COLUMN 2: TRUE 360° NEURAL AI 3D MESH RECONSTRUCTION (`Hunyuan3D-2`) ──
	var mid_vb := VBoxContainer.new()
	mid_vb.custom_minimum_size = Vector2(230, 0)
	mid_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_vb.add_theme_constant_override("separation", 6)

	var lbl_t2 := Label.new()
	lbl_t2.text = "⚡ ۲. ساخت مش سه‌بعدی ۳۶۰ درجه با هوش مصنوعی واقعی (Hunyuan3D-2)"
	lbl_t2.clip_text = true
	lbl_t2.add_theme_color_override("font_color", Color(0.38, 0.86, 1.0))
	mid_vb.add_child(lbl_t2)

	var r_hb := HBoxContainer.new()
	var r_lbl := Label.new()
	r_lbl.text = "دقت و جزئیات مش ۳۶۰ درجه (Octree):"
	r_hb.add_child(r_lbl)
	_res_slider = HSlider.new()
	_res_slider.min_value = 128
	_res_slider.max_value = 224
	_res_slider.step = 16
	_res_slider.value = 176
	_res_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r_hb.add_child(_res_slider)
	mid_vb.add_child(r_hb)

	_btn_mesh_only = _styled_btn("◆ ساخت مش ۳۶۰ درجه واقعی از این عکس + خروجی .GLB", Color(0.08, 0.54, 0.42))
	_btn_mesh_only.pressed.connect(_on_build_360_mesh_only)
	mid_vb.add_child(_btn_mesh_only)

	_btn_mesh_rig = _styled_btn("⚡ ساخت مش ۳۶۰ درجه + ریگ‌گذاری خودکار ۱۹ استخوانی + انیمیشن!", Color(0.14, 0.46, 0.88))
	_btn_mesh_rig.pressed.connect(_on_build_360_mesh_and_rig)
	mid_vb.add_child(_btn_mesh_rig)

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0
	_progress_bar.max_value = 100
	_progress_bar.value = 0
	_progress_bar.custom_minimum_size = Vector2(0, 18)
	mid_vb.add_child(_progress_bar)

	_progress_lbl = Label.new()
	_progress_lbl.text = "آماده — بدون نیاز به API Key (متصل به Hunyuan3D-2 + Neural RemBG)"
	_progress_lbl.clip_text = true
	_progress_lbl.add_theme_font_size_override("font_size", 11)
	_progress_lbl.add_theme_color_override("font_color", Color(0.55, 0.92, 0.72))
	mid_vb.add_child(_progress_lbl)

	var tok_hb := HBoxContainer.new()
	tok_hb.add_theme_constant_override("separation", 4)
	var tok_lbl := Label.new()
	tok_lbl.text = "توکن HF (اختیاری):"
	tok_lbl.add_theme_font_size_override("font_size", 11)
	tok_hb.add_child(tok_lbl)
	_hf_token_edit = LineEdit.new()
	_hf_token_edit.placeholder_text = "خالی بگذارید (رایگان) یا hf_... برای کوتا نامحدود"
	_hf_token_edit.secret = true
	_hf_token_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hf_token_edit.text_changed.connect(func(t: String): if _neural_client: _neural_client.hf_token = t)
	tok_hb.add_child(_hf_token_edit)
	mid_vb.add_child(tok_hb)

	_info_rtl = RichTextLabel.new()
	_info_rtl.bbcode_enabled = true
	_info_rtl.fit_content = true
	_info_rtl.scroll_active = false
	_info_rtl.text = "[color=#94a3b8]هر عکس (.png/.jpg/.webp) را از ویندوز انتخاب کنید، از کلیپ‌بورد بچسبانید یا داخل پنجره بکشید تا مش ۳۶۰ درجه واقعی ساخته و ریگ شود.[/color]"
	mid_vb.add_child(_info_rtl)

	main_hb.add_child(mid_vb)

	# ── COLUMN 3: AUTO-RIGGER FOR ANY MESH (`.GLB/.OBJ`) + LIVE ANIMATIONS ──
	var right_vb := VBoxContainer.new()
	right_vb.custom_minimum_size = Vector2(230, 0)
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 6)

	var lbl_t3 := Label.new()
	lbl_t3.text = "✦ ۳. ریگ‌گذاری خودکار هر مدل (.GLB / .OBJ) و کنترل WASD"
	lbl_t3.clip_text = true
	lbl_t3.add_theme_color_override("font_color", Color(0.38, 0.86, 1.0))
	right_vb.add_child(lbl_t3)

	var btn_pick_mesh := _styled_btn("■ انتخاب فایل مدل سه‌بعدی (.glb / .gltf / .obj) از کامپیوتر", Color(0.54, 0.34, 0.12))
	btn_pick_mesh.pressed.connect(_open_native_mesh_picker)
	right_vb.add_child(btn_pick_mesh)

	var btn_rig_last := _styled_btn("✦ ریگ‌گذاری خودکار ۱۹ استخوانی روی مدل فعلی / انتخابی", Color(0.46, 0.24, 0.72))
	btn_rig_last.pressed.connect(_on_rig_existing_mesh)
	right_vb.add_child(btn_rig_last)

	_show_bones_chk = CheckBox.new()
	_show_bones_chk.text = "نمایش مفاصل اسکلت سه‌بعدی روی مدل"
	_show_bones_chk.button_pressed = false
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

	# Native OS FileDialogs (uses real Windows Explorer on Windows/macOS, clean fallback on X11!)
	var use_os_native := OS.get_name() in ["Windows", "macOS"]

	_img_dialog = FileDialog.new()
	_img_dialog.title = "انتخاب تصویر برای تبدیل به مش سه‌بعدی ۳۶۰ درجه"
	_img_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_img_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_img_dialog.use_native_dialog = use_os_native
	_img_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp, *.bmp ; فایل‌های تصویری"])
	_img_dialog.file_selected.connect(_on_user_picked_image_file)
	add_child(_img_dialog)

	_mesh_dialog = FileDialog.new()
	_mesh_dialog.title = "انتخاب فایل مدل سه‌بعدی برای ریگ‌گذاری خودکار"
	_mesh_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_mesh_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_mesh_dialog.use_native_dialog = use_os_native
	_mesh_dialog.filters = PackedStringArray(["*.glb, *.gltf, *.obj ; مدل‌های سه‌بعدی"])
	_mesh_dialog.file_selected.connect(_on_external_mesh_selected)
	add_child(_mesh_dialog)

	call_deferred("_setup_drag_drop_and_default")


func get_neural_client() -> Node:
	return _neural_client


func _open_native_image_picker() -> void:
	var pic_dir := OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	if not pic_dir.is_empty() and DirAccess.dir_exists_absolute(pic_dir):
		_img_dialog.current_dir = pic_dir
	_img_dialog.popup_centered(Vector2i(820, 540))


func _open_native_mesh_picker() -> void:
	var dl_dir := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if not dl_dir.is_empty() and DirAccess.dir_exists_absolute(dl_dir):
		_mesh_dialog.current_dir = dl_dir
	_mesh_dialog.popup_centered(Vector2i(820, 540))


func _on_user_picked_image_file(fpath: String) -> void:
	load_image_for_preview(fpath)
	_info_rtl.text = "[color=#38bdf8]✓ عکس انتخاب شد: [b]%s[/b] — اکنون روی دکمه «ساخت مش ۳۶۰ درجه» کلیک کنید![/color]" % fpath.get_file()


func _on_paste_clipboard_image() -> void:
	if not DisplayServer.clipboard_has_image():
		_info_rtl.text = "[color=#f59e0b]هیچ عکسی در کلیپ‌بورد ویندوز/سیستم پیدا نشد. ابتدا یک تصویر را Copy Image کنید یا از دکمه انتخاب فایل استفاده کنید.[/color]"
		return
	var clip_img := DisplayServer.clipboard_get_image()
	if clip_img == null or clip_img.is_empty():
		return
	var save_p := "res://generated/concepts/clipboard_" + str(Time.get_ticks_msec() % 100000) + ".png"
	var abs_p := ProjectSettings.globalize_path(save_p)
	DirAccess.make_dir_recursive_absolute(abs_p.get_base_dir())
	clip_img.save_png(abs_p)
	load_image_for_preview(save_p)
	_info_rtl.text = "[color=#22c55e]✓ تصویر از کلیپ‌بورد دریافت شد! در حال ساخت مش سه‌بعدی ۳۶۰ درجه...[/color]"
	_on_build_360_mesh_and_rig()


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
		_log("[color=#38bdf8][Drag & Drop][/color] تصویر دریافت شد: [b]%s[/b] — شروع ساخت مش ۳۶۰ درجه هوش مصنوعی..." % fpath.get_file())
		_on_build_360_mesh_and_rig()
	elif ext in ["glb", "gltf", "obj"]:
		_on_external_mesh_selected(fpath)


func load_image_for_preview(image_path: String) -> void:
	var src := OfflineConvScript.load_any_image(image_path)
	if src == null:
		_log("[color=#ef4444]خطا: باز کردن فایل تصویر ناموفق بود: %s[/color]" % image_path)
		return
	_current_image_path = image_path
	_path_label.text = "تصویر فعال: " + image_path.get_file()

	var thumb := src.duplicate() as Image
	thumb.resize(128, 128, Image.INTERPOLATE_BILINEAR)
	_orig_preview.texture = ImageTexture.create_from_image(thumb)

	var seg: Dictionary = OfflineConvScript.build_foreground_preview_and_mask(src, 96, 0.22)
	_mask_preview.texture = ImageTexture.create_from_image(seg["preview_img"])


func _on_neural_progress(pct: int, msg: String) -> void:
	if _progress_bar:
		_progress_bar.value = pct
	if _progress_lbl:
		_progress_lbl.text = "[%d%%] %s" % [pct, msg]


func _on_neural_concept_ready(orig_img: Image, mask_img: Image, saved_path: String) -> void:
	_current_image_path = saved_path
	if _path_label:
		_path_label.text = "تصویر فعال: " + saved_path.get_file()
	if _orig_preview and orig_img:
		var t1 := orig_img.duplicate() as Image
		t1.resize(128, 128, Image.INTERPOLATE_BILINEAR)
		_orig_preview.texture = ImageTexture.create_from_image(t1)
	if _mask_preview and mask_img:
		var t2 := mask_img.duplicate() as Image
		t2.resize(128, 128, Image.INTERPOLATE_BILINEAR)
		_mask_preview.texture = ImageTexture.create_from_image(t2)


func _get_scene_root() -> Node3D:
	if target_scene_provider.is_valid():
		var provided = target_scene_provider.call()
		if provided is Node3D:
			return provided as Node3D
	if Engine.is_editor_hint():
		var ed_root := EditorInterface.get_edited_scene_root()
		if ed_root is Node3D:
			return ed_root as Node3D
	var tree_root := get_tree().current_scene
	if tree_root is Node3D:
		return tree_root as Node3D
	return null


func _switch_editor_to_3d() -> void:
	if not Engine.is_editor_hint():
		return
	var base := EditorInterface.get_base_control()
	if base:
		var icon_3d := base.get_theme_icon("Node3D", "EditorIcons")
		for b in base.find_children("*", "Button", true, false):
			var btn := b as Button
			if btn and btn.toggle_mode and btn.button_group != null and btn.icon == icon_3d and not btn.text.is_empty():
				EditorInterface.set_main_screen_editor(btn.text)
				return
	EditorInterface.set_main_screen_editor("3D")


func _set_buttons_disabled(dis: bool) -> void:
	if _btn_mesh_only: _btn_mesh_only.disabled = dis
	if _btn_mesh_rig: _btn_mesh_rig.disabled = dis


func _on_build_360_mesh_only() -> void:
	if _neural_client.is_busy():
		return
	var scene_root := _get_scene_root()
	if scene_root == null:
		_log("[color=#ef4444]ابتدا یک صحنه سه‌بعدی باز کنید.[/color]")
		return

	_set_buttons_disabled(true)
	var oct := int(_res_slider.value)
	var res: Dictionary = await _neural_client.generate_from_image_async(_current_image_path, false, oct)
	_set_buttons_disabled(false)

	if not res.get("ok", false):
		_log("[color=#ef4444]" + str(res.get("error", "خطا در ساخت مش سه‌بعدی")) + "[/color]")
		return

	var mesh_node: Node3D = res["node"]
	_place_node_in_scene(scene_root, mesh_node, Vector3(-1.7, 0.0, 0.5))
	_last_spawned_node = mesh_node
	_log(
		"[color=#22c55e][مش ۳۶۰ درجه هوش مصنوعی][/color] ✓ ساخته شد با [b]%s[/b]: %d مثلث (%d ورتکس) | فایل: [b]%s[/b]" %
		[str(res.get("backend", "Hunyuan3D-2")), int(res["triangles"]), int(res["vertices"]), str(res["saved_glb"])]
	)
	_switch_editor_to_3d()


func _on_build_360_mesh_and_rig() -> void:
	if _neural_client.is_busy():
		return
	var scene_root := _get_scene_root()
	if scene_root == null:
		_log("[color=#ef4444]ابتدا یک صحنه سه‌بعدی باز کنید.[/color]")
		return

	_set_buttons_disabled(true)
	var oct := int(_res_slider.value)
	var res: Dictionary = await _neural_client.generate_from_image_async(_current_image_path, true, oct)
	_set_buttons_disabled(false)

	if not res.get("ok", false):
		_log("[color=#ef4444]" + str(res.get("error", "خطا در ساخت مش سه‌بعدی")) + "[/color]")
		return

	var rigged_node: Node3D = res["node"]
	var markers := rigged_node.find_child("BoneDebugMarkers", true, false) as Node3D
	if markers:
		markers.visible = _show_bones_chk.button_pressed

	_place_node_in_scene(scene_root, rigged_node, Vector3(1.7, 0.0, 0.5))
	_last_spawned_node = rigged_node
	_log(
		"[color=#38bdf8][عکس -> مش ۳۶۰ درجه + ریگ خودکار][/color] ✓ %d مثلث به [b]%d استخوان[/b] متصل شد (%s) | ذخیره شد: [b]%s[/b]" %
		[int(res["triangles"]), int(res["bones_count"]), str(res.get("backend", "Hunyuan3D-2")), str(res["saved_glb"])]
	)
	_switch_editor_to_3d()


func _on_external_mesh_selected(mesh_path: String) -> void:
	var scene_root := _get_scene_root()
	if scene_root == null:
		return
	var loaded := LoaderScript.load_model_scene(mesh_path, 1.88)
	if loaded == null:
		_log("[color=#ef4444]خطا در باز کردن فایل سه‌بعدی: %s[/color]" % mesh_path)
		return
	loaded.name = "Imported_" + mesh_path.get_file().get_basename().validate_node_name()
	var out_glb := "res://generated/rigged/" + loaded.name.to_lower() + "_rigged.glb"
	var rres: Dictionary = RiggerScript.autorig_node3d(loaded, _show_bones_chk.button_pressed, "Walk", out_glb)
	loaded.free()
	if not rres.get("ok", false):
		_log("[color=#ef4444]" + str(rres.get("error", "خطا در ریگ‌گذاری")) + "[/color]")
		return
	var rigged_node: Node3D = rres["node"]
	_place_node_in_scene(scene_root, rigged_node, Vector3(1.8, 0.0, 0.6))
	_last_spawned_node = rigged_node
	_log(
		"[color=#c084fc][ریگ‌گذاری خودکار مدل خارجی][/color] ✓ فایل «%s» با %d استخوان ریگ و متحرک شد -> [b]%s[/b]" %
		[mesh_path.get_file(), int(rres["bones_count"]), str(rres["saved_glb"])]
	)
	_switch_editor_to_3d()


func _on_rig_existing_mesh() -> void:
	var scene_root := _get_scene_root()
	if scene_root == null:
		return
	var target: Node3D = null
	if Engine.is_editor_hint():
		var sel := EditorInterface.get_selection().get_selected_nodes()
		if not sel.is_empty() and sel[0] is Node3D and sel[0] != scene_root:
			target = sel[0] as Node3D
	if target == null and is_instance_valid(_last_spawned_node):
		target = _last_spawned_node
	if target == null:
		_log("[color=#f59e0b]ابتدا یک مش بسازید یا یک گره سه‌بعدی در صحنه انتخاب کنید.[/color]")
		return
	if target.find_child("HumanoidAutoSkeleton", true, false) != null:
		_play_anim_on_last("Walk")
		_log("[color=#22c55e]این مدل از قبل دارای اسکلت ۱۹ استخوانی است — انیمیشن راه رفتن فعال شد.[/color]")
		return

	var old_pos := target.position
	var out_glb := "res://generated/rigged/" + target.name.to_lower() + "_autorig.glb"
	var rres: Dictionary = RiggerScript.autorig_node3d(target, _show_bones_chk.button_pressed, "Walk", out_glb)
	if not rres.get("ok", false):
		_log("[color=#ef4444]" + str(rres.get("error", "")) + "[/color]")
		return
	target.queue_free()
	var rigged_node: Node3D = rres["node"]
	_place_node_in_scene(scene_root, rigged_node, old_pos)
	_last_spawned_node = rigged_node
	_log("[color=#c084fc][ریگ خودکار][/color] ✓ اسکلت %d استخوانی متصل شد -> [b]%s[/b]" % [int(rres["bones_count"]), str(rres["saved_glb"])])


func _on_toggle_bone_markers(vis: bool) -> void:
	var scene_root := _get_scene_root()
	if scene_root == null:
		return
	for m in scene_root.find_children("BoneDebugMarkers", "Node3D", true, false):
		(m as Node3D).visible = vis


func _play_anim_on_last(anim_name: String) -> void:
	if not is_instance_valid(_last_spawned_node):
		var sr := _get_scene_root()
		if sr:
			for c in sr.get_children():
				if c.name.begins_with("Rigged_") and c is Node3D:
					_last_spawned_node = c as Node3D
	if not is_instance_valid(_last_spawned_node):
		_log("[color=#f59e0b]ابتدا یک کاراکتر ریگ‌شده بسازید.[/color]")
		return
	var ap := _last_spawned_node.find_child("AutoRigAnimationPlayer", true, false) as AnimationPlayer
	if ap == null:
		var aps := _last_spawned_node.find_children("*", "AnimationPlayer", true, false)
		if not aps.is_empty():
			ap = aps[0] as AnimationPlayer
	if ap and ap.has_animation(anim_name):
		ap.play(anim_name)
		_log("[color=#38bdf8][انیمیشن اسکلت][/color] کلیپ [b]%s[/b] روی مدل ریگ‌شده اجرا شد." % anim_name)


func _on_make_playable_hero() -> void:
	var scene_root := _get_scene_root()
	if scene_root == null or not is_instance_valid(_last_spawned_node):
		_log("[color=#f59e0b]ابتدا یک کاراکتر ۳۶۰ درجه بسازید و ریگ کنید تا جایگزین قهرمان قابل‌بازی شود![/color]")
		return
	var hero := scene_root.get_node_or_null("SamuraiHero") as CharacterBody3D
	if hero == null:
		return
	for ch in hero.get_children():
		if ch.name.ends_with("_Real3D") or ch.name.begins_with("Rigged_") or ch.name.begins_with("AI360_"):
			ch.queue_free()

	var clone := _last_spawned_node.duplicate() as Node3D
	clone.name = "RiggedCustomHero_Real3D"
	clone.position = Vector3.ZERO
	hero.add_child(clone)
	if Engine.is_editor_hint():
		clone.owner = scene_root
	var aps := clone.find_children("*", "AnimationPlayer", true, false)
	if not aps.is_empty():
		var ap := aps[0] as AnimationPlayer
		if ap and ap.has_animation("Idle"):
			ap.play("Idle")
	_log("[color=#22c55e][قهرمان قابل‌بازی WASD][/color] ✓ کاراکتر ۳۶۰ درجه شما جایگزین قهرمان بازی شد! دکمه Play (F5) را بزنید و با WASD + Space بازی کنید!")
	_switch_editor_to_3d()


func _place_node_in_scene(scene_root: Node3D, node: Node3D, pos: Vector3) -> void:
	var existing := scene_root.get_node_or_null(NodePath(node.name))
	if existing:
		existing.free()
	node.position = pos
	scene_root.add_child(node)
	if Engine.is_editor_hint():
		node.owner = scene_root
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(node)
	mesh_or_rig_spawned.emit(node)


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
	frame.custom_minimum_size = Vector2(92, 92)

	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(88, 88)
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
	b.clip_text = true
	b.custom_minimum_size = Vector2(0, 31)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = bg.lightened(0.28)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	b.add_theme_stylebox_override("normal", sb)
	var hov := sb.duplicate() as StyleBoxFlat
	hov.bg_color = bg.lightened(0.14)
	b.add_theme_stylebox_override("hover", hov)
	return b


func _log(msg: String) -> void:
	if _info_rtl:
		_info_rtl.text = msg
	status_logged.emit(msg)
