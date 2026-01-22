class_name SimInput
extends MonsterInput

const POS_EPSILON: float = 10.0

var target_puzzle: NurikabeGameBoard

@onready var monster: Monster = Utils.find_parent_of_type(self, Monster)

func update() -> void:
	pass


func move_to(target: Vector2) -> void:
	var pos_diff: Vector2 = target - monster.position
	if pos_diff.length() > POS_EPSILON:
		dir = pos_diff.normalized()
	else:
		dir = Vector2.ZERO
