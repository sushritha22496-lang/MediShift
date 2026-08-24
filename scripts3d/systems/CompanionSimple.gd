extends BaseSystemSimple

class_name CompanionSimple

class Companion:
	var id: String
	var name: String
	var type: String
	var level: int = 1
	var experience: float = 0.0
	var health: float = 50.0
	var max_health: float = 50.0
	var attack: float = 5.0
	var defense: float = 3.0
	var loyalty: float = 50.0
	var is_active: bool = false
	func _init(p_id: String, p_name: String, p_type: String) -> void:
		id = p_id
		name = p_name
		type = p_type

signal companion_acquired(companion: Companion)
signal companion_leveled_up(companion: Companion)
signal companion_defeated

func _ready() -> void:
	set_state("companions", [])
	set_state("active_id", "")

func acquire_companion(name: String, comp_type: String) -> Companion:
	var companions = get_state("companions", []) as Array[Companion]
	var companion = Companion.new("comp_%d" % companions.size(), name, comp_type)
	companions.append(companion)
	companion_acquired.emit(companion)
	emit_event("companion_acquired", name)
	return companion

func set_active_companion(companion_id: String) -> bool:
	var companions = get_state("companions", []) as Array[Companion]
	for companion in companions:
		if companion.id == companion_id:
			set_state("active_id", companion_id)
			companion.is_active = true
			return true
	return false

func add_experience(amount: float) -> void:
	var companions = get_state("companions", []) as Array[Companion]
	var active_id = get_state("active_id", "")
	for companion in companions:
		if companion.id == active_id:
			companion.experience += amount
			if companion.experience >= companion.level * 100:
				_level_up_companion(companion)

func _level_up_companion(companion: Companion) -> void:
	companion.level += 1
	companion.max_health += 10
	companion.health = companion.max_health
	companion.attack += 2
	companion.defense += 1
	companion.experience = 0
	companion_leveled_up.emit(companion)
	emit_event("companion_levelup", companion.id)

func heal_companion(amount: float) -> void:
	var companions = get_state("companions", []) as Array[Companion]
	var active_id = get_state("active_id", "")
	for companion in companions:
		if companion.id == active_id:
			companion.health = minf(companion.health + amount, companion.max_health)

func damage_companion(amount: float) -> void:
	var companions = get_state("companions", []) as Array[Companion]
	var active_id = get_state("active_id", "")
	for companion in companions:
		if companion.id == active_id:
			companion.health = maxf(companion.health - amount, 0.0)
			if companion.health <= 0:
				companion_defeated.emit()

func increase_loyalty(amount: float) -> void:
	var companions = get_state("companions", []) as Array[Companion]
	var active_id = get_state("active_id", "")
	for companion in companions:
		if companion.id == active_id:
			companion.loyalty = minf(companion.loyalty + amount, 100.0)

func get_companion(companion_id: String) -> Companion:
	var companions = get_state("companions", []) as Array[Companion]
	for companion in companions:
		if companion.id == companion_id:
			return companion
	return null

func get_companions() -> Array:
	return get_state("companions", [])

func get_companion_text() -> String:
	var companions = get_state("companions", []) as Array[Companion]
	var text = "Companions [%d]:\n" % companions.size()
	for companion in companions:
		var status = "★" if companion.is_active else " "
		text += "%s %s (Lvl %d, HP: %.0f)\n" % [status, companion.name, companion.level, companion.health]
	return text
