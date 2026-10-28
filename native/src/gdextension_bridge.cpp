#include "colibri_tiered_runtime.h"
#include "nova_blueprint.hpp"
#include "nova_fracture.hpp"

#include <cstring>
#include <string>

static ColibriTieredContext g_colibri_ctx;
static bool g_initialized = false;
static std::string g_last_json_buffer;

extern "C" {

/* GDExtension & Foreign Function Interface (C ABI) */
int novaforge_native_init(uint64_t engine_vram_reserve_mb, const char* container_path) {
    int rc = colibri_runtime_init(&g_colibri_ctx, engine_vram_reserve_mb, container_path);
    g_initialized = (rc == 0);
    return rc;
}

void novaforge_native_shutdown(void) {
    if (g_initialized) {
        colibri_runtime_shutdown(&g_colibri_ctx);
        g_initialized = false;
    }
}

const char* novaforge_hardware_summary_json(uint64_t engine_vram_reserve_mb) {
    ColibriHardwareProfile hw;
    colibri_detect_hardware(&hw, engine_vram_reserve_mb);
    const char* rec = colibri_recommend_model_tier(&hw);

    char buf[1024];
    snprintf(
        buf, sizeof(buf),
        "{\"total_ram_mb\":%llu,\"available_ram_mb\":%llu,\"total_vram_mb\":%llu,"
        "\"reserved_engine_vram_mb\":%llu,\"ai_usable_vram_mb\":%llu,\"free_disk_mb\":%llu,"
        "\"cpu_threads\":%u,\"recommended_tier\":\"%s\"}",
        (unsigned long long)hw.total_ram_mb,
        (unsigned long long)hw.available_ram_mb,
        (unsigned long long)hw.total_vram_mb,
        (unsigned long long)hw.reserved_engine_vram_mb,
        (unsigned long long)hw.ai_usable_vram_mb,
        (unsigned long long)hw.free_disk_mb,
        hw.cpu_threads,
        rec
    );
    g_last_json_buffer = buf;
    return g_last_json_buffer.c_str();
}

int novaforge_fracture_count_preview(
    float size_x, float size_y, float size_z,
    float impact_force, uint32_t shard_count, int material_id
) {
    auto shards = nova::VoronoiFracturer::fracture_box(
        {-size_x * 0.5f, -size_y * 0.5f, -size_z * 0.5f},
        { size_x * 0.5f,  size_y * 0.5f,  size_z * 0.5f},
        {0.0f, 0.0f, 0.0f},
        impact_force,
        shard_count,
        static_cast<nova::DestructibleMaterial>(material_id)
    );
    return static_cast<int>(shards.size());
}

/* Official Godot 4 GDExtension C ABI Initialization Struct & Callbacks */
typedef uint8_t GDExtensionBool;
typedef enum {
    GDEXTENSION_INITIALIZATION_CORE = 0,
    GDEXTENSION_INITIALIZATION_SERVERS = 1,
    GDEXTENSION_INITIALIZATION_SCENE = 2,
    GDEXTENSION_INITIALIZATION_EDITOR = 3,
    GDEXTENSION_MAX_INITIALIZATION_LEVEL = 4
} GDExtensionInitializationLevel;

typedef struct {
    GDExtensionInitializationLevel minimum_initialization_level;
    void* userdata;
    void (*initialize)(void* userdata, GDExtensionInitializationLevel p_level);
    void (*deinitialize)(void* userdata, GDExtensionInitializationLevel p_level);
} GDExtensionInitialization;

static void nova_gdext_initialize(void* /*userdata*/, GDExtensionInitializationLevel p_level) {
    if (p_level == GDEXTENSION_INITIALIZATION_SCENE && !g_initialized) {
        novaforge_native_init(3072, "");
    }
}

static void nova_gdext_deinitialize(void* /*userdata*/, GDExtensionInitializationLevel p_level) {
    if (p_level == GDEXTENSION_INITIALIZATION_SCENE && g_initialized) {
        novaforge_native_shutdown();
    }
}

GDExtensionBool novaforge_library_init(
    void* p_get_proc_address,
    void* p_library,
    GDExtensionInitialization* r_initialization
) {
    (void)p_get_proc_address;
    (void)p_library;
    if (!r_initialization) return 0;
    r_initialization->minimum_initialization_level = GDEXTENSION_INITIALIZATION_SCENE;
    r_initialization->userdata = nullptr;
    r_initialization->initialize = &nova_gdext_initialize;
    r_initialization->deinitialize = &nova_gdext_deinitialize;
    return 1;
}

} /* extern "C" */
