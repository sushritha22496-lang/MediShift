extends Node3D

class_name NPCBehaviorEnhancer

class NPCBehavior:
	var name: String
	var priority: int = 0
	var callback: Callable
	var enabled: bool = true

var behaviors: Array[NPCBehavior] = []
var current_behavior: NPCBehavior = null
var behavior_timer: float = 0.0
var npc: CharacterBody3D = null
var animation_blender: AdvancedAnimationBlender = null

func initialize(character: CharacterBody3D) -> void:
	npc = character
	animation_blender = AdvancedAnimationBlender.new()
	add_child(animation_blender)

func add_behavior(name: String, callback: Callable, priority: int = 0) -> void:
	var behavior = NPCBehavior.new()
	behavior.name = name
	behavior.callback = callback
	behavior.priority = priority
	behaviors.append(behavior)
	behaviors.sort_custom(func(a, b): return a.priority > b.priority)

func update_behavior(delta: float) -> void:
	behavior_timer += delta

	if current_behavior and current_behavior.enabled:
		current_behavior.callback.call(delta)
	else:
		_select_next_behavior()

func _select_next_behavior() -> void:
	for behavior in behaviors:
		if behavior.enabled:
			current_behavior = behavior
			behavior_timer = 0.0
			break

func enable_behavior(name: String) -> void:
	for behavior in behaviors:
		if behavior.name == name:
			behavior.enabled = true
			_select_next_behavior()
			break

func disable_behavior(name: String) -> void:
	for behavior in behaviors:
		if behavior.name == name:
			behavior.enabled = false
			if current_behavior == behavior:
				_select_next_behavior()
			break

class InteractionBehavior:
	var target: Node3D = null
	var interaction_range: float = 5.0
	var interaction_type: String = "idle"
	var interaction_duration: float = 2.0

func create_interaction_behavior(target: Node3D, type: String, range_dist: float = 5.0) -> InteractionBehavior:
	var behavior = InteractionBehavior.new()
	behavior.target = target
	behavior.interaction_type = type
	behavior.interaction_range = range_dist
	return behavior

func perform_idle_animation(variation: int = 0) -> void:
	if not animation_blender or not animation_blender.anim_player:
		return

	var idle_anims = ["idle", "idle_fidget", "idle_look_around"]
	var anim = idle_anims[variation % idle_anims.size()]
	animation_blender.play_action_animation(anim)

func perform_attention_animation(target: Node3D) -> void:
	if not npc or not target:
		return

	var direction_to_target = (target.global_position - npc.global_position).normalized()
	npc.model.rotation.y = atan2(direction_to_target.x, direction_to_target.z)
	animation_blender.play_action_animation("idle_look_around")

func perform_approach_animation(target: Node3D, speed: float, delta: float) -> void:
	if not npc or not target:
		return

	var direction = (target.global_position - npc.global_position).normalized()
	direction.y = 0.0

	npc.velocity.x = direction.x * speed
	npc.velocity.z = direction.z * speed

	if direction.length() > 0.1:
		npc.model.rotation.y = atan2(direction.x, direction.z)
		animation_blender.update_movement_animation(npc.velocity, false, delta)

func perform_idle_behavior_varied(delta: float) -> void:
	if randf() < 0.3:
		var variation = randi() % 3
		perform_idle_animation(variation)

func perform_patrol_behavior(patrol_points: Array[Vector3], speed: float, delta: float) -> int:
	if patrol_points.is_empty() or not npc:
		return 0

	var closest_index = 0
	var closest_distance = INF

	for i in range(patrol_points.size()):
		var dist = npc.global_position.distance_to(patrol_points[i])
		if dist < closest_distance:
			closest_distance = dist
			closest_index = i

	if closest_distance < 2.0:
		closest_index = (closest_index + 1) % patrol_points.size()

	var target_pos = patrol_points[closest_index]
	var direction = (target_pos - npc.global_position).normalized()
	direction.y = 0.0

	npc.velocity.x = direction.x * speed
	npc.velocity.z = direction.z * speed

	if direction.length() > 0.1:
		npc.model.rotation.y = atan2(direction.x, direction.z)
		animation_blender.update_movement_animation(npc.velocity, false, delta)

	return closest_index

func perform_random_look(delta: float) -> void:
	if randf() < 0.02 and npc and npc.model:
		var random_angle = randf_range(-PI, PI)
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(npc.model, "rotation:y", random_angle, 0.5)

func perform_dialog_facing(target: Node3D, duration: float = 2.0) -> void:
	if not npc or not target:
		return

	var direction = (target.global_position - npc.global_position).normalized()
	var target_angle = atan2(direction.x, direction.z)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(npc.model, "rotation:y", target_angle, 0.5)
