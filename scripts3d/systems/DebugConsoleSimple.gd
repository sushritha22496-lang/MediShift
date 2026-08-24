extends BaseSystemSimple

class_name DebugConsoleSimple

var commands: Dictionary = {}

signal command_executed(command: String)
signal console_opened
signal console_closed

func _ready() -> void:
	set_state("console_open", false)
	set_state("console_history", [])
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

func execute_command(input: String) -> String:
	var parts = input.split(" ")
	var command = parts[0].to_lower()
	var args = parts.slice(1) if parts.size() > 1 else []

	if command not in commands:
		return "Unknown command: %s" % command

	var history = get_state("console_history", [])
	history.append(input)
	if history.size() > 100:
		history.pop_front()
	set_state("console_history", history)

	var result = commands[command].call(args)
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
