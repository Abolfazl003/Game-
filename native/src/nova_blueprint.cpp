#include "nova_blueprint.hpp"

#include <sstream>

namespace nova {

namespace {

std::string pin_to_string(const PinValue& v) {
    if (std::holds_alternative<bool>(v)) return std::get<bool>(v) ? "true" : "false";
    if (std::holds_alternative<int64_t>(v)) return std::to_string(std::get<int64_t>(v));
    if (std::holds_alternative<double>(v)) {
        std::ostringstream oss;
        oss << std::get<double>(v);
        return oss.str();
    }
    if (std::holds_alternative<std::string>(v)) return std::get<std::string>(v);
    return "";
}

double pin_to_double(const PinValue& v) {
    if (std::holds_alternative<double>(v)) return std::get<double>(v);
    if (std::holds_alternative<int64_t>(v)) return static_cast<double>(std::get<int64_t>(v));
    if (std::holds_alternative<bool>(v)) return std::get<bool>(v) ? 1.0 : 0.0;
    return 0.0;
}

bool pin_to_bool(const PinValue& v) {
    if (std::holds_alternative<bool>(v)) return std::get<bool>(v);
    if (std::holds_alternative<int64_t>(v)) return std::get<int64_t>(v) != 0;
    if (std::holds_alternative<double>(v)) return std::get<double>(v) != 0.0;
    if (std::holds_alternative<std::string>(v)) return !std::get<std::string>(v).empty();
    return false;
}

} // namespace

BlueprintGraph::BlueprintGraph(std::string graph_name, std::string base_class)
    : name_(std::move(graph_name)), base_class_(std::move(base_class)) {}

int BlueprintGraph::add_node(const std::string& type_name, BlueprintNodeKind kind,
                             const std::unordered_map<std::string, PinValue>& params,
                             float x, float y) {
    BlueprintNode node;
    node.id = next_id_++;
    node.type_name = type_name;
    node.kind = kind;
    node.params = params;
    node.editor_x = x;
    node.editor_y = y;
    nodes_.push_back(std::move(node));
    return nodes_.back().id;
}

void BlueprintGraph::connect(int from_node, const std::string& from_pin, int to_node, const std::string& to_pin) {
    wires_.push_back(BlueprintWire{from_node, from_pin, to_node, to_pin});
}

void BlueprintGraph::set_variable(const std::string& name, const PinValue& value) {
    variables_[name] = value;
}

PinValue BlueprintGraph::get_variable(const std::string& name) const {
    auto it = variables_.find(name);
    if (it != variables_.end()) return it->second;
    return int64_t{0};
}

int BlueprintGraph::find_connected_target(int from_node, const std::string& from_pin) const {
    for (const auto& w : wires_) {
        if (w.from_node == from_node && w.from_pin == from_pin) {
            return w.to_node;
        }
    }
    return 0;
}

std::vector<ExecutionTraceStep> BlueprintGraph::execute_event(const std::string& event_name) {
    std::vector<ExecutionTraceStep> trace;
    std::string target_type = "Event_" + event_name;
    for (const auto& n : nodes_) {
        if (n.kind == BlueprintNodeKind::EVENT_ENTRY &&
            (n.type_name == target_type || n.type_name == event_name)) {
            trace.push_back({n.id, n.type_name, "Triggered event " + event_name});
            int next = find_connected_target(n.id, "exec_out");
            if (next > 0) {
                execute_node_recursive(next, trace, 0);
            }
        }
    }
    return trace;
}

void BlueprintGraph::execute_node_recursive(int node_id, std::vector<ExecutionTraceStep>& trace, int depth) {
    if (depth > 64) return;
    const BlueprintNode* node = nullptr;
    for (const auto& n : nodes_) {
        if (n.id == node_id) {
            node = &n;
            break;
        }
    }
    if (!node) return;

    if (node->kind == BlueprintNodeKind::FLOW_BRANCH) {
        bool cond = false;
        auto it_var = node->params.find("condition_var");
        if (it_var != node->params.end()) {
            std::string var_name = pin_to_string(it_var->second);
            auto it_min = node->params.find("min_value");
            if (it_min != node->params.end()) {
                cond = pin_to_double(get_variable(var_name)) >= pin_to_double(it_min->second);
            } else {
                cond = pin_to_bool(get_variable(var_name));
            }
        } else if (auto it_c = node->params.find("condition"); it_c != node->params.end()) {
            cond = pin_to_bool(it_c->second);
        }

        trace.push_back({node->id, node->type_name, std::string("Branch evaluated -> ") + (cond ? "True" : "False")});
        int branch_next = find_connected_target(node->id, cond ? "true" : "false");
        if (branch_next > 0) {
            execute_node_recursive(branch_next, trace, depth + 1);
        }
        return;
    }

    if (node->kind == BlueprintNodeKind::FLOW_SEQUENCE) {
        trace.push_back({node->id, node->type_name, "Sequence dispatch"});
        for (int i = 0; i < 8; ++i) {
            int seq_next = find_connected_target(node->id, "then_" + std::to_string(i));
            if (seq_next > 0) {
                execute_node_recursive(seq_next, trace, depth + 1);
            }
        }
        return;
    }

    if (node->kind == BlueprintNodeKind::VARIABLE_SET) {
        auto it_name = node->params.find("var_name");
        auto it_delta = node->params.find("delta");
        auto it_val = node->params.find("value");
        if (it_name != node->params.end()) {
            std::string vname = pin_to_string(it_name->second);
            if (it_delta != node->params.end()) {
                double updated = pin_to_double(get_variable(vname)) + pin_to_double(it_delta->second);
                set_variable(vname, updated);
                trace.push_back({node->id, node->type_name, vname + " adjusted to " + std::to_string(updated)});
            } else if (it_val != node->params.end()) {
                set_variable(vname, it_val->second);
                trace.push_back({node->id, node->type_name, vname + " set to " + pin_to_string(it_val->second)});
            }
        }
    } else {
        std::ostringstream detail;
        detail << "Executed " << node->type_name << "(";
        bool first = true;
        for (const auto& kv : node->params) {
            if (!first) detail << ", ";
            first = false;
            detail << kv.first << "=" << pin_to_string(kv.second);
        }
        detail << ")";
        trace.push_back({node->id, node->type_name, detail.str()});
    }

    int next = find_connected_target(node->id, "exec_out");
    if (next > 0) {
        execute_node_recursive(next, trace, depth + 1);
    }
}

void BlueprintGraph::emit_gdscript_chain(int node_id, int indent, std::string& out, int depth) const {
    if (depth > 64 || node_id <= 0) return;
    const BlueprintNode* node = nullptr;
    for (const auto& n : nodes_) {
        if (n.id == node_id) {
            node = &n;
            break;
        }
    }
    if (!node) return;
    std::string pad(indent * 4, ' ');

    if (node->kind == BlueprintNodeKind::FLOW_BRANCH) {
        std::string expr = "true";
        if (auto it = node->params.find("condition_var"); it != node->params.end()) {
            expr = pin_to_string(it->second);
            if (auto it_m = node->params.find("min_value"); it_m != node->params.end()) {
                expr += " >= " + pin_to_string(it_m->second);
            }
        }
        out += pad + "if " + expr + ":\n";
        int t_next = find_connected_target(node->id, "true");
        if (t_next > 0) emit_gdscript_chain(t_next, indent + 1, out, depth + 1);
        else out += pad + "    pass\n";

        int f_next = find_connected_target(node->id, "false");
        if (f_next > 0) {
            out += pad + "else:\n";
            emit_gdscript_chain(f_next, indent + 1, out, depth + 1);
        }
        return;
    }

    if (node->kind == BlueprintNodeKind::VARIABLE_SET) {
        std::string vname = "state_val";
        if (auto it = node->params.find("var_name"); it != node->params.end()) vname = pin_to_string(it->second);
        if (auto it_d = node->params.find("delta"); it_d != node->params.end()) {
            out += pad + vname + " += " + pin_to_string(it_d->second) + "\n";
        } else if (auto it_v = node->params.find("value"); it_v != node->params.end()) {
            out += pad + vname + " = " + pin_to_string(it_v->second) + "\n";
        }
    } else {
        out += pad + "NovaNativeBus.invoke_blueprint_action(\"" + node->type_name + "\", {";
        bool first = true;
        for (const auto& kv : node->params) {
            if (!first) out += ", ";
            first = false;
            out += "\"" + kv.first + "\": \"" + pin_to_string(kv.second) + "\"";
        }
        out += "})\n";
    }

    int next = find_connected_target(node->id, "exec_out");
    if (next > 0) emit_gdscript_chain(next, indent, out, depth + 1);
}

std::string BlueprintGraph::transpile_to_gdscript() const {
    std::string out = "# Auto-compiled by NovaForge Blueprint Transpiler\n";
    out += "extends " + base_class_ + "\n";
    out += "class_name " + name_ + "\n\n";

    for (const auto& kv : variables_) {
        out += "@export var " + kv.first + " = " + pin_to_string(kv.second) + "\n";
    }
    if (!variables_.empty()) out += "\n";

    for (const auto& n : nodes_) {
        if (n.kind == BlueprintNodeKind::EVENT_ENTRY) {
            std::string fn_name = n.type_name;
            if (fn_name == "Event_BeginPlay") fn_name = "_ready()";
            else if (fn_name == "Event_Tick") fn_name = "_physics_process(delta: float)";
            else fn_name = "on_" + fn_name + "()";

            out += "func " + fn_name + ":\n";
            int next = find_connected_target(n.id, "exec_out");
            if (next > 0) emit_gdscript_chain(next, 1, out, 0);
            else out += "    pass\n";
            out += "\n";
        }
    }
    return out;
}

void BlueprintGraph::emit_cpp_chain(int node_id, int indent, std::string& out, int depth) const {
    if (depth > 64 || node_id <= 0) return;
    const BlueprintNode* node = nullptr;
    for (const auto& n : nodes_) {
        if (n.id == node_id) {
            node = &n;
            break;
        }
    }
    if (!node) return;
    std::string pad(indent * 4, ' ');

    if (node->kind == BlueprintNodeKind::FLOW_BRANCH) {
        std::string expr = "true";
        if (auto it = node->params.find("condition_var"); it != node->params.end()) {
            expr = pin_to_string(it->second);
            if (auto it_m = node->params.find("min_value"); it_m != node->params.end()) {
                expr += " >= " + pin_to_string(it_m->second);
            }
        }
        out += pad + "if (" + expr + ") {\n";
        int t_next = find_connected_target(node->id, "true");
        if (t_next > 0) emit_cpp_chain(t_next, indent + 1, out, depth + 1);
        out += pad + "}";
        int f_next = find_connected_target(node->id, "false");
        if (f_next > 0) {
            out += " else {\n";
            emit_cpp_chain(f_next, indent + 1, out, depth + 1);
            out += pad + "}";
        }
        out += "\n";
        return;
    }

    if (node->kind == BlueprintNodeKind::VARIABLE_SET) {
        std::string vname = "state_val";
        if (auto it = node->params.find("var_name"); it != node->params.end()) vname = pin_to_string(it->second);
        if (auto it_d = node->params.find("delta"); it_d != node->params.end()) {
            out += pad + vname + " += " + pin_to_string(it_d->second) + ";\n";
        } else if (auto it_v = node->params.find("value"); it_v != node->params.end()) {
            out += pad + vname + " = " + pin_to_string(it_v->second) + ";\n";
        }
    } else {
        out += pad + "nova_dispatch_action(\"" + node->type_name + "\");\n";
    }

    int next = find_connected_target(node->id, "exec_out");
    if (next > 0) emit_cpp_chain(next, indent, out, depth + 1);
}

std::string BlueprintGraph::transpile_to_cpp() const {
    std::string out = "// Auto-compiled by NovaForge Native C++20 Blueprint Compiler\n";
    out += "#include <godot_cpp/classes/" + base_class_ + ".hpp>\n\n";
    out += "class " + name_ + " : public godot::" + base_class_ + " {\npublic:\n";
    for (const auto& kv : variables_) {
        out += "    double " + kv.first + " = " + pin_to_string(kv.second) + ";\n";
    }
    out += "\n";
    for (const auto& n : nodes_) {
        if (n.kind == BlueprintNodeKind::EVENT_ENTRY) {
            out += "    void " + n.type_name + "() {\n";
            int next = find_connected_target(n.id, "exec_out");
            if (next > 0) emit_cpp_chain(next, 2, out, 0);
            out += "    }\n\n";
        }
    }
    out += "};\n";
    return out;
}

} // namespace nova
