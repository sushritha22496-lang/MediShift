extends Node3D

class_name GameStateManager

class PlayerStats:
	var health: int = 100
	var max_health: int = 100
	var energy: int = 100
	var max_energy: int = 100
	var experience: int = 0
	var level: int = 1

var player_stats: PlayerStats = PlayerStats.new()
var current_chapter: int = 1
var game_time: float = 0.0
var is_paused: bool = false
var current_location: String = "badrachalam_forest"

var collected_clues: Array[String] = []
var defeated_enemies: Array[String] = []
var completed_quests: Array[String] = []

signal chapter_changed(chapter: int)
signal location_changed(location: String)
signal health_changed(health: int)
signal experience_gained(amount: int)
signal level_up(level: int)

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if not is_paused:
		game_time += delta

func start_chapter(chapter: int) -> void:
	current_chapter = chapter
	chapter_changed.emit(chapter)

func change_location(location: String) -> void:
	current_location = location
	location_changed.emit(location)

func add_experience(amount: int) -> void:
	player_stats.experience += amount
	experience_gained.emit(amount)

	var xp_needed = current_chapter * 100
	if player_stats.experience >= xp_needed:
		level_up_player()

func level_up_player() -> void:
	player_stats.level += 1
	player_stats.max_health += 10
	player_stats.health = player_stats.max_health
	player_stats.max_energy += 5
	player_stats.energy = player_stats.max_energy
	level_up.emit(player_stats.level)

func take_damage(amount: int) -> void:
	player_stats.health = max(0, player_stats.health - amount)
	health_changed.emit(player_stats.health)

	if player_stats.health <= 0:
		game_over()

func heal(amount: int) -> void:
	player_stats.health = min(player_stats.max_health, player_stats.health + amount)
	health_changed.emit(player_stats.health)

func restore_energy(amount: int) -> void:
	player_stats.energy = min(player_stats.max_energy, player_stats.energy + amount)

func consume_energy(amount: int) -> bool:
	if player_stats.energy >= amount:
		player_stats.energy -= amount
		return true
	return false

func add_clue(clue: String) -> void:
	if clue not in collected_clues:
		collected_clues.append(clue)

func add_completed_quest(quest_id: String) -> void:
	if quest_id not in completed_quests:
		completed_quests.append(quest_id)

func get_player_stats() -> PlayerStats:
	return player_stats

func get_progress_percentage() -> float:
	var total = collected_clues.size() + completed_quests.size()
	return float(completed_quests.size()) / maxf(total, 1.0)

func pause_game() -> void:
	is_paused = true
	get_tree().paused = true

func resume_game() -> void:
	is_paused = false
	get_tree().paused = false

func game_over() -> void:
	print("GAME OVER - Rama has fallen")
	pause_game()
