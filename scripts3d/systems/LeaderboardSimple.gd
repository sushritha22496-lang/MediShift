extends BaseSystemSimple

class_name LeaderboardSimple

class ScoreEntry:
	var rank: int
	var player_name: String
	var score: float
	var date: String
	var difficulty: int = 1
	var play_time: float = 0.0
	var game_mode: String = "standard"
	var verified: bool = true
	var streak: int = 0
	var personal_best: bool = false
	func _init(p_rank: int, p_name: String, p_score: float, p_date: String) -> void:
		rank = p_rank
		player_name = p_name
		score = p_score
		date = p_date

var leaderboards: Dictionary = {}
var time_based_leaderboards: Dictionary = {}
var player_personal_bests: Dictionary = {}

signal score_submitted(leaderboard: String, rank: int)
signal new_high_score(leaderboard: String, score: float)
signal personal_best_broken(player: String, score: float)
signal rank_changed(player: String, old_rank: int, new_rank: int)

func _ready() -> void:
	set_state("total_entries", 0)
	set_state("leaderboard_updates", [])
	set_state("suspicious_scores", [])
	_initialize_leaderboards()

func _initialize_leaderboards() -> void:
	var e1 = ScoreEntry.new(1, "Warrior", 50000.0, "2026-08-24")
	e1.difficulty = 3
	e1.play_time = 3600.0
	var e2 = ScoreEntry.new(2, "Hunter", 45000.0, "2026-08-23")
	e2.difficulty = 2
	e2.play_time = 3200.0
	var e3 = ScoreEntry.new(3, "Mage", 40000.0, "2026-08-22")
	e3.difficulty = 2
	e3.play_time = 2800.0
	leaderboards = {
		"score": [e1, e2, e3],
		"speedrun": [
			ScoreEntry.new(1, "Swift", 600.0, "2026-08-24"),
			ScoreEntry.new(2, "Quick", 720.0, "2026-08-23"),
			ScoreEntry.new(3, "Fast", 840.0, "2026-08-22")
		],
		"survival": [
			ScoreEntry.new(1, "Survivor", 120.0, "2026-08-24"),
			ScoreEntry.new(2, "Tough", 100.0, "2026-08-23"),
			ScoreEntry.new(3, "Strong", 90.0, "2026-08-22")
		]
	}
	time_based_leaderboards = {
		"daily": [],
		"weekly": [],
		"monthly": [],
		"all_time": leaderboards["score"].duplicate()
	}

func submit_score(leaderboard: String, player_name: String, score: float, difficulty: int = 1, play_time: float = 0.0, game_mode: String = "standard") -> int:
	if leaderboard not in leaderboards:
		return -1
	if not _is_valid_score(player_name, score, play_time):
		_flag_suspicious_score(player_name, score)
		return -1
	var board = leaderboards[leaderboard]
	var rank = board.size() + 1
	for i in range(board.size()):
		if score > board[i].score:
			rank = i + 1
			break
	if rank <= 20:
		var entry = ScoreEntry.new(rank, player_name, score, "2026-08-24")
		entry.difficulty = difficulty
		entry.play_time = play_time
		entry.game_mode = game_mode
		var old_rank = get_player_rank(leaderboard, player_name)
		_update_personal_best(player_name, score)
		if not player_name in player_personal_bests or score > player_personal_bests[player_name]:
			entry.personal_best = true
			if player_name in player_personal_bests:
				personal_best_broken.emit(player_name, score)
			player_personal_bests[player_name] = score
		board.insert(rank - 1, entry)
		if board.size() > 20:
			board.pop_back()
		for i in range(board.size()):
			board[i].rank = i + 1
		if rank == 1:
			new_high_score.emit(leaderboard, score)
			emit_event("new_high_score", leaderboard)
		if old_rank != -1 and old_rank != rank:
			rank_changed.emit(player_name, old_rank, rank)
		score_submitted.emit(leaderboard, rank)
		var updates = get_state("leaderboard_updates", [])
		updates.append({"player": player_name, "rank": rank, "score": score, "time": Time.get_ticks_msec()})
		if updates.size() > 100:
			updates.pop_front()
		set_state("leaderboard_updates", updates)
		emit_event("score_submitted", {"leaderboard": leaderboard, "rank": rank, "score": score})
		return rank
	return -1

func _is_valid_score(player: String, score: float, play_time: float) -> bool:
	if score < 0:
		return false
	if play_time > 0 and play_time < 10.0:
		return false
	return true

func _flag_suspicious_score(player: String, score: float) -> void:
	var suspicious = get_state("suspicious_scores", [])
	suspicious.append({"player": player, "score": score, "timestamp": Time.get_ticks_msec()})
	if suspicious.size() > 50:
		suspicious.pop_front()
	set_state("suspicious_scores", suspicious)

func _update_personal_best(player: String, score: float) -> void:
	if not player in player_personal_bests:
		player_personal_bests[player] = score

func get_leaderboard(leaderboard: String) -> Array[ScoreEntry]:
	return leaderboards.get(leaderboard, [])

func get_leaderboards() -> Array:
	return leaderboards.keys()

func get_player_rank(leaderboard: String, player_name: String) -> int:
	var board = get_leaderboard(leaderboard)
	for entry in board:
		if entry.player_name == player_name:
			return entry.rank
	return -1

func get_player_personal_best(player_name: String) -> float:
	return player_personal_bests.get(player_name, 0.0)

func get_leaderboard_by_difficulty(leaderboard: String, difficulty: int) -> Array[ScoreEntry]:
	var board = get_leaderboard(leaderboard)
	var filtered: Array[ScoreEntry] = []
	for entry in board:
		if entry.difficulty == difficulty:
			filtered.append(entry)
	return filtered

func get_suspicious_scores() -> Array:
	return get_state("suspicious_scores", [])

func get_leaderboard_updates() -> Array:
	return get_state("leaderboard_updates", [])

func get_leaderboard_text(leaderboard: String = "score", count: int = 5) -> String:
	var board = get_leaderboard(leaderboard)
	var text = "Leaderboard: %s [%d]\n" % [leaderboard.capitalize(), board.size()]
	var max_idx = min(count, board.size())
	for i in range(max_idx):
		var entry = board[i]
		var medal = ["🥇", "🥈", "🥉"][i] if i < 3 else " "
		text += "%s#%d %s - %.0f\n" % [medal, entry.rank, entry.player_name, entry.score]
	return text
