@tool
class_name NurikabeGameBoard
extends Control

const MAX_UNDO: int = 200

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

@export_multiline var grid_string: String

@export_tool_button("Import Grid String") var import_grid_action: Callable = _import_grid

var error_cells: Dictionary[Vector2i, bool] = {}:
	set(value):
		error_cells = value
		_cells_dirty = true

## Cells currently being edited. The value is the most recent player id performing the edit.
var half_cells: Dictionary[Vector2i, int] = {}:
	set(value):
		half_cells = value
		_cells_dirty = true

var lowlight_cells: Dictionary[Vector2i, bool] = {}:
	set(value):
		lowlight_cells = value
		_cells_dirty = true

var _cells_dirty: bool = false

var _undo_stack: Array[UndoAction] = []
var _redo_stack: Array[UndoAction] = []

func _ready() -> void:
	if not Engine.is_editor_hint():
		for cell_pos: Vector2i in %TileMapWall.get_used_cells():
			%SteppableTiles.set_cell(cell_pos)


func _process(_delta: float) -> void:
	refresh_cells()


func reset() -> void:
	_import_grid()


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
	var result: bool = false
	for cell: Vector2i in half_cells:
		if half_cells[cell] == player_id:
			result = true
			break
	return result


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
		var island_id: int = 1 if cell in error_cells else 2 if cell in lowlight_cells else 0
		if cell in half_cells:
			island_id += 3
		%TileMapIsland.set_cell(cell, island_id, Vector2.ZERO)
	
	for cell: Vector2i in %TileMapWall.get_used_cells():
		var wall_id: int = 1 if cell in error_cells else 0
		if cell in half_cells:
			wall_id += 2
		%TileMapWall.set_cell(cell, wall_id, Vector2.ZERO)


func get_used_cells() -> Array[Vector2i]:
	return %TileMapGround.get_used_cells()


func global_to_map(global_point: Vector2) -> Vector2i:
	return %TileMapGround.local_to_map(%TileMapGround.to_local(global_point))


## Sets the specified cells on the game board.[br]
## [br]
## Accepts a dictionary with the following keys:[br]
## 	'pos': (Vector2i) The cell to update.[br]
## 	'value': (String) The value to assign.[br]
func set_cell_strings(changes: Array[Dictionary], player_id: int = -1) -> void:
	if player_id != -1:
		var cell_positions: Array[Vector2i] = []
		var values: Array[String] = []
		for change: Dictionary in changes:
			cell_positions.append(change["pos"])
			values.append(change["value"])
		_push_undo_action(player_id, cell_positions, values)
	
	for change: Dictionary in changes:
		_set_cell_string_internal(change["pos"], change["value"])


func set_cell_string(cell_pos: Vector2i, value: String, player_id: int = -1) -> void:
	if player_id != -1:
		_push_undo_action(player_id, [cell_pos], [value])
	_set_cell_string_internal(cell_pos, value)


func get_cell_string(cell_pos: Vector2i) -> String:
	var result: String = CELL_INVALID
	
	if %TileMapGround.get_cell_source_id(cell_pos) != -1:
		result = CELL_EMPTY
	
	if %TileMapWall.get_cell_source_id(cell_pos) != -1:
		result = CELL_WALL
	
	if %TileMapClue.get_cell_clue(cell_pos) != -1:
		result = str(%TileMapClue.get_cell_clue(cell_pos))
	
	if %TileMapIsland.get_cell_source_id(cell_pos) != -1:
		result = CELL_ISLAND
	
	return result


func set_half_cell(cell_pos: Vector2i, player_id: int) -> void:
	half_cells[cell_pos] = player_id
	_cells_dirty = true


func set_half_cells(cell_positions: Array[Vector2i], player_id: int) -> void:
	for cell_pos: Vector2i in cell_positions:
		half_cells[cell_pos] = player_id
	_cells_dirty = true


func get_global_cursorable_rect() -> Rect2:
	return %CursorableArea.get_global_transform() * %CursorableArea.cursorable_rect


func to_model() -> NurikabeBoardModel:
	var model: NurikabeBoardModel = NurikabeBoardModel.new()
	model.from_game_board(self)
	return model


func undo(player_id: int) -> void:
	for undo_index in _undo_stack.size():
		if _undo_stack[undo_index].player_id != player_id:
			continue
		if _can_apply_undo_action(_undo_stack[undo_index]):
			var undo_action: UndoAction = _undo_stack[undo_index]
			_undo_stack.remove_at(undo_index)
			_apply_undo_action(undo_action)
			_redo_stack.push_front(undo_action)
			break
		else:
			_undo_stack.remove_at(undo_index)


func redo(player_id: int) -> void:
	for redo_index in _redo_stack.size():
		if _redo_stack[redo_index].player_id != player_id:
			continue
		if _can_apply_undo_action(_redo_stack[redo_index], true):
			var redo_action: UndoAction = _redo_stack[redo_index]
			_redo_stack.remove_at(redo_index)
			_apply_undo_action(redo_action, true)
			_undo_stack.push_front(redo_action)
			break
		else:
			_redo_stack.remove_at(redo_index)


func _apply_undo_action(undo_action: UndoAction, is_redo: bool = false) -> void:
	var target_values: Array[String] = undo_action.new_values if is_redo else undo_action.old_values
	for i: int in undo_action.cell_positions.size():
		_set_cell_string_internal(undo_action.cell_positions[i], target_values[i])


func _can_apply_undo_action(undo_action: UndoAction, is_redo: bool = false) -> bool:
	var conflict_count: int = 0
	var expected_values: Array[String] = undo_action.old_values if is_redo else undo_action.new_values
	for i: int in undo_action.cell_positions.size():
		if get_cell_string(undo_action.cell_positions[i]) != expected_values[i]:
			conflict_count += 1
	return conflict_count == 0


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
	
	_undo_stack.clear()
	_redo_stack.clear()
	
	error_cells = {}
	half_cells = {}
	lowlight_cells = {}


func _erase_cell(cell_pos: Vector2i) -> void:
	%TileMapGround.erase_cell(cell_pos)
	%TileMapIsland.erase_cell(cell_pos)
	%TileMapClue.erase_cell(cell_pos)
	%TileMapError.erase_cell(cell_pos)
	%TileMapWall.erase_cell(cell_pos)
	if not Engine.is_editor_hint():
		%SteppableTiles.erase_cell(cell_pos)


func _set_cell_string_internal(cell_pos: Vector2i, value: String) -> void:
	if value.is_valid_int():
		%TileMapClue.set_cell(cell_pos, int(value))
	else:
		%TileMapClue.erase_cell(cell_pos)
	
	var wall_id: int
	if value != CELL_WALL:
		wall_id = -1
	else:
		wall_id = 1 if error_cells.has(cell_pos) else 0
		if half_cells.has(cell_pos):
			wall_id += 2
	%TileMapWall.set_cell(cell_pos, wall_id, Vector2.ZERO)
	
	if not Engine.is_editor_hint():
		if wall_id != 1:
			%SteppableTiles.set_cell(cell_pos)
		else:
			%SteppableTiles.erase_cell(cell_pos)
	
	var ground_id: int = 0 if (cell_pos.x + cell_pos.y) % 2 == 0 else 1
	%TileMapGround.set_cell(cell_pos, ground_id, Vector2.ZERO)
	
	var island_id: int
	if value != CELL_ISLAND:
		island_id = -1
	else:
		island_id = 1 if error_cells.has(cell_pos) else 2 if lowlight_cells.has(cell_pos) else 0
		if half_cells.has(cell_pos):
			island_id += 3
	%TileMapIsland.set_cell(cell_pos, island_id, Vector2.ZERO)
	
	%CursorableArea.set_cell(cell_pos)
	
	if not Engine.is_editor_hint():
		error_cells.erase(cell_pos)
		lowlight_cells.erase(cell_pos)
		_cells_dirty = true


func validate() -> void:
	%ValidateTimer.start()


func _push_undo_action(player_id: int, cell_positions: Array[Vector2i], values: Array[String]) -> void:
	var old_values: Array[String] = []
	for cell_position in cell_positions:
		old_values.append(get_cell_string(cell_position))
	var undo_action: UndoAction = UndoAction.new()
	undo_action.player_id = player_id
	undo_action.cell_positions = cell_positions
	undo_action.new_values = values
	undo_action.old_values = old_values
	_undo_stack.push_front(undo_action)
	
	if _undo_stack.size() > MAX_UNDO:
		_undo_stack.pop_back()
	for i in range(_redo_stack.size() - 1, -1, -1):
		if _redo_stack[i].player_id == player_id:
			_redo_stack.remove_at(i)


func _show_win_screen() -> void:
	SoundManager.play_sfx("win")
	%ResultsOverlay.show_results()


func _on_validate_timer_timeout() -> void:
	var model: NurikabeBoardModel = to_model()
	var result: NurikabeBoardModel.ValidationResult = model.validate()
	
	if result.error_count == 0:
		_show_win_screen()
	
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
	var old_error_cells: Dictionary[Vector2i, bool] = error_cells
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
	
	if not old_error_cells.has_all(new_error_cells.keys()):
		SoundManager.play_sfx("rule_broken")


class UndoAction:
	var player_id: int
	var cell_positions: Array[Vector2i]
	var old_values: Array[String]
	var new_values: Array[String]
	
	func _to_string() -> String:
		return str({
			"player_id": player_id,
			"cell_positions": cell_positions,
			"old_values": old_values,
			"new_values": new_values,
		})


func _on_results_overlay_next_level_button_pressed() -> void:
	reset()
