extends BaseSystemSimple

class_name UIManagerSimple

signal ui_element_shown(element: String)
signal ui_element_hidden(element: String)
signal screen_changed(screen: String)

var ui_elements: Dictionary = {
	"hud": {"visible": true, "layer": 0},
	"inventory": {"visible": false, "layer": 1},
	"map": {"visible": false, "layer": 1},
	"minimap": {"visible": true, "layer": 0},
	"quest_log": {"visible": false, "layer": 1},
	"character_sheet": {"visible": false, "layer": 1},
	"pause_menu": {"visible": false, "layer": 2},
	"dialogue_box": {"visible": false, "layer": 1},
	"notifications": {"visible": true, "layer": 0}
}

func _ready() -> void:
	set_state("current_screen", "game")
	set_state("open_panels", [])

func show_element(element: String) -> bool:
	if element in ui_elements:
		ui_elements[element]["visible"] = true
		ui_element_shown.emit(element)
		emit_event("element_shown", element)
		return true
	return false

func hide_element(element: String) -> bool:
	if element in ui_elements:
		ui_elements[element]["visible"] = false
		ui_element_hidden.emit(element)
		emit_event("element_hidden", element)
		return true
	return false

func toggle_element(element: String) -> bool:
	if element in ui_elements:
		if ui_elements[element]["visible"]:
			hide_element(element)
		else:
			show_element(element)
		return true
	return false

func is_element_visible(element: String) -> bool:
	return ui_elements.get(element, {}).get("visible", false)

func change_screen(screen: String) -> void:
	set_state("current_screen", screen)
	screen_changed.emit(screen)
	emit_event("screen_changed", screen)

func get_current_screen() -> String:
	return get_state("current_screen", "game")

func get_visible_elements() -> Array:
	var visible = []
	for element in ui_elements.keys():
		if ui_elements[element]["visible"]:
			visible.append(element)
	return visible

func get_ui_text() -> String:
	var text = "UI Manager\nScreen: %s\n" % get_current_screen()
	text += "Visible: %s" % ", ".join(get_visible_elements())
	return text
