@tool
extends Node
class_name NovaVisualQualityManager
## One-Click Visual Quality & Art-Style Switcher (`NovaQuality`).
## Reconfigures Godot 4 RenderingServer, WorldEnvironment, DirectionalLight3D shadows,
## shader overrides, and AI 3D polygon/texture budgets across AAA Unreal-Grade,
## Standard Unity-Style, and Indie Stylized presets.

signal quality_tier_changed(tier_id: String, profile: Dictionary)

const TIER_PROFILES: Dictionary = {
	"AAA_UNREAL": {
		"label": "AAA / Unreal-Grade (Forward+ Photoreal)",
		"renderer": "forward_plus",
		"sdfgi": true,
		"ssr": true,
		"ssao": true,
		"ssil": true,
		"volumetric_fog": true,
		"glow_bloom": true,
		"tonemap": Environment.TONE_MAPPER_ACES,
		"shadow_atlas_size": 4096,
		"msaa_3d": Viewport.MSAA_4X,
		"fsr_upscale": true,
		"max_poly_budget": 85000,
		"texture_max_res": 4096,
		"style_shader": ""
	},
	"STANDARD_UNITY": {
		"label": "Standard / Unity-Style (Balanced Crisp 60+ FPS)",
		"renderer": "forward_plus",
		"sdfgi": false,
		"ssr": false,
		"ssao": true,
		"ssil": false,
		"volumetric_fog": false,
		"glow_bloom": true,
		"tonemap": Environment.TONE_MAPPER_FILMIC,
		"shadow_atlas_size": 2048,
		"msaa_3d": Viewport.MSAA_2X,
		"fsr_upscale": false,
		"max_poly_budget": 25000,
		"texture_max_res": 2048,
		"style_shader": ""
	},
	"INDIE_CEL_ANIME": {
		"label": "Indie / Cel-Shaded Anime (Zelda / Genshin Style)",
		"renderer": "forward_plus",
		"sdfgi": false,
		"ssr": false,
		"ssao": false,
		"ssil": false,
		"volumetric_fog": false,
		"glow_bloom": true,
		"tonemap": Environment.TONE_MAPPER_AGX,
		"shadow_atlas_size": 2048,
		"msaa_3d": Viewport.MSAA_4X,
		"fsr_upscale": false,
		"max_poly_budget": 15000,
		"texture_max_res": 1024,
		"style_shader": "res://shaders/cel_toon_outline.gdshader"
	},
	"INDIE_LOWPOLY_COZY": {
		"label": "Indie / Low-Poly Cozy (Ultra-Fast Stylized)",
		"renderer": "mobile",
		"sdfgi": false,
		"ssr": false,
		"ssao": true,
		"ssil": false,
		"volumetric_fog": false,
		"glow_bloom": true,
		"tonemap": Environment.TONE_MAPPER_FILMIC,
		"shadow_atlas_size": 1024,
		"msaa_3d": Viewport.MSAA_2X,
		"fsr_upscale": false,
		"max_poly_budget": 3500,
		"texture_max_res": 512,
		"style_shader": ""
	},
	"INDIE_HD2D": {
		"label": "Indie / HD-2D Diorama (Pixel Sprites + 3D GI & DOF)",
		"renderer": "forward_plus",
		"sdfgi": true,
		"ssr": false,
		"ssao": true,
		"ssil": false,
		"volumetric_fog": true,
		"glow_bloom": true,
		"tonemap": Environment.TONE_MAPPER_ACES,
		"shadow_atlas_size": 2048,
		"msaa_3d": Viewport.MSAA_DISABLED,
		"fsr_upscale": false,
		"max_poly_budget": 8000,
		"texture_max_res": 512,
		"style_shader": ""
	},
	"INDIE_PSX_RETRO": {
		"label": "Indie / PSX Retro (Vertex Snap + Bayer Dither)",
		"renderer": "gl_compatibility",
		"sdfgi": false,
		"ssr": false,
		"ssao": false,
		"ssil": false,
		"volumetric_fog": false,
		"glow_bloom": false,
		"tonemap": Environment.TONE_MAPPER_LINEAR,
		"shadow_atlas_size": 512,
		"msaa_3d": Viewport.MSAA_DISABLED,
		"fsr_upscale": false,
		"max_poly_budget": 1200,
		"texture_max_res": 256,
		"style_shader": "res://shaders/psx_retro.gdshader"
	}
}

var current_tier: String = "AAA_UNREAL"


func apply_quality_tier(tier_id: String, target_root: Node = null) -> Dictionary:
	var key := tier_id.to_upper()
	if not TIER_PROFILES.has(key):
		return {"ok": false, "error": "Unknown quality tier: " + tier_id}

	current_tier = key
	var p: Dictionary = TIER_PROFILES[key]

	if get_viewport():
		get_viewport().msaa_3d = p["msaa_3d"]
		if p["fsr_upscale"]:
			get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
			get_viewport().scaling_3d_scale = 0.77
		else:
			get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
			get_viewport().scaling_3d_scale = 1.0

	RenderingServer.directional_shadow_atlas_set_size(int(p["shadow_atlas_size"]), true)

	var scene_root := target_root
	if scene_root == null and get_tree():
		scene_root = get_tree().current_scene
	if scene_root:
		_configure_world_environment(scene_root, p)

	quality_tier_changed.emit(current_tier, p)
	return {"ok": true, "tier": current_tier, "profile": p}


func _configure_world_environment(root: Node, p: Dictionary) -> void:
	var world_env: WorldEnvironment = null
	for child in root.get_children():
		if child is WorldEnvironment:
			world_env = child
			break
	if world_env == null:
		world_env = WorldEnvironment.new()
		world_env.name = "NovaWorldEnvironment"
		root.add_child(world_env)
		world_env.owner = root

	if world_env.environment == null:
		world_env.environment = Environment.new()

	var env := world_env.environment
	env.tonemap_mode = p["tonemap"]
	env.sdfgi_enabled = p["sdfgi"]
	env.ssr_enabled = p["ssr"]
	env.ssao_enabled = p["ssao"]
	env.ssil_enabled = p["ssil"]
	env.volumetric_fog_enabled = p["volumetric_fog"]
	env.glow_enabled = p["glow_bloom"]
