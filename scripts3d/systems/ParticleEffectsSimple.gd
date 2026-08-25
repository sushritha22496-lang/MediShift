extends BaseSystemSimple

class_name ParticleEffectsSimple

class ParticleEffect:
	var id: String
	var name: String
	var effect_type: String
	var duration: float
	var intensity: float
	var color: Color = Color.WHITE
	var scale: float = 1.0
	var speed: float = 1.0
	var layer: int = 0
	var max_instances: int = 5
	var current_instances: int = 0
	var linked_effects: Array[String] = []
	var screen_space: bool = false
	var attachable: bool = true
	func _init(p_id: String, p_name: String, p_type: String, p_duration: float, p_intensity: float = 1.0) -> void:
		id = p_id
		name = p_name
		effect_type = p_type
		duration = p_duration
		intensity = p_intensity

var particle_effects: Dictionary = {}
var active_effect_instances: Array = []

signal effect_started(effect_id: String)
signal effect_ended(effect_id: String)
signal effect_pooled(effect_id: String)
signal effect_stacked(effect_id: String, stack_count: int)

func _ready() -> void:
	set_state("active_effects", [])
	set_state("effect_instances", [])
	set_state("effect_stacks", {})
	set_state("performance_impact", 0.0)
	set_state("effect_callbacks", {})
	set_state("effect_pool", {})
	_initialize_effects()

func _initialize_effects() -> void:
	var explosion = ParticleEffect.new("explosion", "Explosion", "combat", 0.8, 1.0)
	explosion.color = Color.ORANGE
	explosion.max_instances = 10
	var fireball = ParticleEffect.new("fireball", "Fireball", "spell", 1.2, 0.9)
	fireball.color = Color.RED
	fireball.max_instances = 8
	fireball.linked_effects = ["critical_hit"]
	var heal_aura = ParticleEffect.new("heal_aura", "Heal Aura", "healing", 1.0, 0.7)
	heal_aura.color = Color.GREEN
	heal_aura.max_instances = 5
	var power_up = ParticleEffect.new("power_up", "Power Up", "buff", 0.6, 0.8)
	power_up.color = Color.BLUE
	var death_particles = ParticleEffect.new("death_particles", "Death", "death", 1.5, 1.0)
	death_particles.color = Color.DARK_GRAY
	death_particles.max_instances = 15
	var critical_hit = ParticleEffect.new("critical_hit", "Critical Hit", "combat", 0.5, 1.2)
	critical_hit.color = Color.YELLOW
	critical_hit.intensity = 1.5
	var dodge_flash = ParticleEffect.new("dodge_flash", "Dodge", "movement", 0.3, 0.6)
	dodge_flash.color = Color.LIGHT_BLUE
	var level_up_shine = ParticleEffect.new("level_up_shine", "Level Up", "progression", 1.0, 1.0)
	level_up_shine.color = Color.GOLD
	particle_effects = {
		"explosion": explosion, "fireball": fireball, "heal_aura": heal_aura,
		"power_up": power_up, "death_particles": death_particles,
		"critical_hit": critical_hit, "dodge_flash": dodge_flash,
		"level_up_shine": level_up_shine
	}

func play_effect(effect_id: String, position: Vector3 = Vector3.ZERO) -> bool:
	if effect_id not in particle_effects:
		return false
	var effect = particle_effects[effect_id]
	if effect.current_instances >= effect.max_instances:
		_pool_effect(effect_id)
		effect_pooled.emit(effect_id)
		return false
	effect.current_instances += 1
	var active = get_state("active_effects", [])
	active.append(effect_id)
	set_state("active_effects", active)
	var instances = get_state("effect_instances", [])
	instances.append({"id": effect_id, "position": position, "start_time": Time.get_ticks_msec()})
	set_state("effect_instances", instances)
	var stacks = get_state("effect_stacks", {})
	stacks[effect_id] = stacks.get(effect_id, 0) + 1
	set_state("effect_stacks", stacks)
	if stacks[effect_id] > 1:
		effect_stacked.emit(effect_id, stacks[effect_id])
	effect_started.emit(effect_id)
	_trigger_linked_effects(effect_id, position)
	await get_tree().create_timer(effect.duration).timeout
	stop_effect(effect_id)
	return true

func stop_effect(effect_id: String) -> bool:
	if effect_id not in particle_effects:
		return false
	var effect = particle_effects[effect_id]
	effect.current_instances = max(0, effect.current_instances - 1)
	var active = get_state("active_effects", [])
	active.erase(effect_id)
	set_state("active_effects", active)
	var stacks = get_state("effect_stacks", {})
	if effect_id in stacks:
		stacks[effect_id] = max(0, stacks[effect_id] - 1)
		set_state("effect_stacks", stacks)
	effect_ended.emit(effect_id)
	emit_event("effect_stopped", effect_id)
	return true

func _pool_effect(effect_id: String) -> void:
	var pool = get_state("effect_pool", {})
	if effect_id not in pool:
		pool[effect_id] = 0
	pool[effect_id] += 1
	set_state("effect_pool", pool)

func _trigger_linked_effects(effect_id: String, position: Vector3) -> void:
	var effect = particle_effects[effect_id]
	for linked_id in effect.linked_effects:
		await get_tree().create_timer(0.05).timeout
		play_effect(linked_id, position)

func get_effect(effect_id: String) -> ParticleEffect:
	return particle_effects.get(effect_id, null)

func get_effects_by_type(effect_type: String) -> Array[ParticleEffect]:
	var results: Array[ParticleEffect] = []
	for effect in particle_effects.values():
		if effect.effect_type == effect_type:
			results.append(effect)
	return results

func get_active_effects() -> Array:
	return get_state("active_effects", [])

func set_effect_color(effect_id: String, color: Color) -> bool:
	if effect_id in particle_effects:
		particle_effects[effect_id].color = color
		return true
	return false

func set_effect_scale(effect_id: String, scale: float) -> bool:
	if effect_id in particle_effects:
		particle_effects[effect_id].scale = clampf(scale, 0.1, 10.0)
		return true
	return false

func set_effect_speed(effect_id: String, speed: float) -> bool:
	if effect_id in particle_effects:
		particle_effects[effect_id].speed = clampf(speed, 0.1, 5.0)
		return true
	return false

func get_effect_instances(effect_id: String) -> int:
	if effect_id in particle_effects:
		return particle_effects[effect_id].current_instances
	return 0

func get_effect_stack_count(effect_id: String) -> int:
	var stacks = get_state("effect_stacks", {})
	return stacks.get(effect_id, 0)

func get_pooled_effects() -> Dictionary:
	return get_state("effect_pool", {})

func get_effect_instances_list() -> Array:
	return get_state("effect_instances", [])

func get_effect_text() -> String:
	var active = get_active_effects()
	var total_instances = 0
	for effect_id in active:
		total_instances += get_effect_instances(effect_id)
	var text = "Effects: %d active | %d instances" % [active.size(), total_instances]
	return text

func get_particle_statistics() -> Dictionary:
	var instances = get_state("effect_instances", [])
	var pooled = get_state("effect_pool", {})
	var total_pooled = 0
	for count in pooled.values():
		total_pooled += count
	return {
		"total_effects_defined": particle_effects.size(),
		"active_effects": get_active_effects().size(),
		"effect_instances_recorded": instances.size(),
		"effects_pooled": total_pooled,
		"effect_types_pooled": pooled.size(),
		"total_stacks": get_state("effect_stacks", {}).size()
	}
