extends BaseSystemSimple

class_name ParticleEffectsSimple

class ParticleEffect:
	var id: String
	var name: String
	var effect_type: String
	var duration: float
	var intensity: float
	func _init(p_id: String, p_name: String, p_type: String, p_duration: float, p_intensity: float = 1.0) -> void:
		id = p_id
		name = p_name
		effect_type = p_type
		duration = p_duration
		intensity = p_intensity

var particle_effects: Dictionary = {}

signal effect_started(effect_id: String)
signal effect_ended(effect_id: String)

func _ready() -> void:
	set_state("active_effects", [])
	_initialize_effects()

func _initialize_effects() -> void:
	particle_effects = {
		"explosion": ParticleEffect.new("explosion", "Explosion", "combat", 0.8, 1.0),
		"fireball": ParticleEffect.new("fireball", "Fireball", "spell", 1.2, 0.9),
		"heal_aura": ParticleEffect.new("heal_aura", "Heal Aura", "healing", 1.0, 0.7),
		"power_up": ParticleEffect.new("power_up", "Power Up", "buff", 0.6, 0.8),
		"death_particles": ParticleEffect.new("death_particles", "Death", "death", 1.5, 1.0),
		"critical_hit": ParticleEffect.new("critical_hit", "Critical Hit", "combat", 0.5, 1.2),
		"dodge_flash": ParticleEffect.new("dodge_flash", "Dodge", "movement", 0.3, 0.6),
		"level_up_shine": ParticleEffect.new("level_up_shine", "Level Up", "progression", 1.0, 1.0)
	}

func play_effect(effect_id: String, position: Vector3 = Vector3.ZERO) -> bool:
	if effect_id in particle_effects:
		var active = get_state("active_effects", [])
		active.append(effect_id)
		set_state("active_effects", active)
		effect_started.emit(effect_id)
		emit_event("effect_played", effect_id)
		
		var effect = particle_effects[effect_id]
		await get_tree().create_timer(effect.duration).timeout
		stop_effect(effect_id)
		return true
	return false

func stop_effect(effect_id: String) -> bool:
	var active = get_state("active_effects", [])
	if effect_id in active:
		active.erase(effect_id)
		set_state("active_effects", active)
		effect_ended.emit(effect_id)
		emit_event("effect_stopped", effect_id)
		return true
	return false

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

func get_effect_text() -> String:
	var active = get_active_effects()
	var text = "Particle Effects\nActive: %d\n" % active.size()
	for effect_id in active:
		text += "- %s\n" % particle_effects[effect_id].name
	return text
