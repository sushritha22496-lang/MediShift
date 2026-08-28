extends Node3D

class_name CombatFeedbackManager

static var camera: Camera3D = null
static var last_shake_time: float = 0.0

# Shake settings
const SHAKE_DURATION = 0.2
const SHAKE_INTENSITY_LOW = 0.15
const SHAKE_INTENSITY_MED = 0.3
const SHAKE_INTENSITY_HIGH = 0.6

static func initialize(game_camera: Camera3D) -> void:
	camera = game_camera

static func play_hit_feedback(hit_position: Vector3, damage: int = 10, critical: bool = false) -> void:
	# Visual effects
	if critical:
		CombatVisualEffects.play_critical_hit(hit_position, _get_world())
		_screen_shake(SHAKE_INTENSITY_HIGH, 0.25)
	else:
		CombatVisualEffects.play_hit_effect(hit_position, _get_world(), damage)
		_screen_shake(SHAKE_INTENSITY_MED, SHAKE_DURATION)

	# Audio hook
	_play_impact_sound(hit_position, critical)

static func play_block_feedback(blocker_pos: Vector3) -> void:
	CombatVisualEffects.play_block_effect(blocker_pos, _get_world())
	_screen_shake(SHAKE_INTENSITY_LOW, 0.15)
	_play_block_sound(blocker_pos)

static func play_heal_feedback(healed_pos: Vector3, amount: int) -> void:
	CombatVisualEffects.play_heal_effect(healed_pos, _get_world(), amount)
	_play_heal_sound(healed_pos)

static func play_attack_feedback(attacker: Node3D, weapon: String = "sword") -> void:
	CombatVisualEffects.play_attack_animation(attacker, weapon)
	_play_attack_sound(attacker.global_position, weapon)

static func _screen_shake(intensity: float, duration: float) -> void:
	if not camera:
		return

	# Prevent shake spam
	if Time.get_ticks_msec() - last_shake_time < 50:
		return

	last_shake_time = Time.get_ticks_msec()
	camera.apply_screen_shake(intensity, duration)

static func _play_impact_sound(position: Vector3, critical: bool) -> void:
	# Audio hook - implement when audio system is ready
	if critical:
		print("[AUDIO] Critical hit impact at: ", position)
	else:
		print("[AUDIO] Hit impact at: ", position)

static func _play_block_sound(position: Vector3) -> void:
	print("[AUDIO] Block sound at: ", position)

static func _play_attack_sound(position: Vector3, weapon: String) -> void:
	print("[AUDIO] %s attack sound at: " % weapon, position)

static func _play_heal_sound(position: Vector3) -> void:
	print("[AUDIO] Heal sound at: ", position)

static func _get_world() -> Node3D:
	# Return scene root for particle placement
	if camera and camera.get_tree():
		return camera.get_tree().root
	return Node3D.new()

# Public API for combat system
static func on_attack_landed(attacker: Node3D, defender: Node3D, damage: int, is_critical: bool = false) -> void:
	var hit_pos = defender.global_position + Vector3(0, 1, 0)
	play_hit_feedback(hit_pos, damage, is_critical)
	if defender.has_method("add_impact_feedback"):
		defender.add_impact_feedback(float(damage) / 20.0)

static func on_block(blocker: Node3D) -> void:
	play_block_feedback(blocker.global_position)

static func on_heal(target: Node3D, amount: int) -> void:
	play_heal_feedback(target.global_position + Vector3(0, 1, 0), amount)

static func on_death(character: Node3D) -> void:
	_screen_shake(SHAKE_INTENSITY_HIGH, 0.3)
	# Fade character
	if character.has_node("Model"):
		var tween = character.create_tween()
		tween.tween_property(character.get_node("Model"), "modulate:a", 0.3, 1.0)
