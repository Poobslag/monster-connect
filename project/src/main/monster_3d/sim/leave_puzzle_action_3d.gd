class_name LeavePuzzleAction3D
extends GoapAction

@onready var monster: SimMonster3D = Utils.find_parent_of_type(self, SimMonster3D)

func perform(_delta: float) -> bool:
	monster.solving_board = null
	monster.memory.erase("puzzle.bored_with_puzzle")
	return false
