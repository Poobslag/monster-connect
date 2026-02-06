class_name PlayerMoveHandler
extends Node

@onready var monster: Monster = Utils.find_parent_of_type(self, Monster)

func reset() -> void:
	monster.input.dir = Vector2.ZERO


func update() -> void:
	monster.input.dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
