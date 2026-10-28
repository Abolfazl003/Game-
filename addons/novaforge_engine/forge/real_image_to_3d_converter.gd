@tool
extends RefCounted
## Real 2D-Image-to-3D Watertight Organic Mesh Converter (`Monster-Mash` Poisson PDE Inflation + Photometric Relief + PBR Normal Map + `.GLB` Export).
## Converts ANY user-selected `.png`, `.jpg`, `.jpeg`, `.webp`, or `.bmp` image into:
## 1. A smooth, plump, double-sided watertight 3D `ArrayMesh` (8,000–28,000 triangles) matching the exact silhouette & colors of the image,
## 2. UV-projected PBR `StandardMaterial3D` with Albedo texture + Sobel-derived 3D Normal Map,
## 3. A saved standard `.glb` file (`res://generated/meshes/<name>_3d.glb`) ready for Auto-Rigging or Blender/Godot use!


static func load_any_image(image_path: String) -> Image:
	var abs_path := image_path
	if image_path.begins_with("res://") or image_path.begins_with("user://"):
		abs_path = ProjectSettings.globalize_path(image_path)
	var img := Image.new()
	if FileAccess.file_exists(abs_path):
		var err := img.load(abs_path)
		if err == OK and not img.is_empty():
			img.convert(Image.FORMAT_RGBA8)
			return img
	if image_path.begins_with("res://") and ResourceLoader.exists(image_path):
		var tex = load(image_path)
		if tex is Texture2D:
			var im := (tex as Texture2D).get_image()
			if im and not im.is_empty():
				im.convert(Image.FORMAT_RGBA8)
				return im
	return null


static func build_foreground_preview_and_mask(src_img: Image, grid_res: int = 88, bg_tolerance: float = 0.20) -> Dictionary:
	var work := src_img.duplicate() as Image
	work.convert(Image.FORMAT_RGBA8)
	work.resize(grid_res, grid_res, Image.INTERPOLATE_LANCZOS)

	# Detect if image already has transparency
	var has_alpha := false
	for y in range(grid_res):
		for x in range(grid_res):
			if work.get_pixel(x, y).a < 0.65:
				has_alpha = true
				break
		if has_alpha:
			break

	var mask := PackedByteArray()
	mask.resize(grid_res * grid_res)
	mask.fill(1)

	if has_alpha:
		for y in range(grid_res):
			for x in range(grid_res):
				mask[y * grid_res + x] = 1 if work.get_pixel(x, y).a > 0.16 else 0
	else:
		# Sample perimeter border color and flood-fill background from edges
		var border_samples: Array[Color] = [
			work.get_pixel(0, 0),
			work.get_pixel(grid_res - 1, 0),
			work.get_pixel(0, grid_res - 1),
			work.get_pixel(grid_res - 1, grid_res - 1),
			work.get_pixel(grid_res / 2, 0),
			work.get_pixel(0, grid_res / 2),
			work.get_pixel(grid_res - 1, grid_res / 2),
		]
		var bg := Color(0, 0, 0, 1)
		for c in border_samples:
			bg.r += c.r
			bg.g += c.g
			bg.b += c.b
		bg.r /= float(border_samples.size())
		bg.g /= float(border_samples.size())
		bg.b /= float(border_samples.size())

		var visited := PackedByteArray()
		visited.resize(grid_res * grid_res)
		visited.fill(0)
		var queue: Array[int] = []

		for x in range(grid_res):
			queue.append(x)
			queue.append((grid_res - 1) * grid_res + x)
		for y in range(1, grid_res - 1):
			queue.append(y * grid_res)
			queue.append(y * grid_res + (grid_res - 1))

		var tol_sq := bg_tolerance * bg_tolerance * 3.0
		var head := 0
		while head < queue.size():
			var idx := queue[head]
			head += 1
			if visited[idx] == 1:
				continue
			visited[idx] = 1
			var px := idx % grid_res
			var py := idx / grid_res
			var c := work.get_pixel(px, py)
			var dr := c.r - bg.r
			var dg := c.g - bg.g
			var db := c.b - bg.b
			if (dr * dr + dg * dg + db * db) <= tol_sq:
				mask[idx] = 0
				if px > 0 and visited[idx - 1] == 0: queue.append(idx - 1)
				if px + 1 < grid_res and visited[idx + 1] == 0: queue.append(idx + 1)
				if py > 0 and visited[idx - grid_res] == 0: queue.append(idx - grid_res)
				if py + 1 < grid_res and visited[idx + grid_res] == 0: queue.append(idx + grid_res)

	# Ensure fallback central mask if uniform color image was passed
	var fg_count := 0
	for i in range(mask.size()):
		if mask[i] == 1:
			fg_count += 1
	if fg_count < 24:
		for y in range(grid_res / 6, grid_res - grid_res / 6):
			for x in range(grid_res / 6, grid_res - grid_res / 6):
				mask[y * grid_res + x] = 1
		fg_count = (grid_res * 2 / 3) * (grid_res * 2 / 3)

	# Build clean RGBA preview image showing isolated foreground
	var preview := Image.create(grid_res, grid_res, false, Image.FORMAT_RGBA8)
	for y in range(grid_res):
		for x in range(grid_res):
			var c := work.get_pixel(x, y)
			if mask[y * grid_res + x] == 1:
				preview.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
			else:
				preview.set_pixel(x, y, Color(0.06, 0.09, 0.14, 0.18))

	return {
		"mask": mask,
		"grid_res": grid_res,
		"work_img": work,
		"preview_img": preview,
		"fg_pixels": fg_count
	}


static func reconstruct_3d_mesh_from_image(
	image_path: String,
	grid_res: int = 88,
	depth_scale: float = 0.52,
	target_height: float = 1.85,
	bg_tolerance: float = 0.20,
	export_glb_path: String = ""
) -> Dictionary:
	var src_img := load_any_image(image_path)
	if src_img == null:
		return {"ok": false, "error": "فایل تصویر باز نشد: " + image_path}

	grid_res = clampi(grid_res, 40, 128)
	var seg := build_foreground_preview_and_mask(src_img, grid_res, bg_tolerance)
	var mask: PackedByteArray = seg["mask"]
	var work_img: Image = seg["work_img"]

	# Build Texture with bleeded border pixels so silhouette seams never sample background!
	var tex_img := src_img.duplicate() as Image
	tex_img.convert(Image.FORMAT_RGBA8)
	if tex_img.get_width() > 1024 or tex_img.get_height() > 1024:
		tex_img.resize(1024, 1024, Image.INTERPOLATE_LANCZOS)
	_bleed_transparent_edges(tex_img, 4)
	var albedo_tex := ImageTexture.create_from_image(tex_img)
	var normal_tex := _build_sobel_normal_texture(work_img)

	# Solve Poisson PDE ∇²u = -1 inside silhouette mask (Monster-Mash Smooth Organic Inflation!)
	var n_verts := (grid_res + 1) * (grid_res + 1)
	var v_inside := PackedByteArray()
	v_inside.resize(n_verts)
	v_inside.fill(0)

	# A grid vertex (vx, vy) is interior only if all 4 touching pixels are inside mask
	for vy in range(1, grid_res):
		for vx in range(1, grid_res):
			var m00 := mask[(vy - 1) * grid_res + (vx - 1)]
			var m10 := mask[(vy - 1) * grid_res + vx]
			var m01 := mask[vy * grid_res + (vx - 1)]
			var m11 := mask[vy * grid_res + vx]
			if m00 == 1 and m10 == 1 and m01 == 1 and m11 == 1:
				v_inside[vy * (grid_res + 1) + vx] = 1

	var u := PackedFloat32Array()
	var u_next := PackedFloat32Array()
	u.resize(n_verts)
	u_next.resize(n_verts)
	u.fill(0.0)
	u_next.fill(0.0)

	var h_step := 2.0 / float(grid_res)
	var rhs := h_step * h_step * 1.35

	# 48 Gauss-Seidel / Jacobi relaxation passes -> smooth plump round cross-sections!
	var stride := grid_res + 1
	for _iter in range(48):
		for vy in range(1, grid_res):
			var row_off := vy * stride
			for vx in range(1, grid_res):
				var idx := row_off + vx
				if v_inside[idx] == 1:
					u_next[idx] = 0.25 * (
						u[idx - 1] + u[idx + 1] + u[idx - stride] + u[idx + stride] + rhs
					)
				else:
					u_next[idx] = 0.0
		var tmp := u
		u = u_next
		u_next = tmp

	var max_u := 0.0001
	for i in range(n_verts):
		if u[i] > max_u:
			max_u = u[i]

	# Compute z-height = depth_scale * sqrt(u) + subtle luminance shading relief
	var z_field := PackedFloat32Array()
	z_field.resize(n_verts)
	var max_thick := 0.34 * depth_scale * target_height
	for vy in range(grid_res + 1):
		var py := clampi(vy, 0, grid_res - 1)
		for vx in range(grid_res + 1):
			var px := clampi(vx, 0, grid_res - 1)
			var idx := vy * stride + vx
			if u[idx] > 0.0:
				var norm_u := clampf(u[idx] / max_u, 0.0, 1.0)
				# Cap plateau slightly so thick bodies don't balloon while limbs stay cylindrical
				var shaped := pow(norm_u, 0.46)
				var col := work_img.get_pixel(px, py)
				var lum := col.r * 0.299 + col.g * 0.587 + col.b * 0.114
				var relief := (lum - 0.5) * 0.045 * target_height * norm_u
				z_field[idx] = shaped * max_thick + relief
			else:
				z_field[idx] = 0.0

	# Measure active pixel bounding box so model rests cleanly on y = 0 and centered on x = 0
	var min_px := grid_res
	var max_px := 0
	var min_py := grid_res
	var max_py := 0
	for py in range(grid_res):
		for px in range(grid_res):
			if mask[py * grid_res + px] == 1:
				if px < min_px: min_px = px
				if px > max_px: max_px = px
				if py < min_py: min_py = py
				if py > max_py: max_py = py

	var span_y := float(maxi(1, max_py - min_py + 1))
	var center_x := 0.5 * float(min_px + max_px + 1)
	var aspect := float(src_img.get_width()) / float(maxi(1, src_img.get_height()))
	var scale_y := target_height / span_y
	var scale_x := scale_y * aspect

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var tri_count := 0
	for py in range(grid_res):
		for px in range(grid_res):
			if mask[py * grid_res + px] == 0:
				continue

			var i00 := py * stride + px
			var i10 := py * stride + (px + 1)
			var i01 := (py + 1) * stride + px
			var i11 := (py + 1) * stride + (px + 1)

			var x0 := (float(px) - center_x) * scale_x
			var x1 := (float(px + 1) - center_x) * scale_x
			var y0 := float(max_py + 1 - py) * scale_y
			var y1 := float(max_py + 1 - (py + 1)) * scale_y

			var uv00 := Vector2(float(px) / float(grid_res), float(py) / float(grid_res))
			var uv10 := Vector2(float(px + 1) / float(grid_res), float(py) / float(grid_res))
			var uv01 := Vector2(float(px) / float(grid_res), float(py + 1) / float(grid_res))
			var uv11 := Vector2(float(px + 1) / float(grid_res), float(py + 1) / float(grid_res))

			var f00 := Vector3(x0, y0, z_field[i00])
			var f10 := Vector3(x1, y0, z_field[i10])
			var f01 := Vector3(x0, y1, z_field[i01])
			var f11 := Vector3(x1, y1, z_field[i11])

			# Front surface (+Z, counter-clockwise facing +Z)
			st.set_uv(uv00); st.add_vertex(f00)
			st.set_uv(uv10); st.add_vertex(f10)
			st.set_uv(uv11); st.add_vertex(f11)

			st.set_uv(uv00); st.add_vertex(f00)
			st.set_uv(uv11); st.add_vertex(f11)
			st.set_uv(uv01); st.add_vertex(f01)

			# Back surface (-Z, reversed winding facing -Z)
			var b00 := Vector3(x0, y0, -z_field[i00])
			var b10 := Vector3(x1, y0, -z_field[i10])
			var b01 := Vector3(x0, y1, -z_field[i01])
			var b11 := Vector3(x1, y1, -z_field[i11])

			st.set_uv(uv00); st.add_vertex(b00)
			st.set_uv(uv11); st.add_vertex(b11)
			st.set_uv(uv10); st.add_vertex(b10)

			st.set_uv(uv00); st.add_vertex(b00)
			st.set_uv(uv01); st.add_vertex(b01)
			st.set_uv(uv11); st.add_vertex(b11)

			tri_count += 4

	st.index()
	st.generate_normals()
	st.generate_tangents()
	var arr_mesh := st.commit()

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = albedo_tex
	mat.normal_enabled = true
	mat.normal_scale = 0.65
	mat.normal_texture = normal_tex
	mat.roughness = 0.58
	mat.metallic = 0.08
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	arr_mesh.surface_set_material(0, mat)

	var base_name := image_path.get_file().get_basename().validate_node_name()
	if base_name.is_empty():
		base_name = "Image3DMesh"

	var root_node := Node3D.new()
	root_node.name = "Mesh3D_" + base_name

	var mi := MeshInstance3D.new()
	mi.name = "SculptedMesh3D"
	mi.mesh = arr_mesh
	mi.material_override = mat
	root_node.add_child(mi)
	mi.owner = root_node

	var saved_glb := ""
	var out_path := export_glb_path
	if out_path.is_empty():
		out_path = "res://generated/meshes/" + base_name + "_3d.glb"
	var abs_out := ProjectSettings.globalize_path(out_path)
	DirAccess.make_dir_recursive_absolute(abs_out.get_base_dir())

	var gdoc := GLTFDocument.new()
	var gstate := GLTFState.new()
	if gdoc.append_from_scene(root_node, gstate) == OK:
		if gdoc.write_to_filesystem(gstate, abs_out) == OK:
			saved_glb = out_path

	return {
		"ok": true,
		"node": root_node,
		"mesh_instance": mi,
		"mesh": arr_mesh,
		"triangles": tri_count,
		"vertices": arr_mesh.surface_get_array_len(0),
		"preview_img": seg["preview_img"],
		"saved_glb": saved_glb,
		"name": base_name
	}


static func _bleed_transparent_edges(img: Image, passes: int = 3) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for _p in range(passes):
		var copy := img.duplicate() as Image
		for y in range(h):
			for x in range(w):
				var c := copy.get_pixel(x, y)
				if c.a < 0.2:
					var r := 0.0; var g := 0.0; var b := 0.0; var cnt := 0.0
					for dy in [-1, 0, 1]:
						for dx in [-1, 0, 1]:
							var nx: int = x + int(dx)
							var ny: int = y + int(dy)
							if nx >= 0 and nx < w and ny >= 0 and ny < h:
								var nc := copy.get_pixel(nx, ny)
								if nc.a >= 0.2:
									r += nc.r; g += nc.g; b += nc.b; cnt += 1.0
					if cnt > 0.0:
						img.set_pixel(x, y, Color(r / cnt, g / cnt, b / cnt, 1.0))


static func _build_sobel_normal_texture(img: Image) -> ImageTexture:
	var w := img.get_width()
	var h := img.get_height()
	var nimg := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var ym := maxi(0, y - 1)
		var yp := mini(h - 1, y + 1)
		for x in range(w):
			var xm := maxi(0, x - 1)
			var xp := mini(w - 1, x + 1)
			var l_xm := img.get_pixel(xm, y).get_luminance()
			var l_xp := img.get_pixel(xp, y).get_luminance()
			var l_ym := img.get_pixel(x, ym).get_luminance()
			var l_yp := img.get_pixel(x, yp).get_luminance()
			var dx := (l_xm - l_xp) * 2.2
			var dy := (l_ym - l_yp) * 2.2
			var n := Vector3(dx, dy, 1.0).normalized()
			nimg.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5, 1.0))
	return ImageTexture.create_from_image(nimg)
