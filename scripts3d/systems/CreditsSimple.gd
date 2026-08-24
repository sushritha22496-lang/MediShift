extends BaseSystemSimple

class_name CreditsSimple

class CreditEntry:
	var role: String
	var name: String
	var contribution: String
	func _init(p_role: String, p_name: String, p_contribution: String = "") -> void:
		role = p_role
		name = p_name
		contribution = p_contribution

var credits: Array[CreditEntry] = []

signal credits_started
signal credits_ended
signal credit_section_reached(section: String)

func _ready() -> void:
	set_state("credits_viewed", false)
	_initialize_credits()

func _initialize_credits() -> void:
	credits = [
		CreditEntry.new("Game Design", "Development Team", "Core gameplay mechanics"),
		CreditEntry.new("Programming", "Claude AI", "Game systems and logic"),
		CreditEntry.new("Story", "Ramayana", "Epic narrative"),
		CreditEntry.new("Art Direction", "Game Engine", "Godot 4.x"),
		CreditEntry.new("Music", "Ambient Composer", "Background score"),
		CreditEntry.new("Sound Design", "Audio Team", "Effects and ambience"),
		CreditEntry.new("QA Testing", "Community", "Bug reports and feedback"),
		CreditEntry.new("Special Thanks", "Players", "For playing this game")
	]

func start_credits() -> void:
	credits_started.emit()
	emit_event("credits_started", "")

func end_credits() -> void:
	set_state("credits_viewed", true)
	credits_ended.emit()
	emit_event("credits_ended", "")

func get_credits() -> Array[CreditEntry]:
	return credits

func get_credits_by_role(role: String) -> Array[CreditEntry]:
	return credits.filter(func(c): return c.role == role)

func add_credit(role: String, name: String, contribution: String = "") -> void:
	var entry = CreditEntry.new(role, name, contribution)
	credits.append(entry)
	emit_event("credit_added", name)

func get_credits_text() -> String:
	var text = "=== CREDITS ===\n\n"
	var current_role = ""
	for credit in credits:
		if credit.role != current_role:
			text += "\n[%s]\n" % credit.role
			current_role = credit.role
		if credit.contribution != "":
			text += "  %s - %s\n" % [credit.name, credit.contribution]
		else:
			text += "  %s\n" % credit.name
	return text

func has_viewed_credits() -> bool:
	return get_state("credits_viewed", false)
