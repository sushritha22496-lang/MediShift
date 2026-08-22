extends Control

# ─── Journey Map — India to Lanka ──────────────────────────────────────────────
# Follows Valmiki Ramayana geography: Kishkindha (Deccan) -> Dandaka Forest ->
# Mahendra Mountain (leap launch) -> Ram Setu -> Lanka forts -> battlefield.
# chapter == -1 means a lore/flavor waypoint (always visible, never a jump target).

const NODES: Array[Dictionary] = [
	{"id": "ayodhya",   "name": "Ayodhya",              "pos": Vector2(230, 110), "type": "city",     "chapter": -1,
		"text": "Rama's kingdom. The journey begins — and ends — here."},
	{"id": "rishya",    "name": "Rishyamukha Mountain", "pos": Vector2(300, 260), "type": "mountain", "chapter": 1,
		"text": "Where Hanuman meets Rama and Lakshmana, and the Vanara alliance is forged."},
	{"id": "dandaka",   "name": "Dandaka Forest",       "pos": Vector2(390, 360), "type": "forest",   "chapter": -1,
		"text": "Dense forest split by a rushing river. Vanara scouts often clash with forest demons here."},
	{"id": "dens",      "name": "Vanara Monkey Dens",   "pos": Vector2(280, 440), "type": "cave",     "chapter": -1,
		"text": "Hidden caves in the hills where Sugriva's monkey clans make their home."},
	{"id": "mahendra",  "name": "Mahendra Mountain",    "pos": Vector2(430, 560), "type": "coast",    "chapter": 2,
		"text": "The southern tip of India — launch point for Hanuman's leap across the ocean."},
	{"id": "setu",      "name": "Ram Setu",             "pos": Vector2(575, 615), "type": "bridge",   "chapter": 5,
		"text": "The floating bridge of stones, built to carry Rama's army to Lanka."},
	{"id": "gates",     "name": "Lanka Fort Gates",     "pos": Vector2(730, 630), "type": "fort",     "chapter": 3,
		"text": "Guarded by Lankini — the golden entrance to Ravana's island kingdom."},
	{"id": "vatika",    "name": "Ashoka Vatika",        "pos": Vector2(810, 580), "type": "garden",   "chapter": -1,
		"text": "Where Sita is held captive beneath the Ashoka trees, refusing Ravana's every threat."},
	{"id": "battle",    "name": "Lanka Battlefield",    "pos": Vector2(790, 480), "type": "battle",   "chapter": 6,
		"text": "The final war between Rama's army and Ravana's forces."},
	{"id": "palace",    "name": "Ravana's Palace",      "pos": Vector2(860, 430), "type": "palace",   "chapter": -1,
		"text": "The ten-headed king's throne room, where fate is decided."},
]

const TYPE_COLORS: Dictionary = {
	"city": Color(0.85, 0.7, 0.2),
	"mountain": Color(0.5, 0.45, 0.4),
	"forest": Color(0.15, 0.45, 0.2),
	"cave": Color(0.35, 0.3, 0.3),
	"coast": Color(0.3, 0.6, 0.55),
	"bridge": Color(0.7, 0.65, 0.5),
	"fort": Color(0.55, 0.25, 0.15),
	"garden": Color(0.3, 0.6, 0.25),
	"battle": Color(0.6, 0.1, 0.1),
	"palace": Color(0.75, 0.6, 0.1),
}

const CHAPTER_MARKER_NODE: Dictionary = {
	1: "rishya", 2: "mahendra", 3: "gates", 4: "vatika",
	5: "setu", 6: "battle", 7: "ayodhya"
}

const WILDLIFE: Array[Dictionary] = [
	{"name": "Elephants", "pos": Vector2(340, 300), "color": Color(0.5, 0.45, 0.42)},
	{"name": "Tigers",    "pos": Vector2(430, 330), "color": Color(0.8, 0.5, 0.1)},
	{"name": "Deer",      "pos": Vector2(250, 380), "color": Color(0.65, 0.45, 0.25)},
	{"name": "Peacocks",  "pos": Vector2(350, 420), "color": Color(0.1, 0.5, 0.45)},
	{"name": "Monkeys",   "pos": Vector2(250, 480), "color": Color(0.6, 0.4, 0.2)},
]

@onready var path_container: Node2D = $PathContainer
@onready var node_container: Control = $NodeContainer
@onready var wildlife_container: Control = $WildlifeContainer
@onready var info_panel: PanelContainer = $InfoPanel
@onready var info_title: Label = $InfoPanel/VBox/Title
@onready var info_text: Label = $InfoPanel/VBox/Text
@onready var info_button: Button = $InfoPanel/VBox/ActionButton
@onready var btn_back: Button = $BtnBack

var selected_node: Dictionary = {}

func _ready() -> void:
	btn_back.pressed.connect(_on_back)
	info_panel.visible = false
	_draw_path()
	_spawn_nodes()
	_spawn_wildlife()
	_spawn_hanuman_marker()
	AudioManager.play_bgm("kishkindha")

func _draw_path() -> void:
	var line := Line2D.new()
	line.width = 4.0
	line.default_color = Color(0.9, 0.85, 0.6, 0.7)
	for n in NODES:
		if n.id != "vatika" and n.id != "palace":
			line.add_point(n.pos)
	path_container.add_child(line)

	# Dotted sea-crossing line for Hanuman's leap (Mahendra -> Lanka Gates), drawn separately
	var leap_line := Line2D.new()
	leap_line.width = 3.0
	leap_line.default_color = Color(1.0, 0.9, 0.3, 0.5)
	leap_line.add_point(NODES[4].pos)
	leap_line.add_point(NODES[6].pos)
	path_container.add_child(leap_line)

func _spawn_nodes() -> void:
	for n in NODES:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(64, 64)
		btn.position = n.pos - Vector2(32, 32)
		btn.text = _icon_for_type(n.type)
		btn.add_theme_font_size_override("font_size", 22)

		var state := _node_state(n)
		var color: Color = TYPE_COLORS.get(n.type, Color.WHITE)
		if state == "locked":
			color = color.darkened(0.6)
			btn.disabled = false # still clickable to show "locked" message
		btn.modulate = color

		var label := Label.new()
		label.text = n.name
		label.position = n.pos + Vector2(-60, 34)
		label.custom_minimum_size = Vector2(120, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		node_container.add_child(label)

		btn.pressed.connect(_on_node_pressed.bind(n))
		node_container.add_child(btn)

func _spawn_wildlife() -> void:
	for w in WILDLIFE:
		var dot := ColorRect.new()
		dot.size = Vector2(14, 14)
		dot.position = w.pos - Vector2(7, 7)
		dot.color = w.color
		wildlife_container.add_child(dot)

		var label := Label.new()
		label.text = w.name
		label.position = w.pos + Vector2(-40, 10)
		label.custom_minimum_size = Vector2(80, 16)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.modulate = Color(1, 1, 1, 0.7)
		wildlife_container.add_child(label)

func _spawn_hanuman_marker() -> void:
	var node_id: String = CHAPTER_MARKER_NODE.get(GameManager.current_chapter, "rishya")
	var target_pos: Vector2 = Vector2.ZERO
	for n in NODES:
		if n.id == node_id:
			target_pos = n.pos
			break

	var marker := ColorRect.new()
	marker.size = Vector2(20, 26)
	marker.position = target_pos + Vector2(-10, -60)
	marker.color = Color(0.93, 0.4, 0.05, 1)
	node_container.add_child(marker)

	var label := Label.new()
	label.text = "Hanuman"
	label.position = target_pos + Vector2(-40, -84)
	label.custom_minimum_size = Vector2(80, 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.modulate = Color(1, 0.75, 0.4, 1)
	node_container.add_child(label)

func _icon_for_type(type: String) -> String:
	match type:
		"city": return "AYD"
		"mountain": return "MTN"
		"forest": return "FOR"
		"cave": return "CAV"
		"coast": return "CST"
		"bridge": return "SETU"
		"fort": return "FORT"
		"garden": return "GDN"
		"battle": return "WAR"
		"palace": return "PAL"
		_: return "?"

func _node_state(n: Dictionary) -> String:
	if n.chapter == -1:
		return "lore"
	if n.chapter < GameManager.current_chapter:
		return "completed"
	elif n.chapter == GameManager.current_chapter:
		return "current"
	else:
		return "locked"

func _on_node_pressed(n: Dictionary) -> void:
	selected_node = n
	var state := _node_state(n)
	info_panel.visible = true
	info_title.text = n.name
	info_text.text = n.text
	if info_button.pressed.is_connected(_on_action_pressed):
		info_button.pressed.disconnect(_on_action_pressed)
	info_button.pressed.connect(_on_action_pressed, CONNECT_ONE_SHOT)

	match state:
		"lore":
			info_button.visible = false
		"locked":
			info_button.visible = true
			info_button.text = "Locked — reach Chapter %d first" % n.chapter
			info_button.disabled = true
		"current":
			info_button.visible = true
			info_button.text = "Enter Chapter %d" % n.chapter
			info_button.disabled = false
		"completed":
			info_button.visible = true
			info_button.text = "Replay Chapter %d" % n.chapter
			info_button.disabled = false

func _on_action_pressed() -> void:
	if selected_node.chapter >= 1:
		GameManager.start_chapter(selected_node.chapter as GameManager.Chapter)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
