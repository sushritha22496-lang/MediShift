extends EnemyBase
class_name BossSurasa

# ─── Surasa — Shrink-to-escape mechanic ───────────────────────────────────────
var mouth_open: bool = false
var mouth_size: float = 1.0
var player_inside: bool = false
var escaped: bool = false

signal player_must_shrink()
signal puzzle_solved()

func _ready() -> void:
	super._ready()
	enemy_name = "Surasa"
	max_health = 500.0
	health = max_health
	score_value = 3000
	attack_damage = 0.0
	_start_mouth_challenge()

func _start_mouth_challenge() -> void:
	await get_tree().create_timer(1.5).timeout
	_open_mouth_cycle()

func _open_mouth_cycle() -> void:
	while not escaped and not is_dead:
		mouth_open = true
		mouth_size = 1.0
		anim.play("mouth_open")
		player_must_shrink.emit()
		await get_tree().create_timer(0.5).timeout
		mouth_size = 2.0
		await get_tree().create_timer(0.5).timeout
		mouth_size = 3.0
		await get_tree().create_timer(0.5).timeout
		mouth_size = 4.0
		await get_tree().create_timer(0.5).timeout
		mouth_open = false
		anim.play("mouth_close")
		await get_tree().create_timer(2.0).timeout

func _physics_process(delta: float) -> void:
	if escaped:
		return
	super._physics_process(delta)
	_check_player_escape()

func _check_player_escape() -> void:
	if not player or not mouth_open:
		return
	# Player must be Anima (tiny) to escape
	var is_tiny := player.is_anima if player.has("is_anima") else false
	if is_tiny and mouth_open and mouth_size >= 3.0:
		_handle_escape()

func _handle_escape() -> void:
	escaped = true
	puzzle_solved.emit()
	anim.play("defeated")
	await get_tree().create_timer(1.0).timeout
	AudioManager.play_sfx("power_unlock")
	_die()

func _die() -> void:
	GameManager.bosses_defeated.append("surasa")
	GameManager.add_score(score_value)
	super._die()
