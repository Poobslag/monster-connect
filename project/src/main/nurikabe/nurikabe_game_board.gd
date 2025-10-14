@tool
class_name NurikabeGameBoard
extends Control

const CELL_EMPTY = NurikabeUtils.CELL_EMPTY
const CELL_INVALID = NurikabeUtils.CELL_INVALID
const CELL_ISLAND = NurikabeUtils.CELL_ISLAND
const CELL_WALL = NurikabeUtils.CELL_WALL

@export_multiline var grid_string: String

@export_tool_button("Import Grid String") var import_grid_action: Callable = _import_grid

func _ready() -> void:
	if not Engine.is_editor_hint():
		for cell_pos: Vector2i in %TileMapObject.get_used_cells():
			%SteppableTiles.set_cell(cell_pos)


func global_to_map(global_point: Vector2) -> Vector2i:
	return %TileMapGround.local_to_map(%TileMapGround.to_local(global_point))


func set_cell_string(cell_pos: Vector2i, value: String) -> void:
	if value.is_valid_int():
		%TileMapClues.set_cell(cell_pos, int(value))
	else:
		%TileMapClues.erase_cell(cell_pos)
	
	var object_id: int = 0 if value == CELL_WALL else -1
	%TileMapObject.set_cell(cell_pos, object_id, Vector2.ZERO)
	
	if not Engine.is_editor_hint():
		if object_id == 0:
			%SteppableTiles.set_cell(cell_pos)
		else:
			%SteppableTiles.erase_cell(cell_pos)
	
	var ground_id: int = 0 if (cell_pos.x + cell_pos.y) % 2 == 0 else 1
	%TileMapGround.set_cell(cell_pos, ground_id, Vector2.ZERO)
	
	var island_id: int = 0 if value == CELL_ISLAND else -1
	%TileMapIsland.set_cell(cell_pos, island_id, Vector2.ZERO)
	
	%CursorableArea.set_cell(cell_pos)


func get_cell_string(cell_pos: Vector2i) -> String:
	var result: String = CELL_INVALID
	
	if %TileMapGround.get_cell_source_id(cell_pos) != -1:
		result = CELL_EMPTY
	
	if %TileMapObject.get_cell_source_id(cell_pos) == 0:
		result = CELL_WALL
	
	if not result and %TileMapClues.get_cell_clue(cell_pos) != -1:
		result = str(%TileMapClues.get_cell_clue(cell_pos))
	
	if not result and %TileMapIsland.get_cell_source_id(cell_pos) == 0:
		result = CELL_ISLAND
	
	return result


func get_global_cursorable_rect() -> Rect2:
	return %CursorableArea.get_global_transform() * %CursorableArea.cursorable_rect


func surround_island(cell_pos: Vector2i) -> void:
	var clue_cells: Dictionary[Vector2i, bool] = {}
	var island_cells: Dictionary[Vector2i, bool] = {}
	var ignored_cells: Dictionary[Vector2i, bool] = {}
	var cells_to_check: Dictionary[Vector2i, bool] = {cell_pos: true}
	while cells_to_check.size() > 0:
		var next_cell: Vector2i = cells_to_check.keys()[0]
		cells_to_check.erase(next_cell)
		
		var next_cell_string: String = get_cell_string(next_cell)
		if next_cell_string == CELL_ISLAND:
			island_cells[next_cell] = true
		elif next_cell_string.is_valid_int():
			clue_cells[next_cell] = true
		else:
			ignored_cells[next_cell] = true
			continue
		
		for neighbor_dir: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var neighbor_cell: Vector2i = next_cell + neighbor_dir
			if ignored_cells.has(neighbor_cell) \
					or island_cells.has(neighbor_cell) \
					or clue_cells.has(neighbor_cell) \
					or cells_to_check.has(neighbor_cell) \
					or %TileMapGround.get_cell_source_id(neighbor_cell) == -1:
				continue
			cells_to_check[neighbor_cell] = true
	
	if clue_cells.size() == 1 and island_cells.size() == int(get_cell_string(clue_cells.keys()[0])) - 1:
		for ignored_cell: Vector2i in ignored_cells:
			if get_cell_string(ignored_cell) == CELL_EMPTY:
				set_cell_string(ignored_cell, CELL_WALL)


func _import_grid() -> void:
	%TileMapGround.clear()
	%TileMapClues.clear()
	%TileMapObject.clear()
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
	%TileMapClues.erase_cell(cell_pos)
	%TileMapObject.erase_cell(cell_pos)
	if not Engine.is_editor_hint():
		%SteppableTiles.erase_cell(cell_pos)
