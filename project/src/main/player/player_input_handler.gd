class_name PlayerInputHandler
extends Node

var dir := Vector2.ZERO

func update() -> void:
	dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
