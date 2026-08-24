extends CanvasLayer

class_name NotificationSimple

@export var notification_duration: float = 3.0
@export var max_notifications: int = 5

var notifications: Array[String] = []
var notification_timers: Array[float] = []

signal notification_added(message: String)

func add_notification(message: String) -> void:
	notifications.append(message)
	notification_timers.append(notification_duration)

	if notifications.size() > max_notifications:
		notifications.pop_front()
		notification_timers.pop_front()

	notification_added.emit(message)
	print("💬 %s" % message)

func _process(delta: float) -> void:
	for i in range(notification_timers.size()):
		notification_timers[i] -= delta
		if notification_timers[i] <= 0:
			notifications.remove_at(i)
			notification_timers.remove_at(i)
			break

func get_notifications_text() -> String:
	var text = ""
	for notification in notifications:
		text += notification + "\n"
	return text

func clear_notifications() -> void:
	notifications.clear()
	notification_timers.clear()

func add_quest_notification(quest_title: String) -> void:
	add_notification("📋 New Quest: %s" % quest_title)

func add_achievement_notification(achievement_name: String) -> void:
	add_notification("🏆 Achievement: %s" % achievement_name)

func add_item_notification(item_name: String, quantity: int) -> void:
	add_notification("📦 Received %d x %s" % [quantity, item_name])

func add_level_up_notification(level: int) -> void:
	add_notification("⭐ Level Up! You are now level %d" % level)

func add_warning_notification(message: String) -> void:
	add_notification("⚠️ %s" % message)

func add_success_notification(message: String) -> void:
	add_notification("✓ %s" % message)
