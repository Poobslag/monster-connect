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
		for cell_pos: Vector2i in %TileMapWall.get_used_cells():
			%SteppableTiles.set_cell(cell_pos)


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
	
	var object_id: int = 0 if value == CELL_WALL else -1
	%TileMapWall.set_cell(cell_pos, object_id, Vector2.ZERO)
	
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
	
	if %TileMapWall.get_cell_source_id(cell_pos) == 0:
		result = CELL_WALL
	
	if not result and %TileMapClue.get_cell_clue(cell_pos) != -1:
		result = str(%TileMapClue.get_cell_clue(cell_pos))
	
	if not result and %TileMapIsland.get_cell_source_id(cell_pos) == 0:
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
	%TileMapWall.erase_cell(cell_pos)
	if not Engine.is_editor_hint():
		%SteppableTiles.erase_cell(cell_pos)
