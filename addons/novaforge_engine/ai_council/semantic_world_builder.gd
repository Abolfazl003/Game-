@tool
extends RefCounted
## Semantic Persian & English 3D World & Object Builder (`NovaSemanticWorldBuilder`).
## Parses natural Persian/English prompts (objects, characters, vehicles, weapons, castles, houses,
## nature, quantities, colors, scales, and layouts) and spawns REAL textured, rigged, animated `.glb`
## 3D models — NEVER primitive ovals/capsules or boxes!

const LoaderScript := preload("res://addons/novaforge_engine/forge/glb_asset_loader.gd")

const CATALOG := [
	# Rigged & Animated Characters
	{"id": "samurai", "path": "res://assets/models/characters/ninja_samurai.glb", "height": 1.85, "anim": ["SwordSlash", "Idle"], "type": "char", "label": "سامورایی / نینجا", "kw": ["سامورایی", "نینجا", "شمشیرزن", "قهرمان", "samurai", "ninja", "shinobi"]},
	{"id": "knight", "path": "res://assets/models/characters/golden_knight.glb", "height": 1.92, "anim": ["Idle", "SwordSlash"], "type": "char", "label": "شوالیه زره‌پوش طلایی", "kw": ["شوالیه", "پهلوان", "جنگجو", "زره", "باس", "knight", "paladin", "warrior", "boss"]},
	{"id": "viking", "path": "res://assets/models/characters/viking_warrior.glb", "height": 1.95, "anim": ["Punch", "Idle"], "type": "char", "label": "وایکینگ جنگجو", "kw": ["وایکینگ", "بربر", "غول", "viking", "barbarian"]},
	{"id": "soldier", "path": "res://assets/models/characters/modern_soldier.glb", "height": 1.85, "anim": ["Shoot_OneHanded", "Idle"], "type": "char", "label": "سرباز کماندو", "kw": ["سرباز", "کماندو", "پلیس", "تیرانداز", "نگهبان", "soldier", "guard", "shooter"]},
	{"id": "wizard", "path": "res://assets/models/characters/wizard_mage.glb", "height": 1.88, "anim": ["Victory", "Idle"], "type": "char", "label": "جادوگر اعظم", "kw": ["جادوگر", "ساحر", "موبد", "wizard", "mage", "sorcerer"]},
	{"id": "blacksmith", "path": "res://assets/models/characters/kaveh_blacksmith.glb", "height": 1.85, "anim": ["Idle", "Walk"], "type": "npc", "label": "آهنگر / فروشنده شهر", "kw": ["آهنگر", "فروشنده", "کاوه", "روستایی", "مرد", "آدم", "کاراکتر", "blacksmith", "villager", "npc"]},
	{"id": "goblin", "path": "res://assets/models/characters/goblin_enemy.glb", "height": 1.55, "anim": ["Punch", "Run"], "type": "enemy", "label": "گابلین مهاجم", "kw": ["گابلین", "دیو", "هیولا", "اجنه", "goblin", "orc", "monster"]},
	{"id": "zombie", "path": "res://assets/models/characters/zombie_enemy.glb", "height": 1.82, "anim": ["Walk", "Punch"], "type": "enemy", "label": "زامبی", "kw": ["زامبی", "مرده", "دشمن", "zombie", "undead", "enemy"]},
	{"id": "dog", "path": "res://assets/models/characters/dog_companion.glb", "height": 0.90, "anim": ["Run", "Idle"], "type": "char", "label": "سگ / حیوان همراه", "kw": ["سگ", "گرگ", "حیوان", "پت", "dog", "wolf", "pet", "animal"]},

	# Vehicles
	{"id": "sports_car", "path": "res://assets/models/vehicles/sports_car.glb", "height": 1.25, "anim": [], "type": "vehicle", "label": "ماشین اسپرت مسابقه‌ای", "kw": ["ماشین اسپرت", "خودرو", "ماشین مسابقه", "ماشین", "اتومبیل", "car", "sports car", "race"]},
	{"id": "cyber_car", "path": "res://assets/models/vehicles/cyber_car.glb", "height": 1.22, "anim": [], "type": "vehicle", "label": "ماشین سایبرپانک آینده", "kw": ["سایبرپانک", "ماشین آینده", "فضایی", "cyber", "futuristic car"]},
	{"id": "police_car", "path": "res://assets/models/vehicles/police_car.glb", "height": 1.38, "anim": [], "type": "vehicle", "label": "ماشین پلیس", "kw": ["ماشین پلیس", "گشتی", "police car"]},
	{"id": "suv", "path": "res://assets/models/vehicles/suv_offroad.glb", "height": 1.52, "anim": [], "type": "vehicle", "label": "شاسی‌بلند آفرود", "kw": ["شاسی بلند", "شاسی‌بلند", "جیپ", "آفرود", "suv", "jeep", "offroad"]},
	{"id": "truck", "path": "res://assets/models/vehicles/heavy_truck.glb", "height": 2.35, "anim": [], "type": "vehicle", "label": "کامیون سنگین", "kw": ["کامیون", "تریلی", "وانت", "truck"]},
	{"id": "ship", "path": "res://assets/models/vehicles/pirate_ship.glb", "height": 5.20, "anim": [], "type": "vehicle", "label": "کشتی جنگی بادبانی", "kw": ["کشتی", "قایق", "لنج", "ship", "boat", "pirate"]},

	# Weapons
	{"id": "blade", "path": "res://assets/models/weapons/combat_blade.glb", "height": 1.25, "anim": [], "type": "weapon", "label": "شمشیر / خنجر رزمی", "kw": ["شمشیر", "کاتانا", "خنجر", "تیغه", "sword", "katana", "blade", "knife"]},
	{"id": "axe", "path": "res://assets/models/weapons/battle_axe.glb", "height": 1.30, "anim": [], "type": "weapon", "label": "تبر جنگی", "kw": ["تبر", "axe"]},
	{"id": "hammer", "path": "res://assets/models/weapons/blacksmith_hammer.glb", "height": 1.15, "anim": [], "type": "weapon", "label": "پتک / چکش جنگی", "kw": ["پتک", "چکش", "گرز", "hammer", "mace"]},
	{"id": "rifle", "path": "res://assets/models/weapons/assault_rifle.glb", "height": 0.55, "anim": [], "type": "weapon", "label": "تفنگ تهاجمی", "kw": ["تفنگ", "اسلحه", "کلاش", "مسلسل", "سلاح", "gun", "rifle", "weapon"]},
	{"id": "sniper", "path": "res://assets/models/weapons/sniper_rifle.glb", "height": 0.52, "anim": [], "type": "weapon", "label": "اسنایپر تک‌تیرانداز", "kw": ["اسنایپر", "تک تیرانداز", "sniper"]},
	{"id": "rpg", "path": "res://assets/models/weapons/rocket_launcher.glb", "height": 0.65, "anim": [], "type": "weapon", "label": "آرپی‌جی / موشک‌انداز", "kw": ["موشک", "آرپی‌جی", "آر پی جی", "بازوکا", "rocket", "rpg"]},
	{"id": "cannon", "path": "res://assets/models/weapons/war_cannon.glb", "height": 1.35, "anim": [], "type": "weapon", "label": "توپ جنگی قلعه", "kw": ["توپ جنگی", "توپخانه", "cannon"]},

	# Buildings, Castles, Nature & Destructible Props
	{"id": "castle_gate", "path": "res://assets/models/world/castle_gate.glb", "height": 4.50, "anim": [], "type": "structure", "label": "دروازه سنگی قلعه", "kw": ["دروازه", "قلعه", "دژ", "ارگ", "gate", "castle"]},
	{"id": "castle_tower", "path": "res://assets/models/world/castle_tower.glb", "height": 6.20, "anim": [], "type": "structure", "label": "برج دیده‌بانی قلعه", "kw": ["برج", "برجک", "مناره", "tower"]},
	{"id": "castle_wall", "path": "res://assets/models/world/castle_wall.glb", "height": 3.60, "anim": [], "type": "structure", "label": "دیوار دفاعی سنگی", "kw": ["دیوار", "حصار", "بارو", "wall"]},
	{"id": "house", "path": "res://assets/models/buildings/house_suburban.glb", "height": 4.40, "anim": [], "type": "structure", "label": "خانه ویلایی", "kw": ["خانه", "خونه", "کلبه", "ویلا", "روستا", "دهکده", "house", "home", "village"]},
	{"id": "city_bldg", "path": "res://assets/models/buildings/city_building.glb", "height": 7.50, "anim": [], "type": "structure", "label": "ساختمان شهری", "kw": ["ساختمان", "برج شهری", "آپارتمان", "شهر", "building", "city"]},
	{"id": "bridge", "path": "res://assets/models/world/bridge_stone.glb", "height": 1.65, "anim": [], "type": "structure", "label": "پل سنگی", "kw": ["پل", "bridge"]},
	{"id": "tent", "path": "res://assets/models/world/camp_tent.glb", "height": 2.40, "anim": [], "type": "structure", "label": "چادر کمپ", "kw": ["چادر", "کمپ", "اردوگاه", "tent", "camp"]},
	{"id": "obelisk", "path": "res://assets/models/world/ancient_obelisk.glb", "height": 4.20, "anim": [], "type": "structure", "label": "ستون باستانی", "kw": ["ستون", "مجسمه", "باستانی", "معبد", "statue", "obelisk", "temple"]},
	{"id": "crate", "path": "res://assets/models/world/wooden_crate.glb", "height": 0.95, "anim": [], "type": "destructible", "label": "صندوق چوبی (قابل تخریب)", "kw": ["صندوق", "جعبه", "باکس", "crate", "box"]},
	{"id": "barrel", "path": "res://assets/models/world/wooden_barrel.glb", "height": 1.05, "anim": [], "type": "destructible", "label": "بشکه چوبی (قابل تخریب)", "kw": ["بشکه", "گالن", "barrel"]},
	{"id": "chest", "path": "res://assets/models/world/treasure_chest.glb", "height": 0.92, "anim": [], "type": "destructible", "label": "صندوقچه گنج", "kw": ["گنج", "صندوقچه", "chest", "treasure"]},
	{"id": "campfire", "path": "res://assets/models/world/campfire.glb", "height": 0.65, "anim": [], "type": "campfire", "label": "آتش کمپ نورانی", "kw": ["آتش کمپ", "آتیش", "شعله", "campfire", "bonfire"]},
	{"id": "tree_forest", "path": "res://assets/models/world/tree_forest.glb", "height": 4.20, "anim": [], "type": "nature", "label": "درخت کاج جنگلی", "kw": ["درخت", "کاج", "جنگل", "tree", "pine", "forest"]},
	{"id": "tree_oak", "path": "res://assets/models/world/tree_oak.glb", "height": 4.50, "anim": [], "type": "nature", "label": "درخت بلوط", "kw": ["بلوط", "oak"]},
	{"id": "tree_palm", "path": "res://assets/models/world/tree_palm.glb", "height": 5.00, "anim": [], "type": "nature", "label": "درخت نخل ساحلی", "kw": ["نخل", "جزیره", "ساحل", "palm", "island"]},
	{"id": "rock", "path": "res://assets/models/world/rock_boulder.glb", "height": 1.50, "anim": [], "type": "nature", "label": "صخره سنگی", "kw": ["سنگ", "صخره", "کوه", "rock", "stone", "cliff"]},
]


static func build_from_prompt(scene_root: Node3D, prompt_text: String, clear_previous_ai: bool = false) -> Dictionary:
	if scene_root == null:
		return {"ok": false, "spawned": []}

	var holder := scene_root.get_node_or_null("NovaAISpawnedWorld") as Node3D
	if holder and clear_previous_ai:
		holder.queue_free()
		holder = null
	if holder == null:
		holder = Node3D.new()
		holder.name = "NovaAISpawnedWorld"
		scene_root.add_child(holder)
		if scene_root.owner:
			holder.owner = scene_root.owner
		else:
			holder.owner = scene_root

	var p := prompt_text.to_lower()
	var tint := _detect_color_tint(p)
	var scale_mult := _detect_scale_multiplier(p)
	var base_count := _detect_count(p)

	# Match all requested catalog items from the prompt!
	var matched_entries: Array[Dictionary] = []
	for entry in CATALOG:
		for kw in entry["kw"]:
			if p.contains(str(kw)):
				matched_entries.append(entry)
				break

	# Macro environment presets if broad biome words are mentioned
	if p.contains("جنگل") or p.contains("forest"):
		_add_unique_by_id(matched_entries, "tree_forest")
		_add_unique_by_id(matched_entries, "tree_oak")
		_add_unique_by_id(matched_entries, "rock")
		_add_unique_by_id(matched_entries, "campfire")
	if p.contains("شهر") or p.contains("خیابان") or p.contains("city"):
		_add_unique_by_id(matched_entries, "city_bldg")
		_add_unique_by_id(matched_entries, "house")
		_add_unique_by_id(matched_entries, "sports_car")
		_add_unique_by_id(matched_entries, "police_car")
	if p.contains("قلعه") or p.contains("نبرد") or p.contains("میدان") or p.contains("castle"):
		_add_unique_by_id(matched_entries, "castle_gate")
		_add_unique_by_id(matched_entries, "castle_tower")
		_add_unique_by_id(matched_entries, "knight")
		_add_unique_by_id(matched_entries, "crate")

	# Fallback rich fantasy encounter if prompt was completely abstract (e.g. "یه بازی خفن بساز")
	if matched_entries.is_empty():
		_add_unique_by_id(matched_entries, "knight")
		_add_unique_by_id(matched_entries, "goblin")
		_add_unique_by_id(matched_entries, "castle_gate")
		_add_unique_by_id(matched_entries, "tree_forest")
		_add_unique_by_id(matched_entries, "chest")

	var spawned_labels: Array[String] = []
	var existing_offset := holder.get_child_count()
	var idx := 0

	for entry in matched_entries:
		var copies := base_count if matched_entries.size() == 1 else (3 if entry["type"] == "nature" else 1)
		copies = clampi(copies, 1, 8)
		for c in range(copies):
			var target_h: float = float(entry["height"]) * scale_mult
			var item_tint := tint if (matched_entries.size() <= 2 or entry["type"] == "vehicle" or entry["type"] == "weapon") else Color(1, 1, 1, 0)
			var inst := LoaderScript.load_model_scene(str(entry["path"]), target_h, item_tint)
			if inst == null:
				continue

			inst.name = str(entry["id"]).capitalize() + "_" + str(existing_offset + idx + 1)

			# Intelligent spatial placement (structures/trees further out, characters/cars/weapons near front-center)
			var pos := _compute_smart_slot(str(entry["type"]), existing_offset + idx, copies)
			if entry["type"] == "weapon":
				pos.y += 0.95
			inst.position += pos
			# Face toward player/camera (+Z)
			if entry["type"] in ["char", "enemy", "npc", "vehicle"]:
				inst.rotation.y = atan2(-pos.x, 3.5 - pos.z)

			holder.add_child(inst)

			var anims: Array = entry["anim"]
			if not anims.is_empty():
				LoaderScript.play_character_anim(inst, anims, true)

			if entry["type"] == "campfire":
				_attach_campfire_flame(inst)

			var tag := Label3D.new()
			tag.text = str(entry["label"])
			tag.font_size = 24
			tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			tag.modulate = Color(0.75, 0.93, 1.0)
			tag.position = Vector3(0, target_h / maxf(0.01, inst.scale.y) + 0.35, 0)
			inst.add_child(tag)

			spawned_labels.append(str(entry["label"]))
			idx += 1

	return {
		"ok": true,
		"count": spawned_labels.size(),
		"spawned": spawned_labels
	}


static func _add_unique_by_id(arr: Array[Dictionary], id_name: String) -> void:
	for existing in arr:
		if existing["id"] == id_name:
			return
	for item in CATALOG:
		if item["id"] == id_name:
			arr.append(item)
			return


static func _compute_smart_slot(item_type: String, slot_idx: int, total_copies: int) -> Vector3:
	var angle := float(slot_idx) * 1.15 + 0.35
	match item_type:
		"structure":
			return Vector3(sin(angle) * 5.8, 0.0, -5.2 - float(slot_idx % 3) * 2.4)
		"nature":
			var r := 5.2 + float(slot_idx % 4) * 1.8
			return Vector3(cos(angle) * r, 0.0, sin(angle) * r - 2.0)
		"vehicle":
			return Vector3(-2.6 + float(slot_idx % 3) * 2.8, 0.0, -1.6 - float(slot_idx / 3) * 3.2)
		_:
			if total_copies == 1 and slot_idx == 0:
				return Vector3(1.8, 0.0, -1.2)
			var rad := 2.4 + float(slot_idx / 4) * 1.6
			return Vector3(cos(angle) * rad, 0.0, -1.5 + sin(angle) * 1.8)


static func _attach_campfire_flame(camp_node: Node3D) -> void:
	var fire := CPUParticles3D.new()
	fire.amount = 48
	fire.lifetime = 0.75
	fire.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	fire.emission_sphere_radius = 0.25
	fire.gravity = Vector3(0.0, 3.8, 0.0)
	var sp := SphereMesh.new()
	sp.radius = 0.08; sp.height = 0.16
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.albedo_color = Color(1.0, 0.48, 0.10)
	sp.material = fmat
	fire.mesh = sp
	fire.position = Vector3(0, 0.25, 0)
	camp_node.add_child(fire)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.56, 0.18)
	light.light_energy = 3.2
	light.omni_range = 7.5
	light.position = Vector3(0, 0.85, 0)
	camp_node.add_child(light)


static func _detect_count(p: String) -> int:
	var word_nums := {
		"دو تا": 2, "دوتا": 2, "دو ": 2, "two": 2, "2": 2, "۲": 2,
		"سه تا": 3, "سه‌تا": 3, "سه ": 3, "three": 3, "3": 3, "۳": 3,
		"چهار": 4, "four": 4, "4": 4, "۴": 4,
		"پنج": 5, "five": 5, "5": 5, "۵": 5,
		"شش": 6, "6": 6, "۶": 6,
		"چند": 3, "گروه": 4, "لشکر": 6
	}
	for k in word_nums.keys():
		if p.contains(k):
			return int(word_nums[k])
	return 1


static func _detect_scale_multiplier(p: String) -> float:
	if p.contains("غول") or p.contains("خیلی بزرگ") or p.contains("عظیم") or p.contains("giant"):
		return 1.85
	if p.contains("بزرگ") or p.contains("large") or p.contains("big"):
		return 1.35
	if p.contains("کوچک") or p.contains("ریز") or p.contains("small") or p.contains("mini"):
		return 0.65
	return 1.0


static func _detect_color_tint(p: String) -> Color:
	var cmap := {
		"قرمز": Color(0.92, 0.18, 0.20, 1.0), "سرخ": Color(0.92, 0.18, 0.20, 1.0), "red": Color(0.92, 0.18, 0.20, 1.0),
		"آبی": Color(0.18, 0.52, 0.96, 1.0), "blue": Color(0.18, 0.52, 0.96, 1.0),
		"طلایی": Color(0.96, 0.78, 0.20, 1.0), "زرد": Color(0.96, 0.82, 0.20, 1.0), "gold": Color(0.96, 0.78, 0.20, 1.0),
		"سبز": Color(0.18, 0.80, 0.42, 1.0), "green": Color(0.18, 0.80, 0.42, 1.0),
		"سیاه": Color(0.16, 0.18, 0.22, 1.0), "مشکی": Color(0.16, 0.18, 0.22, 1.0), "black": Color(0.16, 0.18, 0.22, 1.0),
		"سفید": Color(0.95, 0.96, 0.98, 1.0), "نقره": Color(0.82, 0.86, 0.92, 1.0), "white": Color(0.95, 0.96, 0.98, 1.0),
		"بنفش": Color(0.65, 0.28, 0.92, 1.0), "purple": Color(0.65, 0.28, 0.92, 1.0),
	}
	for k in cmap.keys():
		if p.contains(k):
			return cmap[k]
	return Color(1, 1, 1, 0)
