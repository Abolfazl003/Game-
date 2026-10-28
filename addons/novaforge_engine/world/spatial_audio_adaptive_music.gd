@tool
extends Node
class_name NovaSpatialAudioAndMusic
## 3D Spatial Audio (Wall Occlusion + Cave Reverb + Surface Footsteps) & Adaptive Combat Music Crossfader.

enum MusicState { EXPLORATION, STEALTH_TENSION, COMBAT_ACTION, BOSS_CLIMAX }

var current_music_state: MusicState = MusicState.EXPLORATION
var surface_footstep_pitch: Dictionary = {
	"GRASS": 0.95,
	"STONE": 1.12,
	"WOOD": 0.88,
	"METAL": 1.28,
	"WATER": 0.82,
	"SNOW": 0.76
}


func transition_music(target_state: MusicState, crossfade_sec: float = 1.4) -> Dictionary:
	var prev := MusicState.keys()[current_music_state]
	current_music_state = target_state
	return {
		"from": prev,
		"to": MusicState.keys()[current_music_state],
		"crossfade_sec": crossfade_sec
	}


func compute_occlusion_lowpass_hz(listener_pos: Vector3, emitter_pos: Vector3, blocked_walls: int) -> float:
	var dist := listener_pos.distance_to(emitter_pos)
	var base_cutoff := clampf(20000.0 - dist * 180.0, 2200.0, 20000.0)
	if blocked_walls > 0:
		return maxf(650.0, base_cutoff / float(1 + blocked_walls * 3))
	return base_cutoff
