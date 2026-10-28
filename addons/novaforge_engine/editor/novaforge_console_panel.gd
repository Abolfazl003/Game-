@tool
extends VBoxContainer
## Persian Hybrid Output Console Bottom Panel (`کنسول خروجی نوافورج`).

var _console: RichTextLabel


func _ready() -> void:
	custom_minimum_size = Vector2(0, 195)

	var top := HBoxContainer.new()
	var title := Label.new()
	title.text = "⚡ کنسول زنده نوافورج (گراف بلوپرینت + هسته C++20 + GDScript + ممیزی صحنه)"
	title.clip_text = true
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)

	var btn_clear := Button.new()
	btn_clear.text = "پاک کردن گزارش‌ها"
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
	if ctrl and ctrl.has_signal("log_emitted") and not ctrl.is_connected("log_emitted", _on_log_emitted):
		ctrl.connect("log_emitted", _on_log_emitted)
	_on_log_emitted("[color=#94a3b8]// کنسول ترکیبی نوافورج آماده است (بدون نیاز به MCP | ۱۲۳ مهارت | ۱۱۴ ابزار بومی)[/color]")


func _get_ctrl() -> Node:
	if get_tree() and get_tree().root.has_node("NovaEditorController"):
		return get_tree().root.get_node("NovaEditorController")
	return null


func _on_log_emitted(bbcode_line: String) -> void:
	if _console:
		_console.append_text(bbcode_line + "\n")
