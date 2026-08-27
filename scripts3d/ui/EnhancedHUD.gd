extends CanvasLayer

class_name EnhancedHUD

var main_label: Label
var objective_label: Label
var inventory_label: Label
var debug_label: Label
var health_bar: ProgressBar
var progress_bar: ProgressBar
var chapter_label: Label
var distance_label: Label

func _ready() -> void:
	_create_main_label()
	_create_objective_label()
	_create_inventory_label()
	_create_debug_label()
	_create_health_bar()
	_create_progress_bar()
	_create_chapter_label()
	_create_distance_label()

func _create_main_label() -> void:
	main_label = Label.new()
	main_label.anchor_left = 0.5
	main_label.anchor_top = 0.5
	main_label.anchor_right = 0.5
	main_label.anchor_bottom = 0.5
	main_label.offset_left = -300
	main_label.offset_top = -150
	main_label.offset_right = 300
	main_label.offset_bottom = 150
	main_label.custom_minimum_size = Vector2(600, 300)
	main_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(main_label)

func _create_objective_label() -> void:
	objective_label = Label.new()
	objective_label.anchor_left = 0.5
	objective_label.anchor_top = 0.0
	objective_label.anchor_right = 0.5
	objective_label.anchor_bottom = 0.0
	objective_label.offset_left = -200
	objective_label.offset_top = 10
	objective_label.offset_right = 200
	objective_label.offset_bottom = 40
	objective_label.text = "Objective"
	add_child(objective_label)

func _create_inventory_label() -> void:
	inventory_label = Label.new()
	inventory_label.anchor_left = 1.0
	inventory_label.anchor_top = 0.0
	inventory_label.anchor_right = 1.0
	inventory_label.anchor_bottom = 0.0
	inventory_label.offset_left = -200
	inventory_label.offset_top = 10
	inventory_label.offset_right = -10
	inventory_label.offset_bottom = 150
	inventory_label.text = "Inventory"
	add_child(inventory_label)

func _create_debug_label() -> void:
	debug_label = Label.new()
	debug_label.anchor_left = 0.0
	debug_label.anchor_top = 0.0
	debug_label.anchor_right = 0.5
	debug_label.anchor_bottom = 0.1
	debug_label.text = "Debug"
	add_child(debug_label)

func _create_health_bar() -> void:
	health_bar = ProgressBar.new()
	health_bar.anchor_left = 0.0
	health_bar.anchor_top = 0.0
	health_bar.anchor_right = 0.2
	health_bar.anchor_bottom = 0.0
	health_bar.offset_left = 10
	health_bar.offset_top = 50
	health_bar.offset_right = 210
	health_bar.offset_bottom = 80
	health_bar.min_value = 0
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.custom_minimum_size = Vector2(200, 30)
	add_child(health_bar)

	var label = Label.new()
	label.text = "Health"
	label.anchor_left = 0.0
	label.anchor_top = 0.0
	label.offset_left = 10
	label.offset_top = 35
	add_child(label)

func _create_progress_bar() -> void:
	progress_bar = ProgressBar.new()
	progress_bar.anchor_left = 0.0
	progress_bar.anchor_top = 0.0
	progress_bar.anchor_right = 0.3
	progress_bar.anchor_bottom = 0.0
	progress_bar.offset_left = 10
	progress_bar.offset_top = 120
	progress_bar.offset_right = 310
	progress_bar.offset_bottom = 150
	progress_bar.min_value = 0
	progress_bar.max_value = 6
	progress_bar.value = 1
	progress_bar.custom_minimum_size = Vector2(300, 30)
	add_child(progress_bar)

	var label = Label.new()
	label.text = "Story Progress"
	label.anchor_left = 0.0
	label.anchor_top = 0.0
	label.offset_left = 10
	label.offset_top = 105
	add_child(label)

func _create_chapter_label() -> void:
	chapter_label = Label.new()
	chapter_label.anchor_left = 0.5
	chapter_label.anchor_top = 0.0
	chapter_label.anchor_right = 0.5
	chapter_label.anchor_bottom = 0.0
	chapter_label.offset_left = -50
	chapter_label.offset_top = 50
	chapter_label.offset_right = 50
	chapter_label.offset_bottom = 80
	chapter_label.text = "Chapter 1"
	add_child(chapter_label)

func _create_distance_label() -> void:
	distance_label = Label.new()
	distance_label.anchor_left = 0.0
	distance_label.anchor_top = 1.0
	distance_label.anchor_right = 0.3
	distance_label.anchor_bottom = 1.0
	distance_label.offset_left = 10
	distance_label.offset_top = -40
	distance_label.offset_right = 310
	distance_label.offset_bottom = -10
	distance_label.text = "Distance: 0.0m"
	add_child(distance_label)

func show_message(message: String) -> void:
	if main_label:
		main_label.text = message

func show_objective(objective: String) -> void:
	if objective_label:
		objective_label.text = "📍 " + objective

func show_inventory(items: Dictionary) -> void:
	if inventory_label:
		if items.is_empty():
			inventory_label.text = "🎒 Inventory: Empty"
		else:
			var txt = "🎒 Inventory:\n"
			for item_name in items.keys():
				txt += "%s: %d\n" % [item_name, items[item_name]]
			inventory_label.text = txt.strip_edges()

func update_health(current: float, maximum: float) -> void:
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current

func update_progress(current: int, maximum: int) -> void:
	if progress_bar:
		progress_bar.max_value = maximum
		progress_bar.value = current

func update_chapter(chapter_num: int, name: String) -> void:
	if chapter_label:
		chapter_label.text = "Chapter %d: %s" % [chapter_num, name]

func update_distance(distance: float, eta: String) -> void:
	if distance_label:
		distance_label.text = "Distance: %.1fm | ETA: %s" % [distance, eta]

func update_debug_info(info: String) -> void:
	if debug_label:
		debug_label.text = info
