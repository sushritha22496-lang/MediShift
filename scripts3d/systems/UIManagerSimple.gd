extends BaseSystemSimple

class_name UIManagerSimple

class UIElement:
	var name: String
	var visible: bool = false
	var layer: int = 0
	var animation_type: String = "fade"
	var animation_duration: float = 0.3
	var is_modal: bool = false
	var input_enabled: bool = false
	var parent_element: String = ""
	var position: Vector2 = Vector2.ZERO
	var size: Vector2 = Vector2(100, 100)
	var scale: float = 1.0
	func _init(p_name: String, p_visible: bool = false, p_layer: int = 0) -> void:
		name = p_name
		visible = p_visible
		layer = p_layer

signal ui_element_shown(element: String)
signal ui_element_hidden(element: String)
signal screen_changed(screen: String)
signal modal_opened(modal: String)
signal modal_closed(modal: String)
signal animation_started(element: String, animation_type: String)
signal animation_finished(element: String)

var ui_elements: Dictionary = {}
var screen_stack: Array[String] = []
var modal_stack: Array[String] = []

func _ready() -> void:
	set_state("current_screen", "game")
	set_state("open_panels", [])
	set_state("ui_theme", "default")
	set_state("animation_enabled", true)
	set_state("tooltips_enabled", true)
	set_state("ui_scale", 1.0)
	set_state("focused_element", "")
	set_state("ui_history", [])
	_initialize_ui_elements()

func _initialize_ui_elements() -> void:
	var hud = UIElement.new("hud", true, 0)
	hud.animation_type = "fade"
	var inventory = UIElement.new("inventory", false, 1)
	inventory.is_modal = true
	inventory.animation_type = "slide"
	var map = UIElement.new("map", false, 1)
	map.is_modal = true
	var minimap = UIElement.new("minimap", true, 0)
	var quest_log = UIElement.new("quest_log", false, 1)
	quest_log.is_modal = true
	quest_log.animation_type = "slide"
	var character_sheet = UIElement.new("character_sheet", false, 1)
	character_sheet.is_modal = true
	var pause_menu = UIElement.new("pause_menu", false, 2)
	pause_menu.is_modal = true
	pause_menu.animation_type = "scale"
	var dialogue_box = UIElement.new("dialogue_box", false, 1)
	dialogue_box.animation_type = "fade"
	var notifications = UIElement.new("notifications", true, 0)
	notifications.animation_type = "slide"
	ui_elements = {
		"hud": hud, "inventory": inventory, "map": map, "minimap": minimap,
		"quest_log": quest_log, "character_sheet": character_sheet,
		"pause_menu": pause_menu, "dialogue_box": dialogue_box, "notifications": notifications
	}

func show_element(element: String) -> bool:
	if element in ui_elements:
		var elem = ui_elements[element]
		var animation_enabled = get_state("animation_enabled", true)
		if animation_enabled:
			animation_started.emit(element, elem.animation_type)
			await get_tree().create_timer(elem.animation_duration).timeout
			animation_finished.emit(element)
		elem.visible = true
		if elem.is_modal:
			modal_stack.append(element)
			modal_opened.emit(element)
		ui_element_shown.emit(element)
		_track_ui_action("show", element)
		emit_event("element_shown", element)
		return true
	return false

func hide_element(element: String) -> bool:
	if element in ui_elements:
		var elem = ui_elements[element]
		var animation_enabled = get_state("animation_enabled", true)
		if animation_enabled:
			animation_started.emit(element, elem.animation_type)
			await get_tree().create_timer(elem.animation_duration).timeout
			animation_finished.emit(element)
		elem.visible = false
		if elem.is_modal and element in modal_stack:
			modal_stack.erase(element)
			modal_closed.emit(element)
		ui_element_hidden.emit(element)
		_track_ui_action("hide", element)
		emit_event("element_hidden", element)
		return true
	return false

func toggle_element(element: String) -> bool:
	if element in ui_elements:
		if ui_elements[element].visible:
			return await hide_element(element)
		else:
			return await show_element(element)
	return false

func is_element_visible(element: String) -> bool:
	if element in ui_elements:
		return ui_elements[element].visible
	return false

func _track_ui_action(action: String, element: String) -> void:
	var history = get_state("ui_history", [])
	history.append({"action": action, "element": element, "timestamp": Time.get_ticks_msec()})
	if history.size() > 100:
		history.pop_front()
	set_state("ui_history", history)

func change_screen(screen: String) -> void:
	var prev_screen = get_state("current_screen", "game")
	screen_stack.append(screen)
	if screen_stack.size() > 20:
		screen_stack.remove_at(0)
	set_state("current_screen", screen)
	screen_changed.emit(screen)
	emit_event("screen_changed", {"from": prev_screen, "to": screen})

func get_current_screen() -> String:
	return get_state("current_screen", "game")

func get_screen_stack() -> Array[String]:
	return screen_stack.duplicate()

func get_modal_stack() -> Array[String]:
	return modal_stack.duplicate()

func is_any_modal_open() -> bool:
	return not modal_stack.is_empty()

func get_top_modal() -> String:
	if not modal_stack.is_empty():
		return modal_stack[-1]
	return ""

func get_visible_elements() -> Array:
	var visible = []
	for element in ui_elements.keys():
		if ui_elements[element].visible:
			visible.append(element)
	return visible

func get_ui_element(element: String) -> UIElement:
	return ui_elements.get(element)

func set_ui_theme(theme: String) -> void:
	set_state("ui_theme", theme)
	emit_event("theme_changed", theme)

func set_ui_scale(scale: float) -> void:
	set_state("ui_scale", clamp(scale, 0.5, 2.0))
	emit_event("ui_scale_changed", scale)

func set_animations_enabled(enabled: bool) -> void:
	set_state("animation_enabled", enabled)
	emit_event("animations_toggled", enabled)

func go_back_screen() -> bool:
	if screen_stack.size() > 1:
		screen_stack.pop_back()
		var prev_screen = screen_stack[-1]
		change_screen(prev_screen)
		return true
	return false

func get_ui_history() -> Array:
	return get_state("ui_history", [])

func get_ui_text() -> String:
	var modals = get_modal_stack()
	var text = "UI: %s | Modals: %d | Visible: %d\n" % [get_current_screen(), modals.size(), get_visible_elements().size()]
	if not modals.is_empty():
		text += "Modal: %s" % modals[-1]
	return text
