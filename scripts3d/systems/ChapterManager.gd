extends Node3D

class_name ChapterManager

enum Chapter { CH1_MEETING, CH2_GATHERING, CH3_JOURNEY, CH4_BATTLE }

var current_chapter: Chapter = Chapter.CH1_MEETING
var rama: RamaController
var hanuman: HanumanAI
var forest_manager: ForestManager

signal chapter_changed(chapter: Chapter)
signal chapter_completed(chapter: Chapter)

func _ready() -> void:
	rama = get_node_or_null("Characters/Rama")
	hanuman = get_node_or_null("Characters/Hanuman")
	forest_manager = get_parent()

func on_chapter_1_complete() -> void:
	if current_chapter == Chapter.CH1_MEETING:
		current_chapter = Chapter.CH2_GATHERING
		chapter_completed.emit(Chapter.CH1_MEETING)
		chapter_changed.emit(Chapter.CH2_GATHERING)

func get_chapter_title() -> String:
	match current_chapter:
		Chapter.CH1_MEETING: return "Meeting Hanuman"
		Chapter.CH2_GATHERING: return "Gathering Allies"
		Chapter.CH3_JOURNEY: return "Journey to Lanka"
		Chapter.CH4_BATTLE: return "Battle for Sita"
	return ""

func get_chapter_description() -> String:
	match current_chapter:
		Chapter.CH1_MEETING: return "Find and convince Hanuman to help search for Sita"
		Chapter.CH2_GATHERING: return "Gather monkey warriors for the quest"
		Chapter.CH3_JOURNEY: return "Travel across forests and beaches toward Lanka"
		Chapter.CH4_BATTLE: return "Face Ravana's forces and rescue Sita"
	return ""
