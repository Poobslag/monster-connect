class_name LeavePuzzleAction
extends GoapAction

func perform(actor: Variant, _delta: float) -> bool:
	var monster: SimMonster = actor
	monster.solving_board = null
	monster.bored_with_puzzle = false
	return false
