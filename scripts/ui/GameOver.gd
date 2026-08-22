extends Control

@onready var btn_retry: Button = $CenterContainer/VBox/BtnRetry
@onready var btn_menu: Button = $CenterContainer/VBox/BtnMenu
@onready var score_label: Label = $CenterContainer/VBox/ScoreLabel

func _ready() -> void:
	btn_retry.pressed.connect(_on_retry)
	btn_menu.pressed.connect(_on_menu)
	score_label.text = "Score: %d" % GameManager.score
	AudioManager.play_bgm("game_over")

func _on_retry() -> void:
	get_tree().paused = false
	if SaveSystem.load_game():
		GameManager.start_chapter(GameManager.current_chapter)
	else:
		GameManager.new_game()

func _on_menu() -> void:
	GameManager.quit_to_menu()
