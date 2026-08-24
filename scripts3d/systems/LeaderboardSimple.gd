extends Node

class_name LeaderboardSimple

class PlayerScore:
	var rank: int
	var name: String
	var level: int
	var experience: float
	var gold: float
	var playtime: float
	var kills: int
	var deaths: int

	func _init(p_rank: int, p_name: String, p_level: int, p_exp: float, p_gold: float, p_time: float, p_kills: int, p_deaths: int) -> void:
		rank = p_rank
		name = p_name
		level = p_level
		experience = p_exp
		gold = p_gold
		playtime = p_time
		kills = p_kills
		deaths = p_deaths

var leaderboard: Array[PlayerScore] = []
var player_rank: int = 0

signal rank_achieved(rank: int)
signal new_high_score(score: PlayerScore)

func _ready() -> void:
	_initialize_leaderboard()

func _initialize_leaderboard() -> void:
	leaderboard.append(PlayerScore.new(1, "Arjun", 50, 5000, 10000, 1000, 250, 5))
	leaderboard.append(PlayerScore.new(2, "Vikram", 48, 4800, 9500, 950, 240, 8))
	leaderboard.append(PlayerScore.new(3, "Dhruv", 45, 4500, 8000, 900, 210, 12))
	leaderboard.append(PlayerScore.new(4, "Sanjay", 42, 4200, 7500, 850, 195, 15))
	leaderboard.append(PlayerScore.new(5, "Rohan", 40, 4000, 7000, 800, 180, 18))

func submit_score(player_name: String, level: int, experience: float, gold: float, playtime: float, kills: int, deaths: int) -> void:
	var score = PlayerScore.new(leaderboard.size() + 1, player_name, level, experience, gold, playtime, kills, deaths)
	leaderboard.append(score)
	_sort_leaderboard()
	new_high_score.emit(score)
	print("🏆 Score submitted!")

func _sort_leaderboard() -> void:
	leaderboard.sort_custom(func(a, b): return a.experience > b.experience)
	for i in range(leaderboard.size()):
		leaderboard[i].rank = i + 1

func get_leaderboard(limit: int = 10) -> Array[PlayerScore]:
	var result: Array[PlayerScore] = []
	for i in range(mini(limit, leaderboard.size())):
		result.append(leaderboard[i])
	return result

func get_player_position(player_name: String) -> int:
	for score in leaderboard:
		if score.name == player_name:
			return score.rank
	return -1

func get_leaderboard_text(limit: int = 10) -> String:
	var text = "🏆 Top Players:\n"
	for i in range(mini(limit, leaderboard.size())):
		var score = leaderboard[i]
		text += "#%d %s (Lvl %d, Exp: %.0f)\n" % [score.rank, score.name, score.level, score.experience]
	return text
