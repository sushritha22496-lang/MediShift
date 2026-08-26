extends CanvasLayer

class_name HUDSystem

@onready var main_label = $MainLabel
@onready var objective_label = $ObjectiveLabel
@onready var inventory_label = $InventoryLabel
@onready var debug_label = $DebugLabel
@onready var progress_bar = $ProgressBar

var progression: GameProgression
var player_inventory: InventorySystem

signal text_updated(text: String)

func _ready() -> void:
	if not main_label:
		main_label = Label.new()
		add_child(main_label)
		main_label.anchor_left = 0.5
		main_label.anchor_right = 0.5
		main_label.anchor_top = 0.5
		main_label.anchor_bottom = 0.5
		main_label.offset_top = -200

func show_message(text: String, duration: float = 3.0) -> void:
	if main_label:
		main_label.text = text
		text_updated.emit(text)
		if duration > 0:
			await get_tree().create_timer(duration).timeout
			main_label.text = ""

func show_objective(text: String) -> void:
	if objective_label:
		objective_label.text = "📍 " + text

func show_inventory(items: Dictionary) -> void:
	if inventory_label:
		if items.is_empty():
			inventory_label.text = "🎒 Empty"
		else:
			var txt = "🎒 Inventory:\n"
			for item in items:
				txt += "%s: %d\n" % [item, items[item]]
			inventory_label.text = txt

func show_debug(info: String) -> void:
	if debug_label:
		debug_label.text = info

func update_progress(percent: int) -> void:
	if progress_bar:
		progress_bar.value = percent

func update_stage(stage: String) -> void:
	show_objective("Stage: " + stage)
