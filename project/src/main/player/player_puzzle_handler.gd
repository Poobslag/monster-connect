class_name PlayerPuzzleHandler
extends Node

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL
const CELL_SURROUND_ISLAND: String = "cell_surround"

var game_board: NurikabeGameBoard = null

var _cells_to_erase: Dictionary[Vector2i, bool] = {}
var _input_sfx: String
var _last_erased_cell_value: String = CELL_INVALID
var _last_set_cell_value: String = CELL_INVALID
var _prev_cell: Vector2i = Vector2i(-577218, -577218)

@onready var input_handler: PlayerInputHandler = get_parent()
@onready var player: Player = find_parent("Player")

func handle(event: InputEvent) -> void:
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
	_last_set_cell_value = CELL_INVALID
	_last_erased_cell_value = CELL_INVALID


func update() -> void:
	return


func _handle_lmb_press() -> void:
	var cell: Vector2i = _mouse_cell()
	var current_cell_string: String = game_board.get_cell_string(cell)
	match current_cell_string:
		CELL_WALL:
			_cells_to_erase[cell] = true
			game_board.set_half_cell(cell, player.id)
			_last_set_cell_value = CELL_EMPTY
			_input_sfx = "drop_wall_release"
		CELL_EMPTY, CELL_ISLAND:
			game_board.set_cell_string(cell, CELL_WALL, player.id)
			game_board.set_half_cell(cell, player.id)
			_last_set_cell_value = CELL_WALL
			_input_sfx = "drop_wall_press"
	if current_cell_string.is_valid_int():
		var changes: Array[Dictionary] = game_board.to_solver_board().surround_island(cell)
		if changes:
			game_board.set_cell_strings(changes, player.id)
			var cell_positions: Array[Vector2i] = []
			for change: Dictionary[String, Variant] in changes:
				cell_positions.append(change["pos"])
			game_board.set_half_cells(cell_positions, player.id)
			_last_set_cell_value = CELL_SURROUND_ISLAND
			_input_sfx = "surround_island_press"
		else:
			_input_sfx = "surround_island_fail"


func _handle_mb_drag() -> void:
	var cell: Vector2i = _mouse_cell()
	var old_cell_string: String = game_board.get_cell_string(cell)
	if old_cell_string == _last_set_cell_value or old_cell_string not in [CELL_EMPTY, CELL_WALL, CELL_ISLAND]:
		return
	
	match _last_set_cell_value:
		CELL_WALL, CELL_ISLAND:
			if game_board.get_cell_string(cell) != _last_set_cell_value:
				game_board.set_cell_string(cell, _last_set_cell_value, player.id)
				game_board.set_half_cell(cell, player.id)
				if _last_set_cell_value == CELL_WALL:
					_input_sfx = "drop_wall_press"
				elif _last_set_cell_value == CELL_ISLAND:
					_input_sfx = "drop_island_press"
		CELL_EMPTY:
			if not cell in _cells_to_erase and game_board.get_cell_string(cell) != CELL_EMPTY:
				_cells_to_erase[cell] = true
				game_board.set_half_cell(cell, player.id)
				if game_board.get_cell_string(cell) == CELL_WALL:
					_input_sfx = "drop_wall_release"
				elif game_board.get_cell_string(cell) == CELL_ISLAND:
					_input_sfx = "drop_island_release"
				_last_erased_cell_value = game_board.get_cell_string(cell)


func _handle_mb_release() -> void:
	if _cells_to_erase:
		var changes: Array[Dictionary] = []
		for cell: Vector2i in _cells_to_erase:
			changes.append({"pos": cell, "value": CELL_EMPTY} as Dictionary[String, Variant])
		game_board.set_cell_strings(changes, player.id)
	
	if game_board.has_half_cells(player.id):
		if _last_set_cell_value == CELL_WALL:
			_input_sfx = "drop_wall_release"
		elif _last_set_cell_value == CELL_ISLAND:
			_input_sfx = "drop_island_release"
		elif _last_set_cell_value == CELL_EMPTY:
			if _last_erased_cell_value == CELL_WALL:
				SoundManager.play_sfx("drop_wall_press")
			elif _last_erased_cell_value == CELL_ISLAND:
				SoundManager.play_sfx("drop_island_press")
		elif _last_set_cell_value == CELL_SURROUND_ISLAND:
			_input_sfx = "surround_island_release"
		game_board.validate()
	
	game_board.clear_half_cells(player.id)
	_cells_to_erase.clear()
	_last_set_cell_value = CELL_INVALID
	_last_erased_cell_value = CELL_INVALID


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
	var cell: Vector2i = _mouse_cell()
	var current_cell_string: String = game_board.get_cell_string(cell)
	match current_cell_string:
		CELL_ISLAND:
			_cells_to_erase[cell] = true
			game_board.set_half_cell(cell, player.id)
			_last_set_cell_value = CELL_EMPTY
			_input_sfx = "drop_island_release"
		CELL_EMPTY, CELL_WALL:
			game_board.set_cell_string(cell, CELL_ISLAND, player.id)
			game_board.set_half_cell(cell, player.id)
			_last_set_cell_value = CELL_ISLAND
			_input_sfx = "drop_island_press"


func _handle_undo_action() -> void:
	game_board.undo(player.id)
	game_board.validate()
	SoundManager.play_sfx("undo")


func _mouse_cell() -> Vector2i:
	return game_board.global_to_map(
			get_viewport().get_camera_2d().get_global_mouse_position())
