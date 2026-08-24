extends BaseSystemSimple

class_name GameFlowSimple

enum GameState { MENU, PLAYING, PAUSED, LOADING, CUTSCENE, GAME_OVER, VICTORY }

signal state_changed(new_state: GameState)
signal game_started
signal game_ended(victory: bool)
signal checkpoint_reached(checkpoint_id: String)
signal difficulty_changed(new_difficulty: int)
signal run_completed(run_id: String, time: float)
signal speedrun_achieved(run_id: String, time: float)

var current_state: GameState = GameState.MENU
var pause_reason: String = ""

func _ready() -> void:
	set_state("game_state", GameState.MENU)
	set_state("game_time", 0.0)
	set_state("session_active", false)
	set_state("death_count", 0)
	set_state("death_reasons", [])
	set_state("checkpoints", [])
	set_state("current_checkpoint", "")
	set_state("difficulty", 1)
	set_state("session_start_time", Time.get_ticks_msec())
	set_state("session_stats", {})
	set_state("pause_count", 0)
	set_state("last_pause_time", 0)
	set_state("tutorial_progress", 0.0)
	set_state("victory_conditions_met", {})
	set_state("milestones_reached", [])
	set_state("run_history", [])
	set_state("best_times", {})
	set_state("victory_count", 0)

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		var time = get_state("game_time", 0.0)
		time += delta
		set_state("game_time", time)

func change_state(new_state: GameState, reason: String = "") -> void:
	if current_state != new_state:
		current_state = new_state
		set_state("game_state", new_state)
		state_changed.emit(new_state)
		emit_event("state_changed", GameState.keys()[new_state])

		match new_state:
			GameState.PLAYING:
				set_state("session_start_time", Time.get_ticks_msec())
				game_started.emit()
				emit_event("game_started", "")
			GameState.PAUSED:
				pause_reason = reason
				var pause_count = get_state("pause_count", 0) + 1
				set_state("pause_count", pause_count)
				set_state("last_pause_time", Time.get_ticks_msec())
				emit_event("paused", reason)
			GameState.GAME_OVER:
				_record_death(reason)
				game_ended.emit(false)
				emit_event("game_ended", "game_over")
			GameState.VICTORY:
				game_ended.emit(true)
				set_state("session_active", false)
				emit_event("game_ended", "victory")
			GameState.CUTSCENE:
				emit_event("cutscene_started", "")

func start_game() -> void:
	change_state(GameState.PLAYING, "")
	set_state("session_active", true)

func end_game(victory: bool) -> void:
	var reason = "victory" if victory else "defeat"
	change_state(GameState.VICTORY if victory else GameState.GAME_OVER, reason)
	set_state("session_active", false)

func pause_game(reason: String = "user") -> void:
	change_state(GameState.PAUSED, reason)

func resume_game() -> void:
	change_state(GameState.PLAYING, "")

func _record_death(reason: String) -> void:
	var death_count = get_state("death_count", 0) + 1
	set_state("death_count", death_count)
	var death_reasons = get_state("death_reasons", [])
	death_reasons.append({"reason": reason, "time": get_game_time()})
	set_state("death_reasons", death_reasons)
	emit_event("death_recorded", reason)

func register_checkpoint(checkpoint_id: String) -> void:
	var checkpoints = get_state("checkpoints", [])
	if checkpoint_id not in checkpoints:
		checkpoints.append(checkpoint_id)
	set_state("checkpoints", checkpoints)
	set_state("current_checkpoint", checkpoint_id)
	checkpoint_reached.emit(checkpoint_id)
	emit_event("checkpoint_reached", checkpoint_id)

func set_difficulty(difficulty: int) -> void:
	set_state("difficulty", difficulty)
	difficulty_changed.emit(difficulty)
	emit_event("difficulty_changed", difficulty)

func reach_milestone(milestone_id: String) -> void:
	var milestones = get_state("milestones_reached", [])
	if milestone_id not in milestones:
		milestones.append(milestone_id)
		set_state("milestones_reached", milestones)
		emit_event("milestone_reached", milestone_id)

func get_current_state() -> GameState:
	return current_state

func get_game_time() -> float:
	return get_state("game_time", 0.0)

func is_playing() -> bool:
	return current_state == GameState.PLAYING

func get_session_length() -> float:
	var start_time = get_state("session_start_time", 0)
	return (Time.get_ticks_msec() - start_time) / 1000.0

func get_death_count() -> int:
	return get_state("death_count", 0)

func get_difficulty() -> int:
	return get_state("difficulty", 1)

func get_pause_count() -> int:
	return get_state("pause_count", 0)

func get_checkpoints_reached() -> Array:
	return get_state("checkpoints", [])

func get_milestones() -> Array:
	return get_state("milestones_reached", [])

func get_state_text() -> String:
	var deaths = get_death_count()
	var difficulty = get_difficulty()
	return "State: %s | Time: %.1fs | Deaths: %d | Difficulty: %d" % [GameState.keys()[current_state], get_game_time(), deaths, difficulty]

func record_run_completion(run_id: String) -> void:
	var run_time = get_game_time()
	var history = get_state("run_history", [])
	history.append({"run_id": run_id, "time": run_time, "deaths": get_death_count(), "difficulty": get_difficulty(), "timestamp": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("run_history", history)
	var best_times = get_state("best_times", {})
	if run_id not in best_times or run_time < best_times[run_id]:
		best_times[run_id] = run_time
		set_state("best_times", best_times)
		if run_time < 300.0:
			speedrun_achieved.emit(run_id, run_time)
			emit_event("speedrun", {"run": run_id, "time": run_time})
	run_completed.emit(run_id, run_time)
	emit_event("run_completed", run_id)

func get_best_time(run_id: String) -> float:
	var best_times = get_state("best_times", {})
	return best_times.get(run_id, INF)

func get_run_history() -> Array:
	return get_state("run_history", [])

func increment_victory_count() -> void:
	var count = get_state("victory_count", 0)
	set_state("victory_count", count + 1)
	emit_event("victory_recorded", count + 1)

func get_victory_count() -> int:
	return get_state("victory_count", 0)
