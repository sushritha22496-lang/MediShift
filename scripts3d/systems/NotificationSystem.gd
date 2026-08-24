extends CanvasLayer

class_name NotificationSystem

class Notification:
	var message: String
	var duration: float = 3.0
	var type: String = "info"
	var position: Vector2 = Vector2(100, 100)

var notifications: Array[Notification] = []
var notification_label: Label = null

signal notification_shown(message: String)
signal notification_hidden

func _ready() -> void:
	_create_notification_label()

func _create_notification_label() -> void:
	notification_label = Label.new()
	notification_label.add_theme_font_size_override("font_sizes", 20)
	notification_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	notification_label.offset_left = 20
	notification_label.offset_top = 400
	add_child(notification_label)

func show_notification(message: String, duration: float = 3.0, notification_type: String = "info") -> void:
	var notif = Notification.new()
	notif.message = message
	notif.duration = duration
	notif.type = notification_type

	notifications.append(notif)
	notification_shown.emit(message)

	if notification_label:
		notification_label.text = message
		_color_notification(notification_type)

	await get_tree().create_timer(duration).timeout
	notifications.erase(notif)

	if notifications.is_empty() and notification_label:
		notification_label.text = ""

func _color_notification(notif_type: String) -> void:
	if not notification_label:
		return

	match notif_type:
		"success":
			notification_label.add_theme_color_override("font_color", Color.GREEN)
		"error":
			notification_label.add_theme_color_override("font_color", Color.RED)
		"warning":
			notification_label.add_theme_color_override("font_color", Color.YELLOW)
		"info":
			notification_label.add_theme_color_override("font_color", Color.WHITE)

func clear_notifications() -> void:
	notifications.clear()
	if notification_label:
		notification_label.text = ""

func get_active_notifications() -> Array:
	return notifications.duplicate()
