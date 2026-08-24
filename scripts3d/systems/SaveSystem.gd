extends Node3D

class_name SaveSystem

const SAVE_PATH = "user://ramayana_saves/"
const AUTOSAVE_INTERVAL = 300.0

class SaveData:
	var player_position: Vector3
	var player_health: int
	var player_level: int
	var player_experience: int
	var current_chapter: int
	var current_location: String
	var inventory: Dictionary
	var completed_quests: Array[String]
	var collected_clues: Array[String]
	var playtime: float
	var save_timestamp: String

var current_save_file: String = ""
var autosave_timer: float = 0.0
var autosave_enabled: bool = true

signal save_completed(filename: String)
signal load_completed(save_data: SaveData)
signal autosave_triggered

func _ready() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_PATH):
		DirAccess.make_absolute(SAVE_PATH)

func _process(delta: float) -> void:
	if autosave_enabled:
		autosave_timer += delta
		if autosave_timer >= AUTOSAVE_INTERVAL:
			autosave_timer = 0.0
			_autosave()

func create_save_data(player: Node3D, game_state: GameStateManager, inventory: InventorySystem) -> SaveData:
	var save = SaveData.new()
	save.player_position = player.global_position
	save.player_health = game_state.player_stats.health
	save.player_level = game_state.player_stats.level
	save.player_experience = game_state.player_stats.experience
	save.current_chapter = game_state.current_chapter
	save.current_location = game_state.current_location
	save.inventory = inventory.get_inventory()
	save.completed_quests = game_state.completed_quests.duplicate()
	save.collected_clues = game_state.collected_clues.duplicate()
	save.playtime = game_state.game_time
	save.save_timestamp = Time.get_datetime_string_from_system()
	return save

func save_game(filename: String, save_data: SaveData) -> bool:
	var save_file = SAVE_PATH + filename + ".json"

	var json_string = JSON.stringify({
		"player_position": var_to_str(save_data.player_position),
		"player_health": save_data.player_health,
		"player_level": save_data.player_level,
		"player_experience": save_data.player_experience,
		"current_chapter": save_data.current_chapter,
		"current_location": save_data.current_location,
		"inventory": save_data.inventory,
		"completed_quests": save_data.completed_quests,
		"collected_clues": save_data.collected_clues,
		"playtime": save_data.playtime,
		"save_timestamp": save_data.save_timestamp
	})

	var file = FileAccess.open(save_file, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(json_string)
	current_save_file = filename
	save_completed.emit(filename)
	return true

func load_game(filename: String) -> SaveData:
	var save_file = SAVE_PATH + filename + ".json"

	var file = FileAccess.open(save_file, FileAccess.READ)
	if file == null:
		return null

	var json_string = file.get_as_text()
	var json = JSON.new()
	json.parse(json_string)

	var data = json.get_data()

	var save = SaveData.new()
	save.player_position = str_to_var(data["player_position"])
	save.player_health = data["player_health"]
	save.player_level = data["player_level"]
	save.player_experience = data["player_experience"]
	save.current_chapter = data["current_chapter"]
	save.current_location = data["current_location"]
	save.inventory = data["inventory"]
	save.completed_quests = data["completed_quests"]
	save.collected_clues = data["collected_clues"]
	save.playtime = data["playtime"]
	save.save_timestamp = data["save_timestamp"]

	current_save_file = filename
	load_completed.emit(save)
	return save

func _autosave() -> void:
	save_game("autosave", SaveData.new())
	autosave_triggered.emit()

func get_save_files() -> Array:
	var files = []
	var dir = DirAccess.open(SAVE_PATH)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".json"):
				files.append(file_name.trim_suffix(".json"))
			file_name = dir.get_next()

	return files

func delete_save(filename: String) -> bool:
	var save_file = SAVE_PATH + filename + ".json"
	return DirAccess.remove_absolute(save_file) == OK
