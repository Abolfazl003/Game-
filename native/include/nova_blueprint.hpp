#ifndef NOVA_BLUEPRINT_HPP
#define NOVA_BLUEPRINT_HPP

#include <cstdint>
#include <string>
#include <vector>
#include <unordered_map>
#include <variant>
#include <functional>

namespace nova {

using PinValue = std::variant<bool, int64_t, double, std::string>;

enum class BlueprintNodeKind {
    EVENT_ENTRY,      // BeginPlay, Tick, OnInteract, OnDamage, OnCutsceneTrigger
    FLOW_BRANCH,      // If / Else Branch
    FLOW_SEQUENCE,    // Multi-output Sequence
    GAMEPLAY_ACTION,  // MoveCharacter, MeleeCombo, ApplyDamage, DodgeRoll, SpawnVFX, FractureMesh, TriggerCutscene
    MATH_COMPARE,     // Greater, Less, Add, Subtract, Clamp
    VARIABLE_GET,
    VARIABLE_SET
};

struct BlueprintNode {
    int id = 0;
    std::string type_name;
    BlueprintNodeKind kind = BlueprintNodeKind::GAMEPLAY_ACTION;
    std::unordered_map<std::string, PinValue> params;
    float editor_x = 0.0f;
    float editor_y = 0.0f;
};

struct BlueprintWire {
    int from_node = 0;
    std::string from_pin;
    int to_node = 0;
    std::string to_pin;
};

struct ExecutionTraceStep {
    int node_id;
    std::string type_name;
    std::string detail;
};

class BlueprintGraph {
public:
    explicit BlueprintGraph(std::string graph_name = "CharacterBlueprint", std::string base_class = "CharacterBody3D");

    int add_node(const std::string& type_name, BlueprintNodeKind kind,
                 const std::unordered_map<std::string, PinValue>& params = {},
                 float x = 0.0f, float y = 0.0f);

    void connect(int from_node, const std::string& from_pin, int to_node, const std::string& to_pin);

    void set_variable(const std::string& name, const PinValue& value);
    PinValue get_variable(const std::string& name) const;

    /* Native VM Execution (for instant in-editor preview & zero-compile playtesting) */
    std::vector<ExecutionTraceStep> execute_event(const std::string& event_name);

    /* Dual-Target Code Synthesis: Compile Visual Blueprint -> GDScript (Godot 4) or Native C++20 */
    std::string transpile_to_gdscript() const;
    std::string transpile_to_cpp() const;

    const std::vector<BlueprintNode>& nodes() const { return nodes_; }
    const std::vector<BlueprintWire>& wires() const { return wires_; }

private:
    void execute_node_recursive(int node_id, std::vector<ExecutionTraceStep>& trace, int depth);
    int find_connected_target(int from_node, const std::string& from_pin) const;
    void emit_gdscript_chain(int node_id, int indent, std::string& out, int depth) const;
    void emit_cpp_chain(int node_id, int indent, std::string& out, int depth) const;

    std::string name_;
    std::string base_class_;
    int next_id_ = 1;
    std::vector<BlueprintNode> nodes_;
    std::vector<BlueprintWire> wires_;
    std::unordered_map<std::string, PinValue> variables_;
};

} // namespace nova

#endif /* NOVA_BLUEPRINT_HPP */
