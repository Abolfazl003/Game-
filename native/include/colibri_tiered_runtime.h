#ifndef NOVA_COLIBRI_TIERED_RUNTIME_H
#define NOVA_COLIBRI_TIERED_RUNTIME_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#define COLIBRI_MAX_LAYERS 128
#define COLIBRI_MAX_CACHED_EXPERTS 512
#define COLIBRI_MAX_BRAINS 16
#define COLIBRI_BLACKBOARD_CAP 65536

typedef enum {
    COLIBRI_TIER_DISK_NVME = 0,
    COLIBRI_TIER_SYSTEM_RAM = 1,
    COLIBRI_TIER_GPU_VRAM = 2
} ColibriMemoryTier;

typedef enum {
    NOVA_BRAIN_DIRECTOR = 0,
    NOVA_BRAIN_CODER_CPP_BP = 1,
    NOVA_BRAIN_ARTIST_3D_TEX = 2,
    NOVA_BRAIN_ANIMATOR_MOCAP = 3,
    NOVA_BRAIN_CRITIC_QA = 4,
    NOVA_BRAIN_LIVING_NPC = 5
} NovaBrainRole;

typedef enum {
    NOVA_BACKEND_COLIBRI_C = 0,
    NOVA_BACKEND_LLAMA_CPP = 1,
    NOVA_BACKEND_OLLAMA_LOCAL = 2,
    NOVA_BACKEND_HYBRID_CLOUD = 3
} NovaInferenceBackend;

typedef struct {
    uint64_t total_ram_mb;
    uint64_t available_ram_mb;
    uint64_t total_vram_mb;
    uint64_t reserved_engine_vram_mb; /* Reserved for Godot 4 Vulkan + Jolt Physics */
    uint64_t ai_usable_vram_mb;
    uint64_t free_disk_mb;
    uint32_t cpu_threads;
    bool has_vulkan;
    bool has_cuda;
} ColibriHardwareProfile;

typedef struct {
    uint32_t layer_idx;
    uint32_t expert_idx;
    ColibriMemoryTier current_tier;
    uint64_t access_count;
    uint64_t last_tick;
    size_t size_bytes;
    bool pinned_hot;
    uint8_t* payload;
} ColibriExpertSlot;

typedef struct {
    char id[64];
    NovaBrainRole role;
    NovaInferenceBackend backend;
    uint64_t dense_ram_mb;
    uint64_t expert_disk_mb;
    uint32_t active_experts_per_token;
    bool loaded_in_ram;
    bool active_on_gpu;
} RegisteredBrain;

typedef struct {
    ColibriHardwareProfile hw;
    uint64_t ram_budget_bytes;
    uint64_t vram_budget_bytes;
    uint64_t ram_used_bytes;
    uint64_t vram_used_bytes;
    uint64_t disk_bytes_streamed;
    uint64_t cache_hits;
    uint64_t cache_misses;
    uint64_t tick_counter;

    ColibriExpertSlot cache[COLIBRI_MAX_CACHED_EXPERTS];
    size_t cache_count;

    RegisteredBrain brains[COLIBRI_MAX_BRAINS];
    size_t brain_count;
    int active_brain_index;

    char container_path[512];
    char blackboard[COLIBRI_BLACKBOARD_CAP];
} ColibriTieredContext;

/* Lifecycle & Hardware Discovery */
void colibri_detect_hardware(ColibriHardwareProfile* out_hw, uint64_t engine_vram_reserve_mb);
int colibri_runtime_init(ColibriTieredContext* ctx, uint64_t engine_vram_reserve_mb, const char* container_path);
void colibri_runtime_shutdown(ColibriTieredContext* ctx);

/* On-Demand MoE Expert Streaming (NVMe -> RAM LRU -> VRAM Hot Pin) */
const uint8_t* colibri_acquire_expert(
    ColibriTieredContext* ctx,
    uint32_t layer_idx,
    uint32_t expert_idx,
    size_t expert_bytes
);
void colibri_promote_hot_experts(ColibriTieredContext* ctx, uint64_t min_access_threshold);
void colibri_flush_vram_for_renderer(ColibriTieredContext* ctx);

/* Multi-Brain Council Sequential Relay & Shared Blackboard */
int colibri_register_brain(
    ColibriTieredContext* ctx,
    const char* model_id,
    NovaBrainRole role,
    NovaInferenceBackend backend,
    uint64_t dense_ram_mb,
    uint64_t expert_disk_mb,
    uint32_t active_experts_per_token
);
int colibri_relay_activate_brain(ColibriTieredContext* ctx, int brain_index);
int colibri_blackboard_append(ColibriTieredContext* ctx, const char* brain_id, const char* note);
const char* colibri_blackboard_read(const ColibriTieredContext* ctx);
void colibri_blackboard_clear(ColibriTieredContext* ctx);

/* Recommendation helper for consumer machines */
const char* colibri_recommend_model_tier(const ColibriHardwareProfile* hw);

#ifdef __cplusplus
}
#endif

#endif /* NOVA_COLIBRI_TIERED_RUNTIME_H */
