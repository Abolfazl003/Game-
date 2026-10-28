@tool
extends RefCounted
## Real Vertex-Skinning Humanoid Auto-Rigger (`Mixamo / AccuRIG`-style inside Godot 4.7).
## Takes ANY `Node3D` / `MeshInstance3D` (either reconstructed from an uploaded image OR imported from `.glb/.gltf/.obj`),
## analyzes its 3D vertex distribution & arm/leg spans, builds a 19-bone hierarchical `Skeleton3D`,
## computes smooth 4-bone capsule-segment vertex weights (`ARRAY_BONES` + `ARRAY_WEIGHTS`), binds `Skin`,
## builds 5 real skeletal animations (`Idle`, `Walk`, `Run`, `SwordSlash`, `Wave`), and exports a rigged `.glb`!


static func autorig_node3d(
	source_root: Node3D,
	show_bone_markers: bool = true,
	default_anim: String = "Idle",
	export_glb_path: String = ""
) -> Dictionary:
	if source_root == null:
		return {"ok": false, "error": "گره سه‌بعدی نامعتبر است."}

	# Collect all MeshInstance3D surfaces and bake into source_root space
	var mesh_nodes := source_root.find_children("*", "MeshInstance3D", true, false)
	if source_root is MeshInstance3D:
		mesh_nodes.push_front(source_root)
	if mesh_nodes.is_empty():
		return {"ok": false, "error": "هیچ مش سه‌بعدی (MeshInstance3D) در مدل پیدا نشد."}

	var raw_surfaces: Array[Dictionary] = []
	var all_min := Vector3(1e9, 1e9, 1e9)
	var all_max := Vector3(-1e9, -1e9, -1e9)

	for m in mesh_nodes:
		var mi := m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var rel_xform := Transform3D.IDENTITY
		var cur: Node = mi
		while cur != null and cur != source_root:
			if cur is Node3D:
				rel_xform = (cur as Node3D).transform * rel_xform
			cur = cur.get_parent()

		for s_idx in range(mi.mesh.get_surface_count()):
			var arrays := mi.mesh.surface_get_arrays(s_idx)
			if arrays.is_empty() or arrays[Mesh.ARRAY_VERTEX] == null:
				continue
			var src_v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			if src_v.is_empty():
				continue
			var baked_v := PackedVector3Array()
			baked_v.resize(src_v.size())
			for i in range(src_v.size()):
				var p := rel_xform * src_v[i]
				baked_v[i] = p
				if p.x < all_min.x: all_min.x = p.x
				if p.y < all_min.y: all_min.y = p.y
				if p.z < all_min.z: all_min.z = p.z
				if p.x > all_max.x: all_max.x = p.x
				if p.y > all_max.y: all_max.y = p.y
				if p.z > all_max.z: all_max.z = p.z

			var baked_n := PackedVector3Array()
			if arrays[Mesh.ARRAY_NORMAL] != null:
				var src_n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
				baked_n.resize(src_n.size())
				var basis_n := rel_xform.basis.orthonormalized()
				for i in range(src_n.size()):
					baked_n[i] = (basis_n * src_n[i]).normalized()

			var mat := mi.get_active_material(s_idx)
			if mat == null and mi.mesh:
				mat = mi.mesh.surface_get_material(s_idx)

			raw_surfaces.append({
				"verts": baked_v,
				"norms": baked_n,
				"uvs": arrays[Mesh.ARRAY_TEX_UV],
				"indices": arrays[Mesh.ARRAY_INDEX],
				"material": mat
			})

	if raw_surfaces.is_empty():
		return {"ok": false, "error": "ورتکس‌های مش قابل استخراج نبودند."}

	# Normalize horizontal center (X=0, Z=0) and place feet on Y=0
	var center_xz := Vector3(0.5 * (all_min.x + all_max.x), all_min.y, 0.5 * (all_min.z + all_max.z))
	var h := maxf(0.25, all_max.y - all_min.y)
	var half_w := maxf(0.10, 0.5 * (all_max.x - all_min.x))

	# Measure arm span in upper body (0.56H .. 0.84H) & leg width in lower body (0.06H .. 0.44H)
	var arm_max_x := 0.0
	var arm_avg_y := 0.74 * h
	var arm_cnt := 0.0
	var leg_avg_x := 0.0
	var leg_cnt := 0.0

	for surf in raw_surfaces:
		var bv: PackedVector3Array = surf["verts"]
		for i in range(bv.size()):
			var p := bv[i] - center_xz
			bv[i] = p
			var yn := p.y / h
			if yn >= 0.56 and yn <= 0.84 and absf(p.x) > 0.14 * h:
				if absf(p.x) > arm_max_x:
					arm_max_x = absf(p.x)
				if absf(p.x) > 0.25 * half_w:
					arm_avg_y += p.y
					arm_cnt += 1.0
			if yn >= 0.08 and yn <= 0.44 and absf(p.x) > 0.02 * h:
				leg_avg_x += absf(p.x)
				leg_cnt += 1.0
		surf["verts"] = bv

	var shoulder_y := 0.75 * h
	var hand_y := (arm_avg_y / (arm_cnt + 1.0)) if arm_cnt > 8.0 else 0.52 * h
	hand_y = clampf(hand_y, 0.42 * h, 0.80 * h)
	var arm_reach := clampf(arm_max_x if arm_max_x > 0.18 * h else half_w * 0.92, 0.18 * h, 0.95 * h)
	var shoulder_x := clampf(arm_reach * 0.30, 0.08 * h, 0.22 * h)
	var elbow_x := lerp(shoulder_x, arm_reach, 0.54)
	var elbow_y := lerp(shoulder_y, hand_y, 0.52)
	var hip_x := clampf((leg_avg_x / leg_cnt) if leg_cnt > 8.0 else 0.10 * h, 0.06 * h, 0.18 * h)

	# 19-Bone Anatomical Hierarchy: [name, parent_idx, global_pos]
	var bone_defs := [
		["Hips", -1, Vector3(0.0, 0.50 * h, 0.0)],
		["Spine", 0, Vector3(0.0, 0.61 * h, 0.0)],
		["Chest", 1, Vector3(0.0, 0.73 * h, 0.0)],
		["Neck", 2, Vector3(0.0, 0.82 * h, 0.0)],
		["Head", 3, Vector3(0.0, 0.90 * h, 0.0)],

		["LeftShoulder", 2, Vector3(shoulder_x * 0.65, shoulder_y, 0.0)],
		["LeftUpperArm", 5, Vector3(shoulder_x, shoulder_y, 0.0)],
		["LeftLowerArm", 6, Vector3(elbow_x, elbow_y, 0.0)],
		["LeftHand", 7, Vector3(arm_reach * 0.92, hand_y, 0.0)],

		["RightShoulder", 2, Vector3(-shoulder_x * 0.65, shoulder_y, 0.0)],
		["RightUpperArm", 9, Vector3(-shoulder_x, shoulder_y, 0.0)],
		["RightLowerArm", 10, Vector3(-elbow_x, elbow_y, 0.0)],
		["RightHand", 11, Vector3(-arm_reach * 0.92, hand_y, 0.0)],

		["LeftUpperLeg", 0, Vector3(hip_x, 0.47 * h, 0.0)],
		["LeftLowerLeg", 13, Vector3(hip_x, 0.25 * h, 0.0)],
		["LeftFoot", 14, Vector3(hip_x, 0.05 * h, 0.02 * h)],

		["RightUpperLeg", 0, Vector3(-hip_x, 0.47 * h, 0.0)],
		["RightLowerLeg", 16, Vector3(-hip_x, 0.25 * h, 0.0)],
		["RightFoot", 17, Vector3(-hip_x, 0.05 * h, 0.02 * h)],
	]

	# Bone segments [start_pos, end_pos, side_sign (-1 right, 0 center, +1 left)] for smooth envelope weights
	var seg_ends: Array[Vector3] = [
		Vector3(0.0, 0.61 * h, 0.0),          # 0 Hips
		Vector3(0.0, 0.73 * h, 0.0),          # 1 Spine
		Vector3(0.0, 0.82 * h, 0.0),          # 2 Chest
		Vector3(0.0, 0.89 * h, 0.0),          # 3 Neck
		Vector3(0.0, 1.00 * h, 0.0),          # 4 Head
		Vector3(shoulder_x, shoulder_y, 0.0), # 5 LShoulder
		Vector3(elbow_x, elbow_y, 0.0),       # 6 LUpperArm
		Vector3(arm_reach * 0.92, hand_y, 0.0), # 7 LLowerArm
		Vector3(arm_reach * 1.02, hand_y, 0.0), # 8 LHand
		Vector3(-shoulder_x, shoulder_y, 0.0),  # 9 RShoulder
		Vector3(-elbow_x, elbow_y, 0.0),        # 10 RUpperArm
		Vector3(-arm_reach * 0.92, hand_y, 0.0),# 11 RLowerArm
		Vector3(-arm_reach * 1.02, hand_y, 0.0),# 12 RHand
		Vector3(hip_x, 0.25 * h, 0.0),        # 13 LUpperLeg
		Vector3(hip_x, 0.05 * h, 0.0),        # 14 LLowerLeg
		Vector3(hip_x, 0.0, 0.08 * h),        # 15 LFoot
		Vector3(-hip_x, 0.25 * h, 0.0),       # 16 RUpperLeg
		Vector3(-hip_x, 0.05 * h, 0.0),       # 17 RLowerLeg
		Vector3(-hip_x, 0.0, 0.08 * h),       # 18 RFoot
	]
	var bone_sides := [0, 0, 0, 0, 0, 1, 1, 1, 1, -1, -1, -1, -1, 1, 1, 1, -1, -1, -1]

	var skel := Skeleton3D.new()
	skel.name = "HumanoidAutoSkeleton"

	for i in range(bone_defs.size()):
		skel.add_bone(bone_defs[i][0])

	for i in range(bone_defs.size()):
		var p_idx: int = bone_defs[i][1]
		if p_idx >= 0:
			skel.set_bone_parent(i, p_idx)
		var g_pos: Vector3 = bone_defs[i][2]
		var local_pos := g_pos if p_idx < 0 else (g_pos - (bone_defs[p_idx][2] as Vector3))
		skel.set_bone_rest(i, Transform3D(Basis.IDENTITY, local_pos))

	skel.reset_bone_poses()
	var skin := skel.create_skin_from_rest_transforms()

	# Build skinned ArrayMesh with 4-bone smooth capsule weights per vertex
	var skinned_mesh := ArrayMesh.new()
	var total_skinned_verts := 0
	var eps := 0.025 * h

	for s_idx in range(raw_surfaces.size()):
		var surf: Dictionary = raw_surfaces[s_idx]
		var verts: PackedVector3Array = surf["verts"]
		var v_len := verts.size()
		total_skinned_verts += v_len

		var bones_arr := PackedInt32Array()
		var weights_arr := PackedFloat32Array()
		bones_arr.resize(v_len * 4)
		weights_arr.resize(v_len * 4)

		for vi in range(v_len):
			var vp := verts[vi]
			var top_b := [0, 0, 0, 0]
			var top_w := [0.0, 0.0, 0.0, 0.0]

			for bi in range(bone_defs.size()):
				var side: int = bone_sides[bi]
				# Prevent cross-leg / cross-arm bleed across X=0 midline
				if side == 1 and vp.x < -0.02 * h:
					continue
				if side == -1 and vp.x > 0.02 * h:
					continue

				var a: Vector3 = bone_defs[bi][2]
				var b: Vector3 = seg_ends[bi]
				var d := _point_to_segment_dist(vp, a, b)
				var w := 1.0 / pow(maxf(d, eps), 3.1)

				if w > top_w[3]:
					top_w[3] = w
					top_b[3] = bi
					for k in [2, 1, 0]:
						if top_w[k + 1] > top_w[k]:
							var tw: float = top_w[k]; top_w[k] = top_w[k + 1]; top_w[k + 1] = tw
							var tb: int = top_b[k]; top_b[k] = top_b[k + 1]; top_b[k + 1] = tb

			var w_sum: float = top_w[0] + top_w[1] + top_w[2] + top_w[3]
			if w_sum <= 1e-7:
				top_b = [0, 0, 0, 0]
				top_w = [1.0, 0.0, 0.0, 0.0]
				w_sum = 1.0

			var base4 := vi * 4
			for k in range(4):
				bones_arr[base4 + k] = top_b[k]
				weights_arr[base4 + k] = top_w[k] / w_sum

		var mesh_arr := []
		mesh_arr.resize(Mesh.ARRAY_MAX)
		mesh_arr[Mesh.ARRAY_VERTEX] = verts
		if (surf["norms"] as PackedVector3Array).size() == v_len:
			mesh_arr[Mesh.ARRAY_NORMAL] = surf["norms"]
		if surf["uvs"] != null and (surf["uvs"] as PackedVector2Array).size() == v_len:
			mesh_arr[Mesh.ARRAY_TEX_UV] = surf["uvs"]
		if surf["indices"] != null and (surf["indices"] as PackedInt32Array).size() > 0:
			mesh_arr[Mesh.ARRAY_INDEX] = surf["indices"]
		mesh_arr[Mesh.ARRAY_BONES] = bones_arr
		mesh_arr[Mesh.ARRAY_WEIGHTS] = weights_arr

		skinned_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arr)
		if surf["material"] != null:
			skinned_mesh.surface_set_material(skinned_mesh.get_surface_count() - 1, surf["material"])

	var rig_root := Node3D.new()
	rig_root.name = "Rigged_" + source_root.name.validate_node_name()
	rig_root.add_child(skel)
	skel.owner = rig_root

	var skinned_mi := MeshInstance3D.new()
	skinned_mi.name = "SkinnedCharacterMesh"
	skinned_mi.mesh = skinned_mesh
	skinned_mi.skin = skin
	skel.add_child(skinned_mi)
	skinned_mi.skeleton = NodePath("..")
	skinned_mi.owner = rig_root

	# Attach 3D Joint Markers directly via BoneAttachment3D so markers move WITH the animated bones!
	var markers_holder := Node3D.new()
	markers_holder.name = "BoneDebugMarkers"
	markers_holder.visible = show_bone_markers
	skel.add_child(markers_holder)

	var joint_mat := StandardMaterial3D.new()
	joint_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	joint_mat.albedo_color = Color(0.15, 0.92, 1.0, 0.9)
	joint_mat.no_depth_test = true
	var joint_sphere := SphereMesh.new()
	joint_sphere.radius = maxf(0.018, 0.016 * h)
	joint_sphere.height = joint_sphere.radius * 2.0
	joint_sphere.material = joint_mat

	for bi in range(bone_defs.size()):
		var ba := BoneAttachment3D.new()
		ba.name = "Joint_" + str(bone_defs[bi][0])
		ba.bone_idx = bi
		var jmi := MeshInstance3D.new()
		jmi.mesh = joint_sphere
		ba.add_child(jmi)
		markers_holder.add_child(ba)

	# Build Real Procedural Skeletal AnimationPlayer (`Idle`, `Walk`, `Run`, `SwordSlash`, `Wave`)
	var anim_player := AnimationPlayer.new()
	anim_player.name = "AutoRigAnimationPlayer"
	rig_root.add_child(anim_player)
	anim_player.root_node = NodePath("..")
	anim_player.owner = rig_root

	var lib := _build_humanoid_animation_library(h)
	anim_player.add_animation_library("", lib)
	if anim_player.has_animation(default_anim):
		anim_player.play(default_anim)

	var saved_glb := ""
	if not export_glb_path.is_empty():
		var abs_out := ProjectSettings.globalize_path(export_glb_path) if export_glb_path.begins_with("res://") else export_glb_path
		DirAccess.make_dir_recursive_absolute(abs_out.get_base_dir())
		markers_holder.visible = false
		var gdoc := GLTFDocument.new()
		var gstate := GLTFState.new()
		if gdoc.append_from_scene(rig_root, gstate) == OK:
			if gdoc.write_to_filesystem(gstate, abs_out) == OK:
				saved_glb = export_glb_path
		markers_holder.visible = show_bone_markers

	return {
		"ok": true,
		"node": rig_root,
		"skeleton": skel,
		"mesh_instance": skinned_mi,
		"anim_player": anim_player,
		"bones_count": skel.get_bone_count(),
		"skinned_vertices": total_skinned_verts,
		"animations": ["Idle", "Walk", "Run", "SwordSlash", "Wave"],
		"saved_glb": saved_glb
	}


static func _point_to_segment_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var len_sq := ab.length_squared()
	if len_sq <= 1e-8:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)


static func _q_deg(rx: float, ry: float, rz: float) -> Quaternion:
	return Quaternion.from_euler(Vector3(deg_to_rad(rx), deg_to_rad(ry), deg_to_rad(rz)))


static func _add_rot_keys(anim: Animation, bone_name: String, keys: Array) -> void:
	var t := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t, NodePath("HumanoidAutoSkeleton:" + bone_name))
	anim.track_set_interpolation_type(t, Animation.INTERPOLATION_CUBIC)
	for k in keys:
		anim.rotation_track_insert_key(t, float(k[0]), k[1] as Quaternion)


static func _build_humanoid_animation_library(_h: float) -> AnimationLibrary:
	var lib := AnimationLibrary.new()

	# 1. Idle (Breathing & subtle martial stance)
	var idle := Animation.new()
	idle.length = 2.0
	idle.loop_mode = Animation.LOOP_LINEAR
	_add_rot_keys(idle, "Spine", [[0.0, _q_deg(0, 0, 0)], [1.0, _q_deg(-4, 0, 0)], [2.0, _q_deg(0, 0, 0)]])
	_add_rot_keys(idle, "Chest", [[0.0, _q_deg(0, 0, 0)], [1.0, _q_deg(-3, 2, 0)], [2.0, _q_deg(0, 0, 0)]])
	_add_rot_keys(idle, "Head", [[0.0, _q_deg(0, -4, 0)], [1.0, _q_deg(3, 4, 0)], [2.0, _q_deg(0, -4, 0)]])
	_add_rot_keys(idle, "LeftUpperArm", [[0.0, _q_deg(0, 0, -14)], [1.0, _q_deg(4, 0, -8)], [2.0, _q_deg(0, 0, -14)]])
	_add_rot_keys(idle, "RightUpperArm", [[0.0, _q_deg(0, 0, 14)], [1.0, _q_deg(4, 0, 8)], [2.0, _q_deg(0, 0, 14)]])
	lib.add_animation("Idle", idle)

	# 2. Walk Cycle
	var walk := Animation.new()
	walk.length = 1.0
	walk.loop_mode = Animation.LOOP_LINEAR
	_add_rot_keys(walk, "LeftUpperLeg", [[0.0, _q_deg(-28, 0, 0)], [0.5, _q_deg(26, 0, 0)], [1.0, _q_deg(-28, 0, 0)]])
	_add_rot_keys(walk, "RightUpperLeg", [[0.0, _q_deg(26, 0, 0)], [0.5, _q_deg(-28, 0, 0)], [1.0, _q_deg(26, 0, 0)]])
	_add_rot_keys(walk, "LeftLowerLeg", [[0.0, _q_deg(8, 0, 0)], [0.25, _q_deg(32, 0, 0)], [0.5, _q_deg(6, 0, 0)], [1.0, _q_deg(8, 0, 0)]])
	_add_rot_keys(walk, "RightLowerLeg", [[0.0, _q_deg(6, 0, 0)], [0.5, _q_deg(8, 0, 0)], [0.75, _q_deg(32, 0, 0)], [1.0, _q_deg(6, 0, 0)]])
	_add_rot_keys(walk, "LeftUpperArm", [[0.0, _q_deg(22, 0, -18)], [0.5, _q_deg(-22, 0, -18)], [1.0, _q_deg(22, 0, -18)]])
	_add_rot_keys(walk, "RightUpperArm", [[0.0, _q_deg(-22, 0, 18)], [0.5, _q_deg(22, 0, 18)], [1.0, _q_deg(-22, 0, 18)]])
	_add_rot_keys(walk, "Spine", [[0.0, _q_deg(4, -5, 0)], [0.5, _q_deg(4, 5, 0)], [1.0, _q_deg(4, -5, 0)]])
	lib.add_animation("Walk", walk)

	# 3. Run Cycle
	var run := Animation.new()
	run.length = 0.68
	run.loop_mode = Animation.LOOP_LINEAR
	_add_rot_keys(run, "Spine", [[0.0, _q_deg(12, -8, 0)], [0.34, _q_deg(12, 8, 0)], [0.68, _q_deg(12, -8, 0)]])
	_add_rot_keys(run, "LeftUpperLeg", [[0.0, _q_deg(-46, 0, 0)], [0.34, _q_deg(40, 0, 0)], [0.68, _q_deg(-46, 0, 0)]])
	_add_rot_keys(run, "RightUpperLeg", [[0.0, _q_deg(40, 0, 0)], [0.34, _q_deg(-46, 0, 0)], [0.68, _q_deg(40, 0, 0)]])
	_add_rot_keys(run, "LeftLowerLeg", [[0.0, _q_deg(14, 0, 0)], [0.18, _q_deg(58, 0, 0)], [0.34, _q_deg(10, 0, 0)], [0.68, _q_deg(14, 0, 0)]])
	_add_rot_keys(run, "RightLowerLeg", [[0.0, _q_deg(10, 0, 0)], [0.34, _q_deg(14, 0, 0)], [0.52, _q_deg(58, 0, 0)], [0.68, _q_deg(10, 0, 0)]])
	_add_rot_keys(run, "LeftUpperArm", [[0.0, _q_deg(38, 0, -15)], [0.34, _q_deg(-38, 0, -15)], [0.68, _q_deg(38, 0, -15)]])
	_add_rot_keys(run, "RightUpperArm", [[0.0, _q_deg(-38, 0, 15)], [0.34, _q_deg(38, 0, 15)], [0.68, _q_deg(-38, 0, 15)]])
	lib.add_animation("Run", run)

	# 4. SwordSlash (Dynamic Martial Combo)
	var slash := Animation.new()
	slash.length = 0.90
	slash.loop_mode = Animation.LOOP_LINEAR
	_add_rot_keys(slash, "Spine", [[0.0, _q_deg(0, 0, 0)], [0.25, _q_deg(-8, 28, 0)], [0.50, _q_deg(16, -34, 0)], [0.90, _q_deg(0, 0, 0)]])
	_add_rot_keys(slash, "RightUpperArm", [[0.0, _q_deg(0, 0, 10)], [0.25, _q_deg(-65, -20, 35)], [0.50, _q_deg(52, 35, -20)], [0.90, _q_deg(0, 0, 10)]])
	_add_rot_keys(slash, "RightLowerArm", [[0.0, _q_deg(0, 0, 0)], [0.25, _q_deg(-35, 0, 0)], [0.50, _q_deg(10, 0, 0)], [0.90, _q_deg(0, 0, 0)]])
	_add_rot_keys(slash, "LeftUpperArm", [[0.0, _q_deg(0, 0, -12)], [0.50, _q_deg(-25, 0, -28)], [0.90, _q_deg(0, 0, -12)]])
	lib.add_animation("SwordSlash", slash)

	# 5. Wave / Victory
	var wave := Animation.new()
	wave.length = 1.2
	wave.loop_mode = Animation.LOOP_LINEAR
	_add_rot_keys(wave, "RightUpperArm", [[0.0, _q_deg(0, 0, -52)], [0.6, _q_deg(0, 0, -62)], [1.2, _q_deg(0, 0, -52)]])
	_add_rot_keys(wave, "RightLowerArm", [[0.0, _q_deg(0, 0, -25)], [0.3, _q_deg(0, 0, 22)], [0.6, _q_deg(0, 0, -25)], [0.9, _q_deg(0, 0, 22)], [1.2, _q_deg(0, 0, -25)]])
	_add_rot_keys(wave, "Head", [[0.0, _q_deg(0, 0, -5)], [0.6, _q_deg(0, 0, 5)], [1.2, _q_deg(0, 0, -5)]])
	lib.add_animation("Wave", wave)

	return lib
