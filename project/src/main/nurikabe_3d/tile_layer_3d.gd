@tool
class_name TileLayer3D
extends Node3D

@export var tile_scenes: Dictionary[int, PackedScene] = {}
@export var tile_size: Vector2 = Vector2.ONE

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
	
	if value in tile_scenes:
		_values_by_cell[cell_pos] = value
		_add_cell(cell_pos, value)
	else:
		_values_by_cell.erase(cell_pos)


func get_used_cells() -> Array[Vector2i]:
	return _values_by_cell.keys()


func _remove_cell(cell_pos: Vector2i) -> void:
	if tiles_by_cell.has(cell_pos):
		var tile: Node3D = tiles_by_cell[cell_pos]
		tile.queue_free()
		remove_child(tile)
		tiles_by_cell.erase(cell_pos)


func _add_cell(cell_pos: Vector2i, cell_value: int) -> void:
	# instantiate the tile
	var cell_scene: PackedScene = tile_scenes[cell_value]
	var tile: Node3D = cell_scene.instantiate()
	tile.name = "tile_%s_%s" % [cell_pos.x, cell_pos.y]
	
	tiles_by_cell[cell_pos] = tile
	
	# assign the tile properties
	tile.scale.x = tile_size.x
	tile.scale.z = tile_size.y
	tile.position.x = cell_pos.x * tile_size.x
	tile.position.z = cell_pos.y * tile_size.y
	
	_prepare_tile(cell_pos, cell_value, tile)
	
	add_child(tile)
	
	if Engine.is_editor_hint():
		tile.owner = get_tree().edited_scene_root


## Overridden by child classes to prepare the tile before adding it to the scene tree.
func _prepare_tile(_cell_pos: Vector2i, _cell_value: int, _tile: Node3D) -> void:
	pass
