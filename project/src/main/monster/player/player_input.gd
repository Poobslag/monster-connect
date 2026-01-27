class_name PlayerInput
extends MonsterInput

var _drag_origin_in_puzzle: Dictionary[int, bool] = {
	MOUSE_BUTTON_LEFT: false,
	MOUSE_BUTTON_RIGHT: false
}

@onready var monster: Monster = get_parent()

func _unhandled_input(event: InputEvent) -> void:
	# Initialize drag ownership when mouse buttons are pressed
	if event is InputEventMouseButton and event.pressed:
		_drag_origin_in_puzzle[event.button_index] = monster.game_board != null
	if event is InputEventMouseMotion and not is_any_drag_origin_in_puzzle():
		%PuzzleHandler.game_board = monster.game_board
	
	# Route all input based on the drag owner
	monster.cursor.update_position() # ensure cursor position is up to date
	%PuzzleHandler.handle(event)
	
	# Release drag ownership when mouse buttons are released
	if event is InputEventMouseButton and not event.pressed:
		_drag_origin_in_puzzle[event.button_index] = false
		%PuzzleHandler.game_board = null


func is_any_drag_origin_in_puzzle() -> bool:
	return _drag_origin_in_puzzle.get(MOUSE_BUTTON_LEFT, false) \
			or _drag_origin_in_puzzle.get(MOUSE_BUTTON_RIGHT, false)


func update(_delta: float) -> void:
	%MoveHandler.update()
	%PuzzleHandler.update()


func reset() -> void:
	%MoveHandler.reset()
	%PuzzleHandler.reset()
