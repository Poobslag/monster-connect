@tool
class_name GroundLayer
extends Node3D

const TILE_SCENE_1: PackedScene = preload("res://assets/main/nurikabe_3d/tile_blank_1.glb")
const TILE_SCENE_2: PackedScene = preload("res://assets/main/nurikabe_3d/tile_blank_2.glb")
const GROUND_HEIGHT: float = 0.050
const TEXT_FLOAT_OFFSET: float = 0.052
const ERROR_FLOAT_OFFSET: float = 0.051

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
			_add_cell(cell_pos, TILE_SCENE_1)
		1:
			_add_cell(cell_pos, TILE_SCENE_2)


func get_used_cells() -> Array[Vector2i]:
	return _values_by_cell.keys()


func _remove_cell(cell_pos: Vector2i) -> void:
	if tiles_by_cell.has(cell_pos):
		var tile: Node3D = tiles_by_cell[cell_pos]
		tile.queue_free()
		remove_child(tile)
		tiles_by_cell.erase(cell_pos)


func _add_cell(cell_pos: Vector2i, cell_scene: PackedScene) -> void:
	# instantiate the tile
	var tile: Node3D = cell_scene.instantiate()
	tile.name = "tile_%s_%s" % [cell_pos.x, cell_pos.y]
	
	# Assign tile group and metadata for raycasting. Maps colliders back to their board and cell.
	# Only ground tiles are clickable -- walls aren't, to avoid click targets shifting as walls are toggled.
	var child: MeshInstance3D = tile.get_child(0)
	child.set_layer_mask_value(Global.LAYER_CLICKABLE, true)
	tile.add_to_group("board_cells")
	if not Engine.is_editor_hint():
		# Metadata is runtime-only. Serializing it would bloat the .tscn.
		tile.set_meta("board", get_parent())
		tile.set_meta("cell", cell_pos)
	
	add_child(tile)
	tiles_by_cell[cell_pos] = tile
	
	# assign the tile properties
	tile.scale.x = tile_size.x
	tile.scale.z = tile_size.y
	tile.position.x = cell_pos.x * tile_size.x
	tile.position.z = cell_pos.y * tile_size.y
	
	if Engine.is_editor_hint():
		tile.owner = get_tree().edited_scene_root
