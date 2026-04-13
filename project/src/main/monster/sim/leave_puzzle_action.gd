class_name LeavePuzzleAction
extends GoapAction

@onready var monster: SimMonster = Utils.find_parent_of_type(self, SimMonster)

func perform(_delta: float) -> bool:
	monster.solving_board = null
	monster.memory.erase("puzzle.bored_with_puzzle")
	return false
