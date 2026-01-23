@tool
class_name SimMonster
extends Monster

@onready var input: SimInput = %Input

func update_input() -> void:
	input.update()
