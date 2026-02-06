@tool
class_name PlayerMonster
extends Monster

var solving_board: NurikabeGameBoard

@onready var input: PlayerInput = %Input

func update_input(delta: float) -> void:
	input.update(delta)
