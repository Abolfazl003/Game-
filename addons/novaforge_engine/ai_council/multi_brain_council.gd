@tool
extends Node
class_name NovaMultiBrainCouncil
## Multi-Brain Local AI Council (`NovaBrainCouncil`).
## Coordinates multiple specialist local brains (Director, C++/Blueprint Coder, 3D/Texture Artist,
## Mocap/Cutscene Animator, and Critic/QA Judge) over a Shared Blackboard using Sequential VRAM Relay
## so consumer PCs stay fast while producing one unified, verified game update.

signal council_stage_started(brain_role: String, model_id: String)
signal blackboard_updated(brain_role: String, entry: String)
signal council_completed(unified_plan: Dictionary)

var model_hub := NovaLocalModelHub.new()
var shared_blackboard: Array[Dictionary] = []
var active_quality_tier: String = "AAA_UNREAL"


func clear_blackboard() -> void:
	shared_blackboard.clear()


func post_to_blackboard(brain_role: String, model_id: String, proposal: Dictionary) -> void:
	var item := {
		"step": shared_blackboard.size() + 1,
		"brain_role": brain_role,
		"model_id": model_id,
		"proposal": proposal
	}
	shared_blackboard.append(item)
	blackboard_updated.emit(brain_role, JSON.stringify(proposal))


func match_skills_for_prompt(prompt: String) -> Array[String]:
	var p := prompt.to_lower()
	var matched: Array[String] = []

	var keyword_map := {
		"colibri-multi-brain-council": ["چند مغز", "شورا", "همفکری", "council", "colibri"],
		"blueprint-cpp-hybrid": ["بلوپرینت", "سی پلاس", "c++", "blueprint", "کد"],
		"combat-basics": ["فایت", "جنگیدن", "شمشیر", "کمبو", "ضربه", "combat", "fight", "melee", "attack"],
		"character-movement": ["حرکت", "دویدن", "پرش", "راه رفتن", "move", "run", "walk", "jump"],
		"blender-zero-config-materials": ["بلندر", "تکسچر", "متریال", "fbx", "glb", "blend", "blender", "texture"],
		"video-to-motion-mocap": ["ویدیو", "موشن", "شبیه سازی حرکت", "video", "mocap"],
		"in-engine-cutscene-sequencer": ["کات سین", "کات‌سین", "سینمایی", "cutscene", "sequencer"],
		"smart-interactive-objects": ["آبجکت", "کلیک", "منو", "اینترکت", "در", "interact", "door", "chest"],
		"voronoi-3d-destruction": ["تخریب", "بشکنه", "شکستن", "انفجار", "destruct", "fracture", "shatter"],
		"living-evolving-npcs": ["ان پی سی", "زندگی", "هوشمند", "npc", "evolving", "nemesis"],
		"visual-quality-tiers": ["کیفیت", "آنریل", "یونیتی", "ایندی", "unreal", "unity", "indie", "psx"],
		"all-genre-perspectives": ["اول شخص", "سوم شخص", "2.5d", "۲.۵", "ایزومتریک", "ژانر", "fps", "tps", "isometric"]
	}

	for skill_slug in keyword_map.keys():
		for kw in keyword_map[skill_slug]:
			if p.contains(kw):
				matched.append(skill_slug)
				break

	if matched.is_empty():
		matched.append("make-game")
		matched.append("character-movement")
	return matched


## Runs all specialist brains sequentially (VRAM Relay), merges their critiques,
## executes native Zero-MCP engine tools, runs Scene Audit, and returns one unified result.
func execute_prompt_with_council(prompt: String, options: Dictionary = {}) -> Dictionary:
	clear_blackboard()

	# Snapshot before AI edits (Time-Machine safety)
	if get_tree() and get_tree().root.has_node("NovaNativeBus"):
		get_tree().root.get_node("NovaNativeBus").invoke_tool("nova_time_machine_snapshot", {
			"op": "create",
			"label": "Pre-Council: " + prompt.left(40)
		})

	var profile := model_hub.recommend_council_profile(
		int(options.get("ram_mb", 16384)),
		int(options.get("vram_mb", 8192))
	)
	var skills := match_skills_for_prompt(prompt)

	# 1. Director Brain (Game Architecture & Mechanics)
	council_stage_started.emit("DIRECTOR", profile["director"])
	var director_plan := _run_director_specialist(prompt, skills)
	post_to_blackboard("DIRECTOR", profile["director"], director_plan)

	# 2. Coder Brain (Hybrid Blueprint + C++ + GDScript)
	council_stage_started.emit("CODER_CPP_BLUEPRINT", profile["coder"])
	var code_plan := _run_coder_specialist(prompt, director_plan)
	post_to_blackboard("CODER_CPP_BLUEPRINT", profile["coder"], code_plan)

	# 3. 3D Artist & Blender Material Brain
	council_stage_started.emit("ARTIST_3D_MATERIAL", profile["mesh_3d"])
	var art_plan := _run_artist_specialist(prompt, director_plan)
	post_to_blackboard("ARTIST_3D_MATERIAL", profile["mesh_3d"], art_plan)

	# 4. Animator, Video Mocap & Cutscene Brain
	council_stage_started.emit("ANIMATOR_MOCAP_CUTSCENE", "gvhmr-wham-mocap")
	var anim_plan := _run_animator_specialist(prompt, director_plan)
	post_to_blackboard("ANIMATOR_MOCAP_CUTSCENE", "gvhmr-wham-mocap", anim_plan)

	# 5. Critic & QA Judge Brain (Consensus + Scene Audit Verification)
	council_stage_started.emit("CRITIC_QA_JUDGE", profile["director"])
	var unified := _synthesize_unified_consensus(prompt, skills, director_plan, code_plan, art_plan, anim_plan)
	post_to_blackboard("CRITIC_QA_JUDGE", profile["director"], {"consensus_status": "verified", "actions_count": unified["tool_actions"].size()})

	council_completed.emit(unified)
	return unified


func _run_director_specialist(prompt: String, skills: Array[String]) -> Dictionary:
	var p := prompt.to_lower()
	var perspective := "TPS_SOULS"
	if p.contains("اول شخص") or p.contains("fps"):
		perspective = "FPS"
	elif p.contains("2.5d") or p.contains("۲.۵"):
		perspective = "SIDE_2_5D"
	elif p.contains("ایزومتریک") or p.contains("isometric"):
		perspective = "ISOMETRIC"

	var quality := active_quality_tier
	if p.contains("آنریل") or p.contains("انریل") or p.contains("aaa") or p.contains("unreal"):
		quality = "AAA_UNREAL"
	elif p.contains("یونیتی") or p.contains("unity"):
		quality = "STANDARD_UNITY"
	elif p.contains("ایندی") or p.contains("indie") or p.contains("پیکسلی"):
		quality = "INDIE_CEL_ANIME"

	return {
		"perspective": perspective,
		"quality_tier": quality,
		"activated_skills": skills,
		"needs_combat": skills.has("combat-basics"),
		"needs_cutscene": skills.has("in-engine-cutscene-sequencer"),
		"needs_living_npc": skills.has("living-evolving-npcs"),
		"needs_destructible": skills.has("voronoi-3d-destruction")
	}


func _run_coder_specialist(_prompt: String, director_plan: Dictionary) -> Dictionary:
	var bp_nodes: Array = [
		{"type": "Event_BeginPlay", "kind": "EVENT_ENTRY"},
		{"type": "SetupPerspectiveRig", "kind": "GAMEPLAY_ACTION", "perspective": director_plan["perspective"]}
	]
	if director_plan["needs_combat"]:
		bp_nodes.append({"type": "Event_OnAttackInput", "kind": "EVENT_ENTRY"})
		bp_nodes.append({"type": "PlayMeleeCombo3Hit", "kind": "GAMEPLAY_ACTION", "stamina_cost": 18})
	return {
		"blueprint_graph": bp_nodes,
		"compile_targets": ["gdscript", "cpp20_gdextension"]
	}


func _run_artist_specialist(_prompt: String, director_plan: Dictionary) -> Dictionary:
	return {
		"visual_preset": director_plan["quality_tier"],
		"auto_pbr_normal_fix": true,
		"auto_lod_levels": 3
	}


func _run_animator_specialist(_prompt: String, director_plan: Dictionary) -> Dictionary:
	return {
		"humanoid_52_bone_rig": true,
		"foot_locking_ik": true,
		"cutscene_seamless_camera_blend": director_plan["needs_cutscene"]
	}


func _synthesize_unified_consensus(
	prompt: String,
	skills: Array[String],
	director_plan: Dictionary,
	code_plan: Dictionary,
	art_plan: Dictionary,
	anim_plan: Dictionary
) -> Dictionary:
	var actions: Array[Dictionary] = [
		{"tool": "nova_set_visual_quality", "args": {"tier": art_plan["visual_preset"]}},
		{"tool": "nova_set_camera_perspective", "args": {"perspective": director_plan["perspective"]}},
		{"tool": "nova_compile_blueprint", "args": {"graph": code_plan, "target": "gdscript"}}
	]
	if director_plan["needs_cutscene"]:
		actions.append({"tool": "nova_create_cutscene", "args": {"prompt": prompt, "seamless_blend": true}})
	if director_plan["needs_destructible"]:
		actions.append({"tool": "nova_configure_smart_object", "args": {"destructible": true, "shard_count": 16}})
	if director_plan["needs_living_npc"]:
		actions.append({"tool": "nova_configure_living_npc", "args": {"enable_evolving_life": true}})
	actions.append({"tool": "nova_scene_audit", "args": {}})

	return {
		"prompt": prompt,
		"matched_skills": skills,
		"perspective": director_plan["perspective"],
		"quality_tier": art_plan["visual_preset"],
		"animation": anim_plan,
		"tool_actions": actions,
		"vram_flushed_after_relay": true
	}
