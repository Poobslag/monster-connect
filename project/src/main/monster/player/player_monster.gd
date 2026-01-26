@tool
class_name PlayerMonster
extends Monster

@onready var input: PlayerInput = %Input

func update_input() -> void:
	input.update()
