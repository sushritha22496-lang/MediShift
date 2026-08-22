extends EnemyBase
class_name BossIndrajit

# ─── Indrajit / Meghnaad — Invisible attacks, 3 phases ───────────────────────
var is_invisible: bool = false
var invisibility_timer: float = 0.0
var nagapasha_used: bool = false
var shakti_used: bool = false

enum IndrajitPhase { VISIBLE, INVISIBLE, NAGAPASHA }
var indrajit_phase: IndrajitPhase = IndrajitPhase.VISIBLE

func _ready() -> void:
	super._ready()
	enemy_name = "Indrajit"
	max_health = 3000.0
	health = max_health
	attack_damage = 50.0
	move_speed = 200.0
	is_flying_enemy = true
	score_value = 15000

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_handle_invisibility(delta)

func _handle_invisibility(delta: float) -> void:
	if is_invisible:
		invisibility_timer -= delta
		if invisibility_timer <= 0.0:
			_become_visible()
		sprite.modulate.a = 0.15
	else:
		sprite.modulate.a = 1.0

func _state_chase(delta: float) -> void:
	super._state_chase(delta)
	var hp_ratio := health / max_health
	if hp_ratio < 0.6 and not is_invisible and attack_cooldown <= 0.0:
		_go_invisible()
	if hp_ratio < 0.3 and not nagapasha_used:
		_use_nagapasha()

func _go_invisible() -> void:
	is_invisible = true
	invisibility_timer = 4.0
	indrajit_phase = IndrajitPhase.INVISIBLE
	attack_cooldown = 2.0
	_strike_from_shadow()

func _become_visible() -> void:
	is_invisible = false
	indrajit_phase = IndrajitPhase.VISIBLE

func _strike_from_shadow() -> void:
	await get_tree().create_timer(2.0).timeout
	if not player or is_dead:
		return
	global_position = player.global_position + Vector2(randf_range(-100, 100), -50)
	if player.has_method("take_damage"):
		player.take_damage(attack_damage * 1.5, global_position)
	_become_visible()

func _use_nagapasha() -> void:
	nagapasha_used = true
	indrajit_phase = IndrajitPhase.NAGAPASHA
	_play_anim("nagapasha")
	await get_tree().create_timer(1.5).timeout
	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if p.has_method("take_damage"):
			p.take_damage(attack_damage * 2.0, global_position)

func _die() -> void:
	GameManager.bosses_defeated.append("indrajit")
	super._die()
