extends BaseSystemSimple

class_name NotificationSimple

class Notification:
	var id: String
	var title: String
	var message: String
	var notification_type: String
	var duration: float
	var timestamp: float
	var priority: int
	var category: String
	var is_read: bool = false
	var delivery_method: String
	var has_sound: bool = true
	var action_id: String = ""
	var group_key: String = ""
	func _init(p_id: String, p_title: String, p_msg: String, p_type: String = "info", p_duration: float = 3.0) -> void:
		id = p_id
		title = p_title
		message = p_msg
		notification_type = p_type
		duration = p_duration
		timestamp = Time.get_ticks_msec()
		priority = 1
		category = "general"
		delivery_method = "popup"

var active_notifications: Array[Notification] = []
var history_limit: int = 50

signal notification_shown(notification: Notification)
signal notification_dismissed(notification_id: String)
signal notification_read(notification_id: String)
signal notification_actioned(notification_id: String, action: String)

func _ready() -> void:
	set_state("notification_queue", [])
	set_state("notification_history", [])
	set_state("unread_count", 0)
	set_state("priority_queue", [])
	set_state("grouped_notifications", {})
	set_state("notification_actions", {})
	set_state("notification_display_history", [])
	set_state("action_history", [])
	set_state("read_history", [])
	set_state("notification_statistics", {})

func _record_notification_display(notification_id: String, notification_type: String, category: String, priority: int) -> void:
	var history = get_state("notification_display_history", [])
	history.append({"id": notification_id, "type": notification_type, "category": category, "priority": priority, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("notification_display_history", history)

func _record_notification_action(notification_id: String, action: String) -> void:
	var history = get_state("action_history", [])
	history.append({"id": notification_id, "action": action, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("action_history", history)

func _record_notification_read(notification_id: String) -> void:
	var history = get_state("read_history", [])
	history.append({"id": notification_id, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("read_history", history)

func show_notification(title: String, message: String, notification_type: String = "info", duration: float = 3.0, priority: int = 1, category: String = "general") -> Notification:
	var id = "notif_%d" % randi()
	var notif = Notification.new(id, title, message, notification_type, duration)
	notif.priority = priority
	notif.category = category
	_record_notification_display(id, notification_type, category, priority)
	_queue_notification(notif)
	active_notifications.append(notif)
	if active_notifications.size() > 20:
		active_notifications.remove_at(0)
	notification_shown.emit(notif)
	emit_event("notification_shown", {"id": id, "priority": priority, "category": category})
	return notif

func _queue_notification(notif: Notification) -> void:
	var history = get_state("notification_history", [])
	history.append({"id": notif.id, "title": notif.title, "time": notif.timestamp, "read": false})
	if history.size() > history_limit:
		history.remove_at(0)
	set_state("notification_history", history)
	var unread = get_state("unread_count", 0)
	set_state("unread_count", unread + 1)

func dismiss_notification(notification_id: String) -> void:
	for i in range(active_notifications.size()):
		if active_notifications[i].id == notification_id:
			active_notifications.remove_at(i)
			notification_dismissed.emit(notification_id)
			emit_event("notification_dismissed", notification_id)
			break

func mark_notification_read(notification_id: String) -> void:
	for notif in active_notifications:
		if notif.id == notification_id:
			if not notif.is_read:
				notif.is_read = true
				var unread = get_state("unread_count", 0)
				set_state("unread_count", max(0, unread - 1))
				_record_notification_read(notification_id)
				notification_read.emit(notification_id)
				emit_event("notification_read", notification_id)
			break

func trigger_notification_action(notification_id: String, action: String) -> void:
	for notif in active_notifications:
		if notif.id == notification_id:
			_record_notification_action(notification_id, action)
			notification_actioned.emit(notification_id, action)
			emit_event("notification_action", {"id": notification_id, "action": action})
			break

func show_alert(title: String, message: String) -> Notification:
	return show_notification(title, message, "alert", 5.0, 3, "system")

func show_success(title: String, message: String) -> Notification:
	return show_notification(title, message, "success", 3.0, 1, "achievement")

func show_warning(title: String, message: String) -> Notification:
	return show_notification(title, message, "warning", 4.0, 2, "warning")

func show_error(title: String, message: String) -> Notification:
	return show_notification(title, message, "error", 5.0, 3, "error")

func show_quest_update(title: String, message: String) -> Notification:
	return show_notification(title, message, "quest", 3.5, 2, "quest")

func show_chat_message(title: String, message: String) -> Notification:
	return show_notification(title, message, "chat", 2.5, 1, "chat")

func get_active_notifications() -> Array[Notification]:
	return active_notifications

func get_notifications_by_category(category: String) -> Array[Notification]:
	var result: Array[Notification] = []
	for notif in active_notifications:
		if notif.category == category:
			result.append(notif)
	return result

func get_notifications_by_priority(min_priority: int) -> Array[Notification]:
	var result: Array[Notification] = []
	for notif in active_notifications:
		if notif.priority >= min_priority:
			result.append(notif)
	return result

func get_unread_notifications() -> Array[Notification]:
	var result: Array[Notification] = []
	for notif in active_notifications:
		if not notif.is_read:
			result.append(notif)
	return result

func get_notification_count() -> int:
	return active_notifications.size()

func get_unread_count() -> int:
	return get_state("unread_count", 0)

func clear_all_notifications() -> void:
	active_notifications.clear()
	set_state("unread_count", 0)
	emit_event("all_notifications_cleared", "")

func clear_category(category: String) -> void:
	active_notifications = active_notifications.filter(func(n): return n.category != category)
	emit_event("category_cleared", category)

func get_notification_history() -> Array:
	return get_state("notification_history", [])

func get_notification_text() -> String:
	if active_notifications.is_empty():
		return "No active notifications"
	var text = "Notifications: %d [%d unread]\n" % [active_notifications.size(), get_unread_count()]
	for notif in active_notifications.slice(0, 3):
		var marker = "✓" if notif.is_read else "●"
		text += "%s [%s] %s\n" % [marker, notif.category.left(3).to_upper(), notif.title]
	return text

func update_notification_statistics() -> void:
	var stats = get_state("notification_statistics", {})
	var display_history = get_state("notification_display_history", [])
	var action_history = get_state("action_history", [])
	var read_history = get_state("read_history", [])
	stats["total_notifications_displayed"] = display_history.size()
	stats["total_actions_triggered"] = action_history.size()
	stats["total_notifications_read"] = read_history.size()
	stats["current_unread_count"] = get_unread_count()
	stats["total_active_notifications"] = active_notifications.size()
	var category_counts = {}
	for notif in active_notifications:
		category_counts[notif.category] = category_counts.get(notif.category, 0) + 1
	stats["category_breakdown"] = category_counts
	set_state("notification_statistics", stats)

func get_notification_statistics() -> Dictionary:
	update_notification_statistics()
	return get_state("notification_statistics", {})
