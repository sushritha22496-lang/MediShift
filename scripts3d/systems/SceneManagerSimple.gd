extends BaseSystemSimple

class_name SceneManagerSimple

signal scene_changed(scene_name: String)
signal scene_loading(scene_name: String)
signal scene_loaded(scene_name: String)

var available_scenes: Array[String] = []

func _ready() -> void:
	set_state("current_scene", "")
	set_state("previous_scene", "")
	_initialize_scenes()

func _initialize_scenes() -> void:
	available_scenes = [
		"MainMenu",
		"GameWorld",
		"Village",
		"Forest",
		"Temple",
		"Mountain",
		"Cave",
		"DungeonBoss",
		"EndGame",
		"Cutscene",
		"DialogueScene",
		"CombatArena"
	]

func load_scene(scene_name: String) -> bool:
	if scene_name not in available_scenes:
		return false
	
	var prev = get_state("current_scene", "")
	set_state("previous_scene", prev)
	set_state("current_scene", scene_name)
	
	scene_loading.emit(scene_name)
	emit_event("scene_loading", scene_name)
	
	await get_tree().create_timer(0.5).timeout
	scene_loaded.emit(scene_name)
	scene_changed.emit(scene_name)
	emit_event("scene_changed", scene_name)
	return true

func get_current_scene() -> String:
	return get_state("current_scene", "")

func get_previous_scene() -> String:
	return get_state("previous_scene", "")

func reload_current_scene() -> bool:
	var current = get_current_scene()
	if current != "":
		return await load_scene(current)
	return false

func get_available_scenes() -> Array[String]:
	return available_scenes

func is_scene_available(scene_name: String) -> bool:
	return scene_name in available_scenes

func get_scene_text() -> String:
	var current = get_current_scene()
	var prev = get_previous_scene()
	return "Current Scene: %s\nPrevious Scene: %s\nAvailable: %d" % [current, prev, available_scenes.size()]
