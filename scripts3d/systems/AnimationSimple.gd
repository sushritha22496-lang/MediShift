extends BaseSystemSimple

class_name AnimationSimple

class Animation:
	var id: String
	var name: String
	var duration: float
	var looping: bool
	var priority: int
	func _init(p_id: String, p_name: String, p_duration: float, p_loop: bool = false, p_priority: int = 0) -> void:
		id = p_id
		name = p_name
		duration = p_duration
		looping = p_loop
		priority = p_priority

var animations: Dictionary = {}

signal animation_started(animation_id: String)
signal animation_ended(animation_id: String)
signal animation_interrupted(animation_id: String, new_animation: String)

func _ready() -> void:
	set_state("current_animation", "")
	set_state("animation_queue", [])
	_initialize_animations()

func _initialize_animations() -> void:
	animations = {
		"idle": Animation.new("idle", "Idle", 1.0, true, 0),
		"walk": Animation.new("walk", "Walk", 0.8, true, 1),
		"run": Animation.new("run", "Run", 0.6, true, 2),
		"attack": Animation.new("attack", "Attack", 0.5, false, 3),
		"hit": Animation.new("hit", "Hit", 0.3, false, 3),
		"cast": Animation.new("cast", "Cast Spell", 0.7, false, 3),
		"fall": Animation.new("fall", "Fall", 1.0, true, 2),
		"death": Animation.new("death", "Death", 1.5, false, 4)
	}

func play_animation(animation_id: String) -> bool:
	if animation_id not in animations:
		return false

	var current = get_state("current_animation", "")
	var anim = animations[animation_id]
	var current_anim = animations.get(current, null) if current != "" else null

	if current_anim and current_anim.priority < anim.priority:
		animation_interrupted.emit(current, animation_id)
		emit_event("animation_interrupted", animation_id)

	set_state("current_animation", animation_id)
	animation_started.emit(animation_id)
	emit_event("animation_started", animation_id)

	if not anim.looping:
		await get_tree().create_timer(anim.duration).timeout
		if get_state("current_animation", "") == animation_id:
			set_state("current_animation", "")
			animation_ended.emit(animation_id)
			emit_event("animation_ended", animation_id)

	return true

func stop_animation() -> void:
	var current = get_state("current_animation", "")
	if current != "":
		animation_ended.emit(current)
		emit_event("animation_ended", current)
	set_state("current_animation", "")

func queue_animation(animation_id: String) -> void:
	var queue = get_state("animation_queue", [])
	queue.append(animation_id)
	set_state("animation_queue", queue)

func get_current_animation() -> Animation:
	var current = get_state("current_animation", "")
	return animations.get(current, null) if current != "" else null

func is_playing(animation_id: String) -> bool:
	return get_state("current_animation", "") == animation_id

func get_animation(animation_id: String) -> Animation:
	return animations.get(animation_id, null)

func get_animation_text() -> String:
	var current = get_current_animation()
	if current:
		return "Animation: %s (%.1fs)" % [current.name, current.duration]
	return "No animation playing"
