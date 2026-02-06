class_name PlayerInput
extends MonsterInput

var _drag_origin_in_puzzle: Dictionary[int, bool] = {
	MOUSE_BUTTON_LEFT: false,
	MOUSE_BUTTON_RIGHT: false
}

@onready var monster: PlayerMonster = get_parent()

@onready var _command_palette: CommandPalette = CommandPalette.find_instance(self)

func _unhandled_input(event: InputEvent) -> void:
	if _command_palette.has_focus():
		return
	
	# Initialize drag ownership when mouse buttons are pressed
	if event is InputEventMouseButton and event.pressed:
		_drag_origin_in_puzzle[event.button_index] = monster.cursor_board != null
	if event is InputEventMouseMotion and not is_any_drag_origin_in_puzzle():
		%PuzzleHandler.game_board = monster.cursor_board
	
	# Route all input based on the drag owner
	monster.cursor.update_position() # ensure cursor position is up to date
	%PuzzleHandler.handle(event)
	
	# Update monster.solving_board
	if event is InputEventMouseButton and event.is_pressed() and monster.cursor_board != null:
		monster.solving_board = monster.cursor_board
	
	# Release drag ownership when mouse buttons are released
	if event is InputEventMouseButton and not event.pressed:
		_drag_origin_in_puzzle[event.button_index] = false
		%PuzzleHandler.game_board = null


func is_any_drag_origin_in_puzzle() -> bool:
	return _drag_origin_in_puzzle.get(MOUSE_BUTTON_LEFT, false) \
			or _drag_origin_in_puzzle.get(MOUSE_BUTTON_RIGHT, false)


func update(_delta: float) -> void:
	if _command_palette.has_focus():
		return
	
	%MoveHandler.update()
	%PuzzleHandler.update()


func reset() -> void:
	%MoveHandler.reset()
	%PuzzleHandler.reset()
