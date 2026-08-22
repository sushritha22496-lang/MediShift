extends EnemyBase
class_name BossRavana

# ─── Ravana — 10 Heads, 7 Phases ─────────────────────────────────────────────
@export var phase_thresholds: Array[float] = [0.86, 0.72, 0.58, 0.44, 0.30, 0.15, 0.0]

var current_phase: int = 0
var heads_active: int = 10
var phase_triggered: bool = false
var arrow_scene: PackedScene
var clone_scene: PackedScene

enum BossPhase {
	GROUND_SLAM,       # 86-100%
	ARROW_RAIN,        # 72-86%
	SUMMON_ARMY,       # 58-72%
	ILLUSION_COPIES,   # 44-58%
	BRAHMASTRA_CHARGE, # 30-44%
	CHARIOT_BATTLE,    # 15-30%
	NAVEL_EXPOSED      # 0-15% - WEAK POINT
}

signal phase_changed(phase: int, heads: int)
signal head_destroyed(heads_remaining: int)

func _ready() -> void:
	super._ready()
	enemy_name = "Ravana"
	max_health = 10000.0
	health = max_health
	attack_damage = 60.0
	move_speed = 100.0
	score_value = 50000
	AudioManager.play_sfx("boss_roar")

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_check_phase_transition()
	super._physics_process(delta)

func _check_phase_transition() -> void:
	var hp_ratio := health / max_health
	for i in phase_thresholds.size():
		if hp_ratio <= phase_thresholds[i] and current_phase <= i and not phase_triggered:
			_enter_phase(i + 1)
			return

func _enter_phase(phase: int) -> void:
	if phase > 7:
		return
	phase_triggered = true
	current_phase = phase
	heads_active = max(10 - phase, 1)
	phase_changed.emit(phase, heads_active)
	head_destroyed.emit(heads_active)
	AudioManager.play_sfx("boss_roar")
	_phase_intro(phase)
	await get_tree().create_timer(2.0).timeout
	phase_triggered = false

func _phase_intro(phase: int) -> void:
	match phase:
		1: _setup_ground_slam()
		2: _setup_arrow_rain()
		3: _setup_summon()
		4: _setup_illusions()
		5: _setup_brahmastra()
		6: _setup_chariot()
		7: _setup_navel_phase()

# ─── Phase 1: Ground Slam ─────────────────────────────────────────────────────
func _setup_ground_slam() -> void:
	pass

func _do_ground_slam() -> void:
	velocity.y = -800.0
	await get_tree().create_timer(0.5).timeout
	var shockwave_range := 300.0
	var bodies := get_tree().get_nodes_in_group("player")
	for body in bodies:
		if global_position.distance_to(body.global_position) <= shockwave_range:
			if body.has_method("take_damage"):
				body.take_damage(attack_damage * 1.5, global_position)
	AudioManager.play_sfx("explosion")

# ─── Phase 2: Arrow Rain ──────────────────────────────────────────────────────
func _setup_arrow_rain() -> void:
	_start_arrow_rain()

func _start_arrow_rain() -> void:
	for i in 12:
		await get_tree().create_timer(0.15).timeout
		_fire_arrow(Vector2(randf_range(-500, 500), -600))

func _fire_arrow(target_offset: Vector2) -> void:
	if not player:
		return
	var target := player.global_position + target_offset
	pass

# ─── Phase 3: Summon Army ─────────────────────────────────────────────────────
func _setup_summon() -> void:
	for i in 6:
		await get_tree().create_timer(0.3).timeout
		_spawn_minion()

func _spawn_minion() -> void:
	pass

# ─── Phase 4: Illusion Copies ────────────────────────────────────────────────
func _setup_illusions() -> void:
	for i in 3:
		_create_illusion(i)

func _create_illusion(_idx: int) -> void:
	pass

# ─── Phase 5: Brahmastra Charge ───────────────────────────────────────────────
func _setup_brahmastra() -> void:
	_play_anim("brahmastra_charge")
	await get_tree().create_timer(3.0).timeout
	_fire_brahmastra()

func _fire_brahmastra() -> void:
	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if p.has_method("take_damage"):
			p.take_damage(attack_damage * 2.0, global_position)

# ─── Phase 6: Chariot Battle ──────────────────────────────────────────────────
func _setup_chariot() -> void:
	move_speed = 250.0
	is_flying_enemy = true

# ─── Phase 7: Navel Exposed (Weak Point) ─────────────────────────────────────
func _setup_navel_phase() -> void:
	move_speed = 60.0
	attack_damage *= 2.0
	_play_anim("navel_exposed")

func _state_special(delta: float) -> void:
	match current_phase:
		1: _phase1_logic(delta)
		2: _phase2_logic(delta)
		3: _phase3_logic(delta)
		4: _phase4_logic(delta)
		5: _phase5_logic(delta)
		6: _phase6_logic(delta)
		7: _phase7_logic(delta)

func _phase1_logic(_delta: float) -> void:
	if player and attack_cooldown <= 0.0:
		_do_ground_slam()
		attack_cooldown = 3.0

func _phase2_logic(_delta: float) -> void:
	if attack_cooldown <= 0.0:
		_start_arrow_rain()
		attack_cooldown = 5.0

func _phase3_logic(_delta: float) -> void:
	_setup_summon()

func _phase4_logic(_delta: float) -> void:
	pass

func _phase5_logic(_delta: float) -> void:
	pass

func _phase6_logic(_delta: float) -> void:
	if player:
		var dir: float = sign(player.global_position.x - global_position.x)
		velocity.x = dir * move_speed

func _phase7_logic(_delta: float) -> void:
	if player and attack_cooldown <= 0.0:
		var dist := global_position.distance_to(player.global_position)
		if dist < 200.0 and player.has_method("take_damage"):
			player.take_damage(attack_damage * 3.0, global_position)
			attack_cooldown = 2.0

func _die() -> void:
	AudioManager.play_bgm("victory")
	GameManager.set_flag("ravana_dead")
	GameManager.bosses_defeated.append("ravana")
	super._die()
