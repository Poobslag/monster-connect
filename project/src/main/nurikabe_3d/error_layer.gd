@tool
extends Node3D

const GROUND_HEIGHT: float = GroundLayer.GROUND_HEIGHT
const ERROR_FLOAT_OFFSET: float = GroundLayer.ERROR_FLOAT_OFFSET
const GROUND_ERROR_SCENE: PackedScene = preload("res://assets/main/nurikabe_3d/tile_ground_error.glb")

var tile_size: Vector2 = Vector2(1, 1)
var tiles_by_cell: Dictionary[Vector2i, Node3D] = {}

var _values_by_cell: Dictionary[Vector2i, int] = {}


func clear() -> void:
	tiles_by_cell.clear()
	_values_by_cell.clear()
	for child: Node in get_children():
		child.queue_free()
		remove_child(child)


func get_cell(cell_pos: Vector2i) -> int:
	return _values_by_cell.get(cell_pos, -1)


func set_cell(cell_pos: Vector2i, value: int) -> void:
	if _values_by_cell.get(cell_pos, -1) == value:
		return
	
	_remove_cell(cell_pos)
	if value == -1:
		_values_by_cell.erase(cell_pos)
	else:
		_values_by_cell[cell_pos] = value
	match value:
		-1:
			pass
		0:
			_add_cell(cell_pos, GROUND_ERROR_SCENE)


func get_used_cells() -> Array[Vector2i]:
	return _values_by_cell.keys()


func _add_cell(cell_pos: Vector2i, cell_scene: PackedScene) -> void:
	# instantiate the tile
	var tile: Node3D = cell_scene.instantiate()
	tile.name = "error_%s_%s" % [cell_pos.x, cell_pos.y]
	
	add_child(tile)
	tiles_by_cell[cell_pos] = tile
	
	tile.scale.x = tile_size.x
	tile.scale.z = tile_size.y
	tile.position.x = cell_pos.x * tile_size.x
	tile.position.z = cell_pos.y * tile_size.y
	tile.position.y = ERROR_FLOAT_OFFSET
	
	if Engine.is_editor_hint():
		tile.owner = get_tree().edited_scene_root


func _remove_cell(cell_pos: Vector2i) -> void:
	if tiles_by_cell.has(cell_pos):
		var tile: Node3D = tiles_by_cell[cell_pos]
		tile.queue_free()
		remove_child(tile)
		tiles_by_cell.erase(cell_pos)
