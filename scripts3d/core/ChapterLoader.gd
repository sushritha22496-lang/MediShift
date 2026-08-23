extends Node

class_name ChapterLoader

const CHAPTER_SCENES = {
	1: "res://scenes3d/chapters/ch1_kishkindha_3d.tscn",
	2: "res://scenes3d/chapters/ch2_ramas_journey_3d.tscn",
	3: "res://scenes3d/chapters/ch3_ocean_crossing_3d.tscn",
	4: "res://scenes3d/chapters/ch4_lanka_siege_3d.tscn",
}

var current_chapter: int = 1
var completed_chapters: Array[int] = []

func _ready() -> void:
	pass

func load_chapter(chapter_number: int) -> bool:
	"""Load a specific chapter scene"""
	if chapter_number not in CHAPTER_SCENES:
		push_error("Chapter %d not found" % chapter_number)
		return false

	var scene_path = CHAPTER_SCENES[chapter_number]
	if not ResourceLoader.exists(scene_path):
		push_error("Chapter scene not found: %s" % scene_path)
		return false

	current_chapter = chapter_number
	print("📖 Loading Chapter %d: %s" % [chapter_number, scene_path])
	get_tree().change_scene_to_file(scene_path)
	return true

func next_chapter() -> bool:
	"""Progress to the next chapter"""
	var next_chapter = current_chapter + 1
	if next_chapter > 4:
		_show_game_complete()
		return false
	return load_chapter(next_chapter)

func mark_chapter_complete(chapter_number: int) -> void:
	"""Mark a chapter as completed"""
	if chapter_number not in completed_chapters:
		completed_chapters.append(chapter_number)
		print("✅ Chapter %d completed" % chapter_number)

func get_chapter_progress() -> float:
	"""Get game progress as percentage"""
	return (float(completed_chapters.size()) / 4.0) * 100.0

func is_chapter_completed(chapter_number: int) -> bool:
	"""Check if a chapter is completed"""
	return chapter_number in completed_chapters

func _show_game_complete() -> void:
	"""Show game completion message"""
	print("\n" + "="*60)
	print("🏆 CONGRATULATIONS! 🏆")
	print("="*60)
	print("You have completed the entire Ramayana game!")
	print("Rama and Sita are reunited.")
	print("The world is saved from evil.")
	print("="*60 + "\n")
