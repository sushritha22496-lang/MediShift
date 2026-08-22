extends Node

const SAVE_PATH := "user://hanuman_save.dat"
const SAVE_VERSION := 1

func save_game() -> void:
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"chapter": GameManager.current_chapter,
		"score": GameManager.score,
		"enemies_defeated": GameManager.enemies_defeated,
		"bosses_defeated": GameManager.bosses_defeated,
		"powers": GameManager.powers_unlocked.duplicate(),
		"flags": GameManager.story_flags.duplicate()
	}
	var player = get_tree().get_first_node_in_group("player")
	if player:
		data["player_health"] = player.health
		data["player_max_health"] = player.max_health
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var data = file.get_var()
	file.close()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if data.get("version", 0) != SAVE_VERSION:
		return false
	GameManager.current_chapter = data.get("chapter", GameManager.Chapter.KISHKINDHA)
	GameManager.score = data.get("score", 0)
	GameManager.enemies_defeated = data.get("enemies_defeated", 0)
	GameManager.bosses_defeated = data.get("bosses_defeated", [])
	if data.has("powers"):
		for key in data["powers"]:
			GameManager.powers_unlocked[key] = data["powers"][key]
	if data.has("flags"):
		for key in data["flags"]:
			GameManager.story_flags[key] = data["flags"][key]
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
