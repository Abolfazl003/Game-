@tool
extends RefCounted
class_name NovaLocalModelHub
## Local AI Model Hub & Colibrì Tiered Memory Manager.
## Manages local installation, hardware scanning, and VRAM/RAM/NVMe SSD streaming
## across LLM coding brains, Image-to-3D, Auto-Rigging, Video-to-Motion, PBR Textures, Audio & TTS.

const CATALOG: Array[Dictionary] = [
	{
		"id": "glm-5.3-flash-colibri",
		"role": "DIRECTOR_VISION",
		"modality": "text+vision",
		"backend": "colibri_c",
		"dense_ram_mb": 9900,
		"disk_experts_mb": 195000,
		"description": "Frontier MoE Director + Viewport Vision Brain streamed from NVMe SSD via Colibrì."
	},
	{
		"id": "qwen3.6-35b-a3b-colibri",
		"role": "CODER_CPP_BLUEPRINT",
		"modality": "code",
		"backend": "colibri_c",
		"dense_ram_mb": 4200,
		"disk_experts_mb": 20000,
		"description": "Fast MoE C++20, GDScript & Visual Blueprint synthesizer."
	},
	{
		"id": "olmoe-7b-1b-int4",
		"role": "ULTRA_LIGHT_COUNCIL",
		"modality": "text+code",
		"backend": "colibri_c",
		"dense_ram_mb": 1200,
		"disk_experts_mb": 7000,
		"description": "Zero-GPU laptop brain (runs on 8 GB RAM) & embedded Living-NPC runtime model."
	},
	{
		"id": "hunyuan3d-2-local",
		"role": "IMAGE_TO_3D",
		"modality": "3d_mesh_pbr",
		"backend": "python_local",
		"dense_ram_mb": 3200,
		"disk_experts_mb": 12000,
		"description": "High-detail local Image/Text-to-3D mesh + PBR texture synthesis."
	},
	{
		"id": "triposr-light-local",
		"role": "IMAGE_TO_3D_FAST",
		"modality": "3d_mesh",
		"backend": "python_local",
		"dense_ram_mb": 1800,
		"disk_experts_mb": 2400,
		"description": "Sub-second lightweight Image-to-3D mesh generator for Indie/6GB VRAM setups."
	},
	{
		"id": "unirig-humanoid-v2",
		"role": "AUTO_RIGGER",
		"modality": "skeleton_skinning",
		"backend": "python_local",
		"dense_ram_mb": 1500,
		"disk_experts_mb": 1900,
		"description": "Automatic 52-bone Humanoid skeleton placement & geodesic skin weight painting."
	},
	{
		"id": "gvhmr-wham-mocap",
		"role": "VIDEO_TO_MOTION",
		"modality": "3d_motion",
		"backend": "python_local",
		"dense_ram_mb": 2200,
		"disk_experts_mb": 4100,
		"description": "World-space 3D body + finger + face motion extraction from video with Foot-Locking IK."
	},
	{
		"id": "kokoro-persian-multi-tts",
		"role": "NPC_VOICE_TTS",
		"modality": "audio_speech",
		"backend": "python_local",
		"dense_ram_mb": 450,
		"disk_experts_mb": 650,
		"description": "Real-time CPU/GPU local voice synthesis & viseme lip-sync for Living NPCs."
	}
]

var installed_models: Dictionary = {
	"olmoe-7b-1b-int4": true,
	"qwen3.6-35b-a3b-colibri": true,
	"triposr-light-local": true,
	"unirig-humanoid-v2": true,
	"gvhmr-wham-mocap": true,
	"kokoro-persian-multi-tts": true
}

var ollama_endpoint: String = "http://127.0.0.1:11434/api/generate"
var engine_vram_reserve_mb: int = 3072


func get_catalog() -> Array[Dictionary]:
	return CATALOG


func is_installed(model_id: String) -> bool:
	return installed_models.get(model_id, false)


func mark_installed(model_id: String, state: bool = true) -> void:
	installed_models[model_id] = state


func recommend_council_profile(available_ram_mb: int, available_vram_mb: int) -> Dictionary:
	if available_ram_mb >= 24576:
		return {
			"tier": "WORKSTATION_COUNCIL",
			"director": "glm-5.3-flash-colibri",
			"coder": "qwen3.6-35b-a3b-colibri",
			"mesh_3d": "hunyuan3d-2-local",
			"relay_mode": "hybrid_parallel_and_nvme_stream"
		}
	elif available_ram_mb >= 12288 or available_vram_mb >= 6144:
		return {
			"tier": "BALANCED_CREATOR",
			"director": "qwen3.6-35b-a3b-colibri",
			"coder": "qwen3.6-35b-a3b-colibri",
			"mesh_3d": "triposr-light-local",
			"relay_mode": "sequential_vram_relay"
		}
	return {
		"tier": "ULTRA_LOW_PRESSURE_COLIBRI",
		"director": "olmoe-7b-1b-int4",
		"coder": "olmoe-7b-1b-int4",
		"mesh_3d": "triposr-light-local",
		"relay_mode": "strict_disk_stream_zero_gpu_spike"
	}
