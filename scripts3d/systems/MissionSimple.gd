extends TrackableSimple

class_name MissionSimple

signal mission_started(track: Track)
signal mission_progress(track: Track)
signal mission_completed(track: Track)
signal mission_failed(track: Track)

func _ready() -> void:
	track_failed.connect(_on_mission_failed)
	_initialize_missions()

func _initialize_missions() -> void:
	var m1 = start("collect_fruits", "Gather Fruits", 5, "mission", 1)
	m1.rewards = {"gold": 100, "exp": 50}
	m1.time_limit = 300
	m1.optional_objectives = ["collect_ripe_fruits", "collect_quickly"]

	var m2 = start("defeat_bandits", "Defeat Bandits", 3, "mission", 2)
	m2.rewards = {"gold": 250, "exp": 150}
	m2.time_limit = 600
	set_track_milestone("defeat_bandits", 1, {"bonus_gold": 50})
	set_track_milestone("defeat_bandits", 2, {"bonus_gold": 50})

	var m3 = start("find_artifact", "Find Artifact", 1, "mission", 3)
	m3.rewards = {"gold": 500, "exp": 300}
	m3.time_limit = 1200
	m3.optional_objectives = ["find_undamaged", "find_quickly"]

func _on_mission_failed(track: Track) -> void:
	mission_failed.emit(track)
	emit_event("mission_failed", track.id)

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

func complete_optional_objective(mission_id: String, objective_id: String) -> void:
	var mission = get_mission(mission_id)
	if mission and objective_id in mission.optional_objectives:
		mission.optional_progress[objective_id] = true
		emit_event("optional_objective_completed", {"mission": mission_id, "objective": objective_id})

func get_mission_bonus_rewards(mission_id: String) -> Dictionary:
	var mission = get_mission(mission_id)
	var bonus = {}
	if mission and mission.optional_progress.size() > 0:
		for completed_objective in mission.optional_progress:
			if mission.optional_progress[completed_objective]:
				bonus["bonus_exp"] = bonus.get("bonus_exp", 0) + 25
				bonus["bonus_gold"] = bonus.get("bonus_gold", 0) + 50
	return bonus

func get_mission_final_rewards(mission_id: String) -> Dictionary:
	var mission = get_mission(mission_id)
	if not mission:
		return {}
	var rewards = mission.rewards.duplicate()
	var bonuses = get_mission_bonus_rewards(mission_id)
	for bonus_key in bonuses:
		rewards[bonus_key] = rewards.get(bonus_key, 0) + bonuses[bonus_key]
	return rewards

func get_missions_text() -> String:
	var text = "Missions [%d]:\n" % active.size()
	for mission in active:
		var time_left = ""
		if mission.time_limit > 0:
			var elapsed = (Time.get_ticks_msec() - mission.start_time) / 1000
			var remaining = mission.time_limit - elapsed
			if remaining > 0:
				time_left = " [%.0fs]" % remaining
		text += "%s (%d/%d)%s\n" % [mission.title, mission.progress, mission.target, time_left]
	return text if not active.is_empty() else "Missions: None"
