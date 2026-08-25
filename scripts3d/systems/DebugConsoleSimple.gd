extends BaseSystemSimple

class_name DebugConsoleSimple

var commands: Dictionary = {}

signal command_executed(command: String)
signal console_opened
signal console_closed

func _ready() -> void:
	set_state("console_open", false)
	set_state("console_history", [])
	set_state("command_stats", {})
	set_state("error_log", [])
	set_state("performance_data", [])
	set_state("variables", {})
	set_state("command_aliases", {})
	set_state("cheat_detection_log", [])
	_initialize_commands()

func _initialize_commands() -> void:
	commands = {
		"help": func(): return "Available commands: help, spawn, teleport, heal, give_gold, level_up, clear",
		"spawn": func(args): return "Spawned enemy: %s" % args[0] if args.size() > 0 else "Usage: spawn <enemy>",
		"teleport": func(args): return "Teleported to: %s" % args[0] if args.size() > 0 else "Usage: teleport <location>",
		"heal": func(args): return "Healed to full HP",
		"give_gold": func(args): return "Given %s gold" % args[0] if args.size() > 0 else "Usage: give_gold <amount>",
		"level_up": func(): return "Leveled up!",
		"clear": func(): return ""
	}

var cheat_commands: Array = ["heal", "give_gold", "level_up"]

func execute_command(input: String) -> String:
	var parts = input.split(" ")
	var command = parts[0].to_lower()
	var args = parts.slice(1) if parts.size() > 1 else []
	var start_time = Time.get_ticks_msec()

	var aliases = get_state("command_aliases", {})
	if command in aliases:
		command = aliases[command]

	if command not in commands:
		record_error("Unknown command: %s" % command)
		record_command_execution(command, false, Time.get_ticks_msec() - start_time)
		return "Unknown command: %s" % command

	var history = get_state("console_history", [])
	history.append(input)
	if history.size() > 100:
		history.pop_front()
	set_state("console_history", history)

	var result = commands[command].call(args)
	record_command_execution(command, true, Time.get_ticks_msec() - start_time)
	if command in cheat_commands:
		detect_cheat(command)
	command_executed.emit(command)
	emit_event("command_executed", command)
	return result

func open_console() -> void:
	set_state("console_open", true)
	console_opened.emit()
	emit_event("console_opened", "")

func close_console() -> void:
	set_state("console_open", false)
	console_closed.emit()
	emit_event("console_closed", "")

func is_open() -> bool:
	return get_state("console_open", false)

func get_history() -> Array:
	return get_state("console_history", [])

func clear_history() -> void:
	set_state("console_history", [])
	emit_event("history_cleared", "")

func get_console_text() -> String:
	var history = get_history()
	var text = "=== DEBUG CONSOLE ===\n"
	for cmd in history.slice(-5):
		text += "> %s\n" % cmd
	return text

func record_command_execution(command: String, success: bool, execution_time_ms: int) -> void:
	var stats = get_state("command_stats", {})
	if command not in stats:
		stats[command] = {"total": 0, "successful": 0, "failed": 0, "total_time": 0}
	stats[command]["total"] += 1
	if success:
		stats[command]["successful"] += 1
	else:
		stats[command]["failed"] += 1
	stats[command]["total_time"] += execution_time_ms
	set_state("command_stats", stats)

func record_error(error_message: String) -> void:
	var errors = get_state("error_log", [])
	errors.append({"message": error_message, "time": Time.get_ticks_msec()})
	if errors.size() > 50:
		errors.pop_front()
	set_state("error_log", errors)

func record_performance(metric_name: String, value: float) -> void:
	var perf = get_state("performance_data", [])
	perf.append({"metric": metric_name, "value": value, "time": Time.get_ticks_msec()})
	if perf.size() > 100:
		perf.pop_front()
	set_state("performance_data", perf)

func set_variable(var_name: String, value: Variant) -> void:
	var variables = get_state("variables", {})
	variables[var_name] = value
	set_state("variables", variables)

func get_variable(var_name: String) -> Variant:
	var variables = get_state("variables", {})
	return variables.get(var_name, null)

func add_command_alias(alias: String, command: String) -> void:
	var aliases = get_state("command_aliases", {})
	aliases[alias] = command
	set_state("command_aliases", aliases)

func detect_cheat(cheat_type: String) -> void:
	var log = get_state("cheat_detection_log", [])
	log.append({"type": cheat_type, "time": Time.get_ticks_msec()})
	if log.size() > 50:
		log.pop_front()
	set_state("cheat_detection_log", log)
	emit_event("cheat_detected", cheat_type)

func get_command_stats(command: String) -> Dictionary:
	var stats = get_state("command_stats", {})
	return stats.get(command, {})

func get_total_command_executions() -> int:
	var stats = get_state("command_stats", {})
	var total = 0
	for cmd_stat in stats.values():
		total += cmd_stat.get("total", 0)
	return total

func get_error_count() -> int:
	return get_state("error_log", []).size()

func get_debug_console_statistics() -> Dictionary:
	return {
		"total_commands_executed": get_total_command_executions(),
		"unique_commands_used": get_state("command_stats", {}).size(),
		"error_count": get_error_count(),
		"history_size": get_state("console_history", []).size(),
		"cheat_detections": get_state("cheat_detection_log", []).size(),
		"aliases_registered": get_state("command_aliases", {}).size(),
		"variables_set": get_state("variables", {}).size(),
		"performance_entries": get_state("performance_data", []).size(),
		"is_open": is_open()
	}
