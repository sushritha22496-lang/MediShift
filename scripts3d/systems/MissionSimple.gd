extends Node

class_name MissionSimple

class Mission:
	var id: String
	var title: String
	var description: String
	var target: String
	var target_count: int = 1
	var current_count: int = 0
	var reward_gold: float = 0.0
	var reward_exp: float = 0.0
	var completed: bool = false
	var difficulty: String = "Normal"

	func _init(p_id: String, p_title: String, p_desc: String, p_target: String) -> void:
		id = p_id
		title = p_title
		description = p_desc
		target = p_target

var missions: Array[Mission] = []
var active_missions: Array[Mission] = []
var completed_missions: Array[Mission] = []

signal mission_started(mission: Mission)
signal mission_progress(mission: Mission)
signal mission_completed(mission: Mission)

func _ready() -> void:
	_initialize_missions()

func _initialize_missions() -> void:
	var m1 = Mission.new("collect_fruits", "Gather Fruits", "Collect mangoes for the village", "Mango")
	m1.target_count = 5
	m1.reward_gold = 100
	m1.reward_exp = 50

	var m2 = Mission.new("defeat_bandits", "Defeat Bandits", "Eliminate bandits terrorizing the area", "Bandit")
	m2.target_count = 3
	m2.reward_gold = 250
	m2.reward_exp = 150
	m2.difficulty = "Hard"

	var m3 = Mission.new("find_artifact", "Find Artifact", "Search for the ancient artifact", "Artifact")
	m3.target_count = 1
	m3.reward_gold = 500
	m3.reward_exp = 300
	m3.difficulty = "Very Hard"

	missions = [m1, m2, m3]

func start_mission(mission_id: String) -> bool:
	for mission in missions:
		if mission.id == mission_id and not mission in active_missions:
			active_missions.append(mission)
			mission_started.emit(mission)
			print("📋 Mission started: %s" % mission.title)
			return true
	return false

func progress_mission(mission_id: String, progress: int = 1) -> void:
	for mission in active_missions:
		if mission.id == mission_id:
			mission.current_count = minf(mission.current_count + progress, mission.target_count)
			mission_progress.emit(mission)

			if mission.current_count >= mission.target_count:
				complete_mission(mission_id)

func complete_mission(mission_id: String) -> bool:
	for i in range(active_missions.size()):
		if active_missions[i].id == mission_id:
			var mission = active_missions[i]
			mission.completed = true
			completed_missions.append(mission)
			active_missions.remove_at(i)
			mission_completed.emit(mission)
			print("✓ Mission completed: %s" % mission.title)
			return true
	return false

func get_mission(mission_id: String) -> Mission:
	for mission in missions:
		if mission.id == mission_id:
			return mission
	return null

func get_active_missions() -> Array[Mission]:
	return active_missions

func get_missions_text() -> String:
	var text = "Missions [%d]:\n" % active_missions.size()
	for mission in active_missions:
		text += "%s (%d/%d)\n" % [mission.title, mission.current_count, mission.target_count]
	if active_missions.is_empty():
		text = "Missions: None"
	return text
