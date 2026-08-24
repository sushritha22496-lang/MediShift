extends BaseSystemSimple

class_name SpiritSimple

class Spirit:
	var id: String
	var name: String
	var spirit_type: String
	var power: int
	var blessing: String
	var encountered: bool
	func _init(p_id: String, p_name: String, p_type: String, p_power: int, p_blessing: String) -> void:
		id = p_id
		name = p_name
		spirit_type = p_type
		power = p_power
		blessing = p_blessing
		encountered = false

var spirits: Array[Spirit] = []

signal spirit_encountered(spirit: Spirit)
signal blessing_granted(spirit_id: String, blessing: String)
signal spirit_appeased

func _ready() -> void:
	set_state("encountered_spirits", [])
	set_state("active_blessings", [])
	_initialize_spirits()

func _initialize_spirits() -> void:
	spirits = [
		Spirit.new("s1", "Forest Guardian", "nature", 3, "forest_guide"),
		Spirit.new("s2", "River Sprite", "water", 2, "water_crossing"),
		Spirit.new("s3", "Mountain Warden", "earth", 4, "stone_skin"),
		Spirit.new("s4", "Sky Herald", "air", 3, "swift_wind"),
		Spirit.new("s5", "Ancient Soul", "ancestral", 5, "wisdom_echo")
	]

func encounter_spirit(spirit_id: String) -> bool:
	var spirit = _get_spirit(spirit_id)
	if spirit and not spirit.encountered:
		spirit.encountered = true
		var encountered = get_state("encountered_spirits", [])
		encountered.append(spirit_id)
		set_state("encountered_spirits", encountered)
		spirit_encountered.emit(spirit)
		emit_event("spirit_encountered", spirit_id)
		return true
	return false

func grant_blessing(spirit_id: String) -> String:
	var spirit = _get_spirit(spirit_id)
	if spirit and spirit.encountered:
		var blessings = get_state("active_blessings", [])
		if spirit.blessing not in blessings:
			blessings.append(spirit.blessing)
			set_state("active_blessings", blessings)
		blessing_granted.emit(spirit_id, spirit.blessing)
		emit_event("blessing_granted", spirit_id)
		return spirit.blessing
	return ""

func appease_spirit(spirit_id: String) -> void:
	var spirit = _get_spirit(spirit_id)
	if spirit:
		spirit_appeased.emit()
		emit_event("spirit_appeased", spirit_id)

func get_spirit(spirit_id: String) -> Spirit:
	return _get_spirit(spirit_id)

func get_encountered_spirits() -> Array[Spirit]:
	var encountered_ids = get_state("encountered_spirits", [])
	var encountered: Array[Spirit] = []
	for s in spirits:
		if s.id in encountered_ids:
			encountered.append(s)
	return encountered

func get_active_blessings() -> Array:
	return get_state("active_blessings", [])

func has_blessing(blessing: String) -> bool:
	return blessing in get_active_blessings()

func get_spirit_text() -> String:
	var encountered = get_encountered_spirits()
	var blessings = get_active_blessings()
	var text = "Spirits: %d encountered | %d blessings\n" % [encountered.size(), blessings.size()]
	for spirit in encountered:
		var blessed = " ✓" if spirit.blessing in blessings else ""
		text += "○ %s%s\n" % [spirit.name, blessed]
	return text

func _get_spirit(spirit_id: String) -> Spirit:
	for spirit in spirits:
		if spirit.id == spirit_id:
			return spirit
	return null
