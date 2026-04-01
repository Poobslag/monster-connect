class_name PlayerMoveHandler3D
extends Node

const PUZZLE_APPROACH: float = 120.0

@onready var monster: PlayerMonster3D = Utils.find_parent_of_type(self, PlayerMonster3D)

func reset() -> void:
	monster.input.dir = Vector2.ZERO


func update() -> void:
	monster.input.dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
