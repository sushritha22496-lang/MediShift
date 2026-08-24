extends BaseSystemSimple

class_name SceneManagerSimple

class SceneMetadata:
	var name: String
	var difficulty_tier: int = 1
	var is_safe: bool = true
	var load_time: float = 0.5
	var transition_type: String = "fade"
	var prerequisites: Array[String] = []
	var level_requirement: int = 1
	var connected_scenes: Array[String] = []
	var is_locked: bool = false
	var checkpoint_available: bool = false
	func _init(p_name: String) -> void:
		name = p_name

signal scene_changed(scene_name: String)
signal scene_loading(scene_name: String)
signal scene_loaded(scene_name: String)
signal scene_transition_started(scene: String, transition_type: String)
signal scene_transition_finished

var available_scenes: Array[String] = []
var scene_metadata: Dictionary = {}
var scene_stack: Array[String] = []

func _ready() -> void:
	set_state("current_scene", "")
	set_state("previous_scene", "")
	set_state("scene_load_times", {})
	set_state("scene_history", [])
	set_state("bookmarks", [])
	set_state("preloaded_scenes", [])
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
	var main_menu = SceneMetadata.new("MainMenu")
	main_menu.is_safe = true
	main_menu.load_time = 0.3
	var world = SceneMetadata.new("GameWorld")
	world.difficulty_tier = 1
	world.connected_scenes = ["Village", "Forest"]
	world.level_requirement = 1
	var forest = SceneMetadata.new("Forest")
	forest.difficulty_tier = 2
	forest.prerequisites = ["GameWorld"]
	forest.level_requirement = 2
	forest.connected_scenes = ["Temple", "Mountain"]
	var temple = SceneMetadata.new("Temple")
	temple.difficulty_tier = 3
	temple.prerequisites = ["Forest"]
	temple.level_requirement = 5
	temple.checkpoint_available = true
	var mountain = SceneMetadata.new("Mountain")
	mountain.difficulty_tier = 3
	mountain.prerequisites = ["Forest"]
	mountain.level_requirement = 5
	mountain.connected_scenes = ["Cave"]
	var cave = SceneMetadata.new("Cave")
	cave.difficulty_tier = 4
	cave.prerequisites = ["Mountain"]
	cave.level_requirement = 8
	cave.checkpoint_available = true
	var boss = SceneMetadata.new("DungeonBoss")
	boss.difficulty_tier = 5
	boss.prerequisites = ["Cave"]
	boss.level_requirement = 10
	boss.is_safe = false
	scene_metadata = {
		"MainMenu": main_menu, "GameWorld": world, "Forest": forest,
		"Temple": temple, "Mountain": mountain, "Cave": cave, "DungeonBoss": boss
	}

func load_scene(scene_name: String, player_level: int = 1) -> bool:
	if scene_name not in available_scenes:
		return false
	var metadata = scene_metadata.get(scene_name)
	if metadata and metadata.is_locked:
		return false
	if metadata and not _check_prerequisites(scene_name):
		return false
	if metadata and player_level < metadata.level_requirement:
		return false
	var prev = get_state("current_scene", "")
	set_state("previous_scene", prev)
	set_state("current_scene", scene_name)
	scene_stack.append(scene_name)
	if scene_stack.size() > 50:
		scene_stack.remove_at(0)
	var load_start = Time.get_ticks_msec()
	var transition = metadata.transition_type if metadata else "fade"
	scene_transition_started.emit(scene_name, transition)
	scene_loading.emit(scene_name)
	emit_event("scene_loading", {"scene": scene_name, "transition": transition})
	var load_time = metadata.load_time if metadata else 0.5
	await get_tree().create_timer(load_time).timeout
	var load_duration = (Time.get_ticks_msec() - load_start) / 1000.0
	var load_times = get_state("scene_load_times", {})
	load_times[scene_name] = load_duration
	set_state("scene_load_times", load_times)
	var history = get_state("scene_history", [])
	history.append({"scene": scene_name, "timestamp": Time.get_ticks_msec(), "load_time": load_duration})
	if history.size() > 100:
		history.pop_front()
	set_state("scene_history", history)
	scene_loaded.emit(scene_name)
	scene_transition_finished.emit()
	scene_changed.emit(scene_name)
	emit_event("scene_changed", {"scene": scene_name, "load_time": load_duration})
	return true

func _check_prerequisites(scene_name: String) -> bool:
	var metadata = scene_metadata.get(scene_name)
	if not metadata or metadata.prerequisites.is_empty():
		return true
	var history = get_state("scene_history", [])
	var visited_scenes = history.map(func(h): return h["scene"])
	for prereq in metadata.prerequisites:
		if prereq not in visited_scenes:
			return false
	return true

func get_current_scene() -> String:
	return get_state("current_scene", "")

func get_previous_scene() -> String:
	return get_state("previous_scene", "")

func get_scene_stack() -> Array[String]:
	return scene_stack.duplicate()

func get_scene_metadata(scene_name: String) -> SceneMetadata:
	return scene_metadata.get(scene_name)

func is_scene_accessible(scene_name: String, player_level: int = 1) -> bool:
	if scene_name not in available_scenes:
		return false
	var metadata = get_scene_metadata(scene_name)
	if metadata and metadata.is_locked:
		return false
	if metadata and player_level < metadata.level_requirement:
		return false
	if not _check_prerequisites(scene_name):
		return false
	return true

func add_bookmark(scene_name: String) -> bool:
	if scene_name in available_scenes:
		var bookmarks = get_state("bookmarks", [])
		if scene_name not in bookmarks:
			bookmarks.append(scene_name)
		set_state("bookmarks", bookmarks)
		emit_event("bookmark_added", scene_name)
		return true
	return false

func get_bookmarks() -> Array:
	return get_state("bookmarks", [])

func reload_current_scene() -> bool:
	var current = get_current_scene()
	if current != "":
		return await load_scene(current)
	return false

func get_available_scenes() -> Array[String]:
	return available_scenes

func is_scene_available(scene_name: String) -> bool:
	return scene_name in available_scenes

func get_scene_load_times() -> Dictionary:
	return get_state("scene_load_times", {})

func get_scene_history() -> Array:
	return get_state("scene_history", [])

func get_accessible_scenes(player_level: int = 1) -> Array[String]:
	var accessible: Array[String] = []
	for scene in available_scenes:
		if is_scene_accessible(scene, player_level):
			accessible.append(scene)
	return accessible

func get_scene_text() -> String:
	var current = get_current_scene()
	var load_times = get_scene_load_times()
	var load_time = load_times.get(current, 0.0)
	var history_count = get_state("scene_history", []).size()
	var text = "Scene: %s | Load: %.2fs\n" % [current, load_time]
	text += "Stack: %d | History: %d" % [scene_stack.size(), history_count]
	return text
