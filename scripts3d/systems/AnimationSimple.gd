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
	set_state("animation_history", [])
	set_state("animation_blending", {})
	set_state("frame_tracking", {})
	set_state("animation_speed_variations", {})
	set_state("entity_animation_states", {})
	set_state("interrupt_history", [])
	set_state("animation_performance", {})
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

func record_animation_history(animation_id: String, duration_ms: int) -> void:
	var history = get_state("animation_history", [])
	history.append({"animation": animation_id, "duration": duration_ms, "time": Time.get_ticks_msec()})
	if history.size() > 100:
		history.pop_front()
	set_state("animation_history", history)

func set_animation_blend(source_id: String, target_id: String, blend_time: float) -> void:
	var blending = get_state("animation_blending", {})
	blending["%s_%s" % [source_id, target_id]] = {"source": source_id, "target": target_id, "blend_time": blend_time}
	set_state("animation_blending", blending)

func set_animation_speed(animation_id: String, speed: float) -> void:
	var speeds = get_state("animation_speed_variations", {})
	speeds[animation_id] = speed
	set_state("animation_speed_variations", speeds)

func get_animation_speed(animation_id: String) -> float:
	var speeds = get_state("animation_speed_variations", {})
	return speeds.get(animation_id, 1.0)

func track_frame(animation_id: String, frame: int) -> void:
	var tracking = get_state("frame_tracking", {})
	if animation_id not in tracking:
		tracking[animation_id] = []
	tracking[animation_id].append(frame)
	if tracking[animation_id].size() > 50:
		tracking[animation_id].pop_front()
	set_state("frame_tracking", tracking)

func set_entity_animation_state(entity_id: String, state: String) -> void:
	var states = get_state("entity_animation_states", {})
	states[entity_id] = state
	set_state("entity_animation_states", states)

func record_interrupt(interrupted_id: String, new_id: String) -> void:
	var interrupts = get_state("interrupt_history", [])
	interrupts.append({"interrupted": interrupted_id, "new": new_id, "time": Time.get_ticks_msec()})
	if interrupts.size() > 50:
		interrupts.pop_front()
	set_state("interrupt_history", interrupts)

func record_animation_performance(animation_id: String, fps: float, load_time_ms: int) -> void:
	var perf = get_state("animation_performance", {})
	if animation_id not in perf:
		perf[animation_id] = []
	perf[animation_id].append({"fps": fps, "load": load_time_ms, "time": Time.get_ticks_msec()})
	if perf[animation_id].size() > 30:
		perf[animation_id].pop_front()
	set_state("animation_performance", perf)

func get_animation_history() -> Array:
	return get_state("animation_history", [])

func get_interrupt_count() -> int:
	return get_state("interrupt_history", []).size()
