@tool
extends RefCounted
class_name NovaUniversal3DImporter
## Universal Blender All-Format Importer & Zero-Config Auto-Material Binder.
## Accepts `.blend`, `.glb`, `.gltf`, `.fbx`, `.obj`+`.mtl`, `.dae`, `.usd/.usdz`, `.abc`, `.ply`, `.stl`
## and automatically discovers, fixes, and binds every PBR texture channel without manual wiring.

const SUPPORTED_FORMATS := [
	"blend", "glb", "gltf", "fbx", "obj", "dae",
	"usd", "usda", "usdc", "usdz", "abc", "ply", "stl"
]


func import_and_autobind(res_path: String, _options: Dictionary = {}) -> Dictionary:
	var ext := res_path.get_extension().to_lower()
	if not SUPPORTED_FORMATS.has(ext):
		return {"ok": false, "error": "Unsupported 3D format: ." + ext, "supported": SUPPORTED_FORMATS}

	var abs_asset := ProjectSettings.globalize_path(res_path)
	var abs_root := ProjectSettings.globalize_path("res://")
	var resolver_py := ProjectSettings.globalize_path("res://pipelines/blender_bridge/pbr_texture_resolver.py")

	var out_lines: Array = []
	var code := OS.execute("python3", [resolver_py, "--asset", abs_asset, "--project-root", abs_root], out_lines, true)
	if code != 0 or out_lines.is_empty():
		return {"ok": false, "error": "PBR resolver failed", "log": out_lines}

	var parsed = JSON.parse_string("\n".join(out_lines))
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.get("ok", false):
		return {"ok": false, "error": "Invalid PBR resolver response"}

	var mat := build_standard_material_from_slots(parsed.get("bound_pbr_slots", {}))
	var save_mat_path := res_path.get_basename() + "_auto_pbr.tres"
	ResourceSaver.save(mat, save_mat_path)

	return {
		"ok": true,
		"asset": res_path,
		"format": parsed.get("format", ext),
		"material_saved": save_mat_path,
		"bound_slots": parsed.get("bound_pbr_slots", {}),
		"normal_green_flipped": parsed.get("normal_green_flipped", false),
		"gloss_inverted": parsed.get("gloss_inverted_to_roughness", false)
	}


func build_standard_material_from_slots(slots: Dictionary) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.8

	if slots.has("albedo"):
		var tex := _try_load_tex(slots["albedo"]["path"])
		if tex:
			mat.albedo_texture = tex

	if slots.has("normal"):
		var ntex := _try_load_tex(slots["normal"]["path"])
		if ntex:
			mat.normal_enabled = true
			mat.normal_texture = ntex
			# If DirectX normal map was detected, invert Y scale automatically!
			if slots["normal"].get("flip_green_y", false):
				mat.normal_scale = -1.0

	if slots.has("orm"):
		var otex := _try_load_tex(slots["orm"]["path"])
		if otex:
			mat.ao_enabled = true
			mat.ao_texture = otex
			mat.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
			mat.roughness_texture = otex
			mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
			mat.metallic = 1.0
			mat.metallic_texture = otex
			mat.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	else:
		if slots.has("roughness"):
			var rtex := _try_load_tex(slots["roughness"]["path"])
			if rtex:
				mat.roughness_texture = rtex
		if slots.has("metallic"):
			var mtex := _try_load_tex(slots["metallic"]["path"])
			if mtex:
				mat.metallic = 1.0
				mat.metallic_texture = mtex
		if slots.has("ao"):
			var atex := _try_load_tex(slots["ao"]["path"])
			if atex:
				mat.ao_enabled = true
				mat.ao_texture = atex

	if slots.has("emission"):
		var etex := _try_load_tex(slots["emission"]["path"])
		if etex:
			mat.emission_enabled = true
			mat.emission_texture = etex

	if slots.has("height"):
		var htex := _try_load_tex(slots["height"]["path"])
		if htex:
			mat.heightmap_enabled = true
			mat.heightmap_texture = htex

	if slots.has("opacity"):
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR

	return mat


func _try_load_tex(abs_or_res_path: String) -> Texture2D:
	var local_res := ProjectSettings.localize_path(abs_or_res_path)
	if ResourceLoader.exists(local_res):
		return load(local_res) as Texture2D
	if FileAccess.file_exists(abs_or_res_path):
		var img := Image.load_from_file(abs_or_res_path)
		if img:
			return ImageTexture.create_from_image(img)
	return null
