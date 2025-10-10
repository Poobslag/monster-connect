class_name PlayerInputHandler
extends Node

enum InputMethod {
	NONE,
	MOUSE,
	KEYBOARD,
}

const PUZZLE_APPROACH_DISTANCE: float = 60.0
const MOUSE_STOP_DISTANCE: float = 20.0

const EMPTY = NurikabeUtils.EMPTY
const ISLAND = NurikabeUtils.ISLAND
const WALL = NurikabeUtils.WALL

var dir := Vector2.ZERO

var _last_input_method: InputMethod = InputMethod.NONE
var _mouse_target: Vector2
var _mouse_dir: Vector2

@onready var player: Player = get_parent()

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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_left") \
			or event.is_action_pressed("move_right") \
			or event.is_action_pressed("move_up") \
			or event.is_action_pressed("move_down"):
		_last_input_method = InputMethod.KEYBOARD
	
	if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
			or event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_last_input_method = InputMethod.MOUSE
		var target_global_position: Vector2
		if player.current_game_board == null:
			target_global_position = event.global_position
		else:
			var global_puzzle_rect: Rect2 = player.current_game_board.get_global_cursorable_rect()
			var local_puzzle_rect_with_buffer := Rect2(player.to_local(global_puzzle_rect.position), player.to_local(global_puzzle_rect.size)).grow(PUZZLE_APPROACH_DISTANCE)
			print("58: local_puzzle_rect_with_buffer=%s" % [local_puzzle_rect_with_buffer])
			print("60: dist_to_rect=%s" % [dist_to_rect(local_puzzle_rect_with_buffer, Vector2.ZERO)])
			if dist_to_rect(local_puzzle_rect_with_buffer, Vector2.ZERO) <= MOUSE_STOP_DISTANCE:
				print("61: on edge")
			else:
				print("64: not on edge")
				var global_puzzle_rect_with_buffer := Rect2(player.to_global(local_puzzle_rect_with_buffer.position), player.to_global(local_puzzle_rect_with_buffer.size))
				target_global_position = event.global_position.clamp(global_puzzle_rect_with_buffer.position, global_puzzle_rect_with_buffer.end)
		
		
		_mouse_target = player.position + (target_global_position - player.global_position)
		_mouse_dir = (_mouse_target - player.position).normalized()
	
	if event is InputEventMouseButton \
			and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
			and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) \
			and player.current_game_board is NurikabeGameBoard:
		var cell: Vector2i = player.current_game_board.global_to_map(event.global_position)
		var current_cell_string: String = player.current_game_board.get_cell_string(cell)
		match current_cell_string:
			WALL:
				player.current_game_board.set_cell_string(cell, EMPTY)
			EMPTY, ISLAND:
				player.current_game_board.set_cell_string(cell, WALL)

	if event is InputEventMouseButton \
			and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) \
			and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
			and player.current_game_board is NurikabeGameBoard:
		var cell: Vector2i = player.current_game_board.global_to_map(event.global_position)
		var current_cell_string: String = player.current_game_board.get_cell_string(cell)
		match current_cell_string:
			ISLAND:
				player.current_game_board.set_cell_string(cell, EMPTY)
			EMPTY, WALL:
				player.current_game_board.set_cell_string(cell, ISLAND)

	if event is InputEventMouseButton \
			and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
			and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) \
			and player.current_game_board is NurikabeGameBoard:
		var cell: Vector2i = player.current_game_board.global_to_map(event.global_position)
		var current_cell_string: String = player.current_game_board.get_cell_string(cell)
		if current_cell_string == ISLAND or current_cell_string.is_valid_int():
			player.current_game_board.surround_island(cell)


static func dist_to_rect(rect: Rect2, point: Vector2) -> float:
	return point.clamp(rect.position, rect.end).length()
