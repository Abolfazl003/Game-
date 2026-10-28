@tool
extends Node3D
class_name NovaElementalWeatherSystem
## Dynamic Weather, 24h Day/Night Cycle & Systemic Elemental Chemistry (`Fire + Water + Wind + Lightning`).

signal weather_changed(new_weather: String)
signal elemental_reaction_triggered(reaction_name: String, world_pos: Vector3)

enum WeatherState { CLEAR, RAIN, THUNDERSTORM, SNOW, DENSE_FOG }

@export var current_weather: WeatherState = WeatherState.CLEAR
@export_range(0.0, 24.0, 0.1) var time_of_day_hours: float = 14.5
@export var day_length_minutes: float = 18.0
@export var wind_direction: Vector3 = Vector3(1.0, 0.0, 0.25)
@export var wind_strength: float = 1.0

var surface_wetness: float = 0.0


func set_weather(state: WeatherState) -> void:
	current_weather = state
	match state:
		WeatherState.RAIN, WeatherState.THUNDERSTORM:
			surface_wetness = 1.0
		WeatherState.CLEAR:
			surface_wetness = maxf(0.0, surface_wetness - 0.5)
	weather_changed.emit(WeatherState.keys()[current_weather])


## Evaluates systemic chemistry interactions (Zelda-style emergent physics) between elements.
func evaluate_elemental_contact(source_element: String, target_surface_state: String, pos: Vector3) -> Dictionary:
	var src := source_element.to_upper()
	var dst := target_surface_state.to_upper()

	# Rain or Water extinguishes Fire -> Steam Cloud
	if (src == "WATER" or current_weather == WeatherState.RAIN or current_weather == WeatherState.THUNDERSTORM) and dst == "BURNING":
		elemental_reaction_triggered.emit("EXTINGUISH_STEAM", pos)
		return {"reaction": "EXTINGUISH_STEAM", "new_state": "WET", "aoe_radius": 2.5, "damage": 0.0}

	# Fire + Dry Grass/Wood -> Ignites & spreads downwind!
	if src == "FIRE" and (dst == "DRY_GRASS" or dst == "WOOD") and surface_wetness < 0.35:
		var spread_vec := wind_direction.normalized() * (2.0 * wind_strength)
		elemental_reaction_triggered.emit("IGNITE_AND_SPREAD_DOWNWIND", pos)
		return {"reaction": "IGNITE_AND_SPREAD_DOWNWIND", "new_state": "BURNING", "spread_vector": spread_vec, "damage": 18.0}

	# Lightning + Wet Surface or Water Pool -> Chain Electro-Shock AoE!
	if src == "LIGHTNING" and (dst == "WET" or dst == "WATER_POOL" or surface_wetness >= 0.5):
		elemental_reaction_triggered.emit("CHAIN_ELECTRO_SHOCK", pos)
		return {"reaction": "CHAIN_ELECTRO_SHOCK", "new_state": "ELECTRIFIED", "aoe_radius": 7.5, "damage": 45.0}

	# Ice/Frost + Water -> Frozen walkable bridge / slippery ice!
	if src == "ICE" and (dst == "WATER_POOL" or dst == "WET"):
		elemental_reaction_triggered.emit("FREEZE_SURFACE", pos)
		return {"reaction": "FREEZE_SURFACE", "new_state": "FROZEN_ICE", "friction": 0.08, "damage": 8.0}

	return {"reaction": "NONE", "new_state": dst, "damage": 0.0}
