@tool
extends Node3D

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

@export_multiline var grid_string: String

@export_tool_button("Import Grid String") var import_grid_action: Callable = import_grid

@export var tile_size: Vector2 = Vector2(1, 1)


func _ready() -> void:
	%GroundLayer.tile_size = tile_size
	%ClueLayer.tile_size = tile_size
	
	if not Engine.is_editor_hint():
		import_grid()


func import_grid() -> void:
	%GroundLayer.clear()
	%ClueLayer.clear()
	
	var cells: Dictionary[Vector2i, int] = NurikabeUtils.cells_from_grid_string(grid_string)
	for cell: Vector2i in cells:
		set_cell(cell, cells[cell])


func set_cell(cell_pos: Vector2i, value: int, _player_id: int = -1) -> void:
	# update cell value
	_set_cell_internal(cell_pos, value)


func _set_cell_internal(cell_pos: Vector2i, value: int) -> void:
	%GroundLayer.set_cell(cell_pos, value)
	%ClueLayer.set_cell(cell_pos, value)
