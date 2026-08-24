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
	game_won.emit(game_id, reward)
	emit_event("game_won", game_id)
	return reward

func lose_game(game_id: String) -> void:
	var game = _get_game(game_id)
	if game:
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
