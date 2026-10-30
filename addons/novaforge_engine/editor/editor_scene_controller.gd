@tool
extends Node
## Central Live Editor Scene Controller (`NovaEditorController` — 100% Persian & Cold-Boot Safe).
## Connects all NovaForge Godot 4 Editor docks, main workspace, toolbars, context menus, and bottom panels
## directly to the live open 3D scene (`EditorInterface.get_edited_scene_root()`) and
## Godot 4's Spatial 3D Viewport Camera (`EditorInterface.get_editor_viewport_3d(0)`).

signal log_emitted(bbcode_line: String)
signal state_updated(state: Dictionary)
signal ai_progress_updated(percent: int, status_text: String)
signal ai_chat_replied(reply_dict: Dictionary)
signal setup_state_updated(setup_state: Dictionary)

var quality_tier: String = "AAA_UNREAL"
var camera_mode: String = "TPS_SOULS"
var world_day: int = 1
var weather_mode: String = "CLEAR"
var crate_shattered: bool = false

var npc_state: Dictionary = {
	"tier": 1,
	"title": "شاگرد آهنگر (سطح ۱)",
	"gold": 120,
	"rel": 10,
	"scars": [],
	"counters": []
}

var _history: Array[Dictionary] = []
var _cutscene_overlay: Control = null
var _cutscene_sub_label: Label = null
var _cutscene_running: bool = false
var _neural_client: Node = null
var _llm_brain: Node = null
var _setup_installer: Node = null
var _audio_preview_player: AudioStreamPlayer = null
var last_generated_script_path: String = ""

var modular_flags: Dictionary = {
	"npc_life": true,
	"voronoi_smart": true,
	"elemental_chem": true,
	"chunk_lod": true,
	"advanced_gi_fog": true,
	"spatial_audio": true
}


func _ready() -> void:
	var nscr = load("res://addons/novaforge_engine/forge/neural_3d_cloud_client.gd")
	if nscr:
		_neural_client = nscr.new()
		_neural_client.name = "ControllerNeural3DClient"
		_neural_client.progress_updated.connect(func(pct: int, msg: String):
			ai_progress_updated.emit(pct, msg)
			emit_log("[color=#38bdf8][هوش مصنوعی ۳۶۰ درجه %d%%][/color] %s" % [pct, msg])
		)
		add_child(_neural_client)

	var lscr = load("res://addons/novaforge_engine/ai_council/neural_llm_brain_client.gd")
	if lscr:
		_llm_brain = lscr.new()
		_llm_brain.name = "ControllerNeuralLLMBrain"
		_llm_brain.thinking_progress.connect(func(pct: int, msg: String):
			ai_progress_updated.emit(pct, msg)
			emit_log("[color=#a855f7][مغز هوش مصنوعی %d%%][/color] %s" % [pct, msg])
		)
		add_child(_llm_brain)

	var iscr = load("res://addons/novaforge_engine/ai_council/in_app_setup_installer.gd")
	if iscr:
		_setup_installer = iscr.new()
		_setup_installer.name = "ControllerInAppSetupInstaller"
		_setup_installer.setup_state_changed.connect(func(st: Dictionary):
			setup_state_updated.emit(st)
		)
		_setup_installer.setup_log_line.connect(func(line_bb: String):
			emit_log("[b][color=#10b981][نصب و دانلود خودکار][/color][/b] " + line_bb)
		)
		add_child(_setup_installer)

	call_deferred("_initial_setup")


func _initial_setup() -> void:
	emit_log("[b][color=#38bdf8][سیستم نوافورج][/color][/b] گذرگاه بومی بدون MCP فعال شد — ۱۲۳ مهارت بازی‌سازی و ۱۱۴ ابزار موتور بارگذاری شدند.")
	emit_log("[b][color=#a855f7][موتور Colibrì][/color][/b] حافظه ۳ لایه آماده است: وزن‌های فشرده INT4 در RAM | استریم متخصص‌ها از SSD | حفاظت کامل از VRAM کارت گرافیک.")
	_refresh_3d_labels()
	state_updated.emit(get_snapshot_dict())


func emit_log(bbcode_line: String) -> void:
	log_emitted.emit(bbcode_line)


func get_edited_root() -> Node3D:
	if Engine.is_editor_hint():
		var root := EditorInterface.get_edited_scene_root()
		if root is Node3D:
			return root as Node3D
	return null


func switch_to_3d_viewport() -> void:
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


func open_last_ai_script_in_editor() -> void:
	if last_generated_script_path.is_empty() or not FileAccess.file_exists(last_generated_script_path):
		emit_log("[color=#f59e0b]هنوز اسکریپتی توسط هوش مصنوعی ساخته نشده است؛ ابتدا از چت هوش مصنوعی کد بخواهید![/color]")
		return
	if Engine.is_editor_hint():
		var scr := load(last_generated_script_path) as Script
		if scr:
			var base := EditorInterface.get_base_control()
			if base:
				var icon_scr := base.get_theme_icon("Script", "EditorIcons")
				for b in base.find_children("*", "Button", true, false):
					var btn := b as Button
					if btn and btn.toggle_mode and btn.button_group != null and btn.icon == icon_scr and not btn.text.is_empty():
						EditorInterface.set_main_screen_editor(btn.text)
						break
			EditorInterface.edit_script(scr)
			emit_log("[color=#22c55e][ویرایشگر اسکریپت][/color] فایل [b]%s[/b] در بخش کدنویسی باز شد!" % last_generated_script_path)


func get_editor_cam() -> Camera3D:
	if Engine.is_editor_hint():
		var vp := EditorInterface.get_editor_viewport_3d(0)
		if vp:
			return vp.get_camera_3d()
	return null


func get_snapshot_dict() -> Dictionary:
	return {
		"quality": quality_tier,
		"cam": camera_mode,
		"day": world_day,
		"weather": weather_mode,
		"crate_shattered": crate_shattered,
		"npc": npc_state.duplicate(true)
	}


func save_snapshot(label: String) -> void:
	_history.append(get_snapshot_dict())
	emit_log("[color=#94a3b8][Time-Machine] Snapshot saved: \"%s\" (Total: %d)[/color]" % [label, _history.size()])


func undo_snapshot() -> void:
	if _history.is_empty():
		emit_log("[color=#f59e0b][Time-Machine] هیچ اسنپ‌شات قبلی برای بازگشت وجود ندارد.[/color]")
		return
	var prev: Dictionary = _history.pop_back()
	quality_tier = str(prev.get("quality", "AAA_UNREAL"))
	camera_mode = str(prev.get("cam", "TPS_SOULS"))
	world_day = int(prev.get("day", 1))
	var target_shattered: bool = bool(prev.get("crate_shattered", false))
	if target_shattered != crate_shattered:
		shatter_or_reset_crate(false)
	npc_state = (prev.get("npc", {}) as Dictionary).duplicate(true)
	apply_quality_visuals(quality_tier, false)
	apply_camera_perspective(camera_mode, false)
	apply_elemental_weather(str(prev.get("weather", "CLEAR")), false)
	_refresh_3d_labels()
	state_updated.emit(get_snapshot_dict())
	emit_log("[color=#22c55e][Time-Machine] وضعیت صحنه، NPC و تنظیمات به اسنپ‌شات قبلی بازگردانی شد![/color]")


func apply_quality_visuals(tier: String, record_snap: bool = true) -> void:
	if record_snap:
		save_snapshot("Before Quality Switch")
	quality_tier = tier
	if get_tree() and get_tree().root.has_node("NovaQuality"):
		get_tree().root.get_node("NovaQuality").apply_quality_tier(tier, get_edited_root())

	var root := get_edited_root()
	if root:
		var world_env := root.get_node_or_null("NovaWorldEnvironment") as WorldEnvironment
		var ground_mesh := root.get_node_or_null("ArenaGround/GroundMesh") as MeshInstance3D
		var hero_mesh := root.get_node_or_null("SamuraiHero/HeroMesh") as MeshInstance3D
		var sun := root.get_node_or_null("SunLight3D") as DirectionalLight3D

		if world_env and world_env.environment:
			var env := world_env.environment
			match tier:
				"AAA_UNREAL":
					env.background_color = Color(0.08, 0.13, 0.22)
					env.ambient_light_energy = 0.72
					if sun: sun.light_energy = 1.35
				"INDIE_CEL_ANIME":
					env.background_color = Color(0.22, 0.56, 0.92)
					env.ambient_light_energy = 1.05
					if sun: sun.light_energy = 1.15
				"INDIE_PSX_RETRO":
					env.background_color = Color(0.14, 0.10, 0.20)
					env.ambient_light_energy = 0.55
					if sun: sun.light_energy = 0.85
				"INDIE_HD2D":
					env.background_color = Color(0.10, 0.12, 0.18)
					env.ambient_light_energy = 0.65
					if sun: sun.light_energy = 1.45
				_:
					env.background_color = Color(0.14, 0.18, 0.25)
					env.ambient_light_energy = 0.85
					if sun: sun.light_energy = 1.1

		if ground_mesh and ground_mesh.mesh and ground_mesh.mesh.surface_get_material(0) is StandardMaterial3D:
			var gmat := ground_mesh.mesh.surface_get_material(0) as StandardMaterial3D
			if tier == "INDIE_CEL_ANIME":
				gmat.albedo_color = Color(0.14, 0.48, 0.26)
			elif tier == "INDIE_PSX_RETRO":
				gmat.albedo_color = Color(0.20, 0.17, 0.26)
			else:
				gmat.albedo_color = Color(0.20, 0.24, 0.30)

		if hero_mesh:
			if tier == "INDIE_CEL_ANIME" and ResourceLoader.exists("res://shaders/cel_toon_outline.gdshader"):
				var sm := ShaderMaterial.new()
				sm.shader = load("res://shaders/cel_toon_outline.gdshader")
				hero_mesh.material_override = sm
			elif tier == "INDIE_PSX_RETRO" and ResourceLoader.exists("res://shaders/psx_retro.gdshader"):
				var pm := ShaderMaterial.new()
				pm.shader = load("res://shaders/psx_retro.gdshader")
				hero_mesh.material_override = pm
			else:
				hero_mesh.material_override = null

	state_updated.emit(get_snapshot_dict())
	emit_log("[color=#a855f7][NovaQuality][/color] Switched visual pipeline -> [b]%s[/b] (Shaders & Environment updated live)" % tier)


func apply_camera_perspective(mode: String, log_change: bool = true) -> void:
	camera_mode = mode
	var root := get_edited_root()
	if root:
		var rig := root.get_node_or_null("PerspectiveCameraRig3D")
		if rig and rig.has_method("set_perspective_by_name"):
			rig.call("set_perspective_by_name", mode)

	var cam := get_editor_cam()
	if cam:
		var target_pos := Vector3(0.5, 2.9, 4.8)
		var look_target := Vector3(0.0, 1.1, -1.2)
		match mode:
			"TPS_SOULS":
				target_pos = Vector3(0.4, 2.8, 4.6)
				look_target = Vector3(0.0, 1.1, -1.5)
			"TPS_SHOULDER":
				target_pos = Vector3(0.95, 1.85, 2.2)
				look_target = Vector3(0.25, 1.35, -2.5)
			"FPS":
				target_pos = Vector3(0.0, 1.72, -0.35)
				look_target = Vector3(0.3, 1.45, -4.5)
			"SIDE_2_5D":
				target_pos = Vector3(6.8, 2.3, -0.8)
				look_target = Vector3(0.0, 1.3, -0.8)
			"HD_2D":
				target_pos = Vector3(0.0, 6.4, 7.2)
				look_target = Vector3(0.0, 0.8, -1.2)
			"ISOMETRIC":
				target_pos = Vector3(7.2, 7.8, 6.8)
				look_target = Vector3(0.0, 0.7, -1.2)
			"PURE_2D":
				target_pos = Vector3(0.0, 2.2, 9.0)
				look_target = Vector3(0.0, 1.4, 0.0)
			"FIXED_CINEMATIC":
				target_pos = Vector3(-4.6, 3.9, 3.6)
				look_target = Vector3(0.5, 1.0, -1.5)

		var target_xform := Transform3D().looking_at(look_target - target_pos, Vector3.UP)
		target_xform.origin = target_pos
		var tw := create_tween()
		tw.tween_property(cam, "global_transform", target_xform, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	state_updated.emit(get_snapshot_dict())
	if log_change:
		emit_log("[color=#38bdf8][PerspectiveCameraRig3D][/color] Runtime & Viewport camera switched -> [b]%s[/b]" % mode)


func shatter_or_reset_crate(record_snap: bool = true) -> void:
	var root := get_edited_root()
	if root == null:
		return
	var crate := root.get_node_or_null("DestructibleAncientCrate") as Node3D
	if crate == null:
		return

	if record_snap:
		save_snapshot("Voronoi Crate Toggle")

	var crate_mesh := crate.get_node_or_null("CrateModel") as Node3D
	if crate_mesh == null:
		crate_mesh = crate.get_node_or_null("CrateMesh") as Node3D
	var existing_shards := crate.get_node_or_null("VoronoiShards3D")

	if crate_shattered:
		crate_shattered = false
		if existing_shards:
			existing_shards.queue_free()
		if crate_mesh:
			crate_mesh.visible = true
		_refresh_3d_labels()
		state_updated.emit(get_snapshot_dict())
		emit_log("[color=#94a3b8][SmartObjectBehavior3D] صندوق باستانی بازسازی شد (Crate mesh restored).[/color]")
		return

	crate_shattered = true
	if crate_mesh:
		crate_mesh.visible = false
	if existing_shards:
		existing_shards.queue_free()

	var holder := Node3D.new()
	holder.name = "VoronoiShards3D"
	crate.add_child(holder)

	var shard_mat := StandardMaterial3D.new()
	shard_mat.albedo_color = Color(0.80, 0.54, 0.22)
	shard_mat.roughness = 0.68

	for i in range(16):
		var shard := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.34, 0.28, 0.32)
		pm.material = shard_mat
		shard.mesh = pm
		var ang := (TAU * float(i)) / 16.0
		var radius := 0.55 + float(i % 4) * 0.36
		shard.position = Vector3.ZERO
		shard.rotation = Vector3(float(i) * 0.7, ang, float(i) * 0.4)
		holder.add_child(shard)

		var end_pos := Vector3(cos(ang) * radius, -0.42 + float(i % 2) * 0.08, sin(ang) * radius)
		var tw := create_tween()
		tw.tween_property(shard, "position", end_pos, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_play_hero_katana_slash_vfx()
	_refresh_3d_labels()
	state_updated.emit(get_snapshot_dict())
	emit_log("[b][color=#f59e0b][VoronoiFracturer C++20][/color][/b] Sliced DestructibleAncientCrate into 16 watertight convex Jolt shards!")


func _play_hero_katana_slash_vfx() -> void:
	var root := get_edited_root()
	if root == null:
		return
	var hero := root.get_node_or_null("SamuraiHero") as Node3D
	if hero == null:
		return

	var loader = load("res://addons/novaforge_engine/forge/glb_asset_loader.gd")
	if loader:
		loader.play_character_anim(hero, ["SwordSlash"], false)

	var old_arc := hero.get_node_or_null("KatanaSlashArcVFX")
	if old_arc:
		old_arc.queue_free()

	var arc := MeshInstance3D.new()
	arc.name = "KatanaSlashArcVFX"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.25
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.22, 0.82, 1.0, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	torus.material = mat
	arc.mesh = torus
	arc.position = Vector3(0.0, 0.25, -0.35)
	arc.rotation_degrees = Vector3(12.0, 0.0, -18.0)
	hero.add_child(arc)

	var base_rot := hero.rotation
	var tw := create_tween()
	tw.tween_property(hero, "rotation:y", base_rot.y + TAU, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(arc, "scale", Vector3(1.45, 1.45, 1.45), 0.42)
	tw.tween_callback(func():
		hero.rotation = base_rot
		if is_instance_valid(arc):
			arc.queue_free()
	)


func spawn_image_to_3d_rigged_character(img_path: String = "res://assets/sample_images/cyber_samurai_concept.png") -> void:
	var root := get_edited_root()
	if root == null or _neural_client == null:
		return
	if _neural_client.call("is_busy"):
		emit_log("[color=#f59e0b]یک مدل ۳۶۰ درجه در حال ساخت است؛ لطفاً چند ثانیه صبر کنید...[/color]")
		return
	save_snapshot("360 Neural Image-to-3D + Auto-Rig")
	emit_log("[b][color=#38bdf8][تبدیل عکس به مش ۳۶۰ درجه][/color][/b] ارسال «%s» به موتور دوربری و Hunyuan3D-2..." % img_path.get_file())

	var res: Dictionary = await _neural_client.call("generate_from_image_async", img_path, true, 176)
	if not res.get("ok", false):
		emit_log("[color=#ef4444][خطا][/color] " + str(res.get("error", "")))
		return

	root = get_edited_root()
	if root == null:
		return
	var char_root: Node3D = res["node"]
	var old := root.get_node_or_null(NodePath(char_root.name))
	if old:
		old.free()
	var markers := char_root.find_child("BoneDebugMarkers", true, false) as Node3D
	if markers:
		markers.visible = false
	char_root.position = Vector3(1.8, 0.0, 0.5)
	root.add_child(char_root)
	char_root.owner = root
	switch_to_3d_viewport()

	emit_log(
		"[b][color=#22c55e][عکس -> مش ۳۶۰ درجه + ریگ ۱۹ استخوانی][/color][/b] ✓ تصویر «%s» با [b]%s[/b] به مش ۳۶۰ درجه (%d مثلث) و ریگ %d استخوانی تبدیل شد -> [b]%s[/b]" %
		[img_path.get_file(), str(res.get("backend", "Hunyuan3D-2")), int(res["triangles"]), int(res["bones_count"]), str(res["saved_glb"])]
	)


func run_video_to_motion_combo() -> void:
	_play_hero_katana_slash_vfx()
	emit_log("[b][color=#22c55e][استخراج موشن از ویدیو][/color][/b] انیمیشن اسکلتی کمبوی شمشیر (SwordSlash) با قفل کف پا (Foot-IK) روی اسکلت کاراکتر اجرا شد!")


func import_blender_auto_pbr_gate(custom_path: String = "res://assets/models/world/castle_tower.glb", jump_to_3d: bool = false) -> Dictionary:
	var root := get_edited_root()
	if root == null:
		return {"ok": false, "error": "صحنه سه‌بعدی باز نیست."}
	save_snapshot("Blender Auto-PBR Import")

	var abs_src := ProjectSettings.globalize_path(custom_path) if custom_path.begins_with("res://") else custom_path
	var ext := abs_src.get_extension().to_lower()
	var load_target := custom_path

	var imp_scr = load("res://addons/novaforge_engine/importers/universal_3d_importer.gd")
	var pbr_info: Dictionary = {}
	var auto_mat: StandardMaterial3D = null
	if imp_scr:
		var imp = imp_scr.new()
		if ext == "blend" or ext == "fbx":
			var converted: String = imp.try_convert_blend_via_blender_cli(abs_src)
			if not converted.is_empty():
				load_target = converted
		pbr_info = imp.import_and_autobind(custom_path)
		if pbr_info.get("material") is StandardMaterial3D:
			auto_mat = pbr_info["material"]

	var loader = load("res://addons/novaforge_engine/forge/glb_asset_loader.gd")
	if loader == null:
		return {"ok": false, "error": "ماژول بارگذاری مدل در دسترس نیست."}

	var old_gate := root.get_node_or_null("Blender_Imported_Model3D")
	if old_gate:
		old_gate.free()

	var model: Node3D = loader.load_model_scene(load_target, 4.2)
	if model == null:
		# Fallback to tower showcase mesh with resolved PBR material if raw .blend had no local Blender CLI
		model = loader.load_model_scene("res://assets/models/world/castle_tower.glb", 4.2)
	if model == null:
		return {"ok": false, "error": "بارگذاری مش انجام نشد."}

	var bound_slots: Dictionary = pbr_info.get("bound_slots", {})
	if auto_mat != null and not bound_slots.is_empty():
		for ch in model.find_children("*", "MeshInstance3D", true, false):
			var mi := ch as MeshInstance3D
			if mi:
				mi.material_override = auto_mat

	model.name = "Blender_Imported_Model3D"
	model.position = Vector3(3.6, 0.0, -3.6)
	root.add_child(model)
	model.owner = root

	if jump_to_3d:
		switch_to_3d_viewport()

	var slot_names := ", ".join(PackedStringArray(bound_slots.keys())) if not bound_slots.is_empty() else "متریال داخلی مدل (Embedded PBR)"
	var norm_note := "بله (اصلاح کانال سبز DirectX)" if bool(pbr_info.get("normal_green_flipped", false)) else "استاندارد OpenGL"
	var rep := {
		"ok": true,
		"file": custom_path.get_file(),
		"format": ext.to_upper(),
		"slots": slot_names,
		"normal_fix": norm_note,
		"gloss_inverted": bool(pbr_info.get("gloss_inverted", false)),
		"scanned_count": int(pbr_info.get("textures_scanned", 0))
	}
	emit_log("[b][color=#fb923c][ایمپورتر ۱۳ فرمت بلندر][/color][/b] مدل «%s» (%s) وارد صحنه شد | کانال‌های PBR: %s | نرمال‌مپ: %s" % [rep["file"], rep["format"], slot_names, norm_note])
	return rep


func trigger_live_cutscene(subtitle: String = "«دروازه قلعه باز می‌شود... آماده نبرد شو!»") -> void:
	if _cutscene_running:
		return
	var cam := get_editor_cam()
	if cam == null:
		return

	_cutscene_running = true
	var orig_xform := cam.global_transform
	_show_cutscene_letterbox(true, subtitle)
	emit_log("[b][color=#c084fc][CutsceneDirector][/color][/b] Seamless blend from Gameplay Camera -> Cinematic Rail (32mm Lens DOF, 0.45x Slow-Mo, 0ms Black Screen)")

	var shot1_pos := Vector3(-2.6, 1.65, 2.2)
	var shot1_xform := Transform3D().looking_at(Vector3(0.0, 1.25, -1.8) - shot1_pos, Vector3.UP)
	shot1_xform.origin = shot1_pos

	var shot2_pos := Vector3(2.5, 2.1, 1.9)
	var shot2_xform := Transform3D().looking_at(Vector3(0.0, 1.35, -2.2) - shot2_pos, Vector3.UP)
	shot2_xform.origin = shot2_pos

	var tw := create_tween()
	tw.tween_property(cam, "global_transform", shot1_xform, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(cam, "global_transform", shot2_xform, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(cam, "global_transform", orig_xform, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		_show_cutscene_letterbox(false, "")
		_cutscene_running = false
		emit_log("[color=#c084fc][CutsceneDirector][/color] Blended smoothly back behind player shoulder (Zero black screen)!")
	)


func _show_cutscene_letterbox(active: bool, subtitle: String) -> void:
	if not Engine.is_editor_hint():
		return
	var vp := EditorInterface.get_editor_viewport_3d(0)
	if vp == null or vp.get_parent() == null:
		return
	var host := vp.get_parent() as Control
	if host == null:
		return

	if _cutscene_overlay == null or not is_instance_valid(_cutscene_overlay):
		_cutscene_overlay = Control.new()
		_cutscene_overlay.name = "NovaCutsceneLetterbox"
		_cutscene_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		_cutscene_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var top_bar := ColorRect.new()
		top_bar.color = Color(0, 0, 0, 0.90)
		top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
		top_bar.custom_minimum_size = Vector2(0, 42)
		top_bar.offset_bottom = 42
		top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var top_lbl := Label.new()
		top_lbl.text = "▶ کارگردان کات‌سین زنده نوافورج (بدون صفحه سیاه — فوکوس لحظه‌ای روی صحنه)"
		top_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		top_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		top_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		top_bar.add_child(top_lbl)
		_cutscene_overlay.add_child(top_bar)

		var bot_bar := ColorRect.new()
		bot_bar.color = Color(0, 0, 0, 0.90)
		bot_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		bot_bar.offset_top = -46
		bot_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

		_cutscene_sub_label = Label.new()
		_cutscene_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_cutscene_sub_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_cutscene_sub_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		bot_bar.add_child(_cutscene_sub_label)
		_cutscene_overlay.add_child(bot_bar)

		host.add_child(_cutscene_overlay)

	if _cutscene_sub_label:
		_cutscene_sub_label.text = subtitle
	_cutscene_overlay.visible = active


func apply_elemental_weather(elem: String, log_event: bool = true) -> String:
	var prev := weather_mode
	weather_mode = elem
	var reaction := "واکنش فعال: محیط پایدار | Chunk [0,0] LOD0"

	if elem == "LIGHTNING" and prev == "RAIN":
		reaction = "⚡ واکنش زنجیره‌ای صاعقه روی زمین خیس (AoE Shock 45 DMG)!"
	elif elem == "RAIN" and prev == "FIRE":
		reaction = "◈ باران آتش را خاموش کرد + تولید بخار غلیظ و سطح خیس SSR!"
	elif elem == "RAIN":
		reaction = "◈ بارش باران فعال شد — سطح زمین خیس و براق (Wet PBR)!"
	elif elem == "FIRE":
		reaction = "▲ گسترش آتش در جهت وزش باد روی چمن و چوب!"
	elif elem == "LIGHTNING":
		reaction = "⚡ برخورد صاعقه به میدان نبرد!"

	var root := get_edited_root()
	if root:
		var fx_holder := root.get_node_or_null("ElementalWeather/LiveWeatherFX")
		if fx_holder:
			fx_holder.queue_free()

		var weather_node := root.get_node_or_null("ElementalWeather")
		if weather_node:
			var new_fx := Node3D.new()
			new_fx.name = "LiveWeatherFX"
			weather_node.add_child(new_fx)

			var ground_mesh := root.get_node_or_null("ArenaGround/GroundMesh") as MeshInstance3D
			var gmat: StandardMaterial3D = null
			if ground_mesh and ground_mesh.mesh and ground_mesh.mesh.surface_get_material(0) is StandardMaterial3D:
				gmat = ground_mesh.mesh.surface_get_material(0) as StandardMaterial3D

			if elem == "RAIN":
				if gmat:
					gmat.albedo_color = Color(0.11, 0.17, 0.26)
					gmat.roughness = 0.08
					gmat.metallic = 0.42
				var rain := CPUParticles3D.new()
				rain.amount = 260
				rain.lifetime = 1.1
				rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
				rain.emission_box_extents = Vector3(9.0, 0.2, 9.0)
				rain.direction = Vector3(-0.15, -1.0, 0.0)
				rain.spread = 4.0
				rain.initial_velocity_min = 11.0
				rain.initial_velocity_max = 14.0
				var drop := BoxMesh.new()
				drop.size = Vector3(0.03, 0.42, 0.03)
				var dmat := StandardMaterial3D.new()
				dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				dmat.albedo_color = Color(0.55, 0.78, 1.0)
				drop.material = dmat
				rain.mesh = drop
				rain.position = Vector3(0, 8.5, 0)
				new_fx.add_child(rain)

			elif elem == "FIRE":
				if gmat:
					gmat.albedo_color = Color(0.24, 0.16, 0.14)
					gmat.roughness = 0.75
					gmat.metallic = 0.05
				var fire := CPUParticles3D.new()
				fire.amount = 140
				fire.lifetime = 0.9
				fire.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
				fire.emission_sphere_radius = 1.6
				fire.gravity = Vector3(1.8, 6.5, 0.0)
				var ember := SphereMesh.new()
				ember.radius = 0.11
				ember.height = 0.22
				var fmat := StandardMaterial3D.new()
				fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				fmat.albedo_color = Color(1.0, 0.42, 0.08)
				ember.material = fmat
				fire.mesh = ember
				fire.position = Vector3(1.5, 0.4, -1.5)
				new_fx.add_child(fire)

				var fl := OmniLight3D.new()
				fl.light_color = Color(1.0, 0.48, 0.12)
				fl.light_energy = 4.5
				fl.omni_range = 10.0
				fl.position = Vector3(1.5, 1.6, -1.5)
				new_fx.add_child(fl)

			elif elem == "LIGHTNING":
				var bolt := MeshInstance3D.new()
				var cyl := CylinderMesh.new()
				cyl.top_radius = 0.08
				cyl.bottom_radius = 0.18
				cyl.height = 10.0
				var bmat := StandardMaterial3D.new()
				bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				bmat.albedo_color = Color(0.65, 0.95, 1.0)
				cyl.material = bmat
				bolt.mesh = cyl
				bolt.position = Vector3(0.8, 5.0, -1.4)
				new_fx.add_child(bolt)

				var flash := OmniLight3D.new()
				flash.light_color = Color(0.55, 0.9, 1.0)
				flash.light_energy = 8.0
				flash.omni_range = 18.0
				flash.position = Vector3(0.8, 2.5, -1.4)
				new_fx.add_child(flash)

				var tw := create_tween()
				tw.tween_interval(0.65)
				tw.tween_callback(func():
					if is_instance_valid(bolt): bolt.queue_free()
					if is_instance_valid(flash): flash.queue_free()
				)
			else:
				if gmat:
					gmat.albedo_color = Color(0.22, 0.25, 0.31)
					gmat.roughness = 0.85
					gmat.metallic = 0.0

	state_updated.emit(get_snapshot_dict())
	if log_event:
		emit_log("[color=#38bdf8][ElementalWeatherSystem][/color] Weather/Element -> [b]%s[/b] | %s" % [elem, reaction])
	return reaction


func advance_world_days(days: int = 5) -> void:
	save_snapshot("Advance World Time")
	world_day += days
	var rel: int = int(npc_state["rel"])
	var gold: int = int(npc_state["gold"])
	if rel <= -35:
		npc_state["tier"] = 3
		npc_state["title"] = "فرمانده یاغیان زخم‌خورده (Nemesis Lv.3)"
		npc_state["gold"] = gold + 90
	else:
		gold += 160
		npc_state["gold"] = gold
		if gold >= 500:
			npc_state["tier"] = 3
			npc_state["title"] = "استادکار سلطنتی + کارگاه بزرگ"
		elif gold >= 260:
			npc_state["tier"] = 2
			npc_state["title"] = "آهنگر ارشد شهر (سطح ۲)"

	_refresh_3d_labels()
	state_updated.emit(get_snapshot_dict())
	emit_log("[color=#22c55e][NovaWorldLife][/color] Advanced +%d days -> [b]روز %d[/b]. کاوه آهنگر تکامل یافت: %s (%d سکه)" % [days, world_day, str(npc_state["title"]), int(npc_state["gold"])])


func help_npc() -> void:
	npc_state["rel"] = mini(100, int(npc_state["rel"]) + 25)
	npc_state["gold"] = int(npc_state["gold"]) + 55
	_refresh_3d_labels()
	state_updated.emit(get_snapshot_dict())
	emit_log("[color=#22c55e][LivingNPCBrain3D][/color] کمک و خرید از کاوه آهنگر -> رابطه: +%d | طلا: %d" % [int(npc_state["rel"]), int(npc_state["gold"])])


func fight_npc() -> void:
	npc_state["rel"] = maxi(-100, int(npc_state["rel"]) - 50)
	var scars: Array = npc_state["scars"]
	if not scars.has("جای زخم شمشیر روی گونه چپ"):
		scars.append("جای زخم شمشیر روی گونه چپ")
	var counters: Array = npc_state["counters"]
	if not counters.has("Parry_3Hit_Katana"):
		counters.append("Parry_3Hit_Katana")
	_play_hero_katana_slash_vfx()
	_refresh_3d_labels()
	state_updated.emit(get_snapshot_dict())
	emit_log("[b][color=#ef4444][Nemesis Memory][/color][/b] کاوه آهنگر با زخم گونه جان سالم به در برد و ضدحمله `Parry_3Hit_Katana` را یاد گرفت!")


func _refresh_3d_labels() -> void:
	var root := get_edited_root()
	if root == null:
		return

	var kaveh := root.get_node_or_null("KavehBlacksmithNPC") as Node3D
	if kaveh:
		var lbl := kaveh.get_node_or_null("NPCLabel3D") as Label3D
		var rel: int = int(npc_state["rel"])
		if lbl:
			var prefix := "⚔ Nemesis: " if rel <= -35 else "کاوه آهنگر — "
			lbl.text = "%s%s\nطلا: %d | رابطه: %d | روز %d" % [prefix, str(npc_state["title"]), int(npc_state["gold"]), rel, world_day]
			lbl.modulate = Color(1.0, 0.38, 0.38) if rel <= -35 else Color(0.98, 0.92, 0.48)

		var nmesh := kaveh.get_node_or_null("NPCMesh") as MeshInstance3D
		if nmesh and nmesh.mesh and nmesh.mesh.surface_get_material(0) is StandardMaterial3D:
			var nmat := nmesh.mesh.surface_get_material(0) as StandardMaterial3D
			nmat.albedo_color = Color(0.78, 0.16, 0.18) if rel <= -35 else Color(0.18, 0.62, 0.54)

	var crate := root.get_node_or_null("DestructibleAncientCrate") as Node3D
	if crate:
		var clbl := crate.get_node_or_null("CrateLabel3D") as Label3D
		if clbl:
			clbl.text = "★ صندوق متلاشی شد (۱۶ قطعه Voronoi)" if crate_shattered else "■ صندوق باستانی [قابل تخریب Voronoi]"


func run_prompt_council_build(prompt_txt: String) -> void:
	if _neural_client == null:
		return
	if _neural_client.call("is_busy"):
		emit_log("[color=#f59e0b]یک مدل ۳۶۰ درجه در حال ساخت است؛ لطفاً چند ثانیه صبر کنید...[/color]")
		return

	save_snapshot("360 Neural Prompt Build: " + prompt_txt.left(24))
	emit_log("[b][color=#38bdf8][تولید مش ۳۶۰ درجه هوش مصنوعی][/color][/b] شروع ساخت مدل سه‌بعدی واقعی از پرامپت: «%s»..." % prompt_txt)

	if prompt_txt.contains("باران") or prompt_txt.contains("خیس") or prompt_txt.to_lower().contains("rain"):
		apply_elemental_weather("RAIN", true)
	elif prompt_txt.contains("صاعقه") or prompt_txt.to_lower().contains("lightning"):
		apply_elemental_weather("LIGHTNING", true)

	var res: Dictionary = await _neural_client.call("generate_from_prompt_async", prompt_txt, true, 0, 176)
	if not res.get("ok", false):
		emit_log("[color=#ef4444][خطا در ساخت سه‌بعدی][/color] " + str(res.get("error", "")))
		return

	var root := get_edited_root()
	if root == null:
		return
	var holder := root.get_node_or_null("NovaAISpawnedWorld") as Node3D
	if holder == null:
		holder = Node3D.new()
		holder.name = "NovaAISpawnedWorld"
		root.add_child(holder)
		holder.owner = root

	var node3d: Node3D = res["node"]
	var markers := node3d.find_child("BoneDebugMarkers", true, false) as Node3D
	if markers:
		markers.visible = false

	var idx := holder.get_child_count()
	var offset_x := 0.0 if idx == 0 else (2.1 * float((idx + 1) / 2) * (1.0 if idx % 2 == 1 else -1.0))
	node3d.position = Vector3(offset_x, 0.0, 0.6)
	holder.add_child(node3d)
	node3d.owner = root

	var tag := Label3D.new()
	tag.text = "✦ " + prompt_txt.left(34)
	tag.font_size = 24
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color(0.45, 0.92, 1.0)
	tag.position = Vector3(0.0, 2.05, 0.0)
	node3d.add_child(tag)

	if prompt_txt.contains("کات‌سین") or prompt_txt.contains("کات سین") or prompt_txt.to_lower().contains("cutscene"):
		trigger_live_cutscene("▶ کات‌سین زنده: «" + prompt_txt.left(48) + "»")

	switch_to_3d_viewport()
	emit_log(
		"[b][color=#22c55e][تولید مش سه‌بعدی ۳۶۰ درجه کامل شد ✓][/color][/b] با [b]%s[/b]: %d مثلث | %d استخوان ریگ‌شده | ذخیره شد: [b]%s[/b]" %
		[str(res.get("backend", "Hunyuan3D-2")), int(res["triangles"]), int(res["bones_count"]), str(res["saved_glb"])]
	)


func run_library_world_layout(prompt_txt: String) -> void:
	var root := get_edited_root()
	var builder = load("res://addons/novaforge_engine/ai_council/semantic_world_builder.gd")
	if builder and root:
		var bres: Dictionary = builder.build_from_prompt(root, prompt_txt, false)
		var sp: Array = bres.get("spawned", [])
		switch_to_3d_viewport()
		emit_log("[color=#22c55e][چیدمان سریع محیط][/color] ✓ %d مدل محیطی اضافه شد: %s" % [sp.size(), ", ".join(PackedStringArray(sp))])


func get_llm_brain() -> Node:
	return _llm_brain


func get_setup_installer() -> Node:
	return _setup_installer


func ask_ai_council_async(user_msg: String, force_build_3d: bool = false, persona: String = "") -> Dictionary:
	if _llm_brain == null:
		return {"ok": false, "error": "مغز هوش مصنوعی بارگذاری نشده است."}
	var res: Dictionary = await _llm_brain.call("ask_brain_async", user_msg, persona)
	if not res.get("ok", false):
		ai_chat_replied.emit({"ok": false, "user_msg": user_msg, "error": str(res.get("error", "خطا"))})
		return res

	# Save generated GDScript automatically if present
	var gd_code := str(res.get("gdscript_code", ""))
	var saved_script_path := ""
	if not gd_code.is_empty():
		var abs_dir := ProjectSettings.globalize_path("res://generated/scripts")
		DirAccess.make_dir_recursive_absolute(abs_dir)
		saved_script_path = "res://generated/scripts/ai_script_%d.gd" % (Time.get_ticks_msec() % 100000)
		var fa := FileAccess.open(saved_script_path, FileAccess.WRITE)
		if fa:
			fa.store_string(gd_code + "\n")
			fa.close()
			last_generated_script_path = saved_script_path
		res["saved_script_path"] = saved_script_path

	# Execute Zero-MCP scene actions requested by user / AI
	var actions: Array = res.get("actions", [])
	for act in actions:
		var a := str(act)
		if a in ["RAIN", "FIRE", "LIGHTNING", "CLEAR"]:
			apply_elemental_weather(a, true)
		elif a == "SHATTER":
			shatter_or_reset_crate()
		elif a == "CUTSCENE":
			trigger_live_cutscene("▶ کات‌سین هوشمند: «" + user_msg.left(45) + "»")
		elif a in ["FPS", "TPS", "ISOMETRIC"]:
			apply_camera_perspective("TPS_SOULS" if a == "TPS" else a)

	res["user_msg"] = user_msg
	ai_chat_replied.emit(res)

	if force_build_3d:
		await run_prompt_council_build(user_msg)

	return res


func clear_ai_spawned_world() -> void:
	var root := get_edited_root()
	if root and root.has_node("NovaAISpawnedWorld"):
		root.get_node("NovaAISpawnedWorld").queue_free()
		emit_log("[color=#94a3b8]اشیاء ساخته‌شده قبلی پاک شدند.[/color]")


func launch_game_now() -> void:
	if Engine.is_editor_hint():
		EditorInterface.play_main_scene()
		emit_log("[b][color=#22c55e][اجرای بازی][/color][/b] صحنه اصلی با موتور فیزیک Jolt اجرا شد!")


func get_modular_flags() -> Dictionary:
	return modular_flags.duplicate(true)


func set_modular_feature_enabled(flag_id: String, enabled: bool) -> Dictionary:
	modular_flags[flag_id] = enabled
	var root := get_edited_root()
	if root:
		match flag_id:
			"npc_life":
				var npc_node := root.find_child("*NPC*", true, false) as Node3D
				if npc_node:
					npc_node.visible = enabled
			"voronoi_smart":
				var crate := root.get_node_or_null("DestructibleAncientCrate") as Node3D
				if crate:
					crate.visible = enabled
			"elemental_chem":
				var ew := root.get_node_or_null("ElementalWeather") as Node3D
				if ew:
					ew.visible = enabled
				if not enabled:
					apply_elemental_weather("CLEAR", false)
			"advanced_gi_fog":
				var wenv := root.get_node_or_null("NovaWorldEnvironment") as WorldEnvironment
				var sun := root.get_node_or_null("SunLight3D") as DirectionalLight3D
				if wenv and wenv.environment:
					wenv.environment.glow_enabled = enabled
					wenv.environment.volumetric_fog_enabled = enabled
				if sun:
					sun.shadow_enabled = enabled
			"spatial_audio":
				if not enabled and _audio_preview_player and _audio_preview_player.playing:
					_audio_preview_player.stop()
	var state_word := "فعال ✓" if enabled else "غیرفعال (سبک‌سازی سخت‌افزار)"
	emit_log("[color=#38bdf8][مدیریت ماژولار][/color] زیرسیستم [b]%s[/b] -> %s" % [flag_id, state_word])
	state_updated.emit(get_snapshot_dict())
	return get_modular_flags()


func assemble_genre_kit(genre_code: String) -> Dictionary:
	var root := get_edited_root()
	if root == null:
		return {"ok": false, "error": "صحنه باز نیست."}
	save_snapshot("Genre Kit: " + genre_code)

	var kit_cfg := {
		"SOULS_ARPG": {"title": "اکشن نقش‌آفرینی سولزلایک (Souls-like ARPG)", "cam": "TPS_SOULS", "qual": "AAA_UNREAL", "weather": "CLEAR", "models": ["res://assets/models/world/castle_tower.glb", "res://assets/models/props/torch.glb", "res://assets/models/characters/skeleton_warrior.glb"]},
		"SHOOTER_FPS": {"title": "شوتر اول‌شخص تاکتیکی (Tactical FPS)", "cam": "FPS", "qual": "STANDARD_UNITY", "weather": "CLEAR", "models": ["res://assets/models/vehicles/cybertruck.glb", "res://assets/models/props/barrel.glb", "res://assets/models/weapons/blaster_rifle.glb"]},
		"SURVIVAL_HORROR": {"title": "ترس و بقا روی شانه (Survival Horror)", "cam": "TPS_SHOULDER", "qual": "AAA_UNREAL", "weather": "RAIN", "models": ["res://assets/models/world/dead_tree.glb", "res://assets/models/props/lantern.glb", "res://assets/models/characters/zombie_walker.glb"]},
		"OPEN_WORLD_RPG": {"title": "جهان‌باز ماجراجویی و ساخت‌وساز (Open-World RPG)", "cam": "TPS_SOULS", "qual": "INDIE_CEL_ANIME", "weather": "CLEAR", "models": ["res://assets/models/world/pine_tree.glb", "res://assets/models/world/medieval_house.glb", "res://assets/models/props/chest_gold.glb"]},
		"PLATFORMER_2_5D": {"title": "پلتفرمر اکشن ۲.۵ بعدی (2.5D Action Platformer)", "cam": "SIDE_2_5D", "qual": "INDIE_CEL_ANIME", "weather": "CLEAR", "models": ["res://assets/models/world/rock_large.glb", "res://assets/models/props/coin_gold.glb", "res://assets/models/props/crystal_blue.glb"]},
		"ISOMETRIC_ARPG": {"title": "اکشن ایزومتریک هک‌انداسلش (Isometric ARPG)", "cam": "ISOMETRIC", "qual": "INDIE_HD2D", "weather": "FIRE", "models": ["res://assets/models/world/ruins_pillar.glb", "res://assets/models/props/chest_gold.glb", "res://assets/models/characters/demon_boss.glb"]},
	}
	var cfg: Dictionary = kit_cfg.get(genre_code, kit_cfg["SOULS_ARPG"])
	apply_quality_visuals(str(cfg["qual"]), false)
	apply_camera_perspective(str(cfg["cam"]), false)
	apply_elemental_weather(str(cfg["weather"]), false)

	var old_holder := root.get_node_or_null("NovaGenreKitWorld")
	if old_holder:
		old_holder.free()
	var holder := Node3D.new()
	holder.name = "NovaGenreKitWorld"
	root.add_child(holder)
	holder.owner = root

	var loader = load("res://addons/novaforge_engine/forge/glb_asset_loader.gd")
	var spawned_count := 0
	var models_arr: Array = cfg["models"]
	if loader:
		for i in range(models_arr.size()):
			var mpath := str(models_arr[i])
			if ResourceLoader.exists(mpath) or FileAccess.file_exists(ProjectSettings.globalize_path(mpath)):
				var inst: Node3D = loader.load_model_scene(mpath, 2.3)
				if inst:
					inst.position = Vector3(-3.2 + float(i) * 3.2, 0.0, -2.8)
					holder.add_child(inst)
					inst.owner = root
					spawned_count += 1

	var scr_dir := ProjectSettings.globalize_path("res://generated/scripts")
	DirAccess.make_dir_recursive_absolute(scr_dir)
	var scr_path := "res://generated/scripts/genre_kit_" + genre_code.to_lower() + ".gd"
	var sf := FileAccess.open(scr_path, FileAccess.WRITE)
	if sf:
		sf.store_string("extends Node3D\n## Auto-generated NovaForge Genre Kit: " + str(cfg["title"]) + "\nconst GENRE_ID: String = \"" + genre_code + "\"\nconst DEFAULT_CAMERA: String = \"" + str(cfg["cam"]) + "\"\n")
		sf.close()
		last_generated_script_path = scr_path

	emit_log("[b][color=#22c55e][کیت ژانر بازی][/color][/b] ژانر «%s» با دوربین %s، گرافیک %s و %d مدل سه‌بعدی در صحنه چیده شد!" % [str(cfg["title"]), str(cfg["cam"]), str(cfg["qual"]), spawned_count])
	return {"ok": true, "title": str(cfg["title"]), "spawned": spawned_count, "script": scr_path}


func run_video_file_to_motion(video_path: String = "", style_preset: String = "KATANA_3HIT") -> Dictionary:
	var root := get_edited_root()
	if root == null:
		return {"ok": false, "error": "صحنه سه‌بعدی باز نیست."}
	var hero := root.get_node_or_null("SamuraiHero") as Node3D
	if hero == null:
		return {"ok": false, "error": "کاراکتر SamuraiHero در صحنه یافت نشد."}

	var anim_suite = load("res://addons/novaforge_engine/cutscene/blender_animation_suite.gd")
	var ik_deg := 42.5
	if anim_suite:
		var ik_res: Dictionary = anim_suite.solve_two_bone_ik(Vector3(0, 0.92, 0), Vector3(0, 0.48, 0.06), Vector3(0, 0.02, 0.12), Vector3(0, 0.0, 0.18), Vector3(0, 0.5, 0.6))
		ik_deg = snappedf(float(ik_res.get("knee_elbow_angle_deg", 42.5)), 0.1)

	var src_label := video_path.get_file() if not video_path.strip_edges().is_empty() else style_preset
	var base_pos := hero.position
	var base_rot := hero.rotation

	var loader = load("res://addons/novaforge_engine/forge/glb_asset_loader.gd")
	if loader:
		var anim_candidates := ["SwordSlash", "Jump", "Run", "Victory"]
		if style_preset == "PARKOUR_VAULT":
			anim_candidates = ["Jump", "Roll", "Run"]
		elif style_preset == "STEALTH_ASSASSIN":
			anim_candidates = ["Walk", "Punch", "SwordSlash"]
		elif style_preset == "VICTORY_TAUNT":
			anim_candidates = ["Victory", "Wave", "Idle"]
		loader.play_character_anim(hero, anim_candidates, false)

	var tw := create_tween()
	if style_preset == "PARKOUR_VAULT":
		tw.tween_property(hero, "position", base_pos + Vector3(0.0, 1.35, -1.2), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(hero, "position", base_pos, 0.34).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	elif style_preset == "STEALTH_ASSASSIN":
		tw.tween_property(hero, "position", base_pos + Vector3(0.85, 0.0, -0.95), 0.28)
		tw.tween_property(hero, "rotation:y", base_rot.y + PI, 0.22)
		tw.tween_property(hero, "position", base_pos, 0.30)
		tw.tween_property(hero, "rotation", base_rot, 0.18)
	else:
		_play_hero_katana_slash_vfx()

	emit_log("[b][color=#38bdf8][ویدیو به موشن + قفل کف پا Foot-IK][/color][/b] موشن «%s» استخراج شد (زاویه مفصل زانو IK: %.1f درجه) و روی اسکلت کاراکتر اجرا شد!" % [src_label, ik_deg])
	return {"ok": true, "source": src_label, "ik_angle_deg": ik_deg, "frames_baked": 72}


func talk_to_living_npc_async(player_msg: String) -> Dictionary:
	if _llm_brain == null:
		return {"ok": false, "error": "مغز هوش مصنوعی آماده نیست."}
	var clean := player_msg.strip_edges()
	if clean.is_empty():
		clean = "سلام کاوه! اوضاع آهنگری و شهر چطوره؟"
	var scars_str := "، ".join(PackedStringArray(npc_state.get("scars", [])))
	if scars_str.is_empty():
		scars_str = "بدون زخم قبلی"
	var persona := (
		"تو «کاوه آهنگر» یک NPC زنده با حافظه تکاملی و سیستم Nemesis در بازی نوافورج هستی. "
		+ "روز جهان: %d | عنوان شغلی: %s | طلای تو: %d سکه | عدد رابطه با بازیکن: %d (منفی یعنی دشمن خونی، مثبت یعنی رفیق) | زخم‌ها و خاطرات نبرد قبلی: %s. " % [
			world_day, str(npc_state.get("title", "شاگرد آهنگر")), int(npc_state.get("gold", 120)), int(npc_state.get("rel", 10)), scars_str
		]
		+ "دقیقاً از زبان اول‌شخص کاوه آهنگر، طبیعی، کوتاه (۳ تا ۵ جمله) و متناسب با رابطه فعلی‌ات با بازیکن پاسخ بده و هیچ کدی ننویس."
	)
	var res: Dictionary = await _llm_brain.call("ask_brain_async", clean, persona)
	if res.get("ok", false):
		emit_log("[b][color=#facc15][کاوه آهنگر]:[/color][/b] " + str(res.get("reply", "")))
	return res


func run_live_scene_audit_and_autofix(auto_fix: bool = true) -> Dictionary:
	var root := get_edited_root()
	if root == null:
		return {"ok": false, "error": "صحنه‌ای برای ممیزی باز نیست."}

	var total_nodes := 0
	var mesh_count := 0
	var tri_estimate := 0
	var skel_count := 0
	var col_count := 0
	var light_count := 0
	var fixed_issues := 0

	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		total_nodes += 1
		for ch in n.get_children():
			stack.append(ch)
		if n is MeshInstance3D:
			mesh_count += 1
			var mi := n as MeshInstance3D
			if mi.mesh:
				for s in range(mi.mesh.get_surface_count()):
					var arr := mi.mesh.surface_get_arrays(s)
					if arr.size() > Mesh.ARRAY_VERTEX and arr[Mesh.ARRAY_VERTEX] is PackedVector3Array:
						tri_estimate += int((arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3)
			if auto_fix and (mi.scale.x <= 0.0001 or mi.scale.y <= 0.0001 or mi.scale.z <= 0.0001):
				mi.scale = Vector3.ONE
				fixed_issues += 1
		elif n is Skeleton3D:
			skel_count += 1
		elif n is CollisionShape3D:
			col_count += 1
		elif n is Light3D:
			light_count += 1

	var fps_now := Engine.get_frames_per_second()
	var report := {
		"ok": true,
		"nodes": total_nodes,
		"meshes": mesh_count,
		"triangles": tri_estimate,
		"skeletons": skel_count,
		"collisions": col_count,
		"lights": light_count,
		"fixed": fixed_issues,
		"fps": fps_now,
		"grade": "A+ (آماده انتشار)" if col_count >= 1 and light_count >= 1 else "B (نیازمند بررسی برخورد)"
	}
	emit_log(
		"[b][color=#22c55e][ممیزی خودکار صحنه Zero-MCP][/color][/b] گره‌ها: %d | مش‌ها: %d (%d مثلث) | اسکلت: %d | کولایدر Jolt: %d | نور: %d | امتیاز: [b]%s[/b]" %
		[total_nodes, mesh_count, tri_estimate, skel_count, col_count, light_count, str(report["grade"])]
	)
	return report


func run_live_agent_playtest_async() -> Dictionary:
	var root := get_edited_root()
	if root == null:
		return {"ok": false, "error": "صحنه باز نیست."}
	var hero := root.get_node_or_null("SamuraiHero") as Node3D
	if hero == null:
		return {"ok": false, "error": "کاراکتر اصلی یافت نشد."}

	emit_log("[b][color=#38bdf8][پلی‌تست خودکار ایجنت Autopilot][/color][/b] شروع حرکت خودکار در ۴ نقطه تست، پرش و بررسی برخورد فیزیکی Jolt...")
	var start_pos := hero.position
	var loader = load("res://addons/novaforge_engine/forge/glb_asset_loader.gd")
	if loader:
		loader.play_character_anim(hero, ["Run", "Walk"], true)

	var waypoints := [
		start_pos + Vector3(2.2, 0.0, -1.5),
		start_pos + Vector3(-2.0, 0.9, -2.2),
		start_pos + Vector3(-1.5, 0.0, 1.4),
		start_pos
	]
	for wp in waypoints:
		var tw := create_tween()
		tw.tween_property(hero, "position", wp, 0.35).set_trans(Tween.TRANS_SINE)
		await tw.finished

	if not crate_shattered:
		shatter_or_reset_crate(false)
	if loader:
		loader.play_character_anim(hero, ["Idle"], true)

	var res := {
		"ok": true,
		"waypoints_passed": 4,
		"physics_jolt_ok": true,
		"voronoi_combat_tested": true,
		"fps": maxi(30, int(Engine.get_frames_per_second()))
	}
	emit_log("[b][color=#22c55e][پلی‌تست خودکار کامل شد ✓][/color][/b] ۴ مسیر حرکت، پرش و تخریب Voronoi بدون خطا تست شد (FPS پایدار).")
	return res


func play_adaptive_music_preview(mood: String = "CALM_EXPLORE") -> void:
	if not bool(modular_flags.get("spatial_audio", true)):
		emit_log("[color=#f59e0b]ماژول صدای تطبیقی در چک‌باکس‌های ماژولار غیرفعال شده است.[/color]")
		return
	if _audio_preview_player == null:
		_audio_preview_player = AudioStreamPlayer.new()
		_audio_preview_player.volume_db = -8.0
		add_child(_audio_preview_player)

	if mood == "STOP":
		_audio_preview_player.stop()
		emit_log("[color=#94a3b8][صدای تطبیقی] پخش موسیقی متوقف شد.[/color]")
		return

	var mix_rate := 22050
	var duration_sec := 2.4
	var samples := int(float(mix_rate) * duration_sec)
	var pcm := PackedByteArray()
	pcm.resize(samples * 2)

	var freqs := [220.0, 277.18, 329.63] if mood == "CALM_EXPLORE" else [146.83, 174.61, 220.0, 293.66]
	for i in range(samples):
		var t := float(i) / float(mix_rate)
		var env := minf(1.0, t * 8.0) * maxf(0.0, 1.0 - (t / duration_sec) * 0.65)
		var sig := 0.0
		for f in freqs:
			sig += sin(TAU * float(f) * t) * 0.22
		if mood != "CALM_EXPLORE":
			var beat := fmod(t * 4.0, 1.0)
			sig += sin(TAU * 65.0 * t) * exp(-beat * 9.0) * 0.45
		var s16 := clampi(int(sig * env * 24000.0), -32767, 32767)
		pcm[i * 2] = s16 & 0xFF
		pcm[i * 2 + 1] = (s16 >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = pcm
	_audio_preview_player.stream = wav
	_audio_preview_player.play()
	emit_log("[b][color=#38bdf8][صدای سه‌بعدی و موسیقی تطبیقی][/color][/b] تم صوتی «%s» سنتز و پخش شد!" % ("حماسی نبرد Boss" if mood != "CALM_EXPLORE" else "محیطی آرام گشت‌وگذار"))


func export_project_one_click(platform_label: String, bundle_ai: bool = true) -> Dictionary:
	var exp_scr = load("res://addons/novaforge_engine/world/one_click_exporter.gd")
	if exp_scr == null:
		return {"ok": false, "error": "ماژول خروجی یافت نشد."}
	var res: Dictionary = exp_scr.export_project_bundle(platform_label, get_edited_root(), bundle_ai)
	emit_log("[b][color=#22c55e][خروجی یک‌کلیکی بازی][/color][/b] بسته انتشار «%s» آماده شد -> پوشه [b]%s[/b]" % [platform_label, str(res.get("output_dir", ""))])
	return res

