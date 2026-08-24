extends Node

class_name SaveLoadSimple

const SAVE_PATH = "user://ramayana_save/"
const SAVE_FILE = "save_game.json"

signal save_complete
signal load_complete

func _ready() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_PATH):
		DirAccess.make_absolute(SAVE_PATH)

func save_game(player: Node3D, game_state: GameStateSimple, quest_system: QuestSimple) -> bool:
	var save_data = {
		"player_position": _vector3_to_array(player.global_position),
		"player_health": game_state.current_health,
		"player_stamina": game_state.current_stamina,
		"player_mana": game_state.current_mana,
		"level": game_state.level,
		"experience": game_state.experience,
		"gold": game_state.gold,
		"active_quests": [],
		"completed_quests": [],
		"save_time": Time.get_ticks_msec()
	}

	for quest in quest_system.get_active_quests():
		save_data["active_quests"].append({
			"id": quest.id,
			"title": quest.title,
			"completed": quest.completed
		})

	for quest in quest_system.get_completed_quests():
		save_data["completed_quests"].append({
			"id": quest.id,
			"title": quest.title
		})

	var json_string = JSON.stringify(save_data)
	var file = FileAccess.open(SAVE_PATH + SAVE_FILE, FileAccess.WRITE)
	if file == null:
		print("Error saving game")
		return false

	file.store_string(json_string)
	save_complete.emit()
	print("Game saved successfully")
	return true

func load_game() -> Dictionary:
	if not ResourceLoader.exists(SAVE_PATH + SAVE_FILE):
		print("No save file found")
		return {}

	var file = FileAccess.open(SAVE_PATH + SAVE_FILE, FileAccess.READ)
	if file == null:
		print("Error loading game")
		return {}

	var json_string = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		print("Error parsing save file")
		return {}

	load_complete.emit()
	print("Game loaded successfully")
	return json.data

func _vector3_to_array(vec: Vector3) -> Array:
	return [vec.x, vec.y, vec.z]

func _array_to_vector3(arr: Array) -> Vector3:
	return Vector3(arr[0], arr[1], arr[2])

func has_save() -> bool:
	return ResourceLoader.exists(SAVE_PATH + SAVE_FILE)

func delete_save() -> bool:
	if ResourceLoader.exists(SAVE_PATH + SAVE_FILE):
		var dir = DirAccess.open(SAVE_PATH)
		if dir:
			dir.remove(SAVE_FILE)
			return true
	return false
