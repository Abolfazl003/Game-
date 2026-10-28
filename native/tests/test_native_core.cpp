#include "colibri_tiered_runtime.h"
#include "nova_blueprint.hpp"
#include "nova_fracture.hpp"

#include <cassert>
#include <iostream>
#include <string>

int main() {
    std::cout << "[1/4] Testing Colibri 3-Tier Memory Scheduler & Hardware Profiler...\n";
    ColibriTieredContext ctx;
    assert(colibri_runtime_init(&ctx, 3072, "") == 0);
    assert(ctx.hw.cpu_threads >= 1);
    assert(ctx.ram_budget_bytes > 0);

    const uint8_t* exp_a = colibri_acquire_expert(&ctx, 3, 19, 65536);
    assert(exp_a != nullptr);
    assert(ctx.cache_misses == 1 && ctx.cache_hits == 0);

    /* Repeated hits should trigger cache hits and allow VRAM Hot-Store promotion */
    for (int i = 0; i < 5; ++i) {
        const uint8_t* exp_hit = colibri_acquire_expert(&ctx, 3, 19, 65536);
        assert(exp_hit == exp_a);
    }
    assert(ctx.cache_hits == 5);
    colibri_promote_hot_experts(&ctx, 4);
    assert(ctx.vram_used_bytes == 65536);

    /* Flushing VRAM for Godot 3D rendering restores 100% VRAM headroom without losing RAM cache */
    colibri_flush_vram_for_renderer(&ctx);
    assert(ctx.vram_used_bytes == 0);
    std::cout << "  -> Recommended local model tier: " << colibri_recommend_model_tier(&ctx.hw) << "\n";

    std::cout << "[2/4] Testing Multi-Brain Council Sequential VRAM Relay & Shared Blackboard...\n";
    int b_dir = colibri_register_brain(&ctx, "GLM-5.3-Director", NOVA_BRAIN_DIRECTOR, NOVA_BACKEND_COLIBRI_C, 9900, 195000, 8);
    int b_cod = colibri_register_brain(&ctx, "Qwen3.6-Coder", NOVA_BRAIN_CODER_CPP_BP, NOVA_BACKEND_COLIBRI_C, 4200, 20000, 4);
    int b_qa  = colibri_register_brain(&ctx, "DeepSeek-Critic", NOVA_BRAIN_CRITIC_QA, NOVA_BACKEND_COLIBRI_C, 5000, 167000, 6);
    assert(b_dir == 0 && b_cod == 1 && b_qa == 2);

    assert(colibri_relay_activate_brain(&ctx, b_dir) == 0);
    assert(ctx.brains[b_dir].active_on_gpu == true);
    colibri_blackboard_append(&ctx, "GLM-5.3-Director", "Design 3-hit katana combo with stamina cost 20 and cutscene boss intro.");

    assert(colibri_relay_activate_brain(&ctx, b_cod) == 0);
    assert(ctx.brains[b_dir].active_on_gpu == false);
    assert(ctx.brains[b_cod].active_on_gpu == true);
    colibri_blackboard_append(&ctx, "Qwen3.6-Coder", "Synthesized CharacterBody3D Blueprint + Jolt Hitbox3D C++ module.");

    std::string bb = colibri_blackboard_read(&ctx);
    assert(bb.find("GLM-5.3-Director") != std::string::npos);
    assert(bb.find("Qwen3.6-Coder") != std::string::npos);
    colibri_runtime_shutdown(&ctx);

    std::cout << "[3/4] Testing Hybrid Blueprint VM + C++20 / GDScript Transpilers...\n";
    nova::BlueprintGraph bp("SamuraiFighterBP", "CharacterBody3D");
    bp.set_variable("stamina", 50.0);

    int ev_atk = bp.add_node("Event_OnAttackInput", nova::BlueprintNodeKind::EVENT_ENTRY);
    int br_stm = bp.add_node("CheckStamina", nova::BlueprintNodeKind::FLOW_BRANCH, {
        {"condition_var", std::string("stamina")},
        {"min_value", 20.0}
    });
    int sub_stm = bp.add_node("ConsumeStamina", nova::BlueprintNodeKind::VARIABLE_SET, {
        {"var_name", std::string("stamina")},
        {"delta", -20.0}
    });
    int act_slash = bp.add_node("PlayMeleeCombo", nova::BlueprintNodeKind::GAMEPLAY_ACTION, {
        {"combo_index", int64_t{1}},
        {"damage", 35.0},
        {"vfx", std::string("vfx_hit_spark")}
    });

    bp.connect(ev_atk, "exec_out", br_stm, "exec_in");
    bp.connect(br_stm, "true", sub_stm, "exec_in");
    bp.connect(sub_stm, "exec_out", act_slash, "exec_in");

    auto trace = bp.execute_event("OnAttackInput");
    assert(trace.size() == 4);
    assert(std::get<double>(bp.get_variable("stamina")) == 30.0);

    std::string gd_code = bp.transpile_to_gdscript();
    std::string cpp_code = bp.transpile_to_cpp();
    assert(gd_code.find("extends CharacterBody3D") != std::string::npos);
    assert(gd_code.find("PlayMeleeCombo") != std::string::npos);
    assert(cpp_code.find("class SamuraiFighterBP") != std::string::npos);

    std::cout << "[4/4] Testing Real-Time 3D Voronoi Mesh Fracturer (Jolt Destructibles)...\n";
    auto shards = nova::VoronoiFracturer::fracture_box(
        {-1.0f, 0.0f, -1.0f},
        { 1.0f, 2.0f,  1.0f},
        { 0.1f, 1.0f,  0.0f},
        120.0f,
        14,
        nova::DestructibleMaterial::STONE,
        42
    );
    assert(shards.size() == 14);
    for (const auto& s : shards) {
        assert(s.vertices.size() >= 4);
        assert(s.indices.size() >= 12 && s.indices.size() % 3 == 0);
        assert(s.mass > 0.0f);
    }

    std::cout << "ALL NATIVE C/C++ ENGINE CORE TESTS PASSED SUCCESSFULLY!\n";
    return 0;
}
