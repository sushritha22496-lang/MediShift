extends BaseSystemSimple

class_name SaveLoadSimple

class SaveFile:
	var slot: int
	var timestamp: float
	var player_data: Dictionary
	var game_state: Dictionary
	var metadata: Dictionary
	var version: int = 1
	var playtime: float = 0.0
	var character_name: String = ""
	var level: int = 1
	var location: String = ""
	var is_autosave: bool = false
	var backup_slot: int = -1
	var checksum: String = ""
	var save_size: int = 0
	func _init(p_slot: int) -> void:
		slot = p_slot
		timestamp = Time.get_ticks_msec()

signal game_saved(save_slot: int)
signal game_loaded(save_slot: int)
signal save_deleted(save_slot: int)
signal autosave_created(save_slot: int)
signal save_corrupted(save_slot: int)

var save_slots: Dictionary = {}
var autosave_slot: int = -1
var max_slots: int = 10
var max_backups_per_slot: int = 3

func _ready() -> void:
	set_state("last_save_time", 0.0)
	set_state("save_count", 0)
	set_state("autosave_enabled", true)
	set_state("save_backups", {})
	set_state("corrupted_saves", [])
	set_state("total_playtime_saved", 0.0)

func save_game(slot: int, player_data: Dictionary, metadata: Dictionary = {}) -> bool:
	if slot > max_slots:
		return false
	_create_backup(slot)
	var save_file = SaveFile.new(slot)
	save_file.player_data = player_data
	save_file.game_state = _capture_game_state()
	save_file.metadata = metadata
	save_file.character_name = metadata.get("character_name", "Unknown")
	save_file.level = metadata.get("level", 1)
	save_file.location = metadata.get("location", "")
	save_file.playtime = metadata.get("playtime", 0.0)
	save_file.checksum = _calculate_checksum(save_file)
	save_file.save_size = _estimate_save_size(save_file)
	save_slots[slot] = save_file
	var count = get_state("save_count", 0) + 1
	set_state("save_count", count)
	set_state("last_save_time", Time.get_ticks_msec())
	game_saved.emit(slot)
	emit_event("game_saved", {"slot": slot, "size": save_file.save_size})
	return true

func create_autosave(player_data: Dictionary, metadata: Dictionary = {}) -> bool:
	if not get_state("autosave_enabled", true):
		return false
	autosave_slot = (autosave_slot + 1) % 3
	metadata["is_autosave"] = true
	var result = save_game(max_slots + autosave_slot, player_data, metadata)
	if result:
		autosave_created.emit(max_slots + autosave_slot)
		emit_event("autosave_created", max_slots + autosave_slot)
	return result

func _create_backup(slot: int) -> void:
	if slot in save_slots:
		var backups = get_state("save_backups", {})
		if not slot in backups:
			backups[slot] = []
		var slot_backups = backups[slot]
		slot_backups.append({"slot": slot, "data": save_slots[slot], "timestamp": Time.get_ticks_msec()})
		if slot_backups.size() > max_backups_per_slot:
			slot_backups.remove_at(0)
		set_state("save_backups", backups)

func load_game(slot: int) -> Dictionary:
	if slot in save_slots:
		var save_file = save_slots[slot]
		if _verify_checksum(save_file):
			game_loaded.emit(slot)
			emit_event("game_loaded", {"slot": slot, "character": save_file.character_name, "level": save_file.level})
			return {"player": save_file.player_data, "game_state": save_file.game_state, "metadata": save_file.metadata}
		else:
			_mark_save_corrupted(slot)
			save_corrupted.emit(slot)
			return {}
	return {}

func delete_save(slot: int) -> bool:
	if slot in save_slots:
		save_slots.erase(slot)
		var backups = get_state("save_backups", {})
		if slot in backups:
			backups.erase(slot)
			set_state("save_backups", backups)
		save_deleted.emit(slot)
		emit_event("save_deleted", slot)
		return true
	return false

func restore_backup(slot: int, backup_index: int) -> bool:
	var backups = get_state("save_backups", {})
	if slot in backups and backup_index < backups[slot].size():
		var backup = backups[slot][backup_index]
		save_slots[slot] = backup["data"]
		emit_event("backup_restored", {"slot": slot, "index": backup_index})
		return true
	return false

func has_save(slot: int) -> bool:
	return slot in save_slots

func get_save_list() -> Array:
	var saves = []
	for slot in save_slots.keys():
		var save_file = save_slots[slot]
		saves.append({
			"slot": slot,
			"timestamp": save_file.timestamp,
			"character": save_file.character_name,
			"level": save_file.level,
			"location": save_file.location,
			"playtime": save_file.playtime,
			"exists": true,
			"size": save_file.save_size
		})
	return saves

func get_backups(slot: int) -> Array:
	var backups = get_state("save_backups", {})
	return backups.get(slot, [])

func get_corrupted_saves() -> Array:
	return get_state("corrupted_saves", [])

func _mark_save_corrupted(slot: int) -> void:
	var corrupted = get_state("corrupted_saves", [])
	if slot not in corrupted:
		corrupted.append(slot)
	set_state("corrupted_saves", corrupted)

func _calculate_checksum(save_file: SaveFile) -> String:
	var data_str = str(save_file.player_data) + str(save_file.game_state)
	return "%X" % hash(data_str)

func _verify_checksum(save_file: SaveFile) -> bool:
	if save_file.checksum.is_empty():
		return true
	var calculated = _calculate_checksum(save_file)
	return calculated == save_file.checksum

func _estimate_save_size(save_file: SaveFile) -> int:
	return (str(save_file.player_data).length() + str(save_file.game_state).length()) / 1024

func enable_autosave(enabled: bool) -> void:
	set_state("autosave_enabled", enabled)
	emit_event("autosave_toggled", enabled)

func _capture_game_state() -> Dictionary:
	return {
		"time": Time.get_ticks_msec(),
		"playtime": 0.0,
		"session_start": Time.get_ticks_msec()
	}

func get_save_text() -> String:
	var text = "Save Slots [%d/%d]\n" % [get_state("save_count", 0), max_slots]
	var saves = get_save_list()
	for save_info in saves.slice(0, 5):
		text += "Slot %d: %s [Lvl %d]\n" % [save_info["slot"], save_info["character"], save_info["level"]]
	return text
