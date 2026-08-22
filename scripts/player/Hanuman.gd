extends CharacterBody2D

# ─── Constants ────────────────────────────────────────────────────────────────
const WALK_SPEED       := 280.0
const RUN_SPEED        := 460.0
const JUMP_FORCE       := -700.0
const DOUBLE_JUMP_FORCE:= -600.0
const FLY_SPEED        := 500.0
const DASH_SPEED       := 900.0
const DASH_DURATION    := 0.18
const GRAVITY          := 980.0
const COYOTE_TIME      := 0.12
const JUMP_BUFFER_TIME := 0.10
const MAX_JUMPS        := 2
const CLIMB_SPEED      := 200.0
const WALL_SLIDE_SPEED := 80.0
const MAHIMA_SCALE     := Vector2(3.0, 3.0)
const ANIMA_SCALE      := Vector2(0.3, 0.3)
const NORMAL_SCALE     := Vector2(1.0, 1.0)
const SCALE_SPEED      := 4.0

# ─── Stats ────────────────────────────────────────────────────────────────────
@export var max_health: float = 200.0
@export var gada_damage: float = 35.0
@export var heavy_damage: float = 80.0
@export var spin_damage: float = 50.0
@export var tail_damage: float = 40.0

var health: float
var jumps_left: int = MAX_JUMPS
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dash_timer: float = 0.0
var attack_cooldown: float = 0.0
var heavy_hold_timer: float = 0.0
var is_attacking: bool = false
var is_dashing: bool = false
var is_flying: bool = false
var is_climbing: bool = false
var is_mahima: bool = false
var is_anima: bool = false
var is_garima: bool = false
var on_wall: bool = false
var facing_right: bool = true
var rage_meter: float = 0.0
var fly_energy: float = 100.0

# ─── Cheat/Power Flags ────────────────────────────────────────────────────────
var god_mode: bool = false
var infinite_fly: bool = false
var fire_mode_permanent: bool = false
var one_hit_kill: bool = false
var gada_damage_multiplier: float = 1.0
var speed_multiplier: float = 1.0

# ─── Nodes ────────────────────────────────────────────────────────────────────
@onready var sprite: Node2D = $Sprite
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var tail_hitbox: Area2D = $TailHitbox
@onready var body_hitbox: CollisionShape2D = $CollisionShape2D
@onready var climb_detector: RayCast2D = $ClimbDetector
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var wall_detector_l: RayCast2D = $WallDetectorL
@onready var wall_detector_r: RayCast2D = $WallDetectorR
@onready var particles_dash: GPUParticles2D = $Particles/Dash
@onready var particles_fly: GPUParticles2D = $Particles/Fly
@onready var particles_fire: GPUParticles2D = $Particles/Fire
@onready var hud: CanvasLayer = $"../HUD"

# ─── Signals ──────────────────────────────────────────────────────────────────
signal health_changed(current: float, maximum: float)
signal died()
signal rage_filled()
signal rage_changed(current: float)
signal power_used(power: String)

func _play_anim(anim_name: String) -> void:
	if anim.has_animation(anim_name):
		anim.play(anim_name)

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("player")
	health = max_health
	attack_hitbox.monitoring = false
	tail_hitbox.monitoring = false
	attack_hitbox.body_entered.connect(_on_hit_body)
	tail_hitbox.body_entered.connect(_on_tail_hit)
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.DIALOGUE:
		velocity.x = 0.0
		move_and_slide()
		return
	if GameManager.current_state == GameManager.GameState.CUTSCENE:
		return

	_handle_timers(delta)
	_handle_powers_input()
	_handle_movement(delta)
	_handle_jump(delta)
	_handle_fly(delta)
	_handle_climb()
	_handle_attack(delta)
	_handle_scale_transition(delta)
	_update_animation()
	move_and_slide()
	_check_hazards()

# ─── Timers ───────────────────────────────────────────────────────────────────
func _handle_timers(delta: float) -> void:
	if not is_on_floor():
		coyote_timer -= delta
	else:
		coyote_timer = COYOTE_TIME
		jumps_left = MAX_JUMPS
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	if dash_timer > 0.0:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
	if fly_energy < 100.0 and not is_flying:
		fly_energy = minf(fly_energy + 20.0 * delta, 100.0)
	if GameManager.has_power("sanjeevani_aura") and health < max_health and health > 0.0:
		health = minf(health + 3.0 * delta, max_health)
		health_changed.emit(health, max_health)

# ─── Movement ────────────────────────────────────────────────────────────────
func _handle_movement(delta: float) -> void:
	if is_dashing:
		velocity.x = DASH_SPEED * (1.0 if facing_right else -1.0) * speed_multiplier
		return

	var dir: float = Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		facing_right = dir > 0.0
		sprite.scale.x = 1.0 if facing_right else -1.0
		attack_hitbox.scale.x = 1.0 if facing_right else -1.0
		tail_hitbox.scale.x = 1.0 if facing_right else -1.0

	var spd: float = RUN_SPEED if Input.is_action_pressed("dash") else WALK_SPEED
	spd *= speed_multiplier
	if is_mahima:
		spd *= 0.7
	if is_anima:
		spd *= 1.4
	if is_garima:
		spd *= 0.4

	if not is_flying and not is_climbing:
		velocity.x = lerpf(velocity.x, dir * spd, 12.0 * delta)
		if not is_on_floor():
			velocity.y += GRAVITY * delta
	elif is_climbing:
		velocity.x = dir * CLIMB_SPEED
		var vert: float = Input.get_axis("move_up", "move_down") if false else 0.0
		if Input.is_action_pressed("jump"):
			velocity.y = -CLIMB_SPEED
		else:
			velocity.y = 0.0

	if Input.is_action_just_pressed("dash") and not is_dashing and GameManager.has_power("vayuvega"):
		_do_dash()

# ─── Jump ─────────────────────────────────────────────────────────────────────
func _handle_jump(delta: float) -> void:
	if is_flying or is_climbing:
		return
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME

	if jump_buffer_timer > 0.0:
		if is_on_floor() or coyote_timer > 0.0:
			_do_jump(JUMP_FORCE)
		elif jumps_left > 0 and GameManager.has_power("fly"):
			_do_jump(DOUBLE_JUMP_FORCE)

func _do_jump(force: float) -> void:
	velocity.y = force
	jumps_left -= 1
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	AudioManager.play_sfx("jump" if jumps_left == MAX_JUMPS - 1 else "double_jump")
	_play_anim("jump")

func _do_dash() -> void:
	is_dashing = true
	dash_timer = DASH_DURATION
	AudioManager.play_sfx("dash")
	if particles_dash:
		particles_dash.emitting = true

# ─── Fly ──────────────────────────────────────────────────────────────────────
func _handle_fly(delta: float) -> void:
	if not GameManager.has_power("fly"):
		return
	if Input.is_action_pressed("fly") and (fly_energy > 0.0 or infinite_fly):
		is_flying = true
		var dir_x: float = Input.get_axis("move_left", "move_right")
		var dir_y: float = 0.0
		if Input.is_action_pressed("jump"):
			dir_y = -1.0
		elif Input.is_action_pressed("move_down"):
			dir_y = 1.0
		velocity = Vector2(dir_x, dir_y).normalized() * FLY_SPEED * speed_multiplier
		if not infinite_fly:
			fly_energy -= 25.0 * delta
			if fly_energy <= 0.0:
				fly_energy = 0.0
				is_flying = false
		if particles_fly:
			particles_fly.emitting = true
	else:
		if is_flying:
			is_flying = false
			if particles_fly:
				particles_fly.emitting = false

# ─── Climb ───────────────────────────────────────────────────────────────────
func _handle_climb() -> void:
	if climb_detector:
		climb_detector.target_position.x = absf(climb_detector.target_position.x) * (1.0 if facing_right else -1.0)
	if climb_detector and climb_detector.is_colliding():
		on_wall = true
		if Input.is_action_pressed("jump") or Input.is_action_pressed("move_up"):
			is_climbing = true
			velocity.y = -CLIMB_SPEED
	else:
		on_wall = false
		is_climbing = false

	if is_on_wall() and not is_on_floor() and not is_flying:
		var wall_dir: float = -1.0 if wall_detector_l and wall_detector_l.is_colliding() else 1.0
		if (wall_dir < 0 and Input.is_action_pressed("move_left")) or \
		   (wall_dir > 0 and Input.is_action_pressed("move_right")):
			velocity.y = WALL_SLIDE_SPEED

# ─── Powers Input ─────────────────────────────────────────────────────────────
func _handle_powers_input() -> void:
	if Input.is_action_just_pressed("mahima") and GameManager.has_power("mahima"):
		_toggle_mahima()
	if Input.is_action_just_pressed("anima") and GameManager.has_power("anima"):
		_toggle_anima()
	if Input.is_action_just_pressed("tail_fire") and \
	   (GameManager.has_power("tail_fire") or fire_mode_permanent):
		_activate_tail_fire()
	if Input.is_action_just_pressed("garima") and GameManager.has_power("garima"):
		_toggle_garima()
	if Input.is_action_just_pressed("rage") and rage_meter >= 100.0:
		use_rage()

func _toggle_mahima() -> void:
	if is_anima:
		return
	is_mahima = !is_mahima
	AudioManager.play_sfx("mahima")
	power_used.emit("mahima")

func _toggle_anima() -> void:
	if is_mahima:
		return
	is_anima = !is_anima
	AudioManager.play_sfx("anima")
	power_used.emit("anima")

func _toggle_garima() -> void:
	is_garima = !is_garima
	AudioManager.play_sfx("mahima")
	power_used.emit("garima")

func _activate_tail_fire() -> void:
	tail_hitbox.monitoring = true
	if particles_fire:
		particles_fire.emitting = true
	AudioManager.play_sfx("tail_fire")
	power_used.emit("tail_fire")
	await get_tree().create_timer(3.0).timeout
	if not fire_mode_permanent:
		tail_hitbox.monitoring = false
		if particles_fire:
			particles_fire.emitting = false

# ─── Scale Transition ─────────────────────────────────────────────────────────
func _handle_scale_transition(delta: float) -> void:
	var target_scale: Vector2
	if is_mahima:
		target_scale = MAHIMA_SCALE
	elif is_anima:
		target_scale = ANIMA_SCALE
	else:
		target_scale = NORMAL_SCALE
	scale = scale.move_toward(target_scale, SCALE_SPEED * delta)

# ─── Attack ───────────────────────────────────────────────────────────────────
func _handle_attack(delta: float) -> void:
	if attack_cooldown > 0.0:
		return

	if Input.is_action_just_pressed("attack"):
		_do_light_attack()
	elif Input.is_action_pressed("heavy_attack"):
		heavy_hold_timer += delta
		if heavy_hold_timer >= 0.6:
			_do_heavy_attack()
			heavy_hold_timer = 0.0
	else:
		heavy_hold_timer = 0.0

var current_attack_damage: float = 0.0

func _do_light_attack() -> void:
	is_attacking = true
	attack_cooldown = 0.35
	current_attack_damage = gada_damage * gada_damage_multiplier
	attack_hitbox.monitoring = true
	AudioManager.play_sfx("gada_swing")
	_play_anim("attack_light")
	await get_tree().create_timer(0.25).timeout
	attack_hitbox.monitoring = false
	is_attacking = false

func _do_heavy_attack() -> void:
	is_attacking = true
	attack_cooldown = 0.8
	current_attack_damage = heavy_damage * gada_damage_multiplier
	attack_hitbox.monitoring = true
	AudioManager.play_sfx("gada_heavy")
	_play_anim("attack_heavy")
	await get_tree().create_timer(0.5).timeout
	attack_hitbox.monitoring = false
	is_attacking = false

func _on_hit_body(body: Node2D) -> void:
	if body.has_method("take_damage"):
		var dmg := current_attack_damage if not one_hit_kill else 99999.0
		body.take_damage(dmg, global_position)
		AudioManager.play_sfx("gada_hit")
		add_rage(10.0)
		if hud and hud.has_method("add_combo"):
			hud.add_combo()

func _on_tail_hit(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(tail_damage, global_position)
		if body.has_method("set_on_fire"):
			body.set_on_fire()

# ─── Rage ─────────────────────────────────────────────────────────────────────
func add_rage(amount: float) -> void:
	rage_meter = minf(rage_meter + amount, 100.0)
	rage_changed.emit(rage_meter)
	if rage_meter >= 100.0:
		rage_filled.emit()

func use_rage() -> void:
	if rage_meter < 100.0:
		return
	rage_meter = 0.0
	rage_changed.emit(rage_meter)
	AudioManager.play_sfx("roar")
	_activate_rage_mode()

func _activate_rage_mode() -> void:
	gada_damage_multiplier = 2.5
	speed_multiplier = 1.5
	await get_tree().create_timer(5.0).timeout
	gada_damage_multiplier = 1.0
	speed_multiplier = 1.0

# ─── Health ───────────────────────────────────────────────────────────────────
func take_damage(amount: float, source_pos: Vector2 = Vector2.ZERO) -> void:
	if god_mode or is_dashing:
		return
	if is_garima:
		amount *= 0.7
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	_knockback(source_pos)
	_play_anim("hurt")
	if health <= 0.0:
		_die()

func heal(amount: float) -> void:
	health = minf(health + amount, max_health)
	health_changed.emit(health, max_health)
	AudioManager.play_sfx("sanjeevani")

func _knockback(from: Vector2) -> void:
	if is_garima:
		return
	var dir := (global_position - from).normalized()
	velocity += dir * 300.0

func _die() -> void:
	set_physics_process(false)
	died.emit()
	_play_anim("death")
	await get_tree().create_timer(1.5).timeout
	GameManager.trigger_game_over()

# ─── Hazards ──────────────────────────────────────────────────────────────────
func _check_hazards() -> void:
	if global_position.y > 2000.0:
		take_damage(max_health, global_position)

# ─── Animation ────────────────────────────────────────────────────────────────
func _update_animation() -> void:
	if is_attacking or is_dashing:
		return
	if is_flying:
		_play_anim("fly")
	elif is_climbing:
		_play_anim("climb")
	elif not is_on_floor():
		_play_anim("jump" if velocity.y < 0.0 else "fall")
	elif abs(velocity.x) > 20.0:
		_play_anim("run" if abs(velocity.x) > WALK_SPEED * 0.8 else "walk")
	else:
		_play_anim("idle")
