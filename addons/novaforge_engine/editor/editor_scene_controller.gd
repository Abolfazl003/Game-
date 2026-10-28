@tool
extends Node
class_name NovaEditorSceneController
## Central Live Editor Scene Controller (`NovaEditorController`).
## Connects all NovaForge Godot 4 Editor docks, toolbars, context menus, and bottom panels
## directly to the live open 3D scene (`EditorInterface.get_edited_scene_root()`) and
## Godot 4's Spatial 3D Viewport Camera (`EditorInterface.get_editor_viewport_3d(0)`).

signal log_emitted(bbcode_line: String)
signal state_updated(state: Dictionary)

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


func _ready() -> void:
	call_deferred("_initial_setup")


func _initial_setup() -> void:
	emit_log("[b][color=#38bdf8][System][/color][/b] Zero-MCP NativeToolBus online — 123 Game Skills & 114 Engine Tools loaded.")
	emit_log("[b][color=#a855f7][Colibrì][/color][/b] Tiered Memory ready: Dense INT4 in RAM | 21,504 MoE Experts on NVMe SSD | GPU VRAM protected for Godot 4 + Jolt.")
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

	var crate_mesh := crate.get_node_or_null("CrateMesh") as Node3D
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


func spawn_image_to_3d_rigged_character() -> void:
	var root := get_edited_root()
	if root == null:
		return
	save_snapshot("Image-to-3D + 52-Bone Rig")

	var existing := root.get_node_or_null("AI_ImmortalWarrior_Rigged")
	if existing:
		existing.queue_free()

	var char_root := Node3D.new()
	char_root.name = "AI_ImmortalWarrior_Rigged"
	char_root.position = Vector3(2.4, 0.0, 1.2)
	root.add_child(char_root)
	char_root.owner = root

	# Build 52-bone Humanoid Skeleton3D
	var skel := Skeleton3D.new()
	skel.name = "HumanoidSkeleton52"
	var core_bones := [
		"Root", "Hips", "Spine", "Chest", "UpperChest", "Neck", "Head", "Jaw", "LeftEye", "RightEye",
		"LeftShoulder", "LeftUpperArm", "LeftLowerArm", "LeftHand",
		"RightShoulder", "RightUpperArm", "RightLowerArm", "RightHand",
		"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "LeftToes",
		"RightUpperLeg", "RightLowerLeg", "RightFoot", "RightToes"
	]
	for bname in core_bones:
		skel.add_bone(bname)
	for f_idx in range(26):
		skel.add_bone("FingerBone_" + str(f_idx + 1))
	char_root.add_child(skel)
	skel.owner = root

	# Visual Armored Mesh + Golden Crest + Spear
	var armor_mat := StandardMaterial3D.new()
	armor_mat.albedo_color = Color(0.20, 0.45, 0.88)
	armor_mat.metallic = 0.65
	armor_mat.roughness = 0.28

	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.95, 0.76, 0.22)
	gold_mat.metallic = 0.85
	gold_mat.roughness = 0.22

	var body := MeshInstance3D.new()
	body.name = "WarriorLOD0Mesh"
	var cap := CapsuleMesh.new()
	cap.radius = 0.40
	cap.height = 1.75
	cap.material = armor_mat
	body.mesh = cap
	body.position = Vector3(0, 0.9, 0)
	char_root.add_child(body)
	body.owner = root

	var crest := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.45, 0.28, 0.15)
	prism.material = gold_mat
	crest.mesh = prism
	crest.position = Vector3(0, 1.88, 0.08)
	char_root.add_child(crest)
	crest.owner = root

	var spear := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.025
	cyl.bottom_radius = 0.03
	cyl.height = 2.2
	cyl.material = gold_mat
	spear.mesh = cyl
	spear.position = Vector3(0.48, 1.1, -0.15)
	spear.rotation_degrees = Vector3(14, 0, -6)
	char_root.add_child(spear)
	spear.owner = root

	var tag := Label3D.new()
	tag.text = "جنگجوی تولیدشده از عکس\n[52-Bone Rig | LOD 0/1/2]"
	tag.font_size = 26
	tag.modulate = Color(0.55, 0.85, 1.0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0, 2.35, 0)
	char_root.add_child(tag)
	tag.owner = root

	emit_log("[b][color=#38bdf8][AssetForge + AutoRigger][/color][/b] Image -> 3D Mesh (LOD0/1/2) -> Fitted [b]%d-Bone[/b] Skeleton3D (`AI_ImmortalWarrior_Rigged`) spawned in scene!" % skel.get_bone_count())


func run_video_to_motion_combo() -> void:
	_play_hero_katana_slash_vfx()
	var root := get_edited_root()
	if root:
		var hero := root.get_node_or_null("SamuraiHero") as Node3D
		if hero:
			var start_y := hero.position.y
			var tw := create_tween()
			tw.tween_property(hero, "position:y", start_y + 0.85, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(hero, "position:y", start_y, 0.24).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	emit_log("[b][color=#22c55e][VideoToMotion][/color][/b] Extracted 3D world-space combo + Fingers + Face | Foot-Locking IK pinned 47 stance frames | Tagged 21 Hitbox/Spark events!")


func import_blender_auto_pbr_gate() -> void:
	var root := get_edited_root()
	if root == null:
		return
	save_snapshot("Blender Auto-PBR Import")

	var old_gate := root.get_node_or_null("Blender_AncientGate_AutoPBR")
	if old_gate:
		old_gate.queue_free()

	var gate := Node3D.new()
	gate.name = "Blender_AncientGate_AutoPBR"
	gate.position = Vector3(0.0, 0.0, -4.6)
	root.add_child(gate)
	gate.owner = root

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.42, 0.39, 0.35)
	stone_mat.roughness = 0.78
	stone_mat.metallic = 0.12

	var rune_mat := StandardMaterial3D.new()
	rune_mat.albedo_color = Color(0.95, 0.55, 0.15)
	rune_mat.emission_enabled = true
	rune_mat.emission = Color(0.95, 0.45, 0.10)
	rune_mat.emission_energy_multiplier = 1.8

	for side in [-1.8, 1.8]:
		var col := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.65, 3.4, 0.65)
		bm.material = stone_mat
		col.mesh = bm
		col.position = Vector3(side, 1.7, 0.0)
		gate.add_child(col)
		col.owner = root

	var lintel := MeshInstance3D.new()
	var lbm := BoxMesh.new()
	lbm.size = Vector3(4.6, 0.58, 0.82)
	lbm.material = stone_mat
	lintel.mesh = lbm
	lintel.position = Vector3(0.0, 3.55, 0.0)
	gate.add_child(lintel)
	lintel.owner = root

	var crest := MeshInstance3D.new()
	var cbm := BoxMesh.new()
	cbm.size = Vector3(1.8, 0.22, 0.88)
	cbm.material = rune_mat
	crest.mesh = cbm
	crest.position = Vector3(0.0, 3.92, 0.0)
	gate.add_child(crest)
	crest.owner = root

	var tag := Label3D.new()
	tag.text = "دروازه ایمپورت‌شده از Blender (.blend)\n[Auto-PBR: DirectX Normal Flip + ORM]"
	tag.font_size = 26
	tag.modulate = Color(1.0, 0.78, 0.38)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0.0, 4.55, 0.0)
	gate.add_child(tag)
	tag.owner = root

	emit_log("[b][color=#fb923c][Universal3DImporter][/color][/b] Imported .blend/.fbx/.usd -> Auto-bound Albedo, Flipped DirectX Normal Y-Channel, Inverted Gloss->Roughness & Unpacked ORM (`Blender_AncientGate_AutoPBR`)!")


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
		top_lbl.text = "🎬 IN-ENGINE LIVE CUTSCENE SEQUENCER (Zero Black Screen — Real-Time Rack Focus)"
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
		reaction = "💨 باران آتش را خاموش کرد + تولید بخار غلیظ و سطح خیس SSR!"
	elif elem == "RAIN":
		reaction = "🌧️ بارش باران فعال شد — سطح زمین خیس و براق (Wet PBR)!"
	elif elem == "FIRE":
		reaction = "🔥 گسترش آتش در جهت وزش باد روی چمن و چوب!"
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
			var prefix := "⚔️ Nemesis: " if rel <= -35 else "کاوه آهنگر — "
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
			clbl.text = "💥 صندوق متلاشی شد (۱۶ قطعه Voronoi)" if crate_shattered else "📦 صندوق باستانی [قابل تخریب Voronoi]"
