extends Node

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

var _last_set_cell_from: int = CELL_INVALID
var _last_set_cell_to: int = CELL_INVALID
var _mb_press_cell: Vector2i = POS_NOT_FOUND

@onready var board: NurikabeGameBoard3D = get_parent()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			_handle_lmb_press()
		else:
			_handle_lmb_release()


func _handle_lmb_press() -> void:
	var board_hit: Dictionary[String, Variant] = board.get_board_hit_at_mouse()
	if not board_hit:
		return
	
	_mb_press_cell = board_hit["cell"]
	var cell_value: int = board.get_cell(_mb_press_cell)
	if cell_value == CELL_EMPTY:
		_last_set_cell_from = CELL_EMPTY
		_last_set_cell_to = CELL_WALL
		board.set_half_cell(_mb_press_cell, 0)
		board.set_cell(_mb_press_cell, CELL_WALL)
	elif cell_value == CELL_WALL:
		_last_set_cell_from = CELL_WALL
		_last_set_cell_to = CELL_ISLAND
		board.set_half_cell(_mb_press_cell, 0)
		board.set_cell(_mb_press_cell, CELL_ISLAND)
	elif cell_value == CELL_ISLAND:
		_last_set_cell_from = CELL_ISLAND
		_last_set_cell_to = CELL_EMPTY
		board.set_half_cell(_mb_press_cell, 0)


func _handle_lmb_release() -> void:
	if _mb_press_cell == POS_NOT_FOUND:
		return
	
	if _last_set_cell_to == CELL_EMPTY:
		board.clear_half_cells(0)
		board.set_cell(_mb_press_cell, CELL_EMPTY)
	elif _last_set_cell_to == CELL_WALL:
		board.clear_half_cells(0)
		board.set_cell(_mb_press_cell, CELL_WALL)
	elif _last_set_cell_to == CELL_ISLAND:
		board.clear_half_cells(0)
		board.set_cell(_mb_press_cell, CELL_ISLAND)
