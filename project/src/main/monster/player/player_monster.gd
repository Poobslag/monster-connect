@tool
class_name PlayerMonster
extends Monster

signal solving_board_changed

var solving_board: NurikabeGameBoard:
	set(value):
		if solving_board == value:
			return
		solving_board = value
		solving_board_changed.emit()

@onready var input: PlayerInput = %Input

func _ready() -> void:
	super._ready()
	display_name = ""


func update_input(delta: float) -> void:
	input.update(delta)
