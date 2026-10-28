@tool
extends Node3D
class_name PerspectiveCameraRig3D
## Runtime-Switchable All-Perspective Camera Rig (`PerspectiveCameraRig3D`).
## Supports instant mid-gameplay transitions across:
## - FPS (True First-Person + ADS zoom)
## - TPS_SHOULDER (Over-the-Shoulder RE4 / God of War)
## - TPS_SOULS (360 Orbit + Souls-like Target Lock-On)
## - SIDE_2_5D (3D World on 2D Side-Scrolling / Spline Plane)
## - HD_2D (Diorama Tilt-Shift Pixel-in-3D)
## - ISOMETRIC (Top-Down / Diablo / RTS Zoom & Pan)
## - PURE_2D (Orthographic 2D Plane)
## - FIXED_CINEMATIC (Horror / Fixed Room Camera Anchor)

signal perspective_changed(new_mode: String)

enum PerspectiveMode {
	FPS,
	TPS_SHOULDER,
	TPS_SOULS,
	SIDE_2_5D,
	HD_2D,
	ISOMETRIC,
	PURE_2D,
	FIXED_CINEMATIC
}

@export var current_mode: PerspectiveMode = PerspectiveMode.TPS_SOULS
@export var follow_target: Node3D
@export var lock_on_target: Node3D
@export var smooth_speed: float = 10.0

var spring_arm: SpringArm3D
var camera: Camera3D


func _ready() -> void:
	_ensure_rig_nodes()
	apply_perspective(current_mode)


func _ensure_rig_nodes() -> void:
	spring_arm = get_node_or_null("SpringArm3D") as SpringArm3D
	if spring_arm == null:
		spring_arm = SpringArm3D.new()
		spring_arm.name = "SpringArm3D"
		add_child(spring_arm)
	camera = spring_arm.get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		spring_arm.add_child(camera)


func set_perspective_by_name(mode_name: String) -> Dictionary:
	var key := mode_name.to_upper()
	if not PerspectiveMode.keys().has(key):
		return {"ok": false, "error": "Unknown perspective: " + mode_name}
	apply_perspective(PerspectiveMode[key])
	return {"ok": true, "perspective": key}


func apply_perspective(mode: PerspectiveMode) -> void:
	_ensure_rig_nodes()
	current_mode = mode

	match mode:
		PerspectiveMode.FPS:
			camera.projection = Camera3D.PROJECTION_PERSPECTIVE
			camera.fov = 78.0
			spring_arm.spring_length = 0.0
			spring_arm.position = Vector3(0.0, 1.68, 0.0)
			spring_arm.rotation_degrees = Vector3.ZERO

		PerspectiveMode.TPS_SHOULDER:
			camera.projection = Camera3D.PROJECTION_PERSPECTIVE
			camera.fov = 62.0
			spring_arm.spring_length = 2.35
			spring_arm.position = Vector3(0.55, 1.62, 0.0)
			spring_arm.rotation_degrees = Vector3(-8.0, 0.0, 0.0)

		PerspectiveMode.TPS_SOULS:
			camera.projection = Camera3D.PROJECTION_PERSPECTIVE
			camera.fov = 68.0
			spring_arm.spring_length = 4.2
			spring_arm.position = Vector3(0.0, 1.75, 0.0)
			spring_arm.rotation_degrees = Vector3(-14.0, 0.0, 0.0)

		PerspectiveMode.SIDE_2_5D:
			camera.projection = Camera3D.PROJECTION_PERSPECTIVE
			camera.fov = 50.0
			spring_arm.spring_length = 9.5
			spring_arm.position = Vector3(0.0, 2.2, 0.0)
			spring_arm.rotation_degrees = Vector3(-6.0, 0.0, 0.0)

		PerspectiveMode.HD_2D:
			camera.projection = Camera3D.PROJECTION_PERSPECTIVE
			camera.fov = 38.0
			spring_arm.spring_length = 12.0
			spring_arm.position = Vector3(0.0, 4.0, 0.0)
			spring_arm.rotation_degrees = Vector3(-28.0, 0.0, 0.0)

		PerspectiveMode.ISOMETRIC:
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = 14.0
			spring_arm.spring_length = 18.0
			spring_arm.position = Vector3.ZERO
			spring_arm.rotation_degrees = Vector3(-35.264, 45.0, 0.0)

		PerspectiveMode.PURE_2D:
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = 11.0
			spring_arm.spring_length = 15.0
			spring_arm.rotation_degrees = Vector3.ZERO

		PerspectiveMode.FIXED_CINEMATIC:
			camera.projection = Camera3D.PROJECTION_PERSPECTIVE
			camera.fov = 48.0
			spring_arm.spring_length = 0.0

	perspective_changed.emit(PerspectiveMode.keys()[current_mode])


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or follow_target == null:
		return
	if current_mode == PerspectiveMode.FIXED_CINEMATIC:
		camera.look_at(follow_target.global_position + Vector3.UP * 1.2, Vector3.UP)
		return

	var target_pos := follow_target.global_position
	if current_mode == PerspectiveMode.SIDE_2_5D:
		# Constrain player depth plane for 2.5D gameplay
		follow_target.global_position.z = lerpf(follow_target.global_position.z, 0.0, delta * 12.0)

	global_position = global_position.lerp(target_pos, clampf(delta * smooth_speed, 0.0, 1.0))

	if current_mode == PerspectiveMode.TPS_SOULS and lock_on_target != null:
		var mid := (follow_target.global_position + lock_on_target.global_position) * 0.5
		spring_arm.look_at(mid + Vector3.UP * 1.1, Vector3.UP)
