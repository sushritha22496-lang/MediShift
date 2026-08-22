extends CharacterBody2D
class_name EnemyBase

# ─── Stats ────────────────────────────────────────────────────────────────────
@export var enemy_name: String = "Demon"
@export var max_health: float = 100.0
@export var move_speed: float = 120.0
@export var attack_damage: float = 20.0
@export var attack_range: float = 80.0
@export var detect_range: float = 400.0
@export var score_value: int = 100
@export var is_flying_enemy: bool = false
@export var drop_items: Array[String] = []

var health: float
var is_dead: bool = false
var is_attacking: bool = false
var is_stunned: bool = false
var is_on_fire: bool = false
var stun_timer: float = 0.0
var attack_cooldown: float = 0.0
var player: CharacterBody2D = null
var facing_right: bool = true

const GRAVITY := 980.0

# ─── State Machine ────────────────────────────────────────────────────────────
enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD, SPECIAL }
var state: State = State.IDLE
var patrol_dir: float = 1.0
var patrol_timer: float = 0.0

# ─── Nodes ────────────────────────────────────────────────────────────────────
@onready var sprite: Node2D = $Sprite
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var detect_area: Area2D = $DetectArea
@onready var attack_area: Area2D = $AttackArea
@onready var health_bar: ProgressBar = $HealthBar
@onready var fire_particles: GPUParticles2D = $FireParticles

# ─── Signals ──────────────────────────────────────────────────────────────────
signal died(enemy: EnemyBase)
signal health_changed(current: float, maximum: float)

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	if detect_area:
		detect_area.body_entered.connect(_on_player_detected)
		detect_area.body_exited.connect(_on_player_lost)
	if attack_area:
		attack_area.body_entered.connect(_on_attack_landed)
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_handle_timers(delta)
	_run_state_machine(delta)
	if not is_flying_enemy:
		velocity.y += GRAVITY * delta
	move_and_slide()

func _handle_timers(delta: float) -> void:
	if stun_timer > 0.0:
		stun_timer -= delta
		if stun_timer <= 0.0:
			is_stunned = false
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	if is_on_fire:
		take_damage(5.0 * delta, global_position)

func _run_state_machine(delta: float) -> void:
	if is_stunned:
		velocity.x = lerpf(velocity.x, 0.0, 8.0 * delta)
		return
	match state:
		State.IDLE:    _state_idle(delta)
		State.PATROL:  _state_patrol(delta)
		State.CHASE:   _state_chase(delta)
		State.ATTACK:  _state_attack(delta)
		State.SPECIAL: _state_special(delta)

func _state_idle(delta: float) -> void:
	velocity.x = lerpf(velocity.x, 0.0, 8.0 * delta)
	anim.play("idle")
	patrol_timer -= delta
	if patrol_timer <= 0.0:
		state = State.PATROL
		patrol_timer = randf_range(2.0, 5.0)
		patrol_dir = 1.0 if randf() > 0.5 else -1.0

func _state_patrol(delta: float) -> void:
	velocity.x = patrol_dir * move_speed * 0.5
	facing_right = patrol_dir > 0.0
	sprite.scale.x = 1.0 if facing_right else -1.0
	anim.play("walk")
	if is_on_wall():
		patrol_dir *= -1.0
	patrol_timer -= delta
	if patrol_timer <= 0.0:
		state = State.IDLE
		patrol_timer = randf_range(1.0, 3.0)

func _state_chase(delta: float) -> void:
	if not player:
		state = State.PATROL
		return
	var dist := global_position.distance_to(player.global_position)
	if dist <= attack_range and attack_cooldown <= 0.0:
		state = State.ATTACK
		return
	if dist > detect_range * 1.5:
		state = State.PATROL
		player = null
		return
	var dir: float = sign(player.global_position.x - global_position.x)
	velocity.x = dir * move_speed
	facing_right = dir > 0.0
	sprite.scale.x = 1.0 if facing_right else -1.0
	anim.play("run")
	if is_flying_enemy:
		var vy: float = sign(player.global_position.y - global_position.y) * move_speed
		velocity.y = vy

func _state_attack(delta: float) -> void:
	velocity.x = 0.0
	if is_attacking:
		return
	is_attacking = true
	attack_cooldown = 1.5
	anim.play("attack")
	if attack_area:
		attack_area.monitoring = true
	await get_tree().create_timer(0.4).timeout
	if attack_area:
		attack_area.monitoring = false
	is_attacking = false
	state = State.CHASE

func _state_special(_delta: float) -> void:
	pass

# ─── Damage ───────────────────────────────────────────────────────────────────
func take_damage(amount: float, source_pos: Vector2) -> void:
	if is_dead:
		return
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	if health_bar:
		health_bar.value = health
	_knockback(source_pos)
	is_stunned = true
	stun_timer = 0.3
	anim.play("hurt")
	GameManager.add_score(int(amount))
	if health <= 0.0:
		_die()

func _knockback(from: Vector2) -> void:
	var dir := (global_position - from).normalized()
	velocity = dir * 400.0

func set_on_fire() -> void:
	is_on_fire = true
	if fire_particles:
		fire_particles.emitting = true
	await get_tree().create_timer(5.0).timeout
	is_on_fire = false
	if fire_particles:
		fire_particles.emitting = false

func _die() -> void:
	is_dead = true
	state = State.DEAD
	set_physics_process(false)
	GameManager.enemies_defeated += 1
	GameManager.add_score(score_value)
	AudioManager.play_sfx("enemy_death")
	anim.play("death")
	_spawn_drops()
	died.emit(self)
	await get_tree().create_timer(1.2).timeout
	queue_free()

func _spawn_drops() -> void:
	for item in drop_items:
		pass

# ─── Detection ────────────────────────────────────────────────────────────────
func _on_player_detected(body: Node) -> void:
	if body.is_in_group("player"):
		player = body
		state = State.CHASE

func _on_player_lost(body: Node) -> void:
	if body.is_in_group("player"):
		state = State.PATROL

func _on_attack_landed(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(attack_damage, global_position)
