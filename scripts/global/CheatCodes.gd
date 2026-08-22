extends Node

# ─── Cheat Code System ────────────────────────────────────────────────────────
# Activate: press ` (backtick) then type the code and press Enter

var _input_buffer: String = ""
var _console_open: bool = false
var _codes_activated: Array[String] = []

const CODES: Dictionary = {
	"VAYUPUTRA":  "infinite_fly",
	"MAHAVEER":   "god_mode",
	"LANKADAHAN": "fire_mode",
	"SANJEEVANI": "full_heal",
	"GADA108":    "mega_gada",
	"AAKAASH":    "all_powers",
	"RAMANAM":    "one_hit",
	"SUGRIVA":    "all_chapters",
	"HANUMAN":    "infinite_health",
	"PUSHPAKA":   "all_levels",
	"VAJRA":      "super_speed",
	"BRAHMASTRA": "invincible_10s"
}

signal cheat_activated(code: String, effect: String)
signal console_toggled(open: bool)

func _ready() -> void:
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cheat_enter"):
		_console_open = !_console_open
		_input_buffer = ""
		console_toggled.emit(_console_open)
		return

	if not _console_open:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			_try_activate(_input_buffer.strip_edges().to_upper())
			_input_buffer = ""
			_console_open = false
			console_toggled.emit(false)
		elif event.keycode == KEY_BACKSPACE:
			if _input_buffer.length() > 0:
				_input_buffer = _input_buffer.left(_input_buffer.length() - 1)
		elif event.unicode > 0:
			_input_buffer += char(event.unicode)

func _try_activate(code: String) -> void:
	if not CODES.has(code):
		return

	var effect: String = CODES[code]
	if _codes_activated.has(code):
		_deactivate(code, effect)
		return

	_codes_activated.append(code)
	_apply_effect(effect, true)
	cheat_activated.emit(code, effect)

func _apply_effect(effect: String, activate: bool) -> void:
	var player = get_tree().get_first_node_in_group("player")
	match effect:
		"god_mode", "invincible_10s", "infinite_health":
			if player:
				player.god_mode = activate
				if effect == "invincible_10s":
					await get_tree().create_timer(10.0).timeout
					player.god_mode = false
					_codes_activated.erase("BRAHMASTRA")
		"infinite_fly":
			if player:
				player.infinite_fly = activate
				GameManager.unlock_power("fly")
		"fire_mode":
			if player:
				player.fire_mode_permanent = activate
				GameManager.unlock_power("tail_fire")
		"full_heal":
			if player:
				player.health = player.max_health
		"mega_gada":
			if player:
				player.gada_damage_multiplier = 5.0 if activate else 1.0
		"all_powers":
			for power in GameManager.powers_unlocked.keys():
				GameManager.unlock_power(power)
		"one_hit":
			if player:
				player.one_hit_kill = activate
		"all_chapters", "all_levels":
			GameManager.cheat_unlock_all_chapters = activate
		"super_speed":
			if player:
				player.speed_multiplier = 3.0 if activate else 1.0

func _deactivate(code: String, effect: String) -> void:
	_codes_activated.erase(code)
	_apply_effect(effect, false)

func is_active(code: String) -> bool:
	return _codes_activated.has(code)

func get_buffer() -> String:
	return _input_buffer

func reset() -> void:
	_codes_activated.clear()
	_input_buffer = ""
	_console_open = false
