@tool
extends RefCounted
class_name NovaGenreKitAssembler
## Multi-Genre Gameplay Kit Registry & Combinable Assembler.
## Supports mixing multiple genres in one game (e.g. 2.5D + Horror + Souls-like Combat).

const GENRE_KITS: Dictionary = {
	"ACTION_SOULSLIKE": {
		"default_perspective": "TPS_SOULS",
		"modules": ["MeleeCombo3Hit", "ParryAndDodge", "StaminaPool", "LockOnTargeting", "BossMultiPhase"],
		"physics_layers": ["World", "PlayerBody", "EnemyBody", "PlayerHitbox", "EnemyHitbox"]
	},
	"SHOOTER_FPS_TPS": {
		"default_perspective": "FPS",
		"modules": ["BallisticsAndRecoil", "ADSZoom", "MagazineReload", "CoverSystem", "WeaponWheel"],
		"physics_layers": ["World", "PlayerBody", "EnemyBody", "ProjectileHitscan", "DestructibleCover"]
	},
	"FIGHTING_25D_3D": {
		"default_perspective": "SIDE_2_5D",
		"modules": ["FrameDataState", "HighLowGuard", "AirJuggle", "SuperMeter", "DualFighterCamera"],
		"physics_layers": ["ArenaFloor", "Fighter1", "Fighter2", "StrikeBox", "ThrowBox"]
	},
	"PLATFORMER_METROIDVANIA": {
		"default_perspective": "SIDE_2_5D",
		"modules": ["CoyoteTimeJump", "DoubleJump", "WallSlideAndJump", "GrapplingHook", "AirDash"],
		"physics_layers": ["Terrain", "Player", "Hazards", "MovingPlatforms", "AbilityGates"]
	},
	"OPENWORLD_SURVIVAL": {
		"default_perspective": "TPS_SHOULDER",
		"modules": ["WorldChunkStreamer", "ResourceHarvest", "GridBuilding", "HungerWarmth", "DayNightWeather"],
		"physics_layers": ["Terrain", "Player", "Wildlife", "HarvestNodes", "SnapStructures"]
	},
	"RPG_ACTION_TURNBASED": {
		"default_perspective": "TPS_SOULS",
		"modules": ["InventoryLoot", "SkillTree", "QuestJournal", "BranchingDialogue", "LivingNPCEconomy"],
		"physics_layers": ["World", "Party", "NPCs", "Triggers", "LootDrops"]
	},
	"RACING_VEHICLES": {
		"default_perspective": "TPS_SHOULDER",
		"modules": ["JoltVehicleSuspension", "TireDriftGrip", "NitroBoost", "ChassisDeformation", "LapCheckpoints"],
		"physics_layers": ["Track", "Vehicles", "DestructibleProps", "Checkpoints"]
	},
	"HORROR_STEALTH": {
		"default_perspective": "FPS",
		"modules": ["LightAndSoundStealthMeter", "FlashlightBattery", "SanityPulse", "HidingSpots", "FixedCamZones"],
		"physics_layers": ["World", "Player", "StalkerAI", "SoundEmitters", "ShadowZones"]
	},
	"RTS_TOWER_DEFENSE": {
		"default_perspective": "ISOMETRIC",
		"modules": ["BoxSelectUnits", "SquadNavMesh", "ResourceEconomy", "GridTurretPlacement", "WaveSpawner"],
		"physics_layers": ["Ground", "FriendlyUnits", "EnemyWaves", "Buildings", "Projectiles"]
	},
	"ROGUELIKE_BULLET_HEAVEN": {
		"default_perspective": "ISOMETRIC",
		"modules": ["ProceduralDungeon", "AutoFireTargeting", "HordeMultiMeshSwarm", "PermadeathRelicDraft"],
		"physics_layers": ["Arena", "Player", "Swarm", "XPOrbs", "AreaAttacks"]
	}
}


static func assemble_combined_kit(genre_ids: Array[String]) -> Dictionary:
	var combined_modules: Array[String] = []
	var primary_perspective := "TPS_SOULS"
	var first := true

	for gid in genre_ids:
		var k := gid.to_upper()
		if GENRE_KITS.has(k):
			if first:
				primary_perspective = GENRE_KITS[k]["default_perspective"]
				first = false
			for mod in GENRE_KITS[k]["modules"]:
				if not combined_modules.has(mod):
					combined_modules.append(mod)

	return {
		"ok": true,
		"genres": genre_ids,
		"primary_perspective": primary_perspective,
		"enabled_modules": combined_modules
	}
