extends Node

class_name UIHelper

static func create_button(text: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.pressed.connect(callback)
	return btn

static func create_label(text: String, size: int = 24) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	return lbl

static func show_popup(title: str, message: str, duration: float = 2.0) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	dialog.get_ok_button().visible = false
	var root = get_tree().root
	root.add_child(dialog)
	await get_tree().create_timer(duration).timeout
	dialog.queue_free()

static func create_vbox(items: Array) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	for item in items:
		vbox.add_child(item)
	return vbox

static func create_panel(content: Control, padding: int = 10) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.add_child(content)
	content.anchor_left = padding / 100.0
	content.anchor_top = padding / 100.0
	content.anchor_right = 1.0 - (padding / 100.0)
	content.anchor_bottom = 1.0 - (padding / 100.0)
	return panel
