extends Node

class_name SaveManager

const SAVE_PATH = "user://ramayana_save/"

func _ready() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_PATH):
		DirAccess.make_absolute(SAVE_PATH)

func save_game(slot: int = 0) -> bool:
	var save_file = FileAccess.open(SAVE_PATH + "save_%d.dat" % slot, FileAccess.WRITE)
	if save_file == null:
		return false

	var game_manager = GameManager.get_instance()
	var progression = game_manager.progression if game_manager else null

	var data = {
		"chapter": int(progression.current_stage) if progression else 0,
		"hanuman_met": progression.hanuman_met if progression else false,
		"timestamp": Time.get_ticks_msec()
	}

	save_file.store_var(data)
	return true

func load_game(slot: int = 0) -> Dictionary:
	var save_file = FileAccess.open(SAVE_PATH + "save_%d.dat" % slot, FileAccess.READ)
	if save_file == null:
		return {}

	return save_file.get_var()

func has_save(slot: int = 0) -> bool:
	return ResourceLoader.exists(SAVE_PATH + "save_%d.dat" % slot)

func delete_save(slot: int = 0) -> bool:
	var dir = DirAccess.open(SAVE_PATH)
	if dir:
		return dir.remove("save_%d.dat" % slot) == OK
	return false

func get_save_info(slot: int = 0) -> Dictionary:
	if has_save(slot):
		var data = load_game(slot)
		return {"valid": true, "data": data}
	return {"valid": false}
