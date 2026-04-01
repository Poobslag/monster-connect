class_name PlayerInput3D
extends MonsterInput3D

var _drag_origin_in_puzzle: Dictionary[int, bool] = {
	MOUSE_BUTTON_LEFT: false,
	MOUSE_BUTTON_RIGHT: false
}

@onready var monster: PlayerMonster3D = get_parent()

@onready var _command_palette: CommandPalette = CommandPalette.find_instance(self)

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
