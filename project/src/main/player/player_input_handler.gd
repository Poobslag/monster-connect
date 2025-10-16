class_name PlayerInputHandler
extends Node

enum InputMethod {
	NONE,
	MOUSE,
	KEYBOARD,
}

const PUZZLE_APPROACH_TOP := 40.0
const PUZZLE_APPROACH_RIGHT := 80.0
const PUZZLE_APPROACH_BOTTOM := 160.0
const PUZZLE_APPROACH_LEFT := 80.0

const MOUSE_STOP_DISTANCE: float = 20.0

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

var dir := Vector2.ZERO

var _last_input_game_board: NurikabeGameBoard = null
var _last_input_method: InputMethod = InputMethod.NONE
var _mouse_target: Vector2
var _mouse_dir: Vector2

@onready var player: Player = get_parent()

func _unhandled_input(event: InputEvent) -> void:
	# wasd
	if event.is_action_pressed("move_left") \
			or event.is_action_pressed("move_right") \
			or event.is_action_pressed("move_up") \
			or event.is_action_pressed("move_down"):
		_last_input_method = InputMethod.KEYBOARD
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_last_input_game_board = player.current_game_board
	
	# pressing/dragging the left mouse button, not on a puzzle
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed \
			or (event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
			and _last_input_game_board == null):
		_last_input_method = InputMethod.MOUSE
		var target_player_position: Vector2
		if player.current_game_board == null:
			target_player_position = player.to_local(_global_mouse_position())
		else:
			var local_puzzle_rect_with_buffer: Rect2 = \
					player.get_global_transform().affine_inverse() \
					* player.current_game_board.get_global_cursorable_rect() \
					.grow_individual(
						PUZZLE_APPROACH_LEFT, PUZZLE_APPROACH_TOP, PUZZLE_APPROACH_RIGHT, PUZZLE_APPROACH_BOTTOM)
		
			if dist_to_rect(local_puzzle_rect_with_buffer, Vector2.ZERO) <= MOUSE_STOP_DISTANCE:
				target_player_position = Vector2.ZERO
			else:
				target_player_position = nearest_point_on_rect(local_puzzle_rect_with_buffer, Vector2.ZERO)
		
		_mouse_target = player.position + target_player_position
		_mouse_dir = (_mouse_target - player.position).normalized()
	
	# pressing the left mouse button on a puzzle
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT and event.pressed \
			and player.current_game_board is NurikabeGameBoard:
		var cell: Vector2i = player.current_game_board.global_to_map(_global_mouse_position())
		var current_cell_string: String = player.current_game_board.get_cell_string(cell)
		match current_cell_string:
			CELL_WALL:
				player.current_game_board.set_cell_string(cell, CELL_EMPTY)
			CELL_EMPTY, CELL_ISLAND:
				player.current_game_board.set_cell_string(cell, CELL_WALL)
		if current_cell_string.is_valid_int():
			var changes: Array[Dictionary] = player.current_game_board.to_model().surround_island(cell)
			player.current_game_board.set_cell_strings(changes)
	
	# pressing the right mouse button on a puzzle
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed \
			and player.current_game_board is NurikabeGameBoard:
		var cell: Vector2i = player.current_game_board.global_to_map(_global_mouse_position())
		var current_cell_string: String = player.current_game_board.get_cell_string(cell)
		match current_cell_string:
			CELL_ISLAND:
				player.current_game_board.set_cell_string(cell, CELL_EMPTY)
			CELL_EMPTY, CELL_WALL:
				player.current_game_board.set_cell_string(cell, CELL_ISLAND)


func update() -> void:
	if _last_input_method == InputMethod.MOUSE:
		var new_dir: Vector2 = (_mouse_target - player.position).normalized()
		if new_dir.dot(_mouse_dir) < 0.9 or _mouse_target.distance_to(player.position) < MOUSE_STOP_DISTANCE:
			reset()
		else:
			dir = new_dir
	else:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")


func reset() -> void:
	dir = Vector2.ZERO
	_mouse_target = Vector2.ZERO
	_mouse_dir = Vector2.ZERO
	_last_input_method = InputMethod.NONE


func _global_mouse_position() -> Vector2:
	return get_viewport().get_camera_2d().get_global_mouse_position()


static func dist_to_rect(rect: Rect2, point: Vector2) -> float:
	var result: float
	if rect.has_point(point):
		result = min(
			abs(point.x - rect.position.x),
			abs(point.y - rect.position.y),
			abs(point.x - rect.end.x),
			abs(point.y - rect.end.y),
		)
	else:
		result = point.clamp(rect.position, rect.end).distance_to(point)
	return result


static func nearest_point_on_rect(rect: Rect2, point: Vector2) -> Vector2:
	var result: Vector2
	if rect.has_point(point):
		var smallest_distance: float = INF
		for candidate_point: Vector2 in [
				Vector2(rect.position.x, point.y),
				Vector2(point.x, rect.position.y),
				Vector2(rect.end.x, point.y),
				Vector2(point.x, rect.end.y)]:
			var distance: float = point.distance_to(candidate_point)
			if distance < smallest_distance:
				smallest_distance = distance
				result = candidate_point
	else:
		result = point.clamp(rect.position, rect.end)
	return result
