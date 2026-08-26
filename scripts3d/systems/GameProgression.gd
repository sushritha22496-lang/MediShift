extends Node

class_name GameProgression

enum Stage {
	MEET_HANUMAN,
	GATHER_MONKEYS,
	TRAVEL_TO_COAST,
	CROSS_OCEAN,
	BATTLE_RAVANA,
	RESCUE_SITA,
	COMPLETE
}

var current_stage: Stage = Stage.MEET_HANUMAN
var hanuman_met: bool = false
var monkeys_gathered: int = 0
var sita_found: bool = false

signal stage_changed(new_stage: Stage)
signal progress_updated

func advance_stage() -> void:
	match current_stage:
		Stage.MEET_HANUMAN:
			if hanuman_met:
				current_stage = Stage.GATHER_MONKEYS
		Stage.GATHER_MONKEYS:
			if monkeys_gathered >= 3:
				current_stage = Stage.TRAVEL_TO_COAST
		Stage.TRAVEL_TO_COAST:
			current_stage = Stage.CROSS_OCEAN
		Stage.CROSS_OCEAN:
			current_stage = Stage.BATTLE_RAVANA
		Stage.BATTLE_RAVANA:
			current_stage = Stage.RESCUE_SITA
		Stage.RESCUE_SITA:
			if sita_found:
				current_stage = Stage.COMPLETE
	stage_changed.emit(current_stage)
	progress_updated.emit()

func get_stage_name() -> String:
	match current_stage:
		Stage.MEET_HANUMAN: return "Meeting Hanuman"
		Stage.GATHER_MONKEYS: return "Gathering Allies"
		Stage.TRAVEL_TO_COAST: return "Journey Begins"
		Stage.CROSS_OCEAN: return "Ocean Crossing"
		Stage.BATTLE_RAVANA: return "Final Battle"
		Stage.RESCUE_SITA: return "Rescue Sita"
		Stage.COMPLETE: return "Victory!"
	return "Unknown"

func get_progress_percent() -> int:
	return (int(current_stage) * 100) / int(Stage.COMPLETE)
