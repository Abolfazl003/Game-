@tool
extends RefCounted
## Cold-Boot-Safe Universal 3D Model Loader (`.glb`, `.gltf`, `.obj`) + Character Animation Helper.
## Uses Godot 4.7 `GLTFDocument` + `GLTFState` and a native Wavefront `.obj` parser so models load
## both from `res://assets/models/...` and from ANY external disk path (`C:\...` or `/home/...`)
## without requiring pre-imported `.godot/imported/` cache files!


static func load_model_scene(path: String, target_height: float = -1.0, tint_color: Color = Color(1, 1, 1, 0)) -> Node3D:
	var abs_path := path
	if path.begins_with("res://") or path.begins_with("user://"):
		abs_path = ProjectSettings.globalize_path(path)

	if not FileAccess.file_exists(path) and not FileAccess.file_exists(abs_path):
		return null

	var ext := abs_path.get_extension().to_lower()
	var loaded_root: Node3D = null

	if ext == "glb" or ext == "gltf":
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		state.base_path = abs_path.get_base_dir()
		var err := doc.append_from_file(abs_path, state)
		if err == OK:
			var generated := doc.generate_scene(state)
			if generated is Node3D:
				loaded_root = generated as Node3D
				_convert_importer_meshes_to_runtime(loaded_root)
	elif ext == "obj":
		loaded_root = _load_wavefront_obj(abs_path)

	if loaded_root == null and path.begins_with("res://") and ResourceLoader.exists(path):
		var packed = load(path)
		if packed is PackedScene:
			var inst = packed.instantiate()
			if inst is Node3D:
				loaded_root = inst as Node3D

	if loaded_root == null:
		return null

	# Normalize height & ground alignment if requested
	if target_height > 0.0:
		var bounds := compute_hierarchy_aabb(loaded_root)
		if bounds.size.y > 0.001:
			var s := target_height / bounds.size.y
			loaded_root.scale = Vector3.ONE * s
			loaded_root.position.y = -bounds.position.y * s

	if tint_color.a > 0.01:
		apply_tint_to_meshes(loaded_root, tint_color)

	return loaded_root


static func _convert_importer_meshes_to_runtime(root: Node3D) -> void:
	if not ClassDB.class_exists("ImporterMeshInstance3D"):
		return
	var imp_nodes := root.find_children("*", "ImporterMeshInstance3D", true, false)
	for n in imp_nodes:
		if not is_instance_valid(n):
			continue
		var imp := n as Node3D
		if imp == null:
			continue
		var imp_mesh = imp.get("mesh")
		if imp_mesh == null or not imp_mesh.has_method("get_mesh"):
			continue
		var arr_mesh: ArrayMesh = imp_mesh.call("get_mesh")
		if arr_mesh == null:
			continue
		var mi := MeshInstance3D.new()
		mi.name = imp.name
		mi.transform = imp.transform
		mi.mesh = arr_mesh
		var sk = imp.get("skin")
		if sk != null:
			mi.skin = sk
		var sk_path = imp.get("skeleton_path")
		if sk_path is NodePath and not (sk_path as NodePath).is_empty():
			mi.skeleton = sk_path
		for ch in imp.get_children():
			imp.remove_child(ch)
			mi.add_child(ch)
		var par := imp.get_parent()
		if par:
			var idx := imp.get_index()
			par.remove_child(imp)
			par.add_child(mi)
			par.move_child(mi, idx)
			imp.free()


static func compute_hierarchy_aabb(root: Node3D) -> AABB:
	var has_any := false
	var merged := AABB()
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		meshes.push_front(root)
	for m in meshes:
		var mi := m as MeshInstance3D
		if mi and mi.mesh:
			var local_aabb := mi.mesh.get_aabb()
			var rel_xform := Transform3D.IDENTITY
			var cur: Node = mi
			while cur != null and cur != root:
				if cur is Node3D:
					rel_xform = (cur as Node3D).transform * rel_xform
				cur = cur.get_parent()
			var world_box := rel_xform * local_aabb
			if not has_any:
				merged = world_box
				has_any = true
			else:
				merged = merged.merge(world_box)
	return merged if has_any else AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 1.8, 1))


static func apply_tint_to_meshes(root: Node3D, tint: Color) -> void:
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		meshes.push_front(root)
	for m in meshes:
		var mi := m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for surf_idx in range(mi.mesh.get_surface_count()):
			var base_mat := mi.get_active_material(surf_idx)
			var dup := StandardMaterial3D.new()
			if base_mat is StandardMaterial3D:
				dup = (base_mat as StandardMaterial3D).duplicate()
				dup.albedo_color = dup.albedo_color.lerp(tint, 0.65)
			else:
				dup.albedo_color = tint
				dup.roughness = 0.45
			mi.set_surface_override_material(surf_idx, dup)


static func play_character_anim(root: Node3D, preferred_anims: Array, loop_anim: bool = true) -> String:
	if root == null:
		return ""
	var players := root.find_children("*", "AnimationPlayer", true, false)
	for p in players:
		var ap := p as AnimationPlayer
		var list := ap.get_animation_list()
		for cand in preferred_anims:
			var cname := str(cand)
			if list.has(cname):
				var anim_res := ap.get_animation(cname)
				if anim_res and loop_anim:
					anim_res.loop_mode = Animation.LOOP_LINEAR
				ap.play(cname)
				return cname
		# Fuzzy match
		for existing in list:
			for cand in preferred_anims:
				if existing.to_lower().contains(str(cand).to_lower()):
					var anim_res2 := ap.get_animation(existing)
					if anim_res2 and loop_anim:
						anim_res2.loop_mode = Animation.LOOP_LINEAR
					ap.play(existing)
					return existing
	return ""


static func _load_wavefront_obj(abs_path: String) -> Node3D:
	var f := FileAccess.open(abs_path, FileAccess.READ)
	if f == null:
		return null
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var norms := PackedVector3Array()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var parts := line.split(" ", false)
		if parts.is_empty():
			continue
		match parts[0]:
			"v":
				if parts.size() >= 4:
					verts.append(Vector3(parts[1].to_float(), parts[2].to_float(), parts[3].to_float()))
			"vt":
				if parts.size() >= 3:
					uvs.append(Vector2(parts[1].to_float(), 1.0 - parts[2].to_float()))
			"vn":
				if parts.size() >= 4:
					norms.append(Vector3(parts[1].to_float(), parts[2].to_float(), parts[3].to_float()))
			"f":
				if parts.size() >= 4:
					var face_tokens: Array[String] = []
					for i in range(1, parts.size()):
						face_tokens.append(parts[i])
					for tri in range(1, face_tokens.size() - 1):
						for corner_tok in [face_tokens[0], face_tokens[tri], face_tokens[tri + 1]]:
							var sub: PackedStringArray = str(corner_tok).split("/")
							var vi: int = sub[0].to_int() - 1
							if vi >= 0 and vi < verts.size():
								if sub.size() >= 2 and not sub[1].is_empty():
									var ti: int = sub[1].to_int() - 1
									if ti >= 0 and ti < uvs.size():
										st.set_uv(uvs[ti])
								if sub.size() >= 3 and not sub[2].is_empty():
									var ni: int = sub[2].to_int() - 1
									if ni >= 0 and ni < norms.size():
										st.set_normal(norms[ni])
								st.add_vertex(verts[vi])

	st.generate_normals()
	var arr_mesh := st.commit()
	var holder := Node3D.new()
	holder.name = abs_path.get_file().get_basename()
	var mi := MeshInstance3D.new()
	mi.name = "ImportedOBJMesh"
	mi.mesh = arr_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.82, 0.85, 0.90)
	mat.roughness = 0.52
	mi.material_override = mat
	holder.add_child(mi)
	return holder
