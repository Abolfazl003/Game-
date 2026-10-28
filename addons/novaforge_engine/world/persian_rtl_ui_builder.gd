@tool
extends RefCounted
class_name NovaPersianRTLUIBuilder
## Smart Responsive HUD, Menu & Native Persian RTL UI Builder (`ICU / HarfBuzz` Shaping).


static func create_persian_rtl_hud(title_fa: String = "وضعیت جنگجو") -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "NovaSmartHUD"

	var root_ctrl := Control.new()
	root_ctrl.name = "HUDRoot"
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.layout_direction = Control.LAYOUT_DIRECTION_RTL
	layer.add_child(root_ctrl)

	var panel := PanelContainer.new()
	panel.name = "StatusPanel"
	panel.position = Vector2(32, 24)
	root_ctrl.add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = title_fa
	title_lbl.text_direction = Control.TEXT_DIRECTION_RTL
	vbox.add_child(title_lbl)

	var hp_bar := ProgressBar.new()
	hp_bar.name = "HealthBar"
	hp_bar.max_value = 100.0
	hp_bar.value = 100.0
	hp_bar.custom_minimum_size = Vector2(240, 20)
	vbox.add_child(hp_bar)

	var stm_bar := ProgressBar.new()
	stm_bar.name = "StaminaBar"
	stm_bar.max_value = 100.0
	stm_bar.value = 100.0
	stm_bar.custom_minimum_size = Vector2(240, 14)
	vbox.add_child(stm_bar)

	return layer
