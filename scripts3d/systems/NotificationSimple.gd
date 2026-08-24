extends BaseSystemSimple

class_name NotificationSimple

class Notification:
	var id: String
	var title: String
	var message: String
	var notification_type: String
	var duration: float
	var timestamp: float
	func _init(p_id: String, p_title: String, p_msg: String, p_type: String = "info", p_duration: float = 3.0) -> void:
		id = p_id
		title = p_title
		message = p_msg
		notification_type = p_type
		duration = p_duration
		timestamp = Time.get_ticks_msec()

var active_notifications: Array[Notification] = []

signal notification_shown(notification: Notification)
signal notification_dismissed(notification_id: String)

func _ready() -> void:
	set_state("notification_queue", [])
	set_state("notification_history", [])

func show_notification(title: String, message: String, notification_type: String = "info", duration: float = 3.0) -> Notification:
	var id = "notif_%d" % randi()
	var notif = Notification.new(id, title, message, notification_type, duration)
	active_notifications.append(notif)
	notification_shown.emit(notif)
	emit_event("notification_shown", id)
	return notif

func dismiss_notification(notification_id: String) -> void:
	for i in range(active_notifications.size()):
		if active_notifications[i].id == notification_id:
			active_notifications.remove_at(i)
			notification_dismissed.emit(notification_id)
			emit_event("notification_dismissed", notification_id)
			break

func show_alert(title: String, message: String) -> Notification:
	return show_notification(title, message, "alert", 5.0)

func show_success(title: String, message: String) -> Notification:
	return show_notification(title, message, "success", 3.0)

func show_warning(title: String, message: String) -> Notification:
	return show_notification(title, message, "warning", 4.0)

func show_error(title: String, message: String) -> Notification:
	return show_notification(title, message, "error", 5.0)

func get_active_notifications() -> Array[Notification]:
	return active_notifications

func get_notification_count() -> int:
	return active_notifications.size()

func clear_all_notifications() -> void:
	active_notifications.clear()
	emit_event("all_notifications_cleared", "")

func get_notification_text() -> String:
	if active_notifications.is_empty():
		return "No active notifications"
	var text = "Active Notifications: %d\n" % active_notifications.size()
	for notif in active_notifications.slice(0, 3):
		text += "[%s] %s - %s\n" % [notif.notification_type.capitalize(), notif.title, notif.message.substr(0, 30)]
	return text
