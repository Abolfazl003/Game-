@tool
extends Node3D
## Populates `NovaForgeSandbox` with REAL textured, rigged, animated `.glb` 3D models in BOTH
## Godot 4 Editor (`@tool`) and Runtime Play Mode (`F5`) — ZERO primitive capsules or boxes!

const LoaderScript := preload("res://addons/novaforge_engine/forge/glb_asset_loader.gd")


func _ready() -> void:
	call_deferred("_mount_real_3d_world")


func _mount_real_3d_world() -> void:
	# 1. Playable Hero: True 360° Neural AI Sculpted & 19-Bone Auto-Rigged Cyberpunk Samurai (.GLB)
	var hero := get_node_or_null("SamuraiHero") as Node3D
	if hero and hero.get_node_or_null("RealHeroModel3D") == null:
		var hero_path := "res://assets/models/characters/ai_cyber_hero_360.glb"
		if not FileAccess.file_exists(hero_path):
			hero_path = "res://assets/models/characters/ninja_samurai.glb"
		var m_hero := LoaderScript.load_model_scene(hero_path, 1.88)
		if m_hero:
			m_hero.name = "RealHeroModel3D"
			m_hero.rotation_degrees.y = 0.0
			hero.add_child(m_hero)
			LoaderScript.play_character_anim(m_hero, ["Idle"], true)

	# 2. Kaveh Blacksmith Living NPC (Real Rigged 3D Character + Hammer)
	var kaveh := get_node_or_null("KavehBlacksmithNPC") as Node3D
	if kaveh and kaveh.get_node_or_null("RealNPCModel3D") == null:
		var m_npc := LoaderScript.load_model_scene("res://assets/models/characters/kaveh_blacksmith.glb", 1.85)
		if m_npc:
			m_npc.name = "RealNPCModel3D"
			m_npc.rotation_degrees.y = 25.0
			kaveh.add_child(m_npc)
			LoaderScript.play_character_anim(m_npc, ["Idle"], true)
		var hammer := LoaderScript.load_model_scene("res://assets/models/weapons/blacksmith_hammer.glb", 0.95)
		if hammer:
			hammer.name = "AnvilHammerProp"
			hammer.position = Vector3(0.68, 0.0, 0.35)
			hammer.rotation_degrees = Vector3(0, 35, -18)
			kaveh.add_child(hammer)

	# 3. Destructible Ancient Crate (Real Textured 3D Wooden Crate)
	var crate := get_node_or_null("DestructibleAncientCrate") as Node3D
	if crate and crate.get_node_or_null("CrateMesh") == null:
		var m_crate := LoaderScript.load_model_scene("res://assets/models/world/wooden_crate.glb", 1.05)
		if m_crate:
			m_crate.name = "CrateMesh"
			crate.add_child(m_crate)

	# 4. Rich 3D Backdrop Props (Castle Gate, Watchtower, Forest Pines, Rocks, Campfire & Treasure Chest)
	if get_node_or_null("EnvironmentScenery3D") == null:
		var scenery := Node3D.new()
		scenery.name = "EnvironmentScenery3D"
		add_child(scenery)

		var placements := [
			["res://assets/models/world/castle_gate.glb", 4.6, Vector3(0.0, 0.0, -6.2), 0.0],
			["res://assets/models/world/castle_tower.glb", 6.2, Vector3(-5.2, 0.0, -6.8), 15.0],
			["res://assets/models/world/castle_wall.glb", 3.6, Vector3(3.6, 0.0, -6.3), 0.0],
			["res://assets/models/world/tree_forest.glb", 4.2, Vector3(-6.4, 0.0, -2.2), 25.0],
			["res://assets/models/world/tree_forest.glb", 4.6, Vector3(6.2, 0.0, -3.4), -40.0],
			["res://assets/models/world/tree_oak.glb", 4.4, Vector3(5.6, 0.0, 2.2), 18.0],
			["res://assets/models/world/rock_boulder.glb", 1.5, Vector3(-4.5, 0.0, 1.8), 50.0],
			["res://assets/models/world/treasure_chest.glb", 0.85, Vector3(1.4, 0.0, -5.0), -15.0],
			["res://assets/models/world/campfire.glb", 0.55, Vector3(-1.5, 0.0, -0.6), 0.0],
		]
		for item in placements:
			var inst := LoaderScript.load_model_scene(str(item[0]), float(item[1]))
			if inst:
				inst.position += item[2] as Vector3
				inst.rotation_degrees.y = float(item[3])
				scenery.add_child(inst)
				if str(item[0]).ends_with("campfire.glb"):
					var light := OmniLight3D.new()
					light.light_color = Color(1.0, 0.58, 0.18)
					light.light_energy = 2.6
					light.omni_range = 6.5
					light.position = Vector3(0, 0.75, 0)
					inst.add_child(light)
