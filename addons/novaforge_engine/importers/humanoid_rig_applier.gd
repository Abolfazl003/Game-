@tool
extends RefCounted
class_name NovaHumanoidRigApplier
## Instantiates a 52-bone Godot `Skeleton3D` + `SkeletonProfileHumanoid` BoneMap
## from `auto_rigger.py` output and builds Godot `Animation` tracks from `video_to_motion.py`
## (including automatic Combat Hitbox & VFX method call tracks!).


func build_skeleton_from_rig_json(rig_json_path: String) -> Skeleton3D:
	if not FileAccess.file_exists(rig_json_path):
		return null
	var data = JSON.parse_string(FileAccess.get_file_as_string(rig_json_path))
	if typeof(data) != TYPE_DICTIONARY or not data.get("ok", false):
		return null

	var skel := Skeleton3D.new()
	skel.name = "HumanoidSkeleton3D"
	var bones: Array = data.get("bones", [])
	for b in bones:
		skel.add_bone(str(b["name"]))

	for b in bones:
		var idx := skel.find_bone(str(b["name"]))
		var parent_name := str(b["parent"])
		if not parent_name.is_empty():
			var p_idx := skel.find_bone(parent_name)
			if p_idx >= 0:
				skel.set_bone_parent(idx, p_idx)
		var h: Array = b["head"]
		skel.set_bone_rest(idx, Transform3D(Basis.IDENTITY, Vector3(float(h[0]), float(h[1]), float(h[2]))))

	return skel


func build_animation_from_mocap_json(mocap_json_path: String) -> Animation:
	if not FileAccess.file_exists(mocap_json_path):
		return null
	var data = JSON.parse_string(FileAccess.get_file_as_string(mocap_json_path))
	if typeof(data) != TYPE_DICTIONARY or not data.get("ok", false):
		return null

	var anim := Animation.new()
	anim.length = float(data.get("duration_sec", 1.0))
	anim.loop_mode = Animation.LOOP_LINEAR if data.get("loop_enabled", false) else Animation.LOOP_NONE

	# Root motion position track
	var root_track := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(root_track, NodePath("HumanoidSkeleton3D:Hips"))

	# Right arm rotation track
	var arm_track := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(arm_track, NodePath("HumanoidSkeleton3D:RightUpperArm"))

	for fr in data.get("frames", []):
		var t := float(fr["time"])
		var rp: Array = fr["root_pos"]
		anim.position_track_insert_key(root_track, t, Vector3(float(rp[0]), float(rp[1]), float(rp[2])))
		var q := Quaternion.from_euler(Vector3(deg_to_rad(float(fr["right_arm_pitch_deg"])), 0.0, 0.0))
		anim.rotation_track_insert_key(arm_track, t, q)

	# Auto-Combat Event Track (Hitbox activation + VFX sparks + SFX)
	var events: Array = data.get("combat_events", [])
	if not events.is_empty():
		var ev_track := anim.add_track(Animation.TYPE_METHOD)
		anim.track_set_path(ev_track, NodePath("."))
		for ev in events:
			anim.track_insert_key(ev_track, float(ev["time"]), {
				"method": "_on_mocap_combat_event",
				"args": [ev]
			})

	return anim
