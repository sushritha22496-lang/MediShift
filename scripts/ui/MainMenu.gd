extends Control

@onready var btn_new: Button = $CenterContainer/VBox/BtnNew
@onready var btn_continue: Button = $CenterContainer/VBox/BtnContinue
@onready var btn_options: Button = $CenterContainer/VBox/BtnOptions
@onready var btn_quit: Button = $CenterContainer/VBox/BtnQuit
@onready var options_panel: PanelContainer = $OptionsPanel
@onready var bgm_slider: HSlider = $OptionsPanel/VBox/BGMSlider
@onready var sfx_slider: HSlider = $OptionsPanel/VBox/SFXSlider
@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel

func _ready() -> void:
	btn_new.pressed.connect(_on_new_game)
	btn_continue.pressed.connect(_on_continue)
	btn_options.pressed.connect(_on_options)
	btn_quit.pressed.connect(_on_quit)
	if options_panel:
		options_panel.visible = false
		bgm_slider.value_changed.connect(AudioManager.set_bgm_volume)
		sfx_slider.value_changed.connect(AudioManager.set_sfx_volume)
	btn_continue.disabled = not SaveSystem.has_save()
	AudioManager.play_bgm("menu")
	title_label.text = "HANUMAN CHRONICLES"
	subtitle_label.text = "Valmiki Ramayana"

func _on_new_game() -> void:
	if SaveSystem.has_save():
		_confirm_new_game()
	else:
		GameManager.new_game()

func _confirm_new_game() -> void:
	GameManager.new_game()

func _on_continue() -> void:
	if SaveSystem.load_game():
		GameManager.start_chapter(GameManager.current_chapter)

func _on_options() -> void:
	if options_panel:
		options_panel.visible = !options_panel.visible

func _on_quit() -> void:
	get_tree().quit()
