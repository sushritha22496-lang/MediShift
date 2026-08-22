extends EnemyBase
class_name BossAkshaKumar

# ─── Aksha Kumar — Ravana's young son, fast multi-hit ─────────────────────────
var combo_count: int = 0
const MAX_COMBO := 5

func _ready() -> void:
	super._ready()
	enemy_name = "Aksha Kumar"
	max_health = 1200.0
	health = max_health
	attack_damage = 30.0
	move_speed = 280.0
	score_value = 5000
	is_flying_enemy = true

func _state_attack(delta: float) -> void:
	if is_attacking:
		return
	is_attacking = true
	_do_combo()

func _do_combo() -> void:
	for i in MAX_COMBO:
		await get_tree().create_timer(0.2).timeout
		if is_dead or not player:
			break
		var dist := global_position.distance_to(player.global_position)
		if dist < 120.0 and player.has_method("take_damage"):
			player.take_damage(attack_damage, global_position)
		_play_anim("attack")
		AudioManager.play_sfx("gada_swing")
	attack_cooldown = 1.2
	is_attacking = false
	state = State.CHASE

func _die() -> void:
	GameManager.bosses_defeated.append("aksha_kumar")
	GameManager.set_flag("lanka_burned")
	super._die()
