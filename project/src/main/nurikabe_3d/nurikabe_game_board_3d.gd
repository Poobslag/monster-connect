@tool
class_name NurikabeGameBoard3D
extends Node3D

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

@export_multiline var grid_string: String

@export_tool_button("Import Grid String") var import_grid_action: Callable = import_grid

@export var tile_size: Vector2 = Vector2(1, 1)

## Cells currently being edited. The value is the most recent monster id performing the edit.
var half_cells: Dictionary[Vector2i, int] = {}:
	set(value):
		half_cells = value
		_cells_dirty = true

var _cells_dirty: bool = false
var _values_by_cell: Dictionary[Vector2i, int] = {}

func _ready() -> void:
	%GroundLayer.tile_size = tile_size
	%IslandLayer.tile_size = tile_size
	%ClueLayer.tile_size = tile_size
	%WallLayer.tile_size = tile_size
	
	if not Engine.is_editor_hint():
		import_grid()


func _process(_delta: float) -> void:
	refresh_cells()


func clear_half_cells(player_id: int) -> void:
	for cell: Vector2i in get_half_cells(player_id):
		half_cells.erase(cell)
	_cells_dirty = true


func get_half_cells(player_id: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Vector2i in half_cells:
		if half_cells[cell] == player_id:
			result.append(cell)
	return result


func has_half_cells(player_id: int) -> bool:
	return half_cells.values().has(player_id)


func import_grid() -> void:
	%GroundLayer.clear()
	%IslandLayer.clear()
	%ClueLayer.clear()
	%WallLayer.clear()
	_values_by_cell.clear()
	
	var cells: Dictionary[Vector2i, int] = NurikabeUtils.cells_from_grid_string(grid_string)
	for cell: Vector2i in cells:
		set_cell(cell, cells[cell])
	
	half_cells = {}


func refresh_cells() -> void:
	if not _cells_dirty:
		return
	_cells_dirty = false
	
	for cell: Vector2i in %IslandLayer.get_used_cells():
		var island_id: int = 0
		if cell in half_cells:
			island_id += 3
		%IslandLayer.set_cell(cell, island_id)
	
	for cell: Vector2i in %WallLayer.get_used_cells():
		var wall_id: int = 0
		if cell in half_cells:
			wall_id += 2
		%WallLayer.set_cell(cell, wall_id)


func set_cell(cell_pos: Vector2i, value: int, _player_id: int = -1) -> void:
	# update cell value
	_set_cell_internal(cell_pos, value)


func get_cell(cell_pos: Vector2i) -> int:
	return _values_by_cell.get(cell_pos, -1)


func map_to_global(cell: Vector2i) -> Vector3:
	return global_transform * Vector3(cell.x * tile_size.x, 0, cell.y * tile_size.y)


func set_half_cell(cell_pos: Vector2i, player_id: int) -> void:
	half_cells[cell_pos] = player_id
	_cells_dirty = true


func set_half_cells(cell_positions: Array[Vector2i], player_id: int) -> void:
	for cell_pos: Vector2i in cell_positions:
		half_cells[cell_pos] = player_id
	_cells_dirty = true


func _set_cell_internal(cell_pos: Vector2i, value: int) -> void:
	if value == -1:
		_values_by_cell.erase(cell_pos)
	else:
		_values_by_cell[cell_pos] = value
	
	var ground_id: int = 0 if (cell_pos.x + cell_pos.y) % 2 == 0 else 1
	%GroundLayer.set_cell(cell_pos, ground_id)
	
	var island_id: int
	if value != CELL_ISLAND:
		island_id = -1
	else:
		island_id = 0
		if half_cells.has(cell_pos):
			island_id += 3
	%IslandLayer.set_cell(cell_pos, island_id)
	
	%ClueLayer.set_cell(cell_pos, value)
	
	var wall_id: int
	if value != CELL_WALL:
		wall_id = -1
	else:
		wall_id = 0
		if half_cells.has(cell_pos):
			wall_id += 2
	%WallLayer.set_cell(cell_pos, wall_id)
