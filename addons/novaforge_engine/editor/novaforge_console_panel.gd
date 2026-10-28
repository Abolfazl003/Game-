@tool
extends VBoxContainer
class_name NovaForgeConsolePanel
## Hybrid Output Console Bottom Panel (`NovaForge Console`) matching the live studio console:
## Displays Zero-MCP tool calls, Colibrì VRAM relay logs, Voronoi C++20 shard telemetry,
## Elemental Chemistry reactions, and compiled Blueprint -> C++20 / GDScript source code.

var _console: RichTextLabel


func _ready() -> void:
	custom_minimum_size = Vector2(0, 210)

	var top := HBoxContainer.new()
	var title := Label.new()
	title.text = "⚡ NovaForge Hybrid Output Console (Blueprint + C++20 + GDScript + Scene Audit)"
	title.clip_text = true
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)

	var btn_clear := Button.new()
	btn_clear.text = "پاک کردن (Clear)"
	btn_clear.pressed.connect(func(): _console.clear())
	top.add_child(btn_clear)
	add_child(top)

	_console = RichTextLabel.new()
	_console.bbcode_enabled = true
	_console.scroll_following = true
	_console.selection_enabled = true
	_console.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_console)

	call_deferred("_bind_controller")


func _bind_controller() -> void:
	var ctrl := _get_ctrl()
	if ctrl and not ctrl.log_emitted.is_connected(_on_log_emitted):
		ctrl.log_emitted.connect(_on_log_emitted)
	_on_log_emitted("[color=#94a3b8]// NovaForge Hybrid Output Console Ready (Zero-MCP | 123 Skills | 114 Tools)[/color]")


func _get_ctrl() -> NovaEditorSceneController:
	if get_tree() and get_tree().root.has_node("NovaEditorController"):
		return get_tree().root.get_node("NovaEditorController") as NovaEditorSceneController
	return null


func _on_log_emitted(bbcode_line: String) -> void:
	if _console:
		_console.append_text(bbcode_line + "\n")
