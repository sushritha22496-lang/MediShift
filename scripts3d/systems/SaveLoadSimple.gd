extends BaseSystemSimple

class_name SaveLoadSimple

signal game_saved(save_slot: int)
signal game_loaded(save_slot: int)
signal save_deleted(save_slot: int)

var save_slots: Dictionary = {}

func _ready() -> void:
	set_state("last_save_time", 0.0)
	set_state("save_count", 0)

func save_game(slot: int, player_data: Dictionary) -> bool:
	var save_data = {
		"slot": slot,
		"timestamp": Time.get_ticks_msec(),
		"player": player_data,
		"game_state": _capture_game_state()
	}
	save_slots[slot] = save_data
	var count = get_state("save_count", 0)
	count += 1
	set_state("save_count", count)
	set_state("last_save_time", Time.get_ticks_msec())
	game_saved.emit(slot)
	emit_event("game_saved", slot)
	return true

func load_game(slot: int) -> Dictionary:
	if slot in save_slots:
		game_loaded.emit(slot)
		emit_event("game_loaded", slot)
		return save_slots[slot]
	return {}

func delete_save(slot: int) -> bool:
	if slot in save_slots:
		save_slots.erase(slot)
		save_deleted.emit(slot)
		emit_event("save_deleted", slot)
		return true
	return false

func has_save(slot: int) -> bool:
	return slot in save_slots

func get_save_list() -> Array:
	var saves = []
	for slot in save_slots.keys():
		saves.append({
			"slot": slot,
			"timestamp": save_slots[slot]["timestamp"],
			"exists": true
		})
	return saves

func get_save_text() -> String:
	var text = "Save Slots\n"
	text += "Total Saves: %d\n" % get_state("save_count", 0)
	for slot in range(1, 4):
		if has_save(slot):
			text += "Slot %d: ✓\n" % slot
		else:
			text += "Slot %d: -\n" % slot
	return text

func _capture_game_state() -> Dictionary:
	return {
		"time": Time.get_ticks_msec(),
		"playtime": 0.0
	}
