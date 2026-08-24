extends CanvasLayer

class_name MinimapSystem

@export var minimap_size: Vector2 = Vector2(200, 200)
@export var minimap_position: Vector2 = Vector2(1080, 20)
@export var world_width: float = 1200.0
@export var world_height: float = 1200.0

var minimap_viewport: SubViewport
var minimap_container: Control
var player: Node3D = null
var npcs: Array[Node3D] = []

var player_marker: ColorRect
var npc_markers: Dictionary = {}

func _ready() -> void:
	_create_minimap()

func _create_minimap() -> void:
	minimap_container = Control.new()
	minimap_container.size = minimap_size
	minimap_container.position = minimap_position
	add_child(minimap_container)

	var background = ColorRect.new()
	background.color = Color(0.1, 0.1, 0.1, 0.8)
	background.size = minimap_size
	minimap_container.add_child(background)

	var border = ColorRect.new()
	border.color = Color.TRANSPARENT
	border.size = minimap_size
	border.modulate = Color.WHITE
	minimap_container.add_child(border)

	player_marker = ColorRect.new()
	player_marker.color = Color.BLUE
	player_marker.size = Vector2(4, 4)
	minimap_container.add_child(player_marker)

func _process(delta: float) -> void:
	if not player:
		return

	_update_minimap()

func _update_minimap() -> void:
	var player_world_pos = player.global_position
	var minimap_x = (player_world_pos.x / world_width) * minimap_size.x
	var minimap_y = (player_world_pos.z / world_height) * minimap_size.y

	player_marker.position = Vector2(minimap_x, minimap_y) + minimap_position - Vector2(2, 2)

	for npc in npcs:
		if not npc_markers.has(npc.name):
			var marker = ColorRect.new()
			marker.color = Color.RED
			marker.size = Vector2(3, 3)
			minimap_container.add_child(marker)
			npc_markers[npc.name] = marker

		var npc_world_pos = npc.global_position
		var npc_minimap_x = (npc_world_pos.x / world_width) * minimap_size.x
		var npc_minimap_y = (npc_world_pos.z / world_height) * minimap_size.y

		var marker = npc_markers[npc.name]
		marker.position = Vector2(npc_minimap_x, npc_minimap_y) + minimap_position - Vector2(1.5, 1.5)

func set_player(p: Node3D) -> void:
	player = p

func add_npc(npc: Node3D) -> void:
	if not npcs.has(npc):
		npcs.append(npc)

func remove_npc(npc: Node3D) -> void:
	npcs.erase(npc)
	if npc_markers.has(npc.name):
		npc_markers[npc.name].queue_free()
		npc_markers.erase(npc.name)

func set_minimap_position(pos: Vector2) -> void:
	minimap_position = pos
	if minimap_container:
		minimap_container.position = minimap_position

func toggle_minimap(visible: bool) -> void:
	if minimap_container:
		minimap_container.visible = visible
