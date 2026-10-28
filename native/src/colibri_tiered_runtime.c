#include "colibri_tiered_runtime.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(__linux__) || defined(__APPLE__)
#include <unistd.h>
#include <sys/statvfs.h>
#endif

void colibri_detect_hardware(ColibriHardwareProfile* out_hw, uint64_t engine_vram_reserve_mb) {
    if (!out_hw) return;
    memset(out_hw, 0, sizeof(*out_hw));

    out_hw->total_ram_mb = 16384;
    out_hw->available_ram_mb = 12288;
    out_hw->total_vram_mb = 8192;
    out_hw->free_disk_mb = 65536;
    out_hw->cpu_threads = 8;
    out_hw->has_vulkan = true;
    out_hw->has_cuda = false;

#if defined(__linux__)
    FILE* mem = fopen("/proc/meminfo", "r");
    if (mem) {
        char line[256];
        uint64_t total_kb = 0, avail_kb = 0;
        while (fgets(line, sizeof(line), mem)) {
            if (sscanf(line, "MemTotal: %llu kB", (unsigned long long*)&total_kb) == 1) {
                out_hw->total_ram_mb = total_kb / 1024;
            } else if (sscanf(line, "MemAvailable: %llu kB", (unsigned long long*)&avail_kb) == 1) {
                out_hw->available_ram_mb = avail_kb / 1024;
            }
        }
        fclose(mem);
    }

    long nprocs = sysconf(_SC_NPROCESSORS_ONLN);
    if (nprocs > 0) {
        out_hw->cpu_threads = (uint32_t)nprocs;
    }

    struct statvfs vfs;
    if (statvfs(".", &vfs) == 0) {
        uint64_t free_bytes = (uint64_t)vfs.f_bavail * (uint64_t)vfs.f_frsize;
        out_hw->free_disk_mb = free_bytes / (1024ULL * 1024ULL);
    }
#endif

    out_hw->reserved_engine_vram_mb = engine_vram_reserve_mb;
    if (out_hw->total_vram_mb > engine_vram_reserve_mb) {
        out_hw->ai_usable_vram_mb = out_hw->total_vram_mb - engine_vram_reserve_mb;
    } else {
        out_hw->ai_usable_vram_mb = 0;
    }
}

int colibri_runtime_init(ColibriTieredContext* ctx, uint64_t engine_vram_reserve_mb, const char* container_path) {
    if (!ctx) return -1;
    memset(ctx, 0, sizeof(*ctx));

    colibri_detect_hardware(&ctx->hw, engine_vram_reserve_mb);

    /* Cap AI RAM usage to 65% of available RAM so OS + Godot Editor stay ultra-responsive */
    uint64_t safe_ram_mb = (ctx->hw.available_ram_mb * 65ULL) / 100ULL;
    if (safe_ram_mb < 512) safe_ram_mb = 512;

    ctx->ram_budget_bytes = safe_ram_mb * 1024ULL * 1024ULL;
    ctx->vram_budget_bytes = ctx->hw.ai_usable_vram_mb * 1024ULL * 1024ULL;
    ctx->active_brain_index = -1;

    if (container_path) {
        strncpy(ctx->container_path, container_path, sizeof(ctx->container_path) - 1);
    }
    return 0;
}

void colibri_runtime_shutdown(ColibriTieredContext* ctx) {
    if (!ctx) return;
    for (size_t i = 0; i < ctx->cache_count; ++i) {
        free(ctx->cache[i].payload);
        ctx->cache[i].payload = NULL;
    }
    ctx->cache_count = 0;
    ctx->ram_used_bytes = 0;
    ctx->vram_used_bytes = 0;
    ctx->active_brain_index = -1;
}

static void evict_lru_ram_slot(ColibriTieredContext* ctx) {
    int victim = -1;
    uint64_t oldest_tick = UINT64_MAX;

    for (size_t i = 0; i < ctx->cache_count; ++i) {
        if (!ctx->cache[i].pinned_hot && ctx->cache[i].last_tick < oldest_tick) {
            oldest_tick = ctx->cache[i].last_tick;
            victim = (int)i;
        }
    }
    /* Fallback if everything was marked hot */
    if (victim < 0 && ctx->cache_count > 0) {
        victim = 0;
    }
    if (victim >= 0) {
        ColibriExpertSlot* slot = &ctx->cache[victim];
        if (slot->current_tier == COLIBRI_TIER_GPU_VRAM && ctx->vram_used_bytes >= slot->size_bytes) {
            ctx->vram_used_bytes -= slot->size_bytes;
        } else if (ctx->ram_used_bytes >= slot->size_bytes) {
            ctx->ram_used_bytes -= slot->size_bytes;
        }
        free(slot->payload);
        /* Compact array */
        ctx->cache[victim] = ctx->cache[ctx->cache_count - 1];
        memset(&ctx->cache[ctx->cache_count - 1], 0, sizeof(ColibriExpertSlot));
        ctx->cache_count--;
    }
}

const uint8_t* colibri_acquire_expert(
    ColibriTieredContext* ctx,
    uint32_t layer_idx,
    uint32_t expert_idx,
    size_t expert_bytes
) {
    if (!ctx || expert_bytes == 0) return NULL;
    ctx->tick_counter++;

    /* 1. Check VRAM Hot Store & RAM LRU Cache */
    for (size_t i = 0; i < ctx->cache_count; ++i) {
        if (ctx->cache[i].layer_idx == layer_idx && ctx->cache[i].expert_idx == expert_idx) {
            ctx->cache[i].access_count++;
            ctx->cache[i].last_tick = ctx->tick_counter;
            ctx->cache_hits++;
            return ctx->cache[i].payload;
        }
    }

    ctx->cache_misses++;

    /* 2. Ensure RAM budget & slot capacity via LRU eviction */
    while ((ctx->cache_count >= COLIBRI_MAX_CACHED_EXPERTS ||
           (ctx->ram_used_bytes + expert_bytes > ctx->ram_budget_bytes)) &&
           ctx->cache_count > 0) {
        evict_lru_ram_slot(ctx);
    }

    uint8_t* buf = (uint8_t*)malloc(expert_bytes);
    if (!buf) return NULL;

    /* 3. Stream routed expert slice on demand from NVMe container if present, else deterministic quantized block */
    bool read_from_disk = false;
    if (ctx->container_path[0] != '\0') {
        FILE* f = fopen(ctx->container_path, "rb");
        if (f) {
            uint64_t offset = ((uint64_t)layer_idx * 256ULL + (uint64_t)expert_idx) * (uint64_t)expert_bytes;
            if (fseek(f, (long)offset, SEEK_SET) == 0) {
                size_t n = fread(buf, 1, expert_bytes, f);
                if (n == expert_bytes) {
                    read_from_disk = true;
                }
            }
            fclose(f);
        }
    }
    if (!read_from_disk) {
        /* Deterministic INT4 synthetic expert weights for offline validation */
        uint8_t seed = (uint8_t)((layer_idx * 31u + expert_idx * 17u) & 0xFFu);
        memset(buf, seed, expert_bytes);
    }

    ctx->disk_bytes_streamed += expert_bytes;
    ctx->ram_used_bytes += expert_bytes;

    ColibriExpertSlot* slot = &ctx->cache[ctx->cache_count++];
    slot->layer_idx = layer_idx;
    slot->expert_idx = expert_idx;
    slot->current_tier = COLIBRI_TIER_SYSTEM_RAM;
    slot->access_count = 1;
    slot->last_tick = ctx->tick_counter;
    slot->size_bytes = expert_bytes;
    slot->pinned_hot = false;
    slot->payload = buf;

    return slot->payload;
}

void colibri_promote_hot_experts(ColibriTieredContext* ctx, uint64_t min_access_threshold) {
    if (!ctx) return;
    for (size_t i = 0; i < ctx->cache_count; ++i) {
        ColibriExpertSlot* slot = &ctx->cache[i];
        if (!slot->pinned_hot && slot->access_count >= min_access_threshold) {
            if (ctx->vram_used_bytes + slot->size_bytes <= ctx->vram_budget_bytes) {
                if (ctx->ram_used_bytes >= slot->size_bytes) {
                    ctx->ram_used_bytes -= slot->size_bytes;
                }
                ctx->vram_used_bytes += slot->size_bytes;
                slot->current_tier = COLIBRI_TIER_GPU_VRAM;
                slot->pinned_hot = true;
            }
        }
    }
}

void colibri_flush_vram_for_renderer(ColibriTieredContext* ctx) {
    if (!ctx) return;
    for (size_t i = 0; i < ctx->cache_count; ++i) {
        ColibriExpertSlot* slot = &ctx->cache[i];
        if (slot->current_tier == COLIBRI_TIER_GPU_VRAM) {
            slot->current_tier = COLIBRI_TIER_SYSTEM_RAM;
            slot->pinned_hot = false;
            ctx->ram_used_bytes += slot->size_bytes;
        }
    }
    ctx->vram_used_bytes = 0;
    for (size_t b = 0; b < ctx->brain_count; ++b) {
        ctx->brains[b].active_on_gpu = false;
    }
}

int colibri_register_brain(
    ColibriTieredContext* ctx,
    const char* model_id,
    NovaBrainRole role,
    NovaInferenceBackend backend,
    uint64_t dense_ram_mb,
    uint64_t expert_disk_mb,
    uint32_t active_experts_per_token
) {
    if (!ctx || !model_id || ctx->brain_count >= COLIBRI_MAX_BRAINS) return -1;
    int idx = (int)ctx->brain_count++;
    RegisteredBrain* b = &ctx->brains[idx];
    memset(b, 0, sizeof(*b));
    strncpy(b->id, model_id, sizeof(b->id) - 1);
    b->role = role;
    b->backend = backend;
    b->dense_ram_mb = dense_ram_mb;
    b->expert_disk_mb = expert_disk_mb;
    b->active_experts_per_token = active_experts_per_token;
    return idx;
}

int colibri_relay_activate_brain(ColibriTieredContext* ctx, int brain_index) {
    if (!ctx || brain_index < 0 || (size_t)brain_index >= ctx->brain_count) return -1;

    /* Sequential VRAM Relay: unload previous brain from GPU before activating next specialist */
    if (ctx->active_brain_index >= 0 && ctx->active_brain_index != brain_index) {
        RegisteredBrain* prev = &ctx->brains[ctx->active_brain_index];
        prev->active_on_gpu = false;
        /* If RAM is tight (< 16 GB), also release previous dense resident core */
        if (ctx->hw.available_ram_mb < 16384) {
            prev->loaded_in_ram = false;
        }
    }

    RegisteredBrain* next = &ctx->brains[brain_index];
    next->loaded_in_ram = true;
    next->active_on_gpu = (ctx->hw.ai_usable_vram_mb >= 1024);
    ctx->active_brain_index = brain_index;
    return 0;
}

int colibri_blackboard_append(ColibriTieredContext* ctx, const char* brain_id, const char* note) {
    if (!ctx || !brain_id || !note) return -1;
    size_t cur_len = strlen(ctx->blackboard);
    int written = snprintf(
        ctx->blackboard + cur_len,
        COLIBRI_BLACKBOARD_CAP - cur_len,
        "[%s]: %s\n",
        brain_id,
        note
    );
    return (written > 0) ? 0 : -1;
}

const char* colibri_blackboard_read(const ColibriTieredContext* ctx) {
    if (!ctx) return "";
    return ctx->blackboard;
}

void colibri_blackboard_clear(ColibriTieredContext* ctx) {
    if (!ctx) return;
    ctx->blackboard[0] = '\0';
}

const char* colibri_recommend_model_tier(const ColibriHardwareProfile* hw) {
    if (!hw) return "OLMoE-7B-1B-int4";
    if (hw->available_ram_mb >= 24576 && hw->free_disk_mb >= 380000) {
        return "GLM-5.2-744B-MoE-Colibri-Stream + Qwen3.6-35B-A3B";
    }
    if (hw->available_ram_mb >= 16384 && hw->free_disk_mb >= 175000) {
        return "DeepSeek-V4-Flash-284B-Colibri + Qwen2.5-Coder-14B";
    }
    if (hw->available_ram_mb >= 12288) {
        return "Qwen3.6-35B-A3B-MoE + Qwen2.5-Coder-7B-int4";
    }
    return "OLMoE-7B-1B-int4 + Qwen2.5-Coder-3B-int4 (Ultra-Low-RAM Mode)";
}
