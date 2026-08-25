extends CanvasLayer

class_name MinimapSimple

@export var minimap_size: Vector2 = Vector2(200, 200)
@export var world_size: float = 1000.0
@export var player_color: Color = Color.BLUE
@export var npc_color: Color = Color.GREEN
@export var enemy_color: Color = Color.RED

@onready var minimap_panel: Panel = $MinimapPanel
@onready var minimap_draw: Control = $MinimapPanel/MinimapDraw

var player: Node3D = null
var npcs: Array[Node3D] = []
var enemies: Array[Node3D] = []
var visibility_toggle_history: Array = []
var peak_npc_count: int = 0
var peak_enemy_count: int = 0

func _ready() -> void:
	if minimap_panel:
		minimap_panel.size = minimap_size
		minimap_panel.position = Vector2(10, 10)

	if minimap_draw:
		minimap_draw.size = minimap_size
		minimap_draw.queue_redraw()

func _process(_delta: float) -> void:
	_find_entities()
	if minimap_draw:
		minimap_draw.queue_redraw()

func _find_entities() -> void:
	if player == null:
		for entity in get_tree().get_nodes_in_group("player"):
			player = entity
			break

	npcs = get_tree().get_nodes_in_group("npcs")
	enemies = get_tree().get_nodes_in_group("enemies")
	peak_npc_count = maxi(peak_npc_count, npcs.size())
	peak_enemy_count = maxi(peak_enemy_count, enemies.size())

func _draw_minimap() -> void:
	if minimap_draw == null:
		return

	minimap_draw.draw_rect(Rect2(Vector2.ZERO, minimap_size), Color.BLACK)

	if player:
		var player_pos = _world_to_minimap(player.global_position)
		minimap_draw.draw_circle(player_pos, 4, player_color)

	for npc in npcs:
		if is_instance_valid(npc):
			var npc_pos = _world_to_minimap(npc.global_position)
			minimap_draw.draw_circle(npc_pos, 3, npc_color)

	for enemy in enemies:
		if is_instance_valid(enemy):
			var enemy_pos = _world_to_minimap(enemy.global_position)
			minimap_draw.draw_circle(enemy_pos, 3, enemy_color)

func _world_to_minimap(world_pos: Vector3) -> Vector2:
	var normalized_x = (world_pos.x / world_size + 0.5) * minimap_size.x
	var normalized_z = (world_pos.z / world_size + 0.5) * minimap_size.y
	return Vector2(normalized_x, normalized_z)

func set_minimap_visible(visible: bool) -> void:
	if minimap_panel:
		minimap_panel.visible = visible
		visibility_toggle_history.append({"visible": visible, "time": Time.get_ticks_msec()})
		if visibility_toggle_history.size() > 50:
			visibility_toggle_history.pop_front()

func get_minimap_statistics() -> Dictionary:
	return {
		"tracked_npcs": npcs.size(),
		"tracked_enemies": enemies.size(),
		"peak_npc_count": peak_npc_count,
		"peak_enemy_count": peak_enemy_count,
		"has_player": player != null,
		"visibility_toggles": visibility_toggle_history.size(),
		"is_visible": minimap_panel.visible if minimap_panel else false
	}
