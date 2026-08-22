extends EnemyBase
class_name BossKumbhakarna

# ─── Kumbhakarna — Giant, climb-and-attack mechanic ───────────────────────────
var is_asleep: bool = true
var wake_hits: int = 0
const WAKE_HITS_REQUIRED := 10

signal woke_up()
signal player_can_climb()

func _ready() -> void:
	super._ready()
	enemy_name = "Kumbhakarna"
	max_health = 5000.0
	health = max_health
	attack_damage = 80.0
	move_speed = 80.0
	score_value = 20000
	scale = Vector2(4.0, 4.0)
	_play_anim("sleeping")

func take_damage(amount: float, source_pos: Vector2) -> void:
	if is_asleep:
		wake_hits += 1
		health -= amount * 0.1
		if wake_hits >= WAKE_HITS_REQUIRED:
			_wake_up()
		return
	super.take_damage(amount, source_pos)

func _wake_up() -> void:
	is_asleep = false
	_play_anim("waking")
	AudioManager.play_sfx("boss_roar")
	woke_up.emit()
	await get_tree().create_timer(2.0).timeout
	state = State.CHASE
	player_can_climb.emit()

func _state_chase(delta: float) -> void:
	super._state_chase(delta)
	# Stomp attack periodically
	if attack_cooldown <= 0.0:
		_stomp()

func _stomp() -> void:
	attack_cooldown = 3.0
	_play_anim("stomp")
	await get_tree().create_timer(0.6).timeout
	var range_check := 400.0
	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if global_position.distance_to(p.global_position) < range_check:
			if p.has_method("take_damage"):
				p.take_damage(attack_damage, global_position)
	AudioManager.play_sfx("explosion")

func _die() -> void:
	GameManager.bosses_defeated.append("kumbhakarna")
	super._die()
