@tool
extends Node3D
class_name LivingNPCBrain3D
## Modular Checkbox NPC Brain + "Evolving Life & Nemesis AI" (`LivingNPCBrain3D`).
## Every capability is an optional toggle so simple background guards cost almost 0 CPU,
## while key NPCs advance their career, wealth, family, battle scars, and combat counters
## alongside the player's progression through the game!

signal npc_life_progressed(npc_name: String, new_summary: Dictionary)
signal npc_nemesis_adapted(npc_name: String, countered_move: String)
signal npc_limb_crippled(limb_name: String)

enum NPCRole {
	CITIZEN,
	MERCHANT_BLACKSMITH,
	GUARD,
	COMPANION,
	ENEMY,
	BOSS,
	FACTION_LEADER
}

@export_group("Role & Base Identity")
@export var npc_display_name: String = "کاوه آهنگر / Kaveh"
@export var role: NPCRole = NPCRole.MERCHANT_BLACKSMITH

@export_group("Optional Perception & Combat Checkboxes")
@export var enable_vision_cone: bool = true
@export var vision_range_m: float = 18.0
@export var enable_acoustic_hearing: bool = true
@export var enable_locational_limb_damage: bool = false
@export var combat_style: String = "TACTICAL" # AGGRESSIVE, TACTICAL, COWARD, BERSERK

@export_group("Optional Dialogue & Trade Checkboxes")
@export var enable_branching_dialogue: bool = true
@export var enable_free_talk_local_ai: bool = false
@export var enable_trade_and_pickpocket: bool = true

@export_group("Optional Evolving Life & Nemesis AI")
@export var enable_daily_routine: bool = true
@export var enable_memory_and_reputation: bool = true
@export var enable_evolving_life: bool = true

# Dynamic Living State (Serialized by WorldPersistenceManager)
var life_stage_day: int = 1
var career_tier: int = 1
var career_title: String = "Apprentice"
var wealth_gold: int = 120
var family_and_allies: Array[String] = []
var relationship_with_player: int = 0 # -100 (Sworn Nemesis) .. +100 (Loyal Blood-Brother)
var battle_scars: Array[String] = []
var observed_player_moves: Dictionary = {}
var learned_counters: Array[String] = []
var limb_health: Dictionary = {"head": 100.0, "right_arm": 100.0, "left_arm": 100.0, "legs": 100.0}


func _ready() -> void:
	_refresh_career_title()
	if enable_evolving_life and get_tree() and get_tree().root.has_node("NovaWorldLife"):
		get_tree().root.get_node("NovaWorldLife").register_living_npc(self)


func apply_options_dict(opts: Dictionary) -> void:
	npc_display_name = str(opts.get("name", npc_display_name))
	enable_vision_cone = bool(opts.get("enable_vision_cone", enable_vision_cone))
	enable_acoustic_hearing = bool(opts.get("enable_acoustic_hearing", enable_acoustic_hearing))
	enable_locational_limb_damage = bool(opts.get("enable_locational_limb_damage", enable_locational_limb_damage))
	enable_free_talk_local_ai = bool(opts.get("enable_free_talk_local_ai", enable_free_talk_local_ai))
	enable_evolving_life = bool(opts.get("enable_evolving_life", enable_evolving_life))
	_refresh_career_title()


## Advances this NPC's personal life, career, wealth, alliances, or outlaw descent as game time moves forward!
func advance_life_chapter(days_passed: int = 1, world_prosperity: float = 1.0) -> Dictionary:
	if not enable_evolving_life:
		return get_biography_snapshot()

	life_stage_day += maxi(1, days_passed)

	# Economic & Career progression influenced by player relationship & world state
	var trade_bonus := 25 * days_passed if relationship_with_player >= 15 else 8 * days_passed
	if relationship_with_player <= -40:
		# Robbed or betrayed -> may radicalize into a scarred Nemesis / Outlaw captain!
		wealth_gold = maxi(0, wealth_gold - 15 * days_passed)
		if role == NPCRole.CITIZEN or role == NPCRole.MERCHANT_BLACKSMITH:
			role = NPCRole.ENEMY
			combat_style = "TACTICAL"
	else:
		wealth_gold += int(round(float(trade_bonus) * world_prosperity))

	if wealth_gold >= 600 and career_tier < 3:
		career_tier = 3
		if family_and_allies.is_empty():
			family_and_allies.append("Hired Guild Apprentice")
			family_and_allies.append("Married & Expanded Workshop")
	elif wealth_gold >= 260 and career_tier < 2:
		career_tier = 2

	_refresh_career_title()
	var snap := get_biography_snapshot()
	npc_life_progressed.emit(npc_display_name, snap)
	return snap


func record_player_interaction(kind: String, player_move_used: String = "") -> void:
	if enable_memory_and_reputation:
		match kind:
			"helped", "traded_fairly", "saved_life":
				relationship_with_player = clampi(relationship_with_player + 25, -100, 100)
			"robbed", "attacked_and_escaped", "betrayed":
				relationship_with_player = clampi(relationship_with_player - 45, -100, 100)
				if kind == "attacked_and_escaped" and not battle_scars.has("Slash_Scar_Left_Cheek"):
					battle_scars.append("Slash_Scar_Left_Cheek")

	if not player_move_used.is_empty():
		var count: int = int(observed_player_moves.get(player_move_used, 0)) + 1
		observed_player_moves[player_move_used] = count
		if count >= 3 and not learned_counters.has(player_move_used):
			learned_counters.append(player_move_used)
			npc_nemesis_adapted.emit(npc_display_name, player_move_used)


func apply_locational_hit(limb: String, damage: float) -> Dictionary:
	if not enable_locational_limb_damage or not limb_health.has(limb):
		return {"locational": false}
	limb_health[limb] = maxf(0.0, float(limb_health[limb]) - damage)
	var crippled := float(limb_health[limb]) <= 0.0
	if crippled:
		npc_limb_crippled.emit(limb)
	return {
		"locational": true,
		"limb": limb,
		"remaining": limb_health[limb],
		"dropped_weapon": limb == "right_arm" and crippled,
		"limping_slowed": limb == "legs" and crippled
	}


func _refresh_career_title() -> void:
	match role:
		NPCRole.MERCHANT_BLACKSMITH:
			career_title = ["", "Apprentice Blacksmith", "Master Guild Smith", "Legendary Royal Armorer"][clampi(career_tier, 1, 3)]
		NPCRole.ENEMY:
			career_title = "Vengeful Scarred Outlaw" if relationship_with_player <= -40 else "Raider"
		NPCRole.GUARD:
			career_title = ["", "Watchman", "Captain of the Gate", "Royal Commander"][clampi(career_tier, 1, 3)]
		_:
			career_title = ["", "Townsperson", "Prosperous Artisan", "Town Elder"][clampi(career_tier, 1, 3)]


func get_biography_snapshot() -> Dictionary:
	return {
		"name": npc_display_name,
		"role": NPCRole.keys()[role],
		"day": life_stage_day,
		"career_tier": career_tier,
		"career_title": career_title,
		"wealth_gold": wealth_gold,
		"relationship": relationship_with_player,
		"allies": family_and_allies,
		"battle_scars": battle_scars,
		"learned_counters": learned_counters
	}
