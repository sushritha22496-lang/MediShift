extends BaseSystemSimple

class_name LeaderboardSimple

class ScoreEntry:
	var rank: int
	var player_name: String
	var score: float
	var date: String
	func _init(p_rank: int, p_name: String, p_score: float, p_date: String) -> void:
		rank = p_rank
		player_name = p_name
		score = p_score
		date = p_date

var leaderboards: Dictionary = {}

signal score_submitted(leaderboard: String, rank: int)
signal new_high_score(leaderboard: String, score: float)

func _ready() -> void:
	_initialize_leaderboards()

func _initialize_leaderboards() -> void:
	leaderboards = {
		"score": [
			ScoreEntry.new(1, "Warrior", 50000.0, "2026-08-24"),
			ScoreEntry.new(2, "Hunter", 45000.0, "2026-08-23"),
			ScoreEntry.new(3, "Mage", 40000.0, "2026-08-22")
		],
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

func submit_score(leaderboard: String, player_name: String, score: float) -> int:
	if leaderboard not in leaderboards:
		return -1

	var board = leaderboards[leaderboard]
	var rank = board.size() + 1

	for i in range(board.size()):
		if score > board[i].score:
			rank = i + 1
			break

	if rank <= 10:
		var entry = ScoreEntry.new(rank, player_name, score, "2026-08-24")
		board.insert(rank - 1, entry)
		if board.size() > 10:
			board.pop_back()
		
		for i in range(board.size()):
			board[i].rank = i + 1

		if rank == 1:
			new_high_score.emit(leaderboard, score)
			emit_event("new_high_score", leaderboard)
		score_submitted.emit(leaderboard, rank)
		emit_event("score_submitted", leaderboard)
		return rank
	return -1

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

func get_leaderboard_text(leaderboard: String = "score") -> String:
	var board = get_leaderboard(leaderboard)
	var text = "Leaderboard: %s\n" % leaderboard.capitalize()
	for entry in board.slice(0, 5):
		text += "#%d %s - %.0f\n" % [entry.rank, entry.player_name, entry.score]
	return text
