@tool
class_name PlayerMonster3D
extends Monster

signal solving_board_changed

var solving_board: NurikabeGameBoard3D:
	set(value):
		if solving_board == value:
			return
		solving_board = value
		solving_board_changed.emit()

@onready var input: PlayerInput3D = %Input


func update_input(delta: float) -> void:
	input.update(delta)
