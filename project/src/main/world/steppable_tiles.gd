extends Node2D

@export var tile_size: Vector2i:
	set(value):
		tile_size = value
		queue_redraw()

const STEPPABLE_TILE_SCENE: PackedScene = preload("res://src/main/world/steppable_tile.tscn")

var _steppable_tiles_by_cell: Dictionary[Vector2i, Area2D] = {}

func clear() -> void:
	for cell in _steppable_tiles_by_cell:
		erase_cell(cell)


func set_cell(cell: Vector2i) -> void:
	if _steppable_tiles_by_cell.has(cell):
		return
	
	var tile: Area2D = STEPPABLE_TILE_SCENE.instantiate()
	tile.position = Vector2(tile_size) * (Vector2(cell) + Vector2(0.5, 0.5))
	add_child(tile)
	_steppable_tiles_by_cell[cell] = tile


func erase_cell(cell: Vector2i) -> void:
	if not _steppable_tiles_by_cell.has(cell):
		return
	
	var tile: Area2D = _steppable_tiles_by_cell[cell]
	_steppable_tiles_by_cell.erase(cell)
	tile.queue_free()
