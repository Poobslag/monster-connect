@tool
extends Node3D

const TILE_SCENE_1: PackedScene = preload("res://assets/main/nurikabe_3d/tile_blank_1.glb")
const TILE_SCENE_2: PackedScene = preload("res://assets/main/nurikabe_3d/tile_blank_2.glb")

var tile_size: Vector2 = Vector2(1, 1)
var tiles_by_cell: Dictionary[Vector2i, Node3D] = {}

func clear() -> void:
	tiles_by_cell.clear()
	for child: Node in get_children():
		child.queue_free()


func set_cell(cell_pos: Vector2i, _value: int) -> void:
	if tiles_by_cell.has(cell_pos):
		return
	
	# instantiate the tile
	var tile_scene: PackedScene = TILE_SCENE_1 if (cell_pos.x + cell_pos.y) % 2 == 0 else TILE_SCENE_2
	var tile: Node3D = tile_scene.instantiate()
	tile.name = "tile_%s_%s" % [cell_pos.x, cell_pos.y]
	add_child(tile)
	tiles_by_cell[cell_pos] = tile
	
	# assign the tile properties
	tile.scale.x = tile_size.x
	tile.scale.z = tile_size.y
	tile.position.x = cell_pos.x * tile_size.x
	tile.position.z = cell_pos.y * tile_size.y
	
	if Engine.is_editor_hint():
		tile.owner = get_tree().edited_scene_root
