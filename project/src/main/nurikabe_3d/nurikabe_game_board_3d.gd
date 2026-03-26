@tool
class_name NurikabeGameBoard3D
extends Node3D

signal puzzle_finished
signal error_cells_changed

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

@export_multiline var grid_string: String

@export_tool_button("Import Grid String") var import_grid_action: Callable = import_grid

@export var tile_size: Vector2 = Vector2(1, 1)

var allow_unclued_islands: bool = false

var error_cells: Dictionary[Vector2i, bool] = {}:
	set(value):
		error_cells = value
		_cells_dirty = true

var lowlight_cells: Dictionary[Vector2i, bool] = {}:
	set(value):
		lowlight_cells = value
		_cells_dirty = true

## Cells currently being edited. The value is the most recent monster id performing the edit.
var half_cells: Dictionary[Vector2i, int] = {}:
	set(value):
		half_cells = value
		_cells_dirty = true

var _cells_dirty: bool = false
var _values_by_cell: Dictionary[Vector2i, int] = {}
var _finished: bool = false

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
	
	%ClueLayer.error_cells = error_cells
	
	for cell: Vector2i in %GroundLayer.get_used_cells():
		%ErrorLayer.set_cell(cell, 0 if cell in error_cells else -1)
	
	for cell: Vector2i in %IslandLayer.get_used_cells():
		var island_id: int = 1 if error_cells.has(cell) else 0
		if half_cells.has(cell):
			island_id += 3
		%IslandLayer.set_cell(cell, island_id)
	
	for cell: Vector2i in %WallLayer.get_used_cells():
		var wall_id: int = 1 if error_cells.has(cell) else 0
		if half_cells.has(cell):
			wall_id += 2
		%WallLayer.set_cell(cell, wall_id)


func set_cell(cell_pos: Vector2i, value: int, _player_id: int = -1) -> void:
	# update cell value
	_set_cell_internal(cell_pos, value)


func get_cell(cell_pos: Vector2i) -> int:
	return _values_by_cell.get(cell_pos, -1)


func get_used_cells() -> Array[Vector2i]:
	return _values_by_cell.keys()


func map_to_global(cell: Vector2i) -> Vector3:
	return global_transform * Vector3(cell.x * tile_size.x, 0, cell.y * tile_size.y)


func set_half_cell(cell_pos: Vector2i, player_id: int) -> void:
	half_cells[cell_pos] = player_id
	_cells_dirty = true


func set_half_cells(cell_positions: Array[Vector2i], player_id: int) -> void:
	for cell_pos: Vector2i in cell_positions:
		half_cells[cell_pos] = player_id
	_cells_dirty = true


func to_solver_board() -> SolverBoard:
	var board: SolverBoard = SolverBoard.new()
	board.from_game_board_3d(self)
	return board


func validate() -> void:
	%ValidateTimer.start()


func _set_cell_internal(cell_pos: Vector2i, value: int) -> void:
	if value == 0:
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


func _on_validate_timer_timeout() -> void:
	var model: SolverBoard = to_solver_board()
	var result_simple: SolverBoard.ValidationResult = model.validate(SolverBoard.VALIDATE_SIMPLE)
	var result_strict: SolverBoard.ValidationResult = model.validate(SolverBoard.VALIDATE_STRICT)
	
	if result_strict.error_count == 0:
		_finished = true
		
		# fill remaining empty island cells on completion
		for cell: Vector2i in model.cells:
			if model.get_cell(cell) == CELL_EMPTY:
				set_cell(cell, CELL_ISLAND)
		half_cells.clear()
		
		puzzle_finished.emit()
	
	# update lowlight cells if the monster isn't finished
	var new_lowlight_cells: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in model.cells:
		var cell_value: int = model.get_cell(cell)
		if cell_value == CELL_ISLAND or cell_value == CELL_EMPTY or model.has_clue(cell):
			new_lowlight_cells[cell] = true
	for joined_island_cell: Vector2i in result_strict.joined_islands:
		new_lowlight_cells.erase(joined_island_cell)
	for wrong_size_cell: Vector2i in result_strict.wrong_size:
		new_lowlight_cells.erase(wrong_size_cell)
	lowlight_cells = new_lowlight_cells
	model.cleanup()
	
	# update error cells if the monster made a mistake
	var old_error_cells: Dictionary[Vector2i, bool] = error_cells
	var new_error_cells: Dictionary[Vector2i, bool] = {}
	for pool_cell: Vector2i in result_simple.pools:
		new_error_cells[pool_cell] = true
	for joined_island_cell: Vector2i in result_simple.joined_islands:
		new_error_cells[joined_island_cell] = true
	if not allow_unclued_islands:
		for unclued_island_cell: Vector2i in result_simple.unclued_islands:
			new_error_cells[unclued_island_cell] = true
	for wrong_size_cell: Vector2i in result_simple.wrong_size:
		new_error_cells[wrong_size_cell] = true
	for split_wall_cell in result_simple.split_walls:
		new_error_cells[split_wall_cell] = true
	
	# preserve error state for half cells to prevent flickering when multiple players edit simultaneously
	for half_cell: Vector2i in half_cells:
		if old_error_cells.has(half_cell):
			new_error_cells[half_cell] = true
		else:
			new_error_cells.erase(half_cell)
	
	error_cells = new_error_cells
	
	if not old_error_cells.has_all(new_error_cells.keys()):
		var sfx_error_cells: Array[Vector2i] = []
		sfx_error_cells.assign(Utils.subtract(new_error_cells.keys(), old_error_cells.keys()))
		var average_position: Vector3 = Vector3.ZERO
		for sfx_error_cell: Vector2 in sfx_error_cells:
			average_position += map_to_global(sfx_error_cell)
		average_position /= sfx_error_cells.size()
		SoundManager.play_sfx_at_3d("rule_broken", average_position)
	if new_error_cells != old_error_cells:
		error_cells_changed.emit()
