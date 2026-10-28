extends CharacterBody3D
class_name PlayableSamuraiController3D
## Out-of-the-box Playable Character Controller (`WASD` Move, `Space` Jump, `Shift` Dodge,
## `Left Click` 3-Hit Katana Combo w/ Voronoi Fracture Hit Detection, `E` Smart Interact,
## and `1..5` Live Camera Perspective & Quality Tier Switching — Cold-Boot Safe).

@export var move_speed: float = 6.2
@export var dodge_impulse: float = 13.5
@export var jump_velocity: float = 5.4
@export var melee_range: float = 2.8
@export var melee_damage: float = 35.0

var combo_step: int = 0
var _combo_reset_timer: float = 0.0
var _dodge_timer: float = 0.0
var stamina: float = 100.0


func _physics_process(delta: float) -> void:
	var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	if not is_on_floor():
		velocity.y -= gravity * delta

	if _combo_reset_timer > 0.0:
		_combo_reset_timer -= delta
		if _combo_reset_timer <= 0.0:
			combo_step = 0

	if _dodge_timer > 0.0:
		_dodge_timer -= delta
	else:
		stamina = minf(100.0, stamina + 14.0 * delta)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	if Input.is_action_just_pressed("dodge") and stamina >= 20.0 and _dodge_timer <= 0.0:
		stamina -= 20.0
		_dodge_timer = 0.28
		var dodge_dir := direction if direction.length() > 0.1 else -global_transform.basis.z
		velocity.x = dodge_dir.x * dodge_impulse
		velocity.z = dodge_dir.z * dodge_impulse
	elif _dodge_timer <= 0.0:
		if direction.length() > 0.05:
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, move_speed * 8.0 * delta)

	move_and_slide()

	if Input.is_action_just_pressed("attack_light"):
		_perform_melee_combo()

	if Input.is_action_just_pressed("interact"):
		_perform_smart_interact()


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
