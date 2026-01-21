class_name PlayerPuzzleHandler
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

@onready var input_handler: PlayerInputHandler = get_parent()
@onready var player: Player = Utils.find_parent_of_type(self, Player)

func handle(event: InputEvent) -> void:
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
			and (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
				or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)):
		_handle_mb_drag()
	
	# releasing the mouse button after modifying a puzzle
	if event is InputEventMouseButton \
			and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
			and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
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
	_last_mouse_pos = _get_global_mouse_position()
	var cell: Vector2i = _mouse_cell()
	var current_cell_value: int = game_board.get_cell(cell)
	match current_cell_value:
		CELL_WALL:
			_cells_to_erase[cell] = true
			_last_set_cell_from = game_board.get_cell(cell)
			_last_set_cell_to = CELL_EMPTY
			game_board.set_half_cell(cell, player.id)
			_input_sfx = "drop_wall_release"
		CELL_EMPTY, CELL_ISLAND:
			_last_set_cell_from = game_board.get_cell(cell)
			_last_set_cell_to = CELL_WALL
			game_board.set_cell(cell, CELL_WALL, player.id)
			game_board.set_half_cell(cell, player.id)
			_input_sfx = "drop_wall_press"
	if NurikabeUtils.is_clue(current_cell_value):
		var changes: Array[Dictionary] = game_board.to_solver_board().surround_island(cell)
		if changes:
			for change: Dictionary[String, Variant] in changes:
				game_board.set_cell(change["pos"], change["value"])
			var cell_positions: Array[Vector2i] = []
			for change: Dictionary[String, Variant] in changes:
				cell_positions.append(change["pos"])
			_last_set_cell_from = CELL_INVALID
			_last_set_cell_to = CELL_SURROUND_ISLAND
			game_board.set_half_cells(cell_positions, player.id)
			_input_sfx = "surround_island_press"
		else:
			_input_sfx = "surround_island_fail"


func _handle_mb_drag() -> void:
	var cells: Array[Vector2i] = _get_cells_along_line(_last_mouse_pos, _get_global_mouse_position())
	
	for cell: Vector2i in cells:
		_process_drag_cell(cell)
	
	_last_mouse_pos = _get_global_mouse_position()


func _process_drag_cell(cell: Vector2i) -> void:
	var old_cell_value: int = game_board.get_cell(cell)
	if old_cell_value != _last_set_cell_from:
		return
	
	match _last_set_cell_to:
		CELL_WALL, CELL_ISLAND:
			game_board.set_cell(cell, _last_set_cell_to, player.id)
			game_board.set_half_cell(cell, player.id)
			if _last_set_cell_to == CELL_WALL:
				_input_sfx = "drop_wall_press"
			elif _last_set_cell_to == CELL_ISLAND:
				_input_sfx = "drop_island_press"
		CELL_EMPTY:
			if not _cells_to_erase.has(cell):
				_cells_to_erase[cell] = true
				game_board.set_half_cell(cell, player.id)
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
		game_board.set_cells(changes, player.id)
	
	if game_board.has_half_cells(player.id):
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
	
	game_board.clear_half_cells(player.id)
	_cells_to_erase.clear()
	_last_set_cell_from = CELL_INVALID
	_last_set_cell_to = CELL_INVALID


func _handle_mouse_motion() -> void:
	var cell: Vector2i = _mouse_cell()
	if cell != _prev_cell:
		_input_sfx = "cursor_move"
		_prev_cell = cell


func _handle_redo_action() -> void:
	game_board.redo(player.id)
	game_board.validate()
	SoundManager.play_sfx("redo")


func _handle_reset_action() -> void:
	game_board.reset()
	SoundManager.play_sfx("reset")


func _handle_rmb_press() -> void:
	_last_mouse_pos = _get_global_mouse_position()
	var cell: Vector2i = _mouse_cell()
	var current_cell_value: int = game_board.get_cell(cell)
	match current_cell_value:
		CELL_ISLAND:
			_cells_to_erase[cell] = true
			_last_set_cell_from = game_board.get_cell(cell)
			_last_set_cell_to = CELL_EMPTY
			game_board.set_half_cell(cell, player.id)
			_input_sfx = "drop_island_release"
		CELL_EMPTY, CELL_WALL:
			_last_set_cell_from = game_board.get_cell(cell)
			_last_set_cell_to = CELL_ISLAND
			game_board.set_cell(cell, CELL_ISLAND, player.id)
			game_board.set_half_cell(cell, player.id)
			_input_sfx = "drop_island_press"


func _handle_undo_action() -> void:
	game_board.undo(player.id)
	game_board.validate()
	SoundManager.play_sfx("undo")


func _mouse_cell() -> Vector2i:
	return _get_cell_from_position(_get_global_mouse_position())


func _get_cell_from_position(pos: Vector2) -> Vector2i:
	return game_board.global_to_map(pos)


func _get_global_mouse_position() -> Vector2:
	return get_viewport().get_camera_2d().get_global_mouse_position()
