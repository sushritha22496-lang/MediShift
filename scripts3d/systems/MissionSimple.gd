extends TrackableSimple

class_name MissionSimple

signal mission_started(track: Track)
signal mission_progress(track: Track)
signal mission_completed(track: Track)

func _ready() -> void:
	_initialize_missions()

func _initialize_missions() -> void:
	var m1 = start("collect_fruits", "Gather Fruits", 5, "mission")
	m1.rewards = {"gold": 100, "exp": 50}

	var m2 = start("defeat_bandits", "Defeat Bandits", 3, "mission")
	m2.rewards = {"gold": 250, "exp": 150}

	var m3 = start("find_artifact", "Find Artifact", 1, "mission")
	m3.rewards = {"gold": 500, "exp": 300}

func start_mission(mission_id: String) -> Track:
	return get_state(mission_id, null) as Track

func progress_mission(mission_id: String, progress: int = 1) -> void:
	advance(mission_id, progress)

func complete_mission(mission_id: String) -> bool:
	return complete(mission_id)

func get_mission(mission_id: String) -> Track:
	for track in active:
		if track.id == mission_id:
			return track
	for track in completed:
		if track.id == mission_id:
			return track
	return null

func get_active_missions() -> Array[Track]:
	return active

func get_missions_text() -> String:
	var text = "Missions [%d]:\n" % active.size()
	for mission in active:
		text += "%s (%d/%d)\n" % [mission.title, mission.progress, mission.target]
	return text if not active.is_empty() else "Missions: None"
