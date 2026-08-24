extends BaseSystemSimple

class_name GameFlowSimple

enum GameState { MENU, PLAYING, PAUSED, LOADING, CUTSCENE, GAME_OVER, VICTORY }

signal state_changed(new_state: GameState)
signal game_started
signal game_ended(victory: bool)

var current_state: GameState = GameState.MENU

func _ready() -> void:
	set_state("game_state", GameState.MENU)
	set_state("game_time", 0.0)
	set_state("session_active", false)

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		var time = get_state("game_time", 0.0)
		time += delta
		set_state("game_time", time)

func change_state(new_state: GameState) -> void:
	if current_state != new_state:
		current_state = new_state
		set_state("game_state", new_state)
		state_changed.emit(new_state)
		emit_event("state_changed", GameState.keys()[new_state])
		
		match new_state:
			GameState.PLAYING:
				game_started.emit()
				emit_event("game_started", "")
			GameState.GAME_OVER, GameState.VICTORY:
				game_ended.emit(new_state == GameState.VICTORY)
				emit_event("game_ended", GameState.keys()[new_state])

func start_game() -> void:
	change_state(GameState.PLAYING)
	set_state("session_active", true)

func end_game(victory: bool) -> void:
	change_state(GameState.VICTORY if victory else GameState.GAME_OVER)
	set_state("session_active", false)

func get_current_state() -> GameState:
	return current_state

func get_game_time() -> float:
	return get_state("game_time", 0.0)

func is_playing() -> bool:
	return current_state == GameState.PLAYING

func get_state_text() -> String:
	return "State: %s | Time: %.1fs" % [GameState.keys()[current_state], get_game_time()]
