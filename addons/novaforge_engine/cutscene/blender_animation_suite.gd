@tool
extends RefCounted
class_name NovaBlenderAnimationSuite
## Blender-Grade In-Engine Animation Suite:
## 1. Pose Mode Analytical Two-Bone FK/IK Solver (`solve_two_bone_ik`)
## 2. Cubic Bezier Graph Editor Curve Evaluator (`evaluate_bezier_curve`)
## 3. NLA (Non-Linear Animation) Layered Strip Mixer (`blend_nla_layers`)


## Law-of-cosines analytical 3D Two-Bone IK solver (UpperArm->LowerArm->Hand or Thigh->Shin->Foot).
static func solve_two_bone_ik(
	root_pos: Vector3,
	mid_pos: Vector3,
	tip_pos: Vector3,
	target_pos: Vector3,
	pole_pos: Vector3
) -> Dictionary:
	var len_a := root_pos.distance_to(mid_pos)
	var len_b := mid_pos.distance_to(tip_pos)
	var max_reach := maxf(0.001, (len_a + len_b) * 0.999)
	var min_reach := maxf(0.001, absf(len_a - len_b) + 0.001)

	var to_target := target_pos - root_pos
	var dist := clampf(to_target.length(), min_reach, max_reach)
	var dir := to_target.normalized() if to_target.length() > 1e-5 else Vector3.DOWN

	# Law of cosines for interior knee/elbow bend angle
	var cos_root := clampf((len_a * len_a + dist * dist - len_b * len_b) / (2.0 * len_a * dist), -1.0, 1.0)
	var angle_root := acos(cos_root)

	var pole_dir := (pole_pos - root_pos).slide(dir).normalized()
	if pole_dir.length_squared() < 1e-5:
		pole_dir = Vector3.FORWARD.slide(dir).normalized()

	var bend_axis := dir.cross(pole_dir).normalized()
	var solved_mid := root_pos + (dir.rotated(bend_axis, angle_root)) * len_a
	var solved_tip := solved_mid + (target_pos - solved_mid).normalized() * len_b

	return {
		"root_pos": root_pos,
		"mid_pos": solved_mid,
		"tip_pos": solved_tip,
		"knee_elbow_angle_deg": rad_to_deg(acos(clampf((len_a * len_a + len_b * len_b - dist * dist) / (2.0 * len_a * len_b), -1.0, 1.0)))
	}


## Evaluates a Blender-style Graph Editor cubic Bezier segment between two keyframes.
static func evaluate_bezier_curve(
	v0: float,
	out_tangent: float,
	in_tangent: float,
	v1: float,
	u: float
) -> float:
	var t := clampf(u, 0.0, 1.0)
	var omt := 1.0 - t
	var c0 := v0
	var c1 := v0 + out_tangent / 3.0
	var c2 := v1 - in_tangent / 3.0
	var c3 := v1
	return (omt * omt * omt) * c0 + 3.0 * (omt * omt * t) * c1 + 3.0 * (omt * t * t) * c2 + (t * t * t) * c3


## Blends stacked NLA animation strips (`REPLACE`, `ADDITIVE`, `MULTIPLY`) with bone masks.
static func blend_nla_layers(base_pose: Dictionary, strips: Array[Dictionary], current_time: float) -> Dictionary:
	var result := base_pose.duplicate(true)
	for strip in strips:
		var t_start := float(strip.get("start", 0.0))
		var t_end := float(strip.get("end", 1.0))
		if current_time < t_start or current_time > t_end:
			continue
		var weight := clampf(float(strip.get("weight", 1.0)), 0.0, 1.0)
		var mode := str(strip.get("blend_mode", "REPLACE")).to_upper()
		var pose: Dictionary = strip.get("pose", {})
		var bone_mask: Array = strip.get("bone_mask", [])

		for bone_name in pose.keys():
			if not bone_mask.is_empty() and not bone_mask.has(bone_name):
				continue
			var src_val: Vector3 = result.get(bone_name, Vector3.ZERO)
			var dst_val: Vector3 = pose[bone_name]
			if mode == "ADDITIVE":
				result[bone_name] = src_val + dst_val * weight
			elif mode == "MULTIPLY":
				result[bone_name] = src_val.lerp(src_val * dst_val, weight)
			else:
				result[bone_name] = src_val.lerp(dst_val, weight)
	return result
