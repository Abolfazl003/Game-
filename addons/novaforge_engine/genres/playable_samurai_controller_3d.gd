extends CharacterBody3D
class_name PlayableSamuraiController3D
## Playable 3D Character Controller driving REAL skeletal `.glb` / Auto-Rigged `AnimationPlayer`
## (`Idle`, `Walk`, `Run`, `Jump`, `Roll`, `SwordSlash`) + Voronoi Hit Detection + Smart Interact.

const LoaderScript := preload("res://addons/novaforge_engine/forge/glb_asset_loader.gd")

@export var move_speed: float = 6.2
@export var dodge_impulse: float = 13.5
@export var jump_velocity: float = 5.4
@export var melee_range: float = 2.9
@export var melee_damage: float = 35.0

var combo_step: int = 0
var _combo_reset_timer: float = 0.0
var _dodge_timer: float = 0.0
var _attack_anim_lock: float = 0.0
var _current_anim_state: String = ""
var stamina: float = 100.0


func _physics_process(delta: float) -> void:
	var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	if not is_on_floor():
		velocity.y -= gravity * delta

	if _combo_reset_timer > 0.0:
		_combo_reset_timer -= delta
		if _combo_reset_timer <= 0.0:
			combo_step = 0

	if _attack_anim_lock > 0.0:
		_attack_anim_lock -= delta

	if _dodge_timer > 0.0:
		_dodge_timer -= delta
	else:
		stamina = minf(100.0, stamina + 14.0 * delta)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		_set_hero_anim("Jump", false)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := Vector3(input_dir.x, 0.0, input_dir.y).normalized()

	if Input.is_action_just_pressed("dodge") and stamina >= 20.0 and _dodge_timer <= 0.0:
		stamina -= 20.0
		_dodge_timer = 0.34
		var dodge_dir := direction if direction.length() > 0.1 else Vector3.FORWARD
		velocity.x = dodge_dir.x * dodge_impulse
		velocity.z = dodge_dir.z * dodge_impulse
		_set_hero_anim("Roll", false)
	elif _dodge_timer <= 0.0:
		if direction.length() > 0.05:
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
			var model_node := _get_visual_model()
			if model_node:
				model_node.rotation.y = lerp_angle(model_node.rotation.y, atan2(direction.x, direction.z), 12.0 * delta)
			if is_on_floor() and _attack_anim_lock <= 0.0:
				_set_hero_anim("Run", true)
		else:
			velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, move_speed * 8.0 * delta)
			if is_on_floor() and _attack_anim_lock <= 0.0:
				_set_hero_anim("Idle", true)

	move_and_slide()

	if Input.is_action_just_pressed("attack_light"):
		_perform_melee_combo()

	if Input.is_action_just_pressed("interact"):
		_perform_smart_interact()


func _get_visual_model() -> Node3D:
	for child in get_children():
		if child is Node3D and not (child is CollisionShape3D) and not (child is Label3D):
			return child as Node3D
	return null


func _set_hero_anim(anim_key: String, loop_flag: bool) -> void:
	if _current_anim_state == anim_key and loop_flag:
		return
	var m := _get_visual_model()
	if m:
		LoaderScript.play_character_anim(m, [anim_key], loop_flag)
		_current_anim_state = anim_key


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var rig := get_parent().get_node_or_null("PerspectiveCameraRig3D")
	match (event as InputEventKey).keycode:
		KEY_1:
			if rig and rig.has_method("set_perspective_by_name"): rig.call("set_perspective_by_name", "TPS_SOULS")
		KEY_2:
			if rig and rig.has_method("set_perspective_by_name"): rig.call("set_perspective_by_name", "FPS")
		KEY_3:
			if rig and rig.has_method("set_perspective_by_name"): rig.call("set_perspective_by_name", "SIDE_2_5D")
		KEY_4:
			if rig and rig.has_method("set_perspective_by_name"): rig.call("set_perspective_by_name", "ISOMETRIC")
		KEY_5:
			if get_tree().root.has_node("NovaQuality"):
				var q = get_tree().root.get_node("NovaQuality")
				var cur := str(q.get("current_tier"))
				var next_t := "INDIE_CEL_ANIME" if cur == "AAA_UNREAL" else ("INDIE_PSX_RETRO" if cur == "INDIE_CEL_ANIME" else "AAA_UNREAL")
				q.call("apply_quality_tier", next_t)


func _perform_melee_combo() -> void:
	if stamina < 12.0:
		return
	stamina -= 12.0
	combo_step = (combo_step % 3) + 1
	_combo_reset_timer = 1.15
	_attack_anim_lock = 0.55
	_current_anim_state = ""
	_set_hero_anim("SwordSlash", false)

	var dmg := melee_damage * (1.45 if combo_step == 3 else 1.0)
	var root := get_tree().current_scene
	if root == null:
		return
	for node in root.get_children():
		if node is Node3D and node != self:
			var dist := global_position.distance_to((node as Node3D).global_position)
			if dist <= melee_range:
				var smart := node.get_node_or_null("SmartObjectBehavior3D")
				if smart and smart.has_method("apply_weapon_hit"):
					smart.call("apply_weapon_hit", dmg, "MELEE_SWORD", global_position)
				var npc := node.get_node_or_null("LivingNPCBrain3D")
				if npc and npc.has_method("record_player_interaction"):
					npc.call("record_player_interaction", "attacked_and_escaped", "Katana_Combo_" + str(combo_step))


func _perform_smart_interact() -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	for node in root.get_children():
		if node is Node3D and node != self:
			if global_position.distance_to((node as Node3D).global_position) <= 3.0:
				var smart := node.get_node_or_null("SmartObjectBehavior3D")
				if smart and smart.has_method("interact"):
					smart.call("interact", self)
				var npc := node.get_node_or_null("LivingNPCBrain3D")
				if npc and npc.has_method("record_player_interaction"):
					npc.call("record_player_interaction", "traded_fairly")
					npc.call("advance_life_chapter", 1)
