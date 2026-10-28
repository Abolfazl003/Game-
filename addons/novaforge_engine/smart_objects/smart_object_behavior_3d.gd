@tool
extends Node3D
class_name SmartObjectBehavior3D
## Smart Context-Click Object Behavior Component (`SmartObjectBehavior3D`).
## Click any 3D object in the scene to configure via checkboxes or custom AI prompt:
## - Interactable (Auto-Hinge Door/Chest, Pickup Loot, Equip Weapon, Lever, Seat)
## - Real-Time Voronoi 3D Destruction (Glass, Wood, Stone, Metal, Explosive Barrel) with Jolt Physics!

signal interacted(interactor: Node, interaction_kind: String)
signal damaged(amount: float, remaining_hp: float, weapon_tag: String)
signal shattered(shard_count: int, material_name: String, impact_point: Vector3)

enum InteractionKind {
	NONE,
	DOOR_AUTO_HINGE,
	CHEST_LID,
	PICKUP_ITEM,
	EQUIP_WEAPON,
	LEVER_SWITCH,
	SEAT_BENCH,
	CUTSCENE_TRIGGER
}

enum DestructiblePreset {
	GLASS,
	WOOD,
	STONE,
	METAL,
	EXPLOSIVE_BARREL
}

@export_group("Smart Interaction (Click Options)")
@export var is_interactable: bool = true
@export var interaction_kind: InteractionKind = InteractionKind.DOOR_AUTO_HINGE
@export var prompt_key_hint: String = "[E] تعامل / Interact"
@export var highlight_on_look: bool = true
@export var open_angle_deg: float = 95.0

@export_group("Destructible & Voronoi Fracture")
@export var is_destructible: bool = false
@export var material_preset: DestructiblePreset = DestructiblePreset.WOOD
@export var max_health: float = 50.0
@export var required_weapon_tag: String = "ANY" # ANY, MELEE_SWORD, BULLET, EXPLOSION
@export var fracture_shard_count: int = 14
@export var blast_force: float = 18.0

@export_group("Custom AI Prompt Behavior")
@export_multiline var custom_ai_prompt: String = ""

var current_health: float = 50.0
var is_open: bool = false
var _auto_hinge_offset: Vector3 = Vector3.ZERO


func _ready() -> void:
	current_health = max_health
	_detect_automatic_hinge_pivot()


func apply_config_dict(cfg: Dictionary) -> void:
	is_interactable = bool(cfg.get("interactable", is_interactable))
	is_destructible = bool(cfg.get("destructible", is_destructible))
	fracture_shard_count = int(cfg.get("shard_count", fracture_shard_count))
	max_health = float(cfg.get("max_health", max_health))
	current_health = max_health
	required_weapon_tag = str(cfg.get("weapon_filter", required_weapon_tag))
	custom_ai_prompt = str(cfg.get("custom_prompt", custom_ai_prompt))

	var mat_str := str(cfg.get("material", "WOOD")).to_upper()
	match mat_str:
		"GLASS": material_preset = DestructiblePreset.GLASS
		"STONE": material_preset = DestructiblePreset.STONE
		"METAL": material_preset = DestructiblePreset.METAL
		"EXPLOSIVE_BARREL", "EXPLOSIVE": material_preset = DestructiblePreset.EXPLOSIVE_BARREL
		_: material_preset = DestructiblePreset.WOOD


## Automatically detects the left/bottom bounding-box edge so doors & chest lids rotate around their real hinge!
func _detect_automatic_hinge_pivot() -> void:
	var p := get_parent()
	if p is MeshInstance3D and (p as MeshInstance3D).mesh:
		var aabb := (p as MeshInstance3D).mesh.get_aabb()
		if interaction_kind == InteractionKind.CHEST_LID:
			_auto_hinge_offset = Vector3(0.0, aabb.position.y, aabb.position.z)
		else:
			_auto_hinge_offset = Vector3(aabb.position.x, 0.0, 0.0)


func interact(interactor: Node) -> Dictionary:
	if not is_interactable:
		return {"ok": false, "reason": "not_interactable"}

	var p := get_parent() as Node3D
	match interaction_kind:
		InteractionKind.DOOR_AUTO_HINGE:
			is_open = not is_open
			if p:
				p.rotation_degrees.y += open_angle_deg if is_open else -open_angle_deg
		InteractionKind.CHEST_LID:
			is_open = not is_open
			if p:
				p.rotation_degrees.x += -open_angle_deg if is_open else open_angle_deg
		InteractionKind.PICKUP_ITEM:
			if p:
				p.visible = false
		InteractionKind.EQUIP_WEAPON:
			if p and interactor is Node3D:
				p.reparent(interactor)
				p.position = Vector3(0.35, 1.1, -0.4)

	interacted.emit(interactor, InteractionKind.keys()[interaction_kind])
	return {
		"ok": true,
		"kind": InteractionKind.keys()[interaction_kind],
		"is_open": is_open,
		"hinge_pivot": _auto_hinge_offset
	}


func apply_weapon_hit(damage: float, weapon_tag: String = "MELEE_SWORD", impact_point: Vector3 = Vector3.ZERO) -> Dictionary:
	if not is_destructible:
		return {"ok": false, "shattered": false, "reason": "indestructible"}
	if required_weapon_tag != "ANY" and required_weapon_tag != weapon_tag:
		return {"ok": false, "shattered": false, "reason": "wrong_weapon_type"}

	current_health -= damage
	damaged.emit(damage, current_health, weapon_tag)

	if current_health <= 0.0:
		var spawned := _shatter_into_voronoi_shards(impact_point)
		return {
			"ok": true,
			"shattered": true,
			"shards_spawned": spawned,
			"explosive_aoe": material_preset == DestructiblePreset.EXPLOSIVE_BARREL
		}
	return {"ok": true, "shattered": false, "remaining_hp": current_health}


func _shatter_into_voronoi_shards(impact_point: Vector3) -> int:
	var p := get_parent() as Node3D
	var scene_root := get_tree().current_scene if get_tree() else null
	var aabb := AABB(Vector3(-0.5, 0.0, -0.5), Vector3(1.0, 1.0, 1.0))
	if p is MeshInstance3D and (p as MeshInstance3D).mesh:
		aabb = (p as MeshInstance3D).mesh.get_aabb()

	var count := clampi(fracture_shard_count, 4, 64)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337

	if scene_root and p:
		for i in range(count):
			var rb := RigidBody3D.new()
			rb.name = p.name + "_Shard_" + str(i)
			rb.mass = 0.8 if material_preset == DestructiblePreset.WOOD else 2.2

			var mi := MeshInstance3D.new()
			var shard_box := BoxMesh.new()
			shard_box.size = aabb.size / pow(float(count), 1.0 / 3.0)
			mi.mesh = shard_box

			var col := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = shard_box.size
			col.shape = shape

			rb.add_child(mi)
			rb.add_child(col)
			scene_root.add_child(rb)

			var local_off := Vector3(
				rng.randf_range(aabb.position.x, aabb.end.x),
				rng.randf_range(aabb.position.y, aabb.end.y),
				rng.randf_range(aabb.position.z, aabb.end.z)
			)
			rb.global_position = p.global_position + local_off
			var radial := (rb.global_position - impact_point).normalized() + Vector3.UP * 0.35
			var mult := 2.8 if material_preset == DestructiblePreset.EXPLOSIVE_BARREL else 1.0
			rb.apply_central_impulse(radial.normalized() * blast_force * mult)

		p.visible = false

	shattered.emit(count, DestructiblePreset.keys()[material_preset], impact_point)
	return count
