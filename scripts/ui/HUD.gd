extends CanvasLayer

@onready var health_bar: ProgressBar = $MarginContainer/VBox/HealthBar
@onready var health_label: Label = $MarginContainer/VBox/HealthLabel
@onready var fly_bar: ProgressBar = $MarginContainer/VBox/FlyBar
@onready var rage_bar: ProgressBar = $MarginContainer/VBox/RageBar
@onready var score_label: Label = $TopRight/ScoreLabel
@onready var chapter_label: Label = $TopCenter/ChapterLabel
@onready var power_icons: HBoxContainer = $BottomLeft/PowerIcons
@onready var boss_health_bar: ProgressBar = $BossHealthBar
@onready var boss_name_label: Label = $BossHealthBar/BossName
@onready var dialogue_box: PanelContainer = $DialogueBox
@onready var dialogue_speaker: Label = $DialogueBox/VBox/Speaker
@onready var dialogue_text: Label = $DialogueBox/VBox/Text
@onready var dialogue_portrait: TextureRect = $DialogueBox/VBox/Portrait
@onready var cheat_console: PanelContainer = $CheatConsole
@onready var cheat_input_label: Label = $CheatConsole/Label
@onready var notification_label: Label = $NotificationLabel
@onready var combo_label: Label = $ComboLabel

var notification_tween: Tween
var combo_count: int = 0
var combo_timer: float = 0.0

const POWER_LABELS: Dictionary = {
	"gada": "Gada", "fly": "Laghima", "mahima": "Mahima", "anima": "Anima",
	"laghima": "Laghima", "garima": "Garima", "tail_fire": "Agni Tail",
	"vayuvega": "Vayuvega", "sanjeevani_aura": "Sanjeevani"
}

func _ready() -> void:
	_connect_signals()
	boss_health_bar.visible = false
	dialogue_box.visible = false
	cheat_console.visible = false
	notification_label.visible = false
	_refresh_power_icons()
	GameManager.power_unlocked.connect(func(_p): _refresh_power_icons())

func _refresh_power_icons() -> void:
	for child in power_icons.get_children():
		child.queue_free()
	var shown_labels: Array[String] = []
	for power_name in GameManager.powers_unlocked:
		if not GameManager.powers_unlocked[power_name]:
			continue
		var label_text: String = POWER_LABELS.get(power_name, power_name)
		if label_text in shown_labels:
			continue
		shown_labels.append(label_text)
		var chip := Label.new()
		chip.text = "[%s]" % label_text
		chip.add_theme_font_size_override("font_size", 13)
		chip.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4, 1))
		power_icons.add_child(chip)

func _process(delta: float) -> void:
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_count = 0
			combo_label.visible = false
	if cheat_console.visible:
		cheat_input_label.text = "> " + CheatCodes.get_buffer() + "_"

func _connect_signals() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.chapter_started.connect(_on_chapter_started)
	DialogueManager.dialogue_line.connect(_on_dialogue_line)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	CheatCodes.console_toggled.connect(_on_console_toggled)
	CheatCodes.cheat_activated.connect(_on_cheat_activated)
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		player.power_used.connect(_on_power_used)
		player.rage_changed.connect(_on_rage_changed)
		player.rage_filled.connect(_on_rage_filled)
		player.fly_energy_changed.connect(_on_fly_energy_changed)

func _on_fly_energy_changed(current: float) -> void:
	fly_bar.value = current

func _on_rage_changed(current: float) -> void:
	rage_bar.value = current

func _on_rage_filled() -> void:
	_show_notification("RAGE READY! Press [R] to unleash!", 3.0)

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d / %d" % [int(current), int(maximum)]

func _on_score_changed(score: int) -> void:
	score_label.text = "Score: %d" % score

func _on_chapter_started(chapter: GameManager.Chapter) -> void:
	var names: Dictionary = {
		GameManager.Chapter.KISHKINDHA:    "Chapter I — Kishkindha",
		GameManager.Chapter.GREAT_LEAP:    "Chapter II — The Great Leap",
		GameManager.Chapter.LANKA_STEALTH: "Chapter III — Lanka Infiltration",
		GameManager.Chapter.LANKA_RAMPAGE: "Chapter IV — Lanka Rampage",
		GameManager.Chapter.WAR_PREP:      "Chapter V — War Preparation",
		GameManager.Chapter.LANKA_WAR:     "Chapter VI — Lanka War",
		GameManager.Chapter.VICTORY:       "Chapter VII — Victory"
	}
	chapter_label.text = names.get(chapter, "")
	_show_notification(names.get(chapter, ""), 3.0)

func show_boss_health(boss_name: String, current: float, maximum: float) -> void:
	boss_health_bar.visible = true
	boss_name_label.text = boss_name
	boss_health_bar.max_value = maximum
	boss_health_bar.value = current

func hide_boss_health() -> void:
	boss_health_bar.visible = false

func update_boss_health(current: float) -> void:
	boss_health_bar.value = current

func _on_dialogue_line(speaker: String, text: String, _portrait: String) -> void:
	dialogue_box.visible = true
	dialogue_speaker.text = speaker
	dialogue_text.text = ""
	_type_text(text)

func _type_text(text: String) -> void:
	dialogue_text.text = ""
	for i in text.length():
		dialogue_text.text += text[i]
		if i % 3 == 0:
			await get_tree().create_timer(0.02).timeout

func _on_dialogue_ended(_id: String) -> void:
	dialogue_box.visible = false

func _on_console_toggled(open: bool) -> void:
	cheat_console.visible = open

func _on_cheat_activated(code: String, _effect: String) -> void:
	_show_notification("CHEAT: " + code + " ACTIVATED!", 2.0)
	AudioManager.play_sfx("cheat_activate")

func _on_power_used(power: String) -> void:
	_show_notification(power.to_upper() + "!", 1.0)

func add_combo() -> void:
	combo_count += 1
	combo_timer = 2.0
	if combo_count > 2:
		combo_label.visible = true
		combo_label.text = "x%d COMBO!" % combo_count

func _show_notification(text: String, duration: float) -> void:
	notification_label.text = text
	notification_label.visible = true
	notification_label.modulate.a = 1.0
	if notification_tween:
		notification_tween.kill()
	notification_tween = create_tween()
	notification_tween.tween_interval(duration - 0.5)
	notification_tween.tween_property(notification_label, "modulate:a", 0.0, 0.5)
	notification_tween.tween_callback(func(): notification_label.visible = false)
