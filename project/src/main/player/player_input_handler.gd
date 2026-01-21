class_name PlayerInputHandler
extends Node

var _drag_origin_in_puzzle: Dictionary[int, bool] = {
	MOUSE_BUTTON_LEFT: false,
	MOUSE_BUTTON_RIGHT: false
}

var dir: Vector2:
	set(value):
		%MoveHandler.dir = value
	get():
		return %MoveHandler.dir

@onready var player: Player = get_parent()

func _unhandled_input(event: InputEvent) -> void:
	# Initialize drag ownership when mouse buttons are pressed
	if event is InputEventMouseButton and event.pressed:
		_drag_origin_in_puzzle[event.button_index] = player.current_game_board != null
	if event is InputEventMouseMotion and not is_any_drag_origin_in_puzzle():
		%PuzzleHandler.game_board = player.current_game_board
	
	# Route all input based on the drag owner
	%PuzzleHandler.handle(event)
	
	# Release drag ownership when mouse buttons are released
	if event is InputEventMouseButton and not event.pressed:
		_drag_origin_in_puzzle[event.button_index] = false
		%PuzzleHandler.game_board = null


func is_any_drag_origin_in_puzzle() -> bool:
	return _drag_origin_in_puzzle.get(MOUSE_BUTTON_LEFT, false) \
			or _drag_origin_in_puzzle.get(MOUSE_BUTTON_RIGHT, false)


func update() -> void:
	%MoveHandler.update()
	%PuzzleHandler.update()


func reset() -> void:
	%MoveHandler.reset()
	%PuzzleHandler.reset()
