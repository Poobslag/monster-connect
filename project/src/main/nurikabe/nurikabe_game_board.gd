@tool
class_name NurikabeGameBoard
extends Control

const CELL_EMPTY = NurikabeUtils.CELL_EMPTY
const CELL_INVALID = NurikabeUtils.CELL_INVALID
const CELL_ISLAND = NurikabeUtils.CELL_ISLAND
const CELL_WALL = NurikabeUtils.CELL_WALL

@export_multiline var grid_string: String

@export_tool_button("Import Grid String") var import_grid_action: Callable = _import_grid

var error_cells: Dictionary[Vector2i, bool] = {}:
	set(value):
		error_cells = value
		_cells_dirty = true

var lowlight_cells: Dictionary[Vector2i, bool] = {}:
	set(value):
		lowlight_cells = value
		_cells_dirty = true

var _cells_dirty: bool = false

func _ready() -> void:
	if not Engine.is_editor_hint():
		for cell_pos: Vector2i in %TileMapWall.get_used_cells():
			%SteppableTiles.set_cell(cell_pos)


func _process(_delta: float) -> void:
	refresh_cells()


func refresh_cells() -> void:
	if not _cells_dirty:
		return
	_cells_dirty = false
	
	%TileMapClue.error_cells = error_cells
	%TileMapClue.lowlight_cells = lowlight_cells
	
	for cell: Vector2i in %TileMapGround.get_used_cells():
		if cell in error_cells:
			if %TileMapError.get_cell_source_id(cell) != 0:
				%TileMapError.set_cell(cell, 0, Vector2.ZERO)
		else:
			if %TileMapError.get_cell_source_id(cell) == 0:
				%TileMapError.erase_cell(cell)
	
	for cell: Vector2i in %TileMapIsland.get_used_cells():
		if cell in error_cells:
			%TileMapIsland.set_cell(cell, 1, Vector2.ZERO)
		elif cell in lowlight_cells:
			%TileMapIsland.set_cell(cell, 2, Vector2.ZERO)
		else:
			%TileMapIsland.set_cell(cell, 0, Vector2.ZERO)
	
	for cell: Vector2i in %TileMapWall.get_used_cells():
		if cell in error_cells:
			if %TileMapWall.get_cell_source_id(cell) == 0:
				%TileMapWall.set_cell(cell, 1, Vector2.ZERO)
		else:
			if %TileMapWall.get_cell_source_id(cell) == 1:
				%TileMapWall.set_cell(cell, 0, Vector2.ZERO)


func get_used_cells() -> Array[Vector2i]:
	return %TileMapGround.get_used_cells()


func global_to_map(global_point: Vector2) -> Vector2i:
	return %TileMapGround.local_to_map(%TileMapGround.to_local(global_point))


func set_cell_strings(changes: Array[Dictionary]) -> void:
	for change: Dictionary in changes:
		set_cell_string(change["pos"], change["value"])


func set_cell_string(cell_pos: Vector2i, value: String) -> void:
	if value.is_valid_int():
		%TileMapClue.set_cell(cell_pos, int(value))
	else:
		%TileMapClue.erase_cell(cell_pos)
	
	var wall_id: int = -1 if value != CELL_WALL else 1 if error_cells.has(cell_pos) else 0
	%TileMapWall.set_cell(cell_pos, wall_id, Vector2.ZERO)
	
	if not Engine.is_editor_hint():
		if wall_id == 0:
			%SteppableTiles.set_cell(cell_pos)
		else:
			%SteppableTiles.erase_cell(cell_pos)
	
	var ground_id: int = 0 if (cell_pos.x + cell_pos.y) % 2 == 0 else 1
	%TileMapGround.set_cell(cell_pos, ground_id, Vector2.ZERO)
	
	var island_id: int
	if value != CELL_ISLAND:
		island_id = -1
	elif error_cells.has(cell_pos):
		island_id = 1
	elif lowlight_cells.has(cell_pos):
		island_id = 2
	else:
		island_id = 0
	%TileMapIsland.set_cell(cell_pos, island_id, Vector2.ZERO)
	
	%CursorableArea.set_cell(cell_pos)
	
	if not Engine.is_editor_hint():
		error_cells.erase(cell_pos)
		lowlight_cells.erase(cell_pos)
		_cells_dirty = true
		%ValidateTimer.start()


func get_cell_string(cell_pos: Vector2i) -> String:
	var result: String = CELL_INVALID
	
	if %TileMapGround.get_cell_source_id(cell_pos) != -1:
		result = CELL_EMPTY
	
	if %TileMapWall.get_cell_source_id(cell_pos) in [0, 1]:
		result = CELL_WALL
	
	if not result and %TileMapClue.get_cell_clue(cell_pos) != -1:
		result = str(%TileMapClue.get_cell_clue(cell_pos))
	
	if not result and %TileMapIsland.get_cell_source_id(cell_pos) in [0, 1]:
		result = CELL_ISLAND
	
	return result


func get_global_cursorable_rect() -> Rect2:
	return %CursorableArea.get_global_transform() * %CursorableArea.cursorable_rect


func to_model() -> NurikabeBoardModel:
	var model: NurikabeBoardModel = NurikabeBoardModel.new()
	model.from_game_board(self)
	return model


func _import_grid() -> void:
	%TileMapGround.clear()
	%TileMapClue.clear()
	%TileMapError.clear()
	%TileMapWall.clear()
	if not Engine.is_editor_hint():
		%SteppableTiles.clear()
	%CursorableArea.clear()
	var grid_string_rows: PackedStringArray = grid_string.split("\n")
	for y in grid_string_rows.size():
		var row_string: String = grid_string_rows[y]
		@warning_ignore("integer_division")
		for x in row_string.length() / 2:
			set_cell_string(Vector2i(x, y), row_string.substr(x * 2, 2).strip_edges())


func _erase_cell(cell_pos: Vector2i) -> void:
	%TileMapGround.erase_cell(cell_pos)
	%TileMapIsland.erase_cell(cell_pos)
	%TileMapClue.erase_cell(cell_pos)
	%TileMapError.erase_cell(cell_pos)
	%TileMapWall.erase_cell(cell_pos)
	if not Engine.is_editor_hint():
		%SteppableTiles.erase_cell(cell_pos)


func _on_validate_timer_timeout() -> void:
	var model: NurikabeBoardModel = to_model()
	var result: NurikabeBoardModel.ValidationResult = model.validate()
	
	# update lowlight cells if the player isn't finished
	var new_lowlight_cells: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in model.cells:
		if model.get_cell_string(cell).is_valid_int() or model.get_cell_string(cell) in [CELL_EMPTY, CELL_ISLAND]:
			new_lowlight_cells[cell] = true
	for joined_island_cell: Vector2i in result.joined_islands:
		new_lowlight_cells.erase(joined_island_cell)
	for wrong_size_cell: Vector2i in result.wrong_size:
		new_lowlight_cells.erase(wrong_size_cell)
	lowlight_cells = new_lowlight_cells
	
	# update error cells if the player made a mistake
	var new_error_cells: Dictionary[Vector2i, bool] = {}
	for pool_cell: Vector2i in result.pools:
		new_error_cells[pool_cell] = true
	for joined_island_cell: Vector2i in result.joined_islands_unfixable:
		new_error_cells[joined_island_cell] = true
	for unclued_island_cell: Vector2i in result.unclued_islands:
		new_error_cells[unclued_island_cell] = true
	for wrong_size_cell: Vector2i in result.wrong_size_unfixable:
		new_error_cells[wrong_size_cell] = true
	for split_wall_cell in result.split_walls_unfixable:
		new_error_cells[split_wall_cell] = true
	error_cells = new_error_cells
