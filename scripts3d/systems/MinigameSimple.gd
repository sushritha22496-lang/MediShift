extends BaseSystemSimple

class_name MinigameSimple

class Minigame:
	var id: String
	var name: String
	var game_type: String
	var difficulty: int
	var reward: float
	var play_count: int
	func _init(p_id: String, p_name: String, p_type: String, p_diff: int, p_reward: float) -> void:
		id = p_id
		name = p_name
		game_type = p_type
		difficulty = p_diff
		reward = p_reward
		play_count = 0

var minigames: Array[Minigame] = []

signal game_started(game_id: String)
signal game_won(game_id: String, reward: float)
signal game_lost(game_id: String)

func _ready() -> void:
	set_state("games_played", {})
	set_state("total_winnings", 0.0)
	set_state("game_play_history", [])
	set_state("win_loss_ratio", {})
	set_state("game_performance", [])
	set_state("difficulty_progression", [])
	set_state("win_streak", 0)
	set_state("loss_streak", 0)
	set_state("rewards_history", [])
	set_state("minigame_statistics", {})
	_initialize_minigames()

func _initialize_minigames() -> void:
	minigames = [
		Minigame.new("dice_easy", "Dice Game - Easy", "dice", 1, 10.0),
		Minigame.new("dice_hard", "Dice Game - Hard", "dice", 3, 50.0),
		Minigame.new("cards_easy", "Card Game - Easy", "cards", 1, 15.0),
		Minigame.new("cards_hard", "Card Game - Hard", "cards", 3, 75.0),
		Minigame.new("riddle_easy", "Riddle - Easy", "riddle", 1, 20.0),
		Minigame.new("riddle_hard", "Riddle - Hard", "riddle", 3, 100.0)
	]

func play_game(game_id: String) -> bool:
	var game = _get_game(game_id)
	if not game:
		return false
	game.play_count += 1
	_record_play_history(game_id)
	game_started.emit(game_id)
	emit_event("game_started", game_id)
	return true

func win_game(game_id: String) -> float:
	var game = _get_game(game_id)
	if not game:
		return 0.0
	var reward = game.reward * (1.0 + (game.difficulty * 0.25))
	var total = get_state("total_winnings", 0.0)
	total += reward
	set_state("total_winnings", total)
	var games_played = get_state("games_played", {})
	games_played[game_id] = games_played.get(game_id, 0) + 1
	set_state("games_played", games_played)
	_record_win_loss(game_id, true)
	_update_win_streak()
	_record_rewards(game_id, reward)
	game_won.emit(game_id, reward)
	emit_event("game_won", game_id)
	return reward

func lose_game(game_id: String) -> void:
	var game = _get_game(game_id)
	if game:
		_record_win_loss(game_id, false)
		_update_loss_streak()
		game_lost.emit(game_id)
		emit_event("game_lost", game_id)

func get_game(game_id: String) -> Minigame:
	return _get_game(game_id)

func get_games_by_type(game_type: String) -> Array[Minigame]:
	return minigames.filter(func(g): return g.game_type == game_type)

func get_games_by_difficulty(difficulty: int) -> Array[Minigame]:
	return minigames.filter(func(g): return g.difficulty == difficulty)

func get_play_stats(game_id: String) -> int:
	var games_played = get_state("games_played", {})
	return games_played.get(game_id, 0)

func get_total_winnings() -> float:
	return get_state("total_winnings", 0.0)

func get_game_text() -> String:
	var text = "Minigames:\n"
	for game in minigames:
		var plays = get_play_stats(game.id)
		text += "%s (Plays: %d) - Reward: %.0f\n" % [game.name, plays, game.reward]
	return text

func get_all_games() -> Array[Minigame]:
	return minigames

func _get_game(game_id: String) -> Minigame:
	for game in minigames:
		if game.id == game_id:
			return game
	return null

func _record_play_history(game_id: String) -> void:
	var history = get_state("game_play_history", [])
	history.append({"game": game_id, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("game_play_history", history)

func _record_win_loss(game_id: String, won: bool) -> void:
	var ratio = get_state("win_loss_ratio", {})
	if game_id not in ratio:
		ratio[game_id] = {"wins": 0, "losses": 0}
	if won:
		ratio[game_id]["wins"] += 1
	else:
		ratio[game_id]["losses"] += 1
	set_state("win_loss_ratio", ratio)
	var perf = get_state("game_performance", [])
	perf.append({"game": game_id, "result": "win" if won else "loss", "time": Time.get_ticks_msec()})
	if perf.size() > 50:
		perf.pop_front()
	set_state("game_performance", perf)

func _update_win_streak() -> void:
	var streak = get_state("win_streak", 0) + 1
	set_state("win_streak", streak)
	set_state("loss_streak", 0)

func _update_loss_streak() -> void:
	var streak = get_state("loss_streak", 0) + 1
	set_state("loss_streak", streak)
	set_state("win_streak", 0)

func _record_rewards(game_id: String, amount: float) -> void:
	var history = get_state("rewards_history", [])
	history.append({"game": game_id, "reward": amount, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("rewards_history", history)

func get_game_win_rate(game_id: String) -> float:
	var ratio = get_state("win_loss_ratio", {})
	if game_id not in ratio:
		return 0.0
	var data = ratio[game_id]
	var total = data["wins"] + data["losses"]
	return float(data["wins"]) / float(total) if total > 0 else 0.0

func get_current_win_streak() -> int:
	return get_state("win_streak", 0)

func get_current_loss_streak() -> int:
	return get_state("loss_streak", 0)

func record_difficulty_progression(game_id: String, difficulty: int) -> void:
	var progression = get_state("difficulty_progression", [])
	progression.append({"game": game_id, "difficulty": difficulty, "time": Time.get_ticks_msec()})
	if progression.size() > 50:
		progression.pop_front()
	set_state("difficulty_progression", progression)

func get_play_history() -> Array:
	return get_state("game_play_history", [])

func get_rewards_history() -> Array:
	return get_state("rewards_history", [])

func update_minigame_statistics() -> void:
	var stats = get_state("minigame_statistics", {})
	stats["total_plays"] = get_state("game_play_history", []).size()
	stats["total_winnings"] = get_total_winnings()
	stats["win_streak"] = get_current_win_streak()
	stats["loss_streak"] = get_current_loss_streak()
	stats["total_games_available"] = minigames.size()
	stats["difficulty_progression_events"] = get_state("difficulty_progression", []).size()
	set_state("minigame_statistics", stats)

func get_minigame_statistics() -> Dictionary:
	update_minigame_statistics()
	return get_state("minigame_statistics", {})
