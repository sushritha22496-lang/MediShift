extends BaseSystemSimple

class_name MountSimple

class Mount:
	var id: String
	var name: String
	var speed: float
	var stamina: float
	var max_stamina: float
	var level: int
	var rarity: String
	func _init(p_id: String, p_name: String, p_speed: float, p_stamina: float, p_rarity: String = "common") -> void:
		id = p_id
		name = p_name
		speed = p_speed
		max_stamina = p_stamina
		stamina = p_stamina
		level = 1
		rarity = p_rarity

var mounts: Array[Mount] = []
var owned_mounts: Array[Mount] = []

signal mount_acquired(mount: Mount)
signal mount_mounted(mount: Mount)
signal mount_dismounted
signal mount_leveled_up(mount: Mount, new_level: int)

func _ready() -> void:
	set_state("active_mount", null)
	set_state("mount_exp", {})
	_initialize_mounts()

func _initialize_mounts() -> void:
	mounts = [
		Mount.new("horse", "Horse", 25.0, 100.0, "common"),
		Mount.new("stag", "Enchanted Stag", 30.0, 120.0, "uncommon"),
		Mount.new("griffin", "Griffin", 35.0, 150.0, "rare"),
		Mount.new("dragon", "Dragon Hatchling", 40.0, 200.0, "epic")
	]

func acquire_mount(mount_id: String) -> bool:
	var mount = _get_mount_from_list(mount_id, mounts)
	if mount and mount not in owned_mounts:
		var new_mount = Mount.new(mount.id, mount.name, mount.speed, mount.max_stamina, mount.rarity)
		owned_mounts.append(new_mount)
		mount_acquired.emit(new_mount)
		emit_event("mount_acquired", mount_id)
		return true
	return false

func mount(mount_id: String) -> bool:
	var mount = _get_mount_from_list(mount_id, owned_mounts)
	if mount:
		set_state("active_mount", mount)
		mount_mounted.emit(mount)
		emit_event("mount_mounted", mount_id)
		return true
	return false

func dismount() -> void:
	set_state("active_mount", null)
	mount_dismounted.emit()
	emit_event("mount_dismounted", "player")

func get_active_mount() -> Mount:
	return get_state("active_mount", null)

func is_mounted() -> bool:
	return get_active_mount() != null

func level_up_mount(mount_id: String) -> void:
	var mount = _get_mount_from_list(mount_id, owned_mounts)
	if mount:
		mount.level += 1
		mount.speed += 2.0
		mount.max_stamina += 20.0
		mount.stamina = mount.max_stamina
		mount_leveled_up.emit(mount, mount.level)
		emit_event("mount_leveled_up", mount_id)

func restore_mount_stamina(mount_id: String, amount: float) -> void:
	var mount = _get_mount_from_list(mount_id, owned_mounts)
	if mount:
		mount.stamina = minf(mount.stamina + amount, mount.max_stamina)
		emit_event("mount_stamina_restored", mount_id)

func drain_mount_stamina(mount_id: String, amount: float) -> void:
	var mount = _get_mount_from_list(mount_id, owned_mounts)
	if mount:
		mount.stamina -= amount
		if mount.stamina <= 0:
			mount.stamina = 0
			emit_event("mount_tired", mount_id)

func get_owned_mounts() -> Array[Mount]:
	return owned_mounts

func get_all_mounts() -> Array[Mount]:
	return mounts

func get_mount(mount_id: String) -> Mount:
	return _get_mount_from_list(mount_id, mounts)

func get_mount_speed_bonus() -> float:
	var active = get_active_mount()
	if active:
		return active.speed
	return 0.0

func get_mount_text() -> String:
	var active = get_active_mount()
	if not active:
		return "Mount: None\nOwnned Mounts: %d" % owned_mounts.size()
	return "%s (Lvl %d)\nSpeed: %.0f | Stamina: %.0f/%.0f" % [active.name, active.level, active.speed, active.stamina, active.max_stamina]

func _get_mount_from_list(mount_id: String, mount_list: Array[Mount]) -> Mount:
	for mount in mount_list:
		if mount.id == mount_id:
			return mount
	return null
