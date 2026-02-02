class_name PuzzleHandler
extends Node

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

const CELL_SURROUND_ISLAND: int = 822

var game_board: NurikabeGameBoard = null

var _cells_to_erase: Dictionary[Vector2i, bool] = {}
var _input_sfx: String
var _last_set_cell_from: int = CELL_INVALID
var _last_set_cell_to: int = CELL_INVALID
var _prev_cell: Vector2i = Vector2i(-577218, -577218)
var _last_mouse_pos: Vector2 = Vector2.ZERO

var _lmb_pressed: bool = false
var _rmb_pressed: bool = false

@onready var input_handler: MonsterInput = get_parent()
@onready var monster: Monster = Utils.find_parent_of_type(self, Monster)


func _update_pressed(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		_lmb_pressed = event.is_pressed()
	if event.button_index == MOUSE_BUTTON_RIGHT:
		_rmb_pressed = event.is_pressed()


func handle(event: InputEvent) -> void:
	_update_pressed(event)
	if game_board == null or game_board.is_finished():
		# cannot interact with finished game board
		return
	
	_input_sfx = ""
	
	if event is InputEventMouseMotion:
		_handle_mouse_motion()
	
	if event.is_action_pressed("undo"):
		_handle_undo_action()
	
	if event.is_action_pressed("redo"):
		_handle_redo_action()
	
	if event.is_action_pressed("reset"):
		_handle_reset_action()
	
	# pressing the left mouse button on a puzzle
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_lmb_press()
	
	# pressing the right mouse button on a puzzle
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_handle_rmb_press()
	
	# dragging the left or right mouse button on a puzzle
	if event is InputEventMouseMotion \
			and (_lmb_pressed or _rmb_pressed):
		_handle_mb_drag()
	
	# releasing the mouse button after modifying a puzzle
	if event is InputEventMouseButton \
			and not event.pressed:
		_handle_mb_release()
	
	if _input_sfx:
		SoundManager.play_sfx(_input_sfx)


func reset() -> void:
	_cells_to_erase.clear()
	_last_set_cell_from = CELL_INVALID
	_last_set_cell_to = CELL_INVALID
	_prev_cell = Vector2i(-577218, -577218)


func update() -> void:
	return


func _handle_lmb_press() -> void:
	_last_mouse_pos = _get_global_cursor_position()
	var cell: Vector2i = _cursor_cell()
	var current_cell_value: int = game_board.get_cell(cell)
	match current_cell_value:
		CELL_WALL:
			_cells_to_erase[cell] = true
			_last_set_cell_from = game_board.get_cell(cell)
			_last_set_cell_to = CELL_EMPTY
			_set_half_cell(cell, monster.id)
			_input_sfx = "drop_wall_release"
		CELL_EMPTY, CELL_ISLAND:
			_last_set_cell_from = game_board.get_cell(cell)
			_last_set_cell_to = CELL_WALL
			_set_cell(cell, CELL_WALL, monster.id)
			_set_half_cell(cell, monster.id)
			_input_sfx = "drop_wall_press"
	if NurikabeUtils.is_clue(current_cell_value):
		var changes: Array[Dictionary] = game_board.to_solver_board().surround_island(cell)
		if changes:
			for change: Dictionary[String, Variant] in changes:
				_set_cell(change["pos"], change["value"])
			var cell_positions: Array[Vector2i] = []
			for change: Dictionary[String, Variant] in changes:
				cell_positions.append(change["pos"])
			_last_set_cell_from = CELL_INVALID
			_last_set_cell_to = CELL_SURROUND_ISLAND
			_set_half_cells(cell_positions, monster.id)
			_input_sfx = "surround_island_press"
		else:
			_input_sfx = "surround_island_fail"


func _is_editable(cell_pos: Vector2i) -> bool:
	var curr_value: int = game_board.get_cell(cell_pos)
	return curr_value != CELL_INVALID and not NurikabeUtils.is_clue(curr_value)


func _handle_mb_drag() -> void:
	var cells: Array[Vector2i] = _get_cells_along_line(_last_mouse_pos, _get_global_cursor_position())
	
	for cell: Vector2i in cells:
		_process_drag_cell(cell)
	
	_last_mouse_pos = _get_global_cursor_position()


func _process_drag_cell(cell: Vector2i) -> void:
	var old_cell_value: int = game_board.get_cell(cell)
	if old_cell_value == CELL_INVALID:
		return
	if old_cell_value != _last_set_cell_from:
		return
	
	match _last_set_cell_to:
		CELL_WALL, CELL_ISLAND:
			_set_cell(cell, _last_set_cell_to, monster.id)
			_set_half_cell(cell, monster.id)
			if _last_set_cell_to == CELL_WALL:
				_input_sfx = "drop_wall_press"
			elif _last_set_cell_to == CELL_ISLAND:
				_input_sfx = "drop_island_press"
		CELL_EMPTY:
			if not _cells_to_erase.has(cell):
				_cells_to_erase[cell] = true
				_set_half_cell(cell, monster.id)
				if game_board.get_cell(cell) == CELL_WALL:
					_input_sfx = "drop_wall_release"
				elif game_board.get_cell(cell) == CELL_ISLAND:
					_input_sfx = "drop_island_release"


func _get_cells_along_line(from_pos: Vector2, to_pos: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i]
	var from_cell: Vector2i = _get_cell_from_position(from_pos)
	var to_cell: Vector2i = _get_cell_from_position(to_pos)
	var max_steps: int = max(abs(to_cell.x - from_cell.x), abs(to_cell.y - from_cell.y))
	match max_steps:
		0:
			cells = [from_cell]
		1:
			cells = [from_cell, to_cell]
		_:
			cells = []
			var current: Vector2 = Vector2(from_cell)
			var step: Vector2 = (Vector2(to_cell) - Vector2(from_cell)) / max_steps
			for _i in max_steps + 1:
				cells.append(Vector2i(roundi(current.x), roundi(current.y)))
				current += step
	return cells


func _handle_mb_release() -> void:
	if _cells_to_erase:
		var changes: Array[Dictionary] = []
		for cell: Vector2i in _cells_to_erase:
			changes.append({"pos": cell, "value": CELL_EMPTY} as Dictionary[String, Variant])
		_set_cells(changes, monster.id)
	
	if game_board.has_half_cells(monster.id):
		if _last_set_cell_to == CELL_WALL:
			_input_sfx = "drop_wall_release"
		elif _last_set_cell_to == CELL_ISLAND:
			_input_sfx = "drop_island_release"
		elif _last_set_cell_to == CELL_EMPTY:
			if _last_set_cell_from == CELL_WALL:
				SoundManager.play_sfx("drop_wall_press")
			elif _last_set_cell_from == CELL_ISLAND:
				SoundManager.play_sfx("drop_island_press")
		elif _last_set_cell_to == CELL_SURROUND_ISLAND:
			_input_sfx = "surround_island_release"
		game_board.validate()
	
	game_board.clear_half_cells(monster.id)
	_cells_to_erase.clear()
	_last_set_cell_from = CELL_INVALID
	_last_set_cell_to = CELL_INVALID


func _handle_mouse_motion() -> void:
	var cell: Vector2i = _cursor_cell()
	if cell != _prev_cell:
		_input_sfx = "cursor_move"
		_prev_cell = cell


func _handle_redo_action() -> void:
	game_board.redo(monster.id)
	game_board.validate()
	SoundManager.play_sfx("redo")


func _handle_reset_action() -> void:
	game_board.reset()
	SoundManager.play_sfx("reset")


func _handle_rmb_press() -> void:
	_last_mouse_pos = _get_global_cursor_position()
	var cell: Vector2i = _cursor_cell()
	var current_cell_value: int = game_board.get_cell(cell)
	match current_cell_value:
		CELL_ISLAND:
			_cells_to_erase[cell] = true
			_last_set_cell_from = game_board.get_cell(cell)
			_last_set_cell_to = CELL_EMPTY
			_set_half_cell(cell, monster.id)
			_input_sfx = "drop_island_release"
		CELL_EMPTY, CELL_WALL:
			_last_set_cell_from = game_board.get_cell(cell)
			_last_set_cell_to = CELL_ISLAND
			_set_cell(cell, CELL_ISLAND, monster.id)
			_set_half_cell(cell, monster.id)
			_input_sfx = "drop_island_press"


func _handle_undo_action() -> void:
	game_board.undo(monster.id)
	game_board.validate()
	SoundManager.play_sfx("undo")


func _cursor_cell() -> Vector2i:
	return _get_cell_from_position(_get_global_cursor_position())


func _get_cell_from_position(pos: Vector2) -> Vector2i:
	return game_board.global_to_map(pos)


func _get_global_cursor_position() -> Vector2:
	return monster.cursor.global_position


func _set_cell(cell_pos: Vector2i, value: int, player_id: int = -1) -> void:
	if not _is_editable(cell_pos):
		return
	game_board.set_cell(cell_pos, value, player_id)


func _set_half_cell(cell_pos: Vector2i, player_id: int) -> void:
	if not _is_editable(cell_pos):
		return
	game_board.set_half_cell(cell_pos, player_id)


func _set_cells(changes: Array[Dictionary], player_id: int = -1) -> void:
	var filtered_changes: Array[Dictionary] = changes.filter(func(change: Dictionary) -> bool:
		return _is_editable(change["pos"]))
	game_board.set_cells(filtered_changes, player_id)


func _set_half_cells(cell_positions: Array[Vector2i], player_id: int) -> void:
	var filtered_positions: Array[Vector2i] = cell_positions.filter(func(pos: Vector2i) -> bool:
		return _is_editable(pos))
	game_board.set_half_cells(filtered_positions, player_id)
