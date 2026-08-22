extends Node

# ─── Game State ───────────────────────────────────────────────────────────────
enum GameState { MENU, PLAYING, PAUSED, CUTSCENE, DIALOGUE, GAME_OVER, VICTORY }
enum Chapter {
	KISHKINDHA = 1,
	GREAT_LEAP = 2,
	LANKA_STEALTH = 3,
	LANKA_RAMPAGE = 4,
	WAR_PREP = 5,
	LANKA_WAR = 6,
	VICTORY = 7
}

var current_state: GameState = GameState.MENU
var current_chapter: Chapter = Chapter.KISHKINDHA
var cheat_unlock_all_chapters: bool = false
var score: int = 0
var enemies_defeated: int = 0
var bosses_defeated: Array[String] = []

# ─── Player Powers Unlocked ────────────────────────────────────────────────────
var powers_unlocked: Dictionary = {
	"gada": true,
	"fly": false,
	"mahima": false,
	"anima": false,
	"laghima": false,
	"garima": false,
	"tail_fire": false,
	"vayuvega": false,
	"sanjeevani_aura": false
}

# ─── Story Flags ───────────────────────────────────────────────────────────────
var story_flags: Dictionary = {
	"met_rama": false,
	"alliance_formed": false,
	"vali_dead": false,
	"leaped_to_lanka": false,
	"found_sita": false,
	"delivered_ring": false,
	"lanka_burned": false,
	"ram_setu_built": false,
	"lakshmana_saved": false,
	"ravana_dead": false,
	"sita_freed": false
}

# ─── Signals ──────────────────────────────────────────────────────────────────
signal state_changed(new_state: GameState)
signal chapter_started(chapter: Chapter)
signal chapter_completed(chapter: Chapter)
signal power_unlocked(power_name: String)
signal story_flag_set(flag: String)
signal score_changed(new_score: int)
signal game_over()
signal victory()

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and current_state == GameState.PLAYING:
		set_state(GameState.PAUSED)
	elif event.is_action_pressed("pause") and current_state == GameState.PAUSED:
		set_state(GameState.PLAYING)

# ─── State Machine ────────────────────────────────────────────────────────────
func set_state(new_state: GameState) -> void:
	current_state = new_state
	match new_state:
		GameState.PAUSED:
			get_tree().paused = true
		GameState.PLAYING:
			get_tree().paused = false
		GameState.CUTSCENE:
			get_tree().paused = false
		GameState.DIALOGUE:
			get_tree().paused = false
	state_changed.emit(new_state)

# ─── Chapter Management ────────────────────────────────────────────────────────
func start_chapter(chapter: Chapter) -> void:
	current_chapter = chapter
	set_state(GameState.PLAYING)
	chapter_started.emit(chapter)
	var scene_map: Dictionary = {
		Chapter.KISHKINDHA:    "res://scenes/chapters/ch1_kishkindha.tscn",
		Chapter.GREAT_LEAP:    "res://scenes/chapters/ch2_great_leap.tscn",
		Chapter.LANKA_STEALTH: "res://scenes/chapters/ch3_lanka_stealth.tscn",
		Chapter.LANKA_RAMPAGE: "res://scenes/chapters/ch4_lanka_rampage.tscn",
		Chapter.WAR_PREP:      "res://scenes/chapters/ch5_war_prep.tscn",
		Chapter.LANKA_WAR:     "res://scenes/chapters/ch6_lanka_war.tscn",
		Chapter.VICTORY:       "res://scenes/chapters/ch7_victory.tscn"
	}
	if scene_map.has(chapter):
		get_tree().change_scene_to_file(scene_map[chapter])

func complete_chapter(chapter: Chapter) -> void:
	chapter_completed.emit(chapter)
	SaveSystem.save_game()
	var next = chapter + 1
	if next <= Chapter.VICTORY:
		start_chapter(next as Chapter)
	else:
		set_state(GameState.VICTORY)
		victory.emit()

# ─── Powers ───────────────────────────────────────────────────────────────────
func unlock_power(power_name: String) -> void:
	if powers_unlocked.has(power_name):
		powers_unlocked[power_name] = true
		power_unlocked.emit(power_name)
		AudioManager.play_sfx("power_unlock")

func has_power(power_name: String) -> bool:
	return powers_unlocked.get(power_name, false)

# ─── Story Flags ──────────────────────────────────────────────────────────────
func set_flag(flag: String) -> void:
	if story_flags.has(flag):
		story_flags[flag] = true
		story_flag_set.emit(flag)

func get_flag(flag: String) -> bool:
	return story_flags.get(flag, false)

# ─── Score ────────────────────────────────────────────────────────────────────
func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

# ─── Game Over / Victory ──────────────────────────────────────────────────────
func trigger_game_over() -> void:
	set_state(GameState.GAME_OVER)
	game_over.emit()
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")

func new_game() -> void:
	score = 0
	enemies_defeated = 0
	bosses_defeated.clear()
	for key in powers_unlocked:
		powers_unlocked[key] = false
	powers_unlocked["gada"] = true
	for key in story_flags:
		story_flags[key] = false
	cheat_unlock_all_chapters = false
	CheatCodes.reset()
	start_chapter(Chapter.KISHKINDHA)

func quit_to_menu() -> void:
	get_tree().paused = false
	set_state(GameState.MENU)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
