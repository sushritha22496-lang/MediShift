# ChapterManager - Manages game chapter progression
# Handles loading chapters, objectives, progression

extends Node

class_name ChapterManager

# Chapter definitions
enum Chapter { KISHKINDHA = 1, RAMAS_JOURNEY = 2, OCEAN_CROSSING = 3, LANKA_SIEGE = 4 }

# Current state
var current_chapter: Chapter = Chapter.KISHKINDHA
var chapter_complete: bool = false
var objectives: Array = []
var current_objective: int = 0
var story_flags: Dictionary = {}

# Signals
signal chapter_started(chapter: Chapter)
signal chapter_complete(chapter: Chapter)
signal objective_updated(objective: String)
signal story_flag_set(flag: String, value)

func _ready() -> void:
	load_chapter(current_chapter)

# Chapter Management
func load_chapter(chapter: Chapter) -> void:
	"""Load a new chapter"""
	current_chapter = chapter
	chapter_complete = false
	objectives.clear()
	current_objective = 0

	match chapter:
		Chapter.KISHKINDHA:
			_setup_chapter_1()
		Chapter.RAMAS_JOURNEY:
			_setup_chapter_2()
		Chapter.OCEAN_CROSSING:
			_setup_chapter_3()
		Chapter.LANKA_SIEGE:
			_setup_chapter_4()

	emit_signal("chapter_started", chapter)

func _setup_chapter_1() -> void:
	"""Chapter 1: Kishkindha Mountain"""
	objectives = [
		"Defeat the demon guards",
		"Defeat Dundhubi",
		"Escape the mountain"
	]
	_update_objective()

func _setup_chapter_2() -> void:
	"""Chapter 2: Rama's Journey"""
	objectives = [
		"Search for Sita in the forest",
		"Defeat Indrajit",
		"Learn the location of Lanka"
	]
	_update_objective()

func _setup_chapter_3() -> void:
	"""Chapter 3: Ocean Crossing"""
	objectives = [
		"Rally the monkey army",
		"Cross the ocean",
		"Defeat Kumbhakarna",
		"Reach Lanka's shores"
	]
	_update_objective()

func _setup_chapter_4() -> void:
	"""Chapter 4: Lanka Siege (Final)"""
	objectives = [
		"Infiltrate Ravana's palace",
		"Rescue Sita",
		"Defeat Ravana (Phase 1)",
		"Defeat Ravana (Phase 2)",
		"Defeat Ravana (Final Phase)",
		"Escape with Sita"
	]
	_update_objective()

# Objective Management
func _update_objective() -> void:
	"""Update current objective display"""
	if current_objective < objectives.size():
		var obj = objectives[current_objective]
		emit_signal("objective_updated", obj)

func complete_objective() -> void:
	"""Mark current objective complete"""
	current_objective += 1
	if current_objective >= objectives.size():
		complete_chapter()
	else:
		_update_objective()

func complete_chapter() -> void:
	"""Mark chapter complete"""
	chapter_complete = true
	emit_signal("chapter_complete", current_chapter)

	# Advance to next chapter
	if current_chapter < Chapter.LANKA_SIEGE:
		await get_tree().create_timer(2.0).timeout
		load_chapter(current_chapter + 1)
	else:
		# Game complete!
		show_victory_screen()

# Story Flags
func set_story_flag(flag: String, value: bool = true) -> void:
	"""Set a story progression flag"""
	story_flags[flag] = value
	emit_signal("story_flag_set", flag, value)

func get_story_flag(flag: String) -> bool:
	"""Get story flag value"""
	return story_flags.get(flag, false)

# Victory
func show_victory_screen() -> void:
	"""Show game completion screen"""
	print("═" * 60)
	print("🏆 VICTORY! 🏆")
	print("═" * 60)
	print("You have completed the Ramayana!")
	print("Rama and Sita are reunited.")
	print("The world is saved from evil.")
	print("═" * 60)

# Save/Load
func get_chapter_data() -> Dictionary:
	"""Get current chapter data for saving"""
	return {
		"chapter": current_chapter,
		"objective": current_objective,
		"complete": chapter_complete,
		"flags": story_flags
	}

func load_chapter_data(data: Dictionary) -> void:
	"""Load chapter data from save"""
	current_chapter = data.get("chapter", Chapter.KISHKINDHA)
	current_objective = data.get("objective", 0)
	chapter_complete = data.get("complete", false)
	story_flags = data.get("flags", {})
	load_chapter(current_chapter)
