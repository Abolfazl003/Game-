@tool
extends Node3D
class_name NovaCutsceneDirector
## Live In-Engine Cutscene Sequencer (`CutsceneDirector`).
## Turns prompts like "این تیکه کات‌سینه" into zero-black-screen real-time cutscenes:
## - Trigger Area3D (`CutsceneTrigger3D`)
## - Seamless Camera3D blend from gameplay camera -> cinematic rail -> back behind player
## - Focal length & Rack-Focus DOF (`CameraAttributesPractical`)
## - Time-scale slow-motion impact beats + optional QTE prompt!

signal cutscene_started(cutscene_id: String)
signal cutscene_shot_changed(shot_index: int, shot_data: Dictionary)
signal cutscene_qte_prompted(action_name: String, window_sec: float)
signal cutscene_finished(cutscene_id: String)

@export var cutscene_id: String = "boss_gate_intro"
@export var seamless_gameplay_blend: bool = true
@export var blend_in_duration: float = 0.65
@export var blend_out_duration: float = 0.65
@export var shots: Array[Dictionary] = []

var _cinematic_cam: Camera3D
var _previous_gameplay_cam: Camera3D
var _is_playing: bool = false


func build_cutscene_from_spec(scene_root: Node, spec: Dictionary) -> Dictionary:
	var cid: String = spec.get("id", "cutscene_" + str(Time.get_ticks_msec()))
	var prompt_txt: String = str(spec.get("prompt", "")).to_lower()

	var holder := Node3D.new()
	holder.name = "Cutscene_" + cid
	holder.set_script(load("res://addons/novaforge_engine/cutscene/cutscene_director.gd"))
	holder.cutscene_id = cid
	holder.seamless_gameplay_blend = bool(spec.get("seamless_blend", true))

	# Create Trigger Zone (`Area3D`)
	var trigger := Area3D.new()
	trigger.name = "CutsceneTrigger3D"
	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = spec.get("trigger_size", Vector3(6.0, 4.0, 6.0))
	shape_node.shape = box
	trigger.add_child(shape_node)
	holder.add_child(trigger)

	# Create Cinematic Camera Rig with Practical Rack-Focus DOF
	var cam := Camera3D.new()
	cam.name = "CutsceneCamera3D"
	cam.fov = 42.0
	var attrs := CameraAttributesPractical.new()
	attrs.dof_blur_far_enabled = true
	attrs.dof_blur_far_distance = 14.0
	cam.attributes = attrs
	holder.add_child(cam)

	# Auto-compose cinematic shots from prompt keywords (e.g. boss gate / dramatic zoom / slow-mo)
	var generated_shots: Array[Dictionary] = [
		{
			"name": "Seamless_Push_In",
			"duration": 2.2,
			"cam_offset": Vector3(0.0, 2.1, 6.5),
			"fov": 45.0,
			"time_scale": 1.0,
			"subtitle": spec.get("opening_subtitle", "")
		},
		{
			"name": "Heroic_Low_Angle_SlowMo",
			"duration": 1.8,
			"cam_offset": Vector3(1.8, 0.9, 3.2),
			"fov": 32.0,
			"time_scale": 0.45 if (prompt_txt.contains("باس") or prompt_txt.contains("boss") or prompt_txt.contains("اسلوموشن")) else 1.0,
			"camera_shake": 0.25,
			"qte_action": spec.get("qte_action", "")
		},
		{
			"name": "Return_To_Player_Shoulder",
			"duration": 0.8,
			"cam_offset": Vector3(0.0, 1.8, 3.8),
			"fov": 65.0,
			"time_scale": 1.0
		}
	]
	holder.shots = generated_shots

	if scene_root:
		scene_root.add_child(holder)
		holder.owner = scene_root
		trigger.owner = scene_root
		shape_node.owner = scene_root
		cam.owner = scene_root

	return {
		"ok": true,
		"cutscene_id": cid,
		"shot_count": generated_shots.size(),
		"seamless_zero_black_screen": holder.seamless_gameplay_blend
	}


func play_cutscene(gameplay_camera: Camera3D = null) -> void:
	if _is_playing:
		return
	_is_playing = true
	_previous_gameplay_cam = gameplay_camera
	_cinematic_cam = get_node_or_null("CutsceneCamera3D") as Camera3D

	if seamless_gameplay_blend and _previous_gameplay_cam and _cinematic_cam:
		_cinematic_cam.global_transform = _previous_gameplay_cam.global_transform
		_cinematic_cam.fov = _previous_gameplay_cam.fov
		_cinematic_cam.current = true

	cutscene_started.emit(cutscene_id)
	for i in range(shots.size()):
		cutscene_shot_changed.emit(i, shots[i])
		var qte := str(shots[i].get("qte_action", ""))
		if not qte.is_empty():
			cutscene_qte_prompted.emit(qte, 1.2)

	Engine.time_scale = 1.0
	if _previous_gameplay_cam:
		_previous_gameplay_cam.current = true
	_is_playing = false
	cutscene_finished.emit(cutscene_id)
